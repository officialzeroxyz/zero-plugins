# Contributing

Thanks for helping improve the Zero plugins. This repo is built up iteratively,
one carefully reviewed PR at a time — keep changes focused and explain the
"why" in your PR description.

## Versioning

The plugin ships from several host-specific manifests (Claude Code, Codex, and
the Gemini overlay). They are kept **in lockstep on a single [semver](https://semver.org)
version** so every host installs the same release.

**Any change to what a plugin ships must bump the version in the same PR.** That
includes the `zero` skill, the hooks, the MCP configuration, and the manifests
themselves — anything an installed plugin actually delivers. Pure documentation
changes that don't touch shipped files (the README, the `guides/`, this file)
don't need a bump.

Pick the level by the nature of the change:

| Command       | When                                                        | Example                                            |
| ------------- | ----------------------------------------------------------- | -------------------------------------------------- |
| `make patch`  | Bug fixes, wording/typo fixes, no behavior change (`x.y.Z`) | Fix a broken path in a hook script                 |
| `make minor`  | Backward-compatible behavior change (`x.Y.0`)               | Add a new step to the skill; new hook              |
| `make major`  | Breaking change (`X.0.0`)                                   | Remove or rename something installs depend on      |

Always bump through the Makefile — never hand-edit the `version` field in a
manifest. The targets rewrite every manifest at once, so the versions can't
drift:

```bash
make version   # print the current version
make patch     # 1.3.2 -> 1.3.3
make minor     # 1.3.2 -> 1.4.0
make major     # 1.3.2 -> 2.0.0
```

(`make` with no target prints the available commands and the current version.
The bump targets require [`jq`](https://stedolan.github.io/jq/).)

A CI check (`.github/workflows/version-check.yml`) enforces this on every PR: it
fails if shipped plugin files changed without a version bump, or if the
manifests fall out of lockstep. Plugin READMEs are treated as docs and don't
trip it.

### Adding a new plugin manifest

When you introduce a new versioned manifest (e.g. support for another host),
add its path to the `MANIFESTS` list in the `Makefile` so it's bumped along
with the others. The Makefile is the single source of truth for which manifests
are versioned — if it isn't in that list, it will silently drift out of sync.
