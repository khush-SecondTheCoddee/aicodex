# TermuxCoderAI (Production-Ready, No Dependencies)

`TermuxCoderAI` is a local coding assistant designed for **Termux (non-root)** with **zero install requirements**.

## Guarantees

- No external APIs.
- No pip/npm/pkg/apt installs.
- Runs with built-in shell tooling (`bash`, `awk`, `sed`, `grep`, `tail`, `date`, etc.).

## Why this is production-ready

- Strict bash mode: `set -euo pipefail`
- Atomic writes for state files (prevents partial/corrupt output)
- Persistent mode/config state
- History rotation (bounded file growth)
- Built-in health checks (`--selftest` / `:selftest`)
- One-shot API mode for scripting (`--prompt "..."`)

## Resource profile (6GB RAM compatible)

- Process memory is lightweight (shell script + small text state files).
- No model weights or background services are loaded.
- Input length and history size are bounded for predictable resource usage.

## Quick start

```bash
chmod +x termux_coder_ai.sh
./termux_coder_ai.sh
```

## Command mode

Inside interactive mode:

- `:help`
- `:mode code`
- `:mode chat`
- `:mode shell`
- `:scaffold python myapp`
- `:status`
- `:selftest`
- `:history`
- `:save output.txt`
- `:quit`

## Non-interactive mode

```bash
./termux_coder_ai.sh --version
./termux_coder_ai.sh --selftest
./termux_coder_ai.sh --prompt "create a python todo app"
```

## Output behavior

- Generates practical code templates for Python/Bash/C/JS requests.
- Can scaffold starter projects for Python/Bash/C.
- Stores state in `~/.termux_coder_ai/`.

## Important note

This is a **local rule-based coding engine** implemented for reliability in restricted environments.
It does not depend on neural model binaries, so it remains usable offline and on constrained mobile devices.
