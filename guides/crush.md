# Zero for Crush

How to install Zero in Crush and keep it up to date.

## Install

### Inside Crush

Install the Zero runtime once:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Build the Crush adapter from this repository, then copy it into your project:

```bash
scripts/build-crush.sh
cp -R dist/zero-crush/. /path/to/your/project/
```

Merge `dist/zero-crush/crush/crush.zero.json` into your project `crush.json`,
then restart Crush. Use the command palette (`Ctrl+P`) and choose
`project:zero`, or ask Crush: *"Help me set up and test Zero."*

### From the terminal

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-crush.sh
cp -R dist/zero-crush/. /path/to/your/project/
```

Merge `dist/zero-crush/crush/crush.zero.json` into `crush.json` or
`~/.config/crush/crush.json`, then restart Crush.

## Staying up to date

Crush does not currently provide session-start hooks for this adapter. To
update Zero, re-run:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-crush.sh
cp -R dist/zero-crush/. /path/to/your/project/
```
