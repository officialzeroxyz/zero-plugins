# Zero plugins — release helpers.
#
# The plugin ships from several host-specific manifests that must stay in
# lockstep on a single semver version. `make patch|minor|major` bumps the
# version in EVERY manifest below at once, so they never drift.
#
#   make patch   # bug fixes / docs / no behavior change      x.y.Z -> x.y.(Z+1)
#   make minor   # backward-compatible behavior change        x.Y.z -> x.(Y+1).0
#   make major   # breaking change                            X.y.z -> (X+1).0.0
#   make version # print the current version
#
# IMPORTANT: when you add a new versioned plugin manifest, add its path to
# MANIFESTS below so it gets bumped with the others. See AGENTS.md / CONTRIBUTING.md.

# Every versioned plugin manifest. Keep this list complete (see note above).
MANIFESTS := \
	plugins/zero/.claude-plugin/plugin.json \
	plugins/zero/.codex-plugin/plugin.json \
	plugins/zero/.factory-plugin/plugin.json \
	plugins/zero-mcp/.claude-plugin/plugin.json \
	plugins/zero-mcp/.codex-plugin/plugin.json \
	plugins/zero-gemini/gemini-extension.json \
	plugins/zero-hermes/manifest.json \
	plugins/zero-hermes/hermes/plugin.yaml

# The manifest read for the current version (all of MANIFESTS stay in lockstep).
VERSION_SOURCE := plugins/zero/.claude-plugin/plugin.json

.DEFAULT_GOAL := help
.PHONY: help version patch minor major bump

help: ## Show this help
	@echo "Zero plugins — make targets:"
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | sort | \
		awk -F':.*## ' '{ printf "  %-8s %s\n", $$1, $$2 }'
	@echo ""
	@echo "Current version: $$(jq -r .version $(VERSION_SOURCE))"

version: ## Print the current plugin version
	@jq -r .version $(VERSION_SOURCE)

patch: ## Bump the patch version (x.y.Z) across all manifests
	@$(MAKE) --no-print-directory bump PART=patch

minor: ## Bump the minor version (x.Y.0) across all manifests
	@$(MAKE) --no-print-directory bump PART=minor

major: ## Bump the major version (X.0.0) across all manifests
	@$(MAKE) --no-print-directory bump PART=major

# Internal: bump PART={patch|minor|major} in every manifest.
bump:
	@command -v jq >/dev/null 2>&1 || { echo "make: jq is required (brew install jq)" >&2; exit 1; }
	@current=$$(jq -r .version $(VERSION_SOURCE)); \
	major=$${current%%.*}; rest=$${current#*.}; minor=$${rest%%.*}; patch=$${rest##*.}; \
	case "$(PART)" in \
	  patch) patch=$$((patch + 1));; \
	  minor) minor=$$((minor + 1)); patch=0;; \
	  major) major=$$((major + 1)); minor=0; patch=0;; \
	  *) echo "make: unknown PART '$(PART)' (use patch|minor|major)" >&2; exit 1;; \
	esac; \
	next="$$major.$$minor.$$patch"; \
	for m in $(MANIFESTS); do \
	  [ -f "$$m" ] || { echo "make: missing manifest: $$m" >&2; exit 1; }; \
	  grep -Eq '"version"|^version:' "$$m" || { echo "make: no version key in $$m" >&2; exit 1; }; \
	  tmp=$$(mktemp); \
	  sed -e 's/\("version"[[:space:]]*:[[:space:]]*"\)[^"]*"/\1'"$$next"'"/' \
	      -e 's/^version:[[:space:]]*.*/version: '"$$next"'/' "$$m" > "$$tmp" && mv "$$tmp" "$$m"; \
	  echo "  $$m -> $$next"; \
	done; \
	echo "Bumped $$current -> $$next"
