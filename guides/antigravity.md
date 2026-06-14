# Zero for Google Antigravity CLI

How to install Zero in Google Antigravity CLI and keep it up to date.

## Install

### Install Antigravity CLI

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

Open a fresh terminal so `agy` is on PATH.

### Install Zero

From a checkout of `officialzeroxyz/zero-plugins`:

```bash
scripts/build-antigravity.sh
agy plugin install dist/zero-antigravity
```

That's it — Zero sets itself up automatically. Start Antigravity CLI in your
project with `agy`, then ask: *"Help me set up and test Zero."* It walks you
through signing in.

## Staying up to date

- The Zero runner updates before Antigravity model invocations.
- To update the plugin itself from a fresh checkout of this repo, rebuild and
  reinstall it:

  ```bash
  git pull
  scripts/build-antigravity.sh
  agy plugin install dist/zero-antigravity
  ```
