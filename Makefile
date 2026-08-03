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

.PHONY: help install _install update doctor \
	brew-install brew-update brewfile-dump brew-prune \
	stow-link stow-unlink _clean-legacy-claude-skills-stow \
	mise-install skills-install skills-update \
	gh-extensions-install gh-extensions-update \
	gitalias-install gitalias-update \
	vim-plugins-install vim-plugins-update bat-cache-build \
	mcp-setup claude-mcp-setup codex-mcp-setup \
	claude-permissions-promote

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

stow-link: ## packages 配下をホームディレクトリへリンク
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
		[ -f "$$skill_file_path" ] || return 1; \
		metadata_repository=$$(sed -n 's/^[[:space:]]*github-repo:[[:space:]]*//p' "$$skill_file_path" | head -n 1); \
		[ "$$metadata_repository" = "$$expected_repository" ]; \
	}; \
	for skill_spec in $(AGENT_SKILLS); do \
		repository=$${skill_spec%:*}; \
		skill=$${skill_spec#*:}; \
		canonical_path="$(AGENT_SKILLS_DIR)/$$skill"; \
		claude_path="$(CLAUDE_SKILLS_DIR)/$$skill"; \
		codex_path="$(CODEX_SKILLS_DIR)/$$skill"; \
		if [ -L "$$canonical_path" ]; then \
			if is_managed_skill "$$canonical_path" "$$repository"; then \
				rm -f "$$canonical_path"; \
			else \
				printf '%s\n' "管理外の symlink と競合しています: $$canonical_path" >&2; \
				exit 1; \
			fi; \
		fi; \
		gh skill install "$$repository" "$$skill" --dir "$(AGENT_SKILLS_DIR)" -f; \
		if [ -L "$$claude_path" ]; then \
			target=$$(readlink "$$claude_path"); \
			if [ "$$claude_path" -ef "$$canonical_path" ]; then \
				:; \
			elif [ ! -e "$$claude_path" ]; then \
				rm -f "$$claude_path"; \
			elif is_managed_skill "$$claude_path" "$$repository"; then \
				rm -f "$$claude_path"; \
			else \
				printf '%s\n' "既存の外部 symlink を保持します: $$claude_path -> $$target"; \
			fi; \
		elif [ -e "$$claude_path" ]; then \
			if is_managed_skill "$$claude_path" "$$repository"; then \
				rm -rf "$$claude_path"; \
			else \
				printf '%s\n' "管理外の既存 skill を保持します: $$claude_path"; \
			fi; \
		fi; \
		if [ ! -e "$$claude_path" ] && [ ! -L "$$claude_path" ]; then \
			ln -s "$$canonical_path" "$$claude_path"; \
		fi; \
		if [ -L "$$codex_path" ]; then \
			target=$$(readlink "$$codex_path"); \
			if [ ! -e "$$codex_path" ] || [ "$$codex_path" -ef "$$canonical_path" ] || is_managed_skill "$$codex_path" "$$repository"; then \
				rm -f "$$codex_path"; \
			else \
				printf '%s\n' "既存の外部 symlink を保持します: $$codex_path -> $$target"; \
			fi; \
		elif [ -e "$$codex_path" ]; then \
			if is_managed_skill "$$codex_path" "$$repository"; then \
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
