.DEFAULT_GOAL := help

PACKAGES := zsh vim wezterm git starship yazi bat tig lazygit claude codex copilot worktrunk gh-dash mise pnpm atuin

AGENT_SKILLS := \
	hirokisakabe/issuekit:acceptance-check \
	hirokisakabe/issuekit:cross-review \
	hirokisakabe/issuekit:issue-create \
	hirokisakabe/issuekit:issue-dispatch \
	hirokisakabe/issuekit:issue-implement \
	hirokisakabe/issuekit:issue-investigate \
	hirokisakabe/issuekit:issue-pick \
	hirokisakabe/issuekit:issue-refine \
	hirokisakabe/issuekit:worktree-start \
	anthropics/skills:frontend-design \
	anthropics/skills:skill-creator \
	vercel-labs/agent-browser:agent-browser

AGENT_SKILLS_DIR ?= $(HOME)/.agents/skills
CLAUDE_SKILLS_DIR ?= $(HOME)/.claude/skills
CODEX_SKILLS_DIR ?= $(HOME)/.codex/skills
CODEX_SHARED_CONFIG := config/codex/config.toml
CODEX_USER_CONFIG ?= $(HOME)/.codex/config.toml
CODEX_SYSTEM_CONFIG ?= /etc/codex/config.toml
CODEX_CONFIG_SUDO ?= sudo

.PHONY: help install _install update doctor \
	brew-install brew-update brewfile-dump brew-prune \
	stow-link stow-unlink _clean-legacy-claude-skills-stow \
	mise-install skills-install skills-update \
	gh-extensions-install gh-extensions-update \
	gitalias-install gitalias-update \
	vim-plugins-install vim-plugins-update bat-cache-build \
	mcp-setup claude-mcp-setup codex-mcp-setup \
	claude-permissions-promote codex-user-config-migrate \
	codex-system-config-dry-run codex-system-config-install \
	codex-system-config-check codex-system-config-verify

help: ## 利用可能なタスク一覧を表示
	@awk 'BEGIN {FS = ":.*## "; count = 0} /^[a-zA-Z][a-zA-Z0-9_-]*:.*## / {names[count] = $$1; descriptions[count] = $$2; if (length($$1) > width) width = length($$1); count++} END {for (i = 0; i < count; i++) printf "\033[36m%-*s\033[0m %s\n", width + 2, names[i], descriptions[i]}' $(MAKEFILE_LIST)

install: ## dotfiles 環境を初回セットアップ
	./install.sh

_install:
	$(MAKE) brew-install
	$(MAKE) stow-link
	$(MAKE) mise-install
	$(MAKE) skills-install
	$(MAKE) gh-extensions-install
	$(MAKE) gitalias-install
	$(MAKE) vim-plugins-install
	$(MAKE) bat-cache-build
	$(MAKE) doctor

update: ## 管理対象のパッケージと外部リソースを更新
	$(MAKE) brew-update
	$(MAKE) skills-update
	$(MAKE) gh-extensions-update
	$(MAKE) gitalias-update
	$(MAKE) vim-plugins-update
	$(MAKE) bat-cache-build

brew-install: ## Brewfile のパッケージをインストール
	brew bundle install --file=Brewfile

brew-update: ## Homebrew と Brewfile のパッケージを更新
	brew update
	brew bundle install --file=Brewfile

brewfile-dump: ## 現在の Homebrew 状態を Brewfile に書き出し
	brew bundle dump --force --file=Brewfile

brew-prune: ## Brewfile にない Homebrew パッケージを確認後に削除
	@output=$$(brew bundle cleanup --file=Brewfile 2>&1); cleanup_status=$$?; \
	printf '%s\n' "$$output"; \
	if [ "$$cleanup_status" -eq 0 ]; then \
		exit 0; \
	fi; \
	if ! printf '%s\n' "$$output" | grep -Fq 'Run `brew bundle cleanup --force`'; then \
		exit "$$cleanup_status"; \
	fi; \
	printf '\nBrewfile にないパッケージを削除しますか? [y/N] '; \
	read -r answer; \
	case "$$answer" in \
		y|Y) brew bundle cleanup --force --file=Brewfile ;; \
		*) printf '%s\n' "削除を中止しました。" ;; \
	esac

