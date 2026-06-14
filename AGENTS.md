# Repo conventions for agents

- Any time a new agent or harness is added to `guides/agent-install.md`, also
  create a standalone install guide for it in `guides/` (covering install and
  updates only, written for a consumer audience — see the existing guides for
  the shape) and link it from the **Install Zero** list in `README.md`.

## Commit messages

- Every commit and PR title must follow [Conventional Commits](https://www.conventionalcommits.org):
  `type(scope)?: description` (e.g. `fix(guides): correct plugin cache path`).
  PRs are squash-merged, so the **PR title** becomes the commit on `main` — it
  is held to the same rule.
- Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
  `build`, `ci`, `chore`, `revert`. The scope is optional; append `!` after the
  type/scope (e.g. `feat!:`) to flag a breaking change.
- A CI check (`.github/workflows/commit-lint.yml`) enforces this on every PR.

## Versioning

- Any change to what a plugin ships — the skill, hooks, MCP config, or a plugin
  manifest itself — requires a version bump in the **same** change. Don't ship
  plugin behavior changes without one. Docs-only edits that touch nothing the
  plugin ships (READMEs, guides, this file) don't need a bump.
- Bump with the Makefile, never by hand-editing manifests — it keeps every
  host-specific manifest in lockstep on one version:
  - `make patch` — bug fixes / no behavior change (`x.y.Z`)
  - `make minor` — backward-compatible behavior change (`x.Y.0`)
  - `make major` — breaking change (`X.0.0`)
  Choose the level per [semver](https://semver.org); see `CONTRIBUTING.md`.
- When you add a **new** versioned plugin manifest, add its path to the
  `MANIFESTS` list in the `Makefile` so it gets bumped with the rest. The
  Makefile is the single source of truth for which manifests are versioned.
