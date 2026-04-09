.PHONY: install update sync link unlink setup-mcp promote-webfetch help

PACKAGES := zsh vim wezterm git npm starship yazi bat tig lazygit claude codex claude-skills worktrunk gh-dash gram mise wtfutil

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Run install.sh to setup dotfiles
	./install.sh

update: ## Update Homebrew packages from Brewfile
	brew bundle --file=Brewfile

sync: ## Sync current Homebrew packages to Brewfile
	brew bundle dump --force --file=Brewfile

link: ## Create symlinks with stow
	@mkdir -p ~/.config/yazi ~/.claude ~/.codex ~/.config/worktrunk ~/.config/gh-dash ~/.config/gram ~/.config/mise ~/.config/bat/themes ~/.config/lazygit ~/.config/wtf
	cd packages && stow -v -t ~ $(PACKAGES)

unlink: ## Remove symlinks with stow
	cd packages && stow -v -D -t ~ $(PACKAGES)

setup-mcp: ## Setup MCP servers for Claude Code
	-claude mcp add --scope user --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest
	-claude mcp add --scope user --transport http asana https://mcp.asana.com/mcp

promote-webfetch: ## Promote WebFetch domains from history to permissions.allow
	./scripts/promote-webfetch.sh
