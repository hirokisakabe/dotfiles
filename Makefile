.DEFAULT_GOAL := help

PACKAGES := zsh vim wezterm git starship yazi bat tig lazygit claude codex copilot gh-dash mise pnpm atuin

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
CODEX_SYSTEM_CONFIG ?= /etc/codex/config.toml
CODEX_CONFIG_SUDO ?= sudo

.PHONY: help test install _install update doctor \
	brew-install brew-update brewfile-dump brew-prune \
	stow-link stow-unlink _clean-legacy-claude-skills-stow \
	mise-install skills-install skills-update \
	gh-extensions-install gh-extensions-update \
	gitalias-install gitalias-update \
	vim-plugins-install vim-plugins-update bat-cache-build \
	claude-permissions-promote \
	codex-system-config-dry-run codex-system-config-install \
	codex-system-config-check codex-system-config-verify

help: ## 利用可能なタスク一覧を表示
	@awk 'BEGIN {FS = ":.*## "; count = 0} /^[a-zA-Z][a-zA-Z0-9_-]*:.*## / {names[count] = $$1; descriptions[count] = $$2; if (length($$1) > width) width = length($$1); count++} END {for (i = 0; i < count; i++) printf "\033[36m%-*s\033[0m %s\n", width + 2, names[i], descriptions[i]}' $(MAKEFILE_LIST)

test: ## Shell script のテストを実行
	./tests/shell-scripts.sh

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
	@AGENT_SKILLS_DIR="$(AGENT_SKILLS_DIR)" \
	CLAUDE_SKILLS_DIR="$(CLAUDE_SKILLS_DIR)" \
	CODEX_SKILLS_DIR="$(CODEX_SKILLS_DIR)" \
		./scripts/skills-install.sh $(AGENT_SKILLS)

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

codex-system-config-dry-run: ## system configの適用内容または差分を表示
	@CODEX_SHARED_CONFIG="$(CODEX_SHARED_CONFIG)" CODEX_SYSTEM_CONFIG="$(CODEX_SYSTEM_CONFIG)" \
		CODEX_CONFIG_SUDO="$(CODEX_CONFIG_SUDO)" ./scripts/codex-system-config.sh dry-run

codex-system-config-install: codex-system-config-dry-run ## 共有Codex設定をsystem configへ導入・更新
	@CODEX_SHARED_CONFIG="$(CODEX_SHARED_CONFIG)" CODEX_SYSTEM_CONFIG="$(CODEX_SYSTEM_CONFIG)" \
		CODEX_CONFIG_SUDO="$(CODEX_CONFIG_SUDO)" ./scripts/codex-system-config.sh install

codex-system-config-check: ## 共有Codex設定を一時CODEX_HOMEで非破壊検証
	@CODEX_SHARED_CONFIG="$(CODEX_SHARED_CONFIG)" CODEX_SYSTEM_CONFIG="$(CODEX_SYSTEM_CONFIG)" \
		CODEX_CONFIG_SUDO="$(CODEX_CONFIG_SUDO)" ./scripts/codex-system-config.sh check

codex-system-config-verify: ## 導入済みsystem configの有効値をcodex doctorで検証
	@CODEX_SHARED_CONFIG="$(CODEX_SHARED_CONFIG)" CODEX_SYSTEM_CONFIG="$(CODEX_SYSTEM_CONFIG)" \
		CODEX_CONFIG_SUDO="$(CODEX_CONFIG_SUDO)" ./scripts/codex-system-config.sh verify

claude-permissions-promote: ## WebFetch 履歴のドメインを Claude Code の許可設定へ反映
	./scripts/promote-webfetch.sh

doctor: ## dotfiles のセットアップ状態を読み取り専用で検査
	@./scripts/doctor.sh $(PACKAGES)
