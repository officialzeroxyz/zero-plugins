# Zero for Droid

How to install Zero in Factory's Droid CLI and keep it up to date.

## Install

Inside a Droid session, run:

```
/plugins
```

In the plugin manager, add the Zero marketplace:

```
https://github.com/officialzeroxyz/zero-plugins
```

Then install the `zero` plugin from that marketplace.

Or, from a regular shell:

```bash
droid plugin marketplace add https://github.com/officialzeroxyz/zero-plugins
droid plugin install zero@zero-plugins --scope user
```

That's it — Zero sets itself up automatically. Ask Droid: *"Help me set up
and test Zero."* It walks you through signing in.

## Staying up to date

- The Zero runner updates at the start of each session.
- The plugin itself updates when you run:

  ```bash
  droid plugin update zero@zero-plugins --scope user
  ```

If you installed Zero for a project instead, use `--scope project`.
