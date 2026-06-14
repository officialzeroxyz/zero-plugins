# Zero for Continue CLI

How to install Zero in Continue CLI (`cn`) and keep it up to date.

## Install

### Inside Continue CLI

Continue CLI does not have an in-session plugin installer. Install Zero from
the terminal, then restart `cn`.

### From the terminal

From the root of the project where you use Continue:

```bash
rm -rf /tmp/zero-plugins
git clone --depth 1 https://github.com/officialzeroxyz/zero-plugins /tmp/zero-plugins
/tmp/zero-plugins/scripts/build-continue.sh
cp -R /tmp/zero-plugins/dist/zero-continue/. .
```

Restart Continue CLI:

```bash
cn
```

Zero sets itself up automatically. Then ask Continue: *"Help me set up and
test Zero."* It walks you through signing in.

## Staying up to date

- The Zero runner updates at the start of each Continue CLI session.
- To update the project files, rerun the terminal install commands from this
  guide.
