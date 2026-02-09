# TermuxCoderAI (No Dependencies)

A custom offline coding assistant designed for **Termux (non-root)** using only built-in shell tools.

## Why this fits your requirement

- No package installation required.
- No Python modules, Node modules, or external APIs.
- Runs with `bash` and core utilities available in typical Termux setups.

## Features

- Interactive local coding assistant loop.
- Modes: `code`, `chat`, `shell`.
- Quick scaffold generator for `python`, `bash`, and `c` projects.
- Saves last response and keeps local history.

## Usage

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
Inside the assistant:

- `:help`
- `:mode code`
- `:scaffold python myapp`
- `:save output.txt`
- `:history`
- `:quit`

## Example prompt

- `create a python todo app`
- `explain binary search in simple terms`
- `write a bash backup script`

## Notes

This is a **rule-based local model** (offline assistant behavior) rather than a neural LLM. It is intentionally dependency-free and practical for restricted environments.