stow-link: codex-user-config-migrate ## packages 配下をホームディレクトリへリンク
	$(MAKE) _clean-legacy-claude-skills-stow
	cd packages && stow -v --no-folding -t "$$HOME" $(PACKAGES)

stow-unlink: ## Stow 管理のシンボリックリンクを削除
	$(MAKE) _clean-legacy-claude-skills-stow
	cd packages && stow -v --no-folding -D -t "$$HOME" $(PACKAGES)

_clean-legacy-claude-skills-stow:
	@if [ -L "$$HOME/.claude/skills" ]; then \
		target=$$(readlink "$$HOME/.claude/skills"); \
		case "$$target" in *packages/claude-skills/.claude/skills*) rm -f "$$HOME/.claude/skills" ;; esac; \
	fi
	@if [ -d "$$HOME/.claude/skills" ]; then \
		find "$$HOME/.claude/skills" -type l -print 2>/dev/null | while IFS= read -r link; do \
			target=$$(readlink "$$link"); \
			case "$$target" in *packages/claude-skills/.claude/skills/*) rm -f "$$link" ;; esac; \
		done; \
	fi

mise-install: ## mise 管理の開発ツールをインストール
	mise install

skills-install: ## 管理対象の agent skill をインストール
	@mkdir -p "$(AGENT_SKILLS_DIR)" "$(CLAUDE_SKILLS_DIR)"
	@set -e; \
	is_managed_skill() { \
		skill_file_path="$$1/SKILL.md"; \
		expected_repository="https://github.com/$$2"; \
		expected_skill_path="skills/$$3"; \
		[ -f "$$skill_file_path" ] || return 1; \
		awk -v expected_repository="$$expected_repository" -v expected_skill_path="$$expected_skill_path" ' \
			NR == 1 { if ($$0 != "---") exit 1; frontmatter = 1; next } \
			frontmatter && $$0 == "---" { \
				closed = 1; \
				valid_sha = length(tree_sha) == 40 && tree_sha !~ /[^0-9a-f]/; \
				exit !(metadata_count == 1 && !invalid_metadata && repo_count == 1 && path_count == 1 && sha_count == 1 && repository == expected_repository && skill_path == expected_skill_path && valid_sha); \
			} \
			frontmatter && $$0 == "metadata:" { metadata = 1; metadata_count++; next } \
			metadata && /^[^[:space:]]/ { metadata = 0 } \
			metadata && /^  [^ ]/ { invalid_metadata = 1; metadata = 0 } \
			metadata && /^    github-repo:[[:space:]]*/ { repo_count++; repository = $$0; sub(/^    github-repo:[[:space:]]*/, "", repository); next } \
			metadata && /^    github-path:[[:space:]]*/ { path_count++; skill_path = $$0; sub(/^    github-path:[[:space:]]*/, "", skill_path); next } \
			metadata && /^    github-tree-sha:[[:space:]]*/ { sha_count++; tree_sha = $$0; sub(/^    github-tree-sha:[[:space:]]*/, "", tree_sha); next } \
			END { if (!closed) exit 1 } \
		' "$$skill_file_path" >/dev/null; \
	}; \
	for skill_spec in $(AGENT_SKILLS); do \
		repository=$${skill_spec%:*}; \
		skill=$${skill_spec#*:}; \
		canonical_path="$(AGENT_SKILLS_DIR)/$$skill"; \
		claude_path="$(CLAUDE_SKILLS_DIR)/$$skill"; \
		codex_path="$(CODEX_SKILLS_DIR)/$$skill"; \
		if [ -L "$$canonical_path" ]; then \
			if is_managed_skill "$$canonical_path" "$$repository" "$$skill"; then \
				rm -f "$$canonical_path"; \
			else \
				printf '%s\n' "管理外の symlink と競合しています: $$canonical_path" >&2; \
				exit 1; \
			fi; \
		elif [ -e "$$canonical_path" ] && ! is_managed_skill "$$canonical_path" "$$repository" "$$skill"; then \
			printf '%s\n' "管理外の既存 skill と競合しています: $$canonical_path" >&2; \
			exit 1; \
		fi; \
		gh skill install "$$repository" "$$skill" --dir "$(AGENT_SKILLS_DIR)" -f; \
		if [ -L "$$claude_path" ]; then \
			target=$$(readlink "$$claude_path"); \
			if [ "$$claude_path" -ef "$$canonical_path" ]; then \
				:; \
			elif [ ! -e "$$claude_path" ]; then \
				printf '%s\n' "既存の壊れた外部 symlink を保持します: $$claude_path -> $$target"; \
			elif is_managed_skill "$$claude_path" "$$repository" "$$skill"; then \
				rm -f "$$claude_path"; \
			else \
				printf '%s\n' "既存の外部 symlink を保持します: $$claude_path -> $$target"; \
			fi; \
		elif [ -e "$$claude_path" ]; then \
			if is_managed_skill "$$claude_path" "$$repository" "$$skill"; then \
				rm -rf "$$claude_path"; \
			else \
				printf '%s\n' "管理外の既存 skill を保持します: $$claude_path"; \
			fi; \
		fi; \
		if [ ! -e "$$claude_path" ] && [ ! -L "$$claude_path" ]; then \
			if [ "$(AGENT_SKILLS_DIR)" = "$(HOME)/.agents/skills" ] && [ "$(CLAUDE_SKILLS_DIR)" = "$(HOME)/.claude/skills" ]; then \
				link_target="../../.agents/skills/$$skill"; \
			else \
				link_target="$$canonical_path"; \
			fi; \
			ln -s "$$link_target" "$$claude_path"; \
		fi; \
		if [ -L "$$codex_path" ]; then \
			target=$$(readlink "$$codex_path"); \
			if [ -e "$$codex_path" ] && { [ "$$codex_path" -ef "$$canonical_path" ] || is_managed_skill "$$codex_path" "$$repository" "$$skill"; }; then \
				rm -f "$$codex_path"; \
			else \
				printf '%s\n' "既存の外部 symlink を保持します: $$codex_path -> $$target"; \
			fi; \
		elif [ -e "$$codex_path" ]; then \
			if is_managed_skill "$$codex_path" "$$repository" "$$skill"; then \
				rm -rf "$$codex_path"; \
			else \
				printf '%s\n' "管理外の既存 skill を保持します: $$codex_path"; \
			fi; \
		fi; \
	done

