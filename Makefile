.PHONY: install update sync link unlink clean-legacy-claude-skills-stow setup-openhands setup-mcp setup-headroom skills-install promote-webfetch help

PACKAGES := zsh vim wezterm git npm starship yazi bat tig lazygit claude codex copilot worktrunk gh-dash mise pnpm atuin

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Run install.sh to setup dotfiles
	./install.sh

update: ## Update Homebrew itself and packages from Brewfile
	brew update
	brew bundle --file=Brewfile

sync: ## Sync current Homebrew packages to Brewfile
	brew bundle dump --force --file=Brewfile

link: ## Create symlinks with stow and install agent skills via gh skill
	$(MAKE) clean-legacy-claude-skills-stow
	cd packages && stow -v --no-folding -t ~ $(PACKAGES)
	$(MAKE) skills-install

unlink: ## Remove symlinks with stow
	$(MAKE) clean-legacy-claude-skills-stow
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

skills-install: ## Install agent skills globally via gh skill
	gh skill install hirokisakabe/issuekit acceptance-check --agent claude-code --scope user -f
	gh skill install hirokisakabe/issuekit cross-review --agent claude-code --scope user -f
	gh skill install hirokisakabe/issuekit issue-create --agent claude-code --scope user -f
	gh skill install hirokisakabe/issuekit issue-implement --agent claude-code --scope user -f
	gh skill install hirokisakabe/issuekit issue-pick --agent claude-code --scope user -f
	gh skill install hirokisakabe/issuekit issue-refine --agent claude-code --scope user -f
	gh skill install hirokisakabe/issuekit worktree-start --agent claude-code --scope user -f
	gh skill install anthropics/skills frontend-design --agent claude-code --scope user -f
	gh skill install anthropics/skills skill-creator --agent claude-code --scope user -f
	gh skill install vercel-labs/agent-browser agent-browser --agent claude-code --scope user -f

setup-openhands: ## Install OpenHands via uv (uv must be installed)
	uv tool install openhands --python 3.12

setup-headroom: ## Install headroom-ai via pipx (requires Python 3.10-3.13)
	pipx install "headroom-ai[all]" --python python3.13

setup-mcp: ## Setup MCP servers for Claude Code
	-claude mcp add --scope user --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest

promote-webfetch: ## Promote WebFetch domains from history to permissions.allow
	./scripts/promote-webfetch.sh
