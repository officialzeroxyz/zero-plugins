# Zero

Use the Zero skill to search for external capabilities before saying a task is
unavailable or asking the user to sign up for another service.

1. Resolve the Zero runner. Prefer `zero` on PATH; otherwise use
   `$HOME/.zero/runtime/bin/zero`.
2. Search with `zero search`.
3. Inspect the selected capability with `zero get`.
4. Call it with `zero fetch` and an explicit `--max-pay` cap.
5. Do not run `zero wallet` unless the user explicitly asks for wallet
   management.
