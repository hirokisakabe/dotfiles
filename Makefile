.PHONY: install update sync link unlink clean-legacy-claude-skills-stow setup-mcp apm-install promote-webfetch help

PACKAGES := zsh vim wezterm git npm starship yazi bat tig lazygit claude codex worktrunk gh-dash gram mise wtfutil apm issuekit

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Run install.sh to setup dotfiles
	./install.sh

update: ## Update Homebrew packages from Brewfile
	brew bundle --file=Brewfile

sync: ## Sync current Homebrew packages to Brewfile
	brew bundle dump --force --file=Brewfile

link: ## Create symlinks with stow and deploy Claude Code skills via APM
	@mkdir -p ~/.localskills
	$(MAKE) clean-legacy-claude-skills-stow
	cd packages && stow -v --no-folding -t ~ $(PACKAGES)
	ln -snf "$$(pwd)/packages/issuekit" ~/.localskills/issuekit
	$(MAKE) apm-install

unlink: ## Remove symlinks with stow
	$(MAKE) clean-legacy-claude-skills-stow
	cd packages && stow -v --no-folding -D -t ~ $(PACKAGES)
	rm -f ~/.localskills/issuekit

clean-legacy-claude-skills-stow: ## Remove old Stow links for APM-managed Claude Code skills
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

apm-install: ## Deploy Claude Code skills/plugins via APM (uses ~/apm.yml managed by stow)
	@command -v apm >/dev/null 2>&1 || { echo "apm CLI not found on PATH; install with: brew install microsoft/apm/apm" >&2; exit 0; }
	cd $$HOME && apm install

setup-mcp: ## Setup MCP servers for Claude Code
	-claude mcp add --scope user --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest
	-claude mcp add --scope user --transport http asana https://mcp.asana.com/mcp

promote-webfetch: ## Promote WebFetch domains from history to permissions.allow
	./scripts/promote-webfetch.sh
