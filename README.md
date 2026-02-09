# TermuxCoderAI (Local Coding Model, No Dependencies)

TermuxCoderAI is a dependency-free coding assistant for Termux non-root.

## What changed

This version removes static template-only behavior and uses a lightweight on-device **intent scoring + code synthesis model**:

- Detects language from prompt.
- Scores requested features (CLI, file I/O, classes, algorithms, API/server intent).
- Synthesizes code structure from those features.
- Outputs runnable starter implementations (not fixed one-template responses).

## Why it runs on 6GB RAM

- Single Bash process.
- No model weights, no background daemon, no network calls.
- Bounded input size and bounded history log.

## Requirements

Only pre-available shell tools:

- `bash`
- `awk`, `tail`, `wc`, `date`, `cp`, `mv`, `cat`

No installs required.

## Usage

```bash
chmod +x termux_coder_ai.sh
./termux_coder_ai.sh
```

### Interactive commands

- `:help`
- `:mode code|chat|shell`
- `:status`
- `:history`
- `:save output.txt`
- `:quit`

### Non-interactive

```bash
./termux_coder_ai.sh --version
./termux_coder_ai.sh --selftest
./termux_coder_ai.sh --prompt "build a python cli todo with json storage"
```

## Notes

This is a practical local coding model implemented with deterministic, inspectable logic suitable for offline constrained environments.
