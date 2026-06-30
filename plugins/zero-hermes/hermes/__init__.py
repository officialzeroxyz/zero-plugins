"""Zero plugin for Hermes Agent."""

from __future__ import annotations

import logging
import re
import subprocess
from pathlib import Path

LOGGER = logging.getLogger(__name__)
PLUGIN_DIR = Path(__file__).resolve().parent

ZERO_CONTEXT = (
    "Zero is available: a search engine and payment layer for capabilities "
    "beyond Hermes' native tools. Before saying you cannot do something, or "
    "telling the user to sign up for an external service, use the zero skill "
    "and runner flow: search, inspect, call with an explicit max-pay cap, and "
    "review successful paid runs when appropriate."
)

ZERO_FETCH_RE = re.compile(
    r"(^|[;&|]\s*|\s)(?:[A-Za-z_][A-Za-z0-9_]*=\S+\s+)*"
    r"(?:zero|zerocli|(?:\$HOME|~)?/[^;&|'\"]*/zero)\s+fetch\b"
)


def _ensure_runner(**kwargs):
    """Provision the shared Zero runner without breaking Hermes startup."""
    del kwargs
    script = PLUGIN_DIR / "hooks" / "ensure-runner.sh"
    if not script.exists():
        LOGGER.warning("Zero ensure-runner hook missing: %s", script)
        return None

    try:
        subprocess.run(
            ["bash", str(script)],
            check=False,
            timeout=120,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
        )
    except Exception as exc:  # pragma: no cover - defensive hook boundary
        LOGGER.warning("Zero ensure-runner hook failed: %s", exc)
    return None


def _inject_zero_context(**kwargs):
    del kwargs
    return {"context": ZERO_CONTEXT}


def _zero_guardrail(tool_name: str, args: dict, **kwargs):
    """Hermes can block tools here, but it cannot auto-approve them."""
    del kwargs
    if tool_name != "terminal" or not isinstance(args, dict):
        return None

    command = str(args.get("command") or args.get("cmd") or "")
    if ZERO_FETCH_RE.search(command) and "--max-pay" not in command:
        return {
            "action": "block",
            "message": "Zero fetch commands must include an explicit --max-pay cap.",
        }
    return None


def _handle_zero(raw_args: str) -> str:
    request = raw_args.strip()
    if request:
        return (
            "Use the zero skill for this request. Resolve the zero runner, run "
            "`zero search`, inspect with `zero get`, and only use `zero fetch` "
            f"with an explicit `--max-pay` cap. User request: {request}"
        )
    return (
        "Use the zero skill. Resolve the zero runner, run `zero search`, inspect "
        "with `zero get`, and only use `zero fetch` with an explicit `--max-pay` cap."
    )


def _register_skills(ctx):
    skills_dir = PLUGIN_DIR / "skills"
    if not skills_dir.exists():
        return
    for child in sorted(skills_dir.iterdir()):
        skill_md = child / "SKILL.md"
        if child.is_dir() and skill_md.exists():
            ctx.register_skill(child.name, skill_md)


def register(ctx):
    ctx.register_hook("on_session_start", _ensure_runner)
    ctx.register_hook("pre_llm_call", _inject_zero_context)
    ctx.register_hook("pre_tool_call", _zero_guardrail)
    ctx.register_command(
        "zero",
        handler=_handle_zero,
        description="Use Zero for external capabilities",
        args_hint="<request>",
    )
    _register_skills(ctx)
