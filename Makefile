.PHONY: install update sync link unlink clean-legacy-claude-skills-stow clean-legacy-apm setup-mcp skills-install promote-webfetch help

PACKAGES := zsh vim wezterm git npm starship yazi bat tig lazygit claude codex worktrunk gh-dash gram mise

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Run install.sh to setup dotfiles
	./install.sh

update: ## Update Homebrew packages from Brewfile
	brew bundle --file=Brewfile

sync: ## Sync current Homebrew packages to Brewfile
	brew bundle dump --force --file=Brewfile

link: ## Create symlinks with stow and install Claude Code skills via skills.sh
	$(MAKE) clean-legacy-claude-skills-stow
	$(MAKE) clean-legacy-apm
	cd packages && stow -v --no-folding -t ~ $(PACKAGES)
	$(MAKE) skills-install

unlink: ## Remove symlinks with stow
	$(MAKE) clean-legacy-claude-skills-stow
	$(MAKE) clean-legacy-apm
	cd packages && stow -v --no-folding -D -t ~ $(PACKAGES)

clean-legacy-claude-skills-stow: ## Remove old Stow links for legacy Claude Code skills package
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

clean-legacy-apm: ## Remove legacy APM artefacts (~/apm.yml symlink) from old stow setup
	@if [ -L "$$HOME/apm.yml" ]; then \
		target=$$(readlink "$$HOME/apm.yml"); \
		case "$$target" in *packages/apm/apm.yml*) rm -f "$$HOME/apm.yml" ;; esac; \
	fi

skills-install: ## Install Claude Code skills globally via skills.sh
	@command -v npx >/dev/null 2>&1 || { echo "npx not found on PATH; skipping skills install (install Node via mise first)" >&2; exit 0; }
	npx -y skills@latest add hirokisakabe/issuekit --global -y
	npx -y skills@latest add anthropics/skills --skill frontend-design --global -y
	npx -y skills@latest add anthropics/skills --skill skill-creator --global -y
	npx -y skills@latest add vercel-labs/agent-browser --global -y

setup-mcp: ## Setup MCP servers for Claude Code
	-claude mcp add --scope user --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest
	-claude mcp add --scope user --transport http asana https://mcp.asana.com/mcp

promote-webfetch: ## Promote WebFetch domains from history to permissions.allow
	./scripts/promote-webfetch.sh
