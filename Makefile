.PHONY: install update sync link unlink doctor clean-legacy-claude-skills-stow setup-mcp setup-claude-mcp setup-codex-mcp skills-install promote-webfetch help

PACKAGES := zsh vim wezterm git starship yazi bat tig lazygit claude codex copilot worktrunk gh-dash mise pnpm atuin

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

doctor: ## Check dotfiles setup without making changes
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
	run_check "Homebrew dependencies" brew bundle check --verbose --file=Brewfile; \
	run_check "Stow links" check_stow; \
	run_check "zsh syntax" zsh -n packages/zsh/.zshrc; \
	run_check "mise installation" mise doctor; \
	printf '\n'; \
	if [ "$$status" -eq 0 ]; then \
		printf 'All checks passed.\n'; \
	else \
		printf 'One or more checks failed.\n' >&2; \
	fi; \
	exit "$$status"

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

setup-mcp: setup-claude-mcp setup-codex-mcp ## Setup MCP servers for AI coding agents

setup-claude-mcp: ## Setup MCP servers for Claude Code
	-claude mcp add --scope user --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest

setup-codex-mcp: ## Setup MCP servers for Codex
	-codex mcp add chrome-devtools -- npx chrome-devtools-mcp@latest

promote-webfetch: ## Promote WebFetch domains from history to permissions.allow
	./scripts/promote-webfetch.sh
