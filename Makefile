.DEFAULT_GOAL := help

PACKAGES := zsh vim wezterm iterm2 git starship yazi bat tig lazygit claude codex copilot gh-dash mise pnpm atuin vscode

# owner/repo:skill-name または owner/repo:path/to/skill で指定する。
AGENT_SKILLS := \
	hirokisakabe/issuekit:acceptance-check \
	hirokisakabe/issuekit:cross-review \
	hirokisakabe/issuekit:issue-create \
	hirokisakabe/issuekit:issue-discover \
	hirokisakabe/issuekit:issue-dispatch \
	hirokisakabe/issuekit:issue-implement \
	hirokisakabe/issuekit:issue-investigate \
	hirokisakabe/issuekit:issue-pick \
	hirokisakabe/issuekit:issue-refine \
	hirokisakabe/issuekit:worktree-start \
	anthropics/skills:frontend-design \
	anthropics/skills:skill-creator \
	jakubkrehel/make-interfaces-feel-better:make-interfaces-feel-better \
	Owl-Listener/designer-skills:visual-critique/skills/critique-affordance \
	Owl-Listener/designer-skills:visual-critique/skills/critique-composition \
	Owl-Listener/designer-skills:visual-critique/skills/critique-information-density \
	Owl-Listener/designer-skills:visual-critique/skills/critique-visual-hierarchy \
	Owl-Listener/designer-skills:designer-toolkit/skills/ux-writing \
	vercel-labs/agent-browser:agent-browser

# skillの正本は共通ディレクトリ。Codexは直接参照し、Claudeはsymlink経由で参照する。
AGENT_SKILLS_DIR ?= $(HOME)/.agents/skills
CLAUDE_SKILLS_DIR ?= $(HOME)/.claude/skills
CODEX_SKILLS_DIR ?= $(HOME)/.codex/skills
CODEX_SHARED_CONFIG := config/codex/config.toml
CODEX_SYSTEM_CONFIG ?= /etc/codex/config.toml
CODEX_CONFIG_SUDO ?= sudo

.PHONY: help test install _install update doctor iterm2-configure \
	brew-install brew-update brewfile-dump brew-prune \
	stow-link stow-unlink _clean-legacy-claude-skills-stow \
	mise-install skills-install skills-update \
	gh-extensions-install gh-extensions-update \
	gitalias-install gitalias-update \
	vim-plugins-install vim-plugins-update bat-cache-build \
	codex-system-config-dry-run codex-system-config-install \
	codex-system-config-check codex-system-config-verify

help: ## 利用可能なタスク一覧を表示
	@awk 'BEGIN {FS = ":.*## "; count = 0} /^[a-zA-Z][a-zA-Z0-9_-]*:.*## / {names[count] = $$1; descriptions[count] = $$2; if (length($$1) > width) width = length($$1); count++} END {for (i = 0; i < count; i++) printf "\033[36m%-*s\033[0m %s\n", width + 2, names[i], descriptions[i]}' $(MAKEFILE_LIST)

test: ## スクリプトのテストを実行
	./tests/shell-scripts.sh
	python3 tests/claude-session-launcher.py

install: ## dotfiles 環境を初回セットアップ
	./install.sh

_install:
	$(MAKE) brew-install
	$(MAKE) stow-link
	$(MAKE) iterm2-configure
	$(MAKE) mise-install
	$(MAKE) skills-install
	$(MAKE) gh-extensions-install
	$(MAKE) gitalias-install
	$(MAKE) vim-plugins-install
	$(MAKE) bat-cache-build
	$(MAKE) doctor

update: ## インストール済み Homebrew パッケージと管理対象の外部リソースを更新
	$(MAKE) brew-update
	$(MAKE) skills-update
	$(MAKE) gh-extensions-update
	$(MAKE) gitalias-update
	$(MAKE) vim-plugins-update
	$(MAKE) bat-cache-build

brew-install: ## Brewfile のパッケージをインストール
	brew bundle install --file=Brewfile

brew-update: ## インストール済み Homebrew パッケージを全更新し Brewfile を適用
	brew update
	brew upgrade --no-ask
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

# GUI変更は正本に自動保存しない。継続する変更はpackages/iterm2内のplistを編集する。
iterm2-configure: ## Stow管理のiTerm2設定を次回起動から読み込む
	@test -f "$$HOME/.config/iterm2/com.googlecode.iterm2.plist" || { echo '先に make stow-link を実行してください。' >&2; exit 1; }
	defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$$HOME/.config/iterm2"
	defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
	defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true
	defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 1

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

# 共有Codex設定はmake installの対象外。初回・更新時は以下を順に実行する。
# make codex-system-config-dry-run → make codex-system-config-install → make codex-system-config-verify
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

doctor: ## dotfiles のセットアップ状態を読み取り専用で検査
	@./scripts/doctor.sh $(PACKAGES)