skills-update: ## インストール済みの agent skill を更新
	gh skill update --all --dir "$(AGENT_SKILLS_DIR)"

gh-extensions-install: ## 管理対象の GitHub CLI 拡張をインストール
	gh extension install dlvhdr/gh-dash --force
	gh extension install babarot/gh-infra --force

gh-extensions-update: ## インストール済みの GitHub CLI 拡張を更新
	gh extension upgrade --all

gitalias-install: ## GitAlias をインストール
	mkdir -p "$$HOME/.git-extensions"
	@tmp_file=$$(mktemp "$$HOME/.git-extensions/gitalias.txt.XXXXXX"); \
	trap 'rm -f "$$tmp_file"' EXIT HUP INT TERM; \
	curl -fsSL https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt -o "$$tmp_file"; \
	mv "$$tmp_file" "$$HOME/.git-extensions/gitalias.txt"

gitalias-update: gitalias-install ## GitAlias を更新

vim-plugins-install: ## 管理対象の Vim プラグインをインストール
	@if [ ! -d "$$HOME/.vim/pack/themes/start/iceberg.vim" ]; then \
		mkdir -p "$$HOME/.vim/pack/themes/start"; \
		git clone --depth 1 https://github.com/cocopon/iceberg.vim.git "$$HOME/.vim/pack/themes/start/iceberg.vim"; \
	fi

vim-plugins-update: vim-plugins-install ## 管理対象の Vim プラグインを更新
	git -C "$$HOME/.vim/pack/themes/start/iceberg.vim" pull --ff-only

bat-cache-build: ## bat のテーマキャッシュを再構築
	bat cache --build

mcp-setup: claude-mcp-setup codex-mcp-setup ## AI coding agent の MCP サーバーを設定

claude-mcp-setup: ## Claude Code の MCP サーバーを設定
	@claude mcp get chrome-devtools >/dev/null 2>&1 || \
		claude mcp add --scope user --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest

codex-mcp-setup: ## Codex の MCP サーバーを設定
	@codex mcp get chrome-devtools >/dev/null 2>&1 || \
		codex mcp add chrome-devtools -- npx chrome-devtools-mcp@latest

codex-user-config-migrate: ## 旧Stow symlinkを内容を保持した通常ファイルへ移行
	@set -eu; \
	user_config="$(CODEX_USER_CONFIG)"; \
	legacy_path='packages/codex/.codex/config.toml'; \
	if [ ! -L "$$user_config" ]; then \
		exit 0; \
	fi; \
	link_target=$$(readlink "$$user_config"); \
	case "$$link_target" in \
		/*) target_path="$$link_target" ;; \
		*) target_dir=$$(cd "$$(dirname "$$user_config")/$$(dirname "$$link_target")" 2>/dev/null && pwd -P) || { \
			printf '%s\n' "管理元を確認できない symlink を保持します: $$user_config -> $$link_target" >&2; \
			exit 1; \
		}; \
		target_path="$$target_dir/$$(basename "$$link_target")" ;; \
	esac; \
	target_repo=$$(git -C "$$(dirname "$$target_path")" rev-parse --show-toplevel 2>/dev/null) || { \
		printf '%s\n' "管理外の symlink を保持します: $$user_config -> $$link_target" >&2; \
		exit 1; \
	}; \
	current_common_dir=$$(git rev-parse --path-format=absolute --git-common-dir); \
	target_common_dir=$$(git -C "$$target_repo" rev-parse --path-format=absolute --git-common-dir); \
	current_origin=$$(git config --get remote.origin.url 2>/dev/null || true); \
	target_origin=$$(git -C "$$target_repo" config --get remote.origin.url 2>/dev/null || true); \
	normalize_origin() { printf '%s\n' "$$1" | sed -E 's#^git@github.com:#https://github.com/#; s#^ssh://git@github.com/#https://github.com/#; s#\.git$$##'; }; \
	current_origin=$$(normalize_origin "$$current_origin"); \
	target_origin=$$(normalize_origin "$$target_origin"); \
	if [ "$$target_path" != "$$target_repo/$$legacy_path" ] || { \
		[ "$$target_common_dir" != "$$current_common_dir" ] && { \
			[ -z "$$current_origin" ] || [ "$$target_origin" != "$$current_origin" ]; \
		}; \
	}; then \
		printf '%s\n' "管理外の symlink を保持します: $$user_config -> $$link_target" >&2; \
		exit 1; \
	fi; \
	tmp_file=$$(mktemp "$$(dirname "$$user_config")/.config.toml.migrate.XXXXXX"); \
	trap 'rm -f "$$tmp_file"' 0 1 2 15; \
	if [ -f "$$user_config" ]; then \
		cp -p "$$user_config" "$$tmp_file"; \
	else \
		legacy_commit=$$(for commit in $$(git -C "$$target_repo" log --format=%H --all -- "$$legacy_path"); do \
			if git -C "$$target_repo" cat-file -e "$$commit:$$legacy_path" 2>/dev/null; then \
				printf '%s\n' "$$commit"; \
				break; \
			fi; \
		done); \
		if [ -z "$$legacy_commit" ] || ! git -C "$$target_repo" show "$$legacy_commit:$$legacy_path" >"$$tmp_file"; then \
			printf '%s\n' "旧 user config の内容を復元できません: $$user_config" >&2; \
			exit 1; \
		fi; \
	fi; \
	mv -f "$$tmp_file" "$$user_config"; \
	trap - 0 1 2 15; \
	printf '%s\n' "通常ファイルへ移行しました: $$user_config"

codex-system-config-dry-run: ## system configの適用内容または差分を表示
	@set -eu; \
	source="$(CODEX_SHARED_CONFIG)"; \
	destination="$(CODEX_SYSTEM_CONFIG)"; \
	if $(CODEX_CONFIG_SUDO) test -L "$$destination"; then \
		printf '%s\n' "symlink は自動処理しません: $$destination" >&2; \
		exit 1; \
	fi; \
	if $(CODEX_CONFIG_SUDO) test -e "$$destination"; then \
		tmp_file=$$(mktemp); \
		$(CODEX_CONFIG_SUDO) cat "$$destination" >"$$tmp_file"; \
		if cmp -s "$$tmp_file" "$$source"; then \
			printf '%s\n' "変更はありません: $$destination"; \
		else \
			printf '%s\n' "適用予定の差分: $$destination"; \
			diff -u "$$tmp_file" "$$source" || true; \
		fi; \
		rm -f "$$tmp_file"; \
	else \
		printf '%s\n' "新規作成予定: $$destination"; \
		sed -n '1,$$p' "$$source"; \
	fi

codex-system-config-install: codex-system-config-dry-run ## 共有Codex設定をsystem configへ導入・更新
	@set -eu; \
	source="$(CODEX_SHARED_CONFIG)"; \
	destination="$(CODEX_SYSTEM_CONFIG)"; \
	if $(CODEX_CONFIG_SUDO) test -e "$$destination"; then \
		tmp_file=$$(mktemp); \
		$(CODEX_CONFIG_SUDO) cat "$$destination" >"$$tmp_file"; \
		if cmp -s "$$tmp_file" "$$source"; then \
			rm -f "$$tmp_file"; \
			printf '%s\n' "既に最新です: $$destination"; \
			exit 0; \
		fi; \
		rm -f "$$tmp_file"; \
		printf '既存の %s を上記内容で更新しますか? [y/N] ' "$$destination"; \
		read -r answer; \
		case "$$answer" in y|Y) ;; *) printf '%s\n' '更新を中止しました。'; exit 1 ;; esac; \
	fi; \
	$(CODEX_CONFIG_SUDO) install -d -m 0755 "$$(dirname "$$destination")"; \
	$(CODEX_CONFIG_SUDO) install -m 0644 "$$source" "$$destination"; \
	printf '%s\n' "導入しました: $$destination"

codex-system-config-check: ## 共有Codex設定を一時CODEX_HOMEで非破壊検証
	@set -eu; \
	tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT HUP INT TERM; \
	cp "$(CODEX_SHARED_CONFIG)" "$$tmp_dir/config.toml"; \
	report="$$tmp_dir/doctor.json"; \
	CODEX_HOME="$$tmp_dir" codex doctor --json >"$$report" || true; \
	jq -e ' \
		.checks["config.load"].status == "ok" and \
		(.checks["config.load"].details["feature flag overrides"] | contains("runtime_metrics=true")) and \
		.checks["sandbox.helpers"].details["approval policy"] == "OnRequest" and \
		.checks["sandbox.helpers"].details["filesystem sandbox"] == "unrestricted" \
	' "$$report" >/dev/null; \
	printf '%s\n' '共有Codex設定の読み込みと代表値を確認しました。'

codex-system-config-verify: ## 導入済みsystem configの有効値をcodex doctorで検証
	@set -eu; \
	source="$(CODEX_SHARED_CONFIG)"; \
	destination="$(CODEX_SYSTEM_CONFIG)"; \
	if $(CODEX_CONFIG_SUDO) test -L "$$destination" || ! $(CODEX_CONFIG_SUDO) test -f "$$destination"; then \
		printf '%s\n' "system config が通常ファイルとして導入されていません: $$destination" >&2; \
		exit 1; \
	fi; \
	if ! $(CODEX_CONFIG_SUDO) cmp -s "$$source" "$$destination"; then \
		printf '%s\n' "system config が共有設定の正本と一致しません: $$destination" >&2; \
		exit 1; \
	fi; \
	tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT HUP INT TERM; \
	mkdir "$$tmp_dir/expected-home" "$$tmp_dir/actual-home"; \
	cp "$$source" "$$tmp_dir/expected-home/config.toml"; \
	CODEX_HOME="$$tmp_dir/expected-home" codex doctor --json >"$$tmp_dir/expected.json" || true; \
	CODEX_HOME="$$tmp_dir/actual-home" codex doctor --json >"$$tmp_dir/actual.json" || true; \
	jq -e --slurpfile expected "$$tmp_dir/expected.json" ' \
		.checks["config.load"].status == "ok" and \
		.checks["config.load"].details.model == $$expected[0].checks["config.load"].details.model and \
		.checks["config.load"].details["feature flag overrides"] == $$expected[0].checks["config.load"].details["feature flag overrides"] and \
		.checks["sandbox.helpers"].details["approval policy"] == $$expected[0].checks["sandbox.helpers"].details["approval policy"] and \
		.checks["sandbox.helpers"].details["filesystem sandbox"] == $$expected[0].checks["sandbox.helpers"].details["filesystem sandbox"] \
	' "$$tmp_dir/actual.json" >/dev/null; \
	printf '%s\n' '有効なCodex設定の代表値を確認しました。'

claude-permissions-promote: ## WebFetch 履歴のドメインを Claude Code の許可設定へ反映
	./scripts/promote-webfetch.sh

doctor: ## dotfiles のセットアップ状態を読み取り専用で検査
	@status=0; \
	run_check() { \
		name="$$1"; \
		shift; \
		printf '\n==> %s\n' "$$name"; \
		if "$$@"; then \
			printf '[PASS] %s\n' "$$name"; \
		else \
			printf '[FAIL] %s\n' "$$name" >&2; \
			status=1; \
		fi; \
	}; \
	check_stow() { \
		output=$$(stow --simulate --verbose --no-folding --dir=packages --target="$$HOME" $(PACKAGES) 2>&1); \
		stow_status=$$?; \
		[ -z "$$output" ] || printf '%s\n' "$$output"; \
		[ "$$stow_status" -eq 0 ] || return "$$stow_status"; \
		if printf '%s\n' "$$output" | grep -Eq '^(LINK|MKDIR):'; then \
			printf 'Stow would create links or directories.\n' >&2; \
			return 1; \
		fi; \
	}; \
	check_gh_extensions() { \
		output=$$(gh extension list); \
		printf '%s\n' "$$output" | grep -Fq 'dlvhdr/gh-dash' && \
			printf '%s\n' "$$output" | grep -Fq 'babarot/gh-infra'; \
	}; \
	run_check "Homebrew dependencies" brew bundle check --verbose --file=Brewfile; \
	run_check "Stow links" check_stow; \
	run_check "zsh syntax" zsh -n packages/zsh/.zshrc; \
	run_check "mise installation" mise doctor; \
	run_check "GitHub CLI extensions" check_gh_extensions; \
	run_check "GitAlias" test -f "$$HOME/.git-extensions/gitalias.txt"; \
	run_check "Vim plugins" test -d "$$HOME/.vim/pack/themes/start/iceberg.vim"; \
	run_check "bat theme cache" sh -c 'bat --list-themes | grep -Fxq Iceberg'; \
	printf '\n'; \
	if [ "$$status" -eq 0 ]; then \
		printf 'All checks passed.\n'; \
	else \
		printf 'One or more checks failed.\n' >&2; \
	fi; \
	exit "$$status"
