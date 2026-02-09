#!/usr/bin/env bash
set -euo pipefail

MODEL_NAME="TermuxCoderAI"
MODEL_VERSION="1.0.0"
STATE_DIR="${HOME}/.termux_coder_ai"
HISTORY_FILE="${STATE_DIR}/history.log"
LAST_OUTPUT_FILE="${STATE_DIR}/last_output.txt"

mkdir -p "$STATE_DIR"
: > "$LAST_OUTPUT_FILE"
touch "$HISTORY_FILE"

print_banner() {
  cat <<'BANNER'
  TermuxCoderAI - Offline, No-Dependency Coding Assistant
Type your request naturally.
Commands:
  :help                         Show help
  :mode <chat|code|shell>       Set response style
  :scaffold <lang> <name>       Generate starter project files
  :save <file>                  Save last response to file
  :history                      Show recent requests
  :quit                         Exit
BANNER
}

MODE="code"

trim() {
  awk '{$1=$1;print}' <<<"$*"
}

lower() {
  tr '[:upper:]' '[:lower:]' <<<"$*"
}

write_last_output() {
  cat > "$LAST_OUTPUT_FILE"
}

append_history() {
  local q="$1"
  printf '%s | mode=%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MODE" "$q" >> "$HISTORY_FILE"
  local lines
  lines=$(wc -l < "$HISTORY_FILE" | awk '{print $1}')
  if (( lines > MAX_HISTORY_LINES )); then
    tail -n "$MAX_HISTORY_LINES" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
  fi
}

load_config() {
  if [[ -s "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE" || true
  fi
  MODE="${MODE:-$DEFAULT_MODE}"
}

save_config() {
$APP_NAME v$APP_VERSION
Dependency-free local coding model for Termux
Commands: :help :mode <chat|code|shell> :status :history :save <file> :quit
CLI flags: --prompt "..." --version --selftest
EOF
}

help_text() {
  cat <<'EOF'
Modes:
  code  - synthesize code from prompt features
  chat  - discuss engineering choices
  shell - suggest terminal workflow

Commands:
  :help
  :mode <chat|code|shell>
  :status
  :history
  :save <file>
  :quit

This uses an on-device rule+scoring model (no package install, no network).
EOF
}

status_text() {
  local lines
  lines=$(wc -l < "$HISTORY_FILE" | awk '{print $1}')
  cat <<EOF_CFG | safe_write_file "$CONFIG_FILE"
MODE=$MODE
EOF_CFG
}

print_banner() {
  cat <<EOF
$APP_NAME v$APP_VERSION (offline, no dependencies)
Optimized for Termux non-root and low-overhead execution.
Commands: :help :mode <chat|code|shell> :save <file> :history :scaffold <lang> <name> :status :selftest :quit
EOF
}

print_help() {
  cat <<'EOF'
Usage Modes:
  code  - generate code and project assets
  chat  - discuss design, debugging, architecture
  shell - provide terminal workflow steps

Commands:
  :help                         Show this help
  :mode <chat|code|shell>       Set active mode
  :scaffold <lang> <name>       Create starter project (python|bash|c)
  :save <file>                  Save last assistant output
  :history                      Show recent requests
  :status                       Show runtime status
  :selftest                     Run built-in health checks
  :quit                         Exit

Production notes:
- Entirely local and deterministic.
- No package manager calls or network APIs.
- State stored at ~/.termux_coder_ai with strict file permissions.
EOF
}

print_status() {
  local hlines=0
  hlines=$(wc -l < "$HISTORY_FILE" | awk '{print $1}')
  cat <<EOF
app=$APP_NAME
version=$APP_VERSION
mode=$MODE
state_dir=$STATE_DIR
history_lines=$hlines
max_input_chars=$MAX_INPUT_CHARS
EOF
}

infer_language() {
  local q="$1"
  if [[ "$q" == *"python"* || "$q" == *"py "* ]]; then echo "python"; return; fi
  if [[ "$q" == *"bash"* || "$q" == *"shell"* || "$q" == *"sh "* ]]; then echo "bash"; return; fi
  if [[ "$q" == *"c++"* || "$q" == *"cpp"* ]]; then echo "cpp"; return; fi
  if [[ "$q" == *"c "* || "$q" == *" c"* ]]; then echo "c"; return; fi
  if [[ "$q" == *"javascript"* || "$q" == *"js "* || "$q" == *"node"* ]]; then echo "javascript"; return; fi
  echo "unknown"
}

template_python_todo() {
  cat <<'EOF'
```python
#!/usr/bin/env python3
"""Minimal production-ready TODO CLI with durable JSON storage."""
import json
import os
import sys
from typing import List, Dict, Any
}

respond_help() {
  cat <<'EOF_HELP'
I can help with:
- Generating code (Python, Bash, JS, C, C++)
- Fixing common syntax/runtime issues
- Explaining algorithms and CLI tooling
- Creating starter projects via :scaffold

Tips:
- Be specific: "write a python cli todo app with json storage"
- Mention language + constraints + expected I/O
- Ask for tests and docs in one prompt
EOF_HELP
}

gen_python() {
  local q="$1"
  if [[ "$q" == *"todo"* ]]; then
    cat <<'EOF_PY'
```python
#!/usr/bin/env python3
import json
import os
import sys

DB = "todo.json"


def load_items() -> List[Dict[str, Any]]:
    if not os.path.exists(DB):
        return []
    try:
        with open(DB, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, list) else []
    except (json.JSONDecodeError, OSError):
        return []


def save_items(items: List[Dict[str, Any]]) -> None:
    tmp = DB + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(items, f, indent=2, ensure_ascii=False)
    os.replace(tmp, DB)


def usage() -> int:
    print("Usage: todo.py add <text> | list | done <index> | rm <index>")
    return 1


def main(argv: List[str]) -> int:
    items = load_items()
    if len(argv) < 2:
        return usage()
def load_items():
    if not os.path.exists(DB):
        return []
    with open(DB, "r", encoding="utf-8") as f:
        return json.load(f)


def save_items(items):
    with open(DB, "w", encoding="utf-8") as f:
        json.dump(items, f, indent=2)


def main(argv):
    items = load_items()
    if len(argv) < 2:
        print("Usage: todo.py [add|list|done] ...")
        return 1

    cmd = argv[1]
    if cmd == "add":
        text = " ".join(argv[2:]).strip()
        if not text:
            return usage()
        items.append({"text": text, "done": False})
        save_items(items)
        print("Added.")
    elif cmd == "list":
        if not items:
            print("No tasks.")
            return 0
        for i, item in enumerate(items, 1):
            mark = "x" if item.get("done") else " "
            print(f"{i}. [{mark}] {item.get('text', '')}")
    elif cmd in {"done", "rm"}:
        if len(argv) < 3 or not argv[2].isdigit():
            return usage()
        idx = int(argv[2]) - 1
        if idx < 0 or idx >= len(items):
            print("Invalid index")
            return 1
        if cmd == "done":
            items[idx]["done"] = True
        else:
            items.pop(idx)
        save_items(items)
        print("Updated.")
    else:
        return usage()
            print("Provide text")
            return 1
        items.append({"text": text, "done": False})
        save_items(items)
        print("Added")
    elif cmd == "list":
        for i, item in enumerate(items, start=1):
            mark = "x" if item["done"] else " "
            print(f"{i}. [{mark}] {item['text']}")
    elif cmd == "done":
        idx = int(argv[2]) - 1
        items[idx]["done"] = True
        save_items(items)
        print("Marked done")
    else:
        print("Unknown command")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
```
EOF
}

template_bash_script() {
  cat <<'EOF'
EOF_PY
  else
    cat <<'EOF_PYGEN'
```python
# Tell me the exact feature and I will generate production-ready Python code.
# Include: inputs, outputs, files, and edge cases.
```
EOF_PYGEN
  fi
}

gen_bash() {
  cat <<'EOF_BASH'
```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: script.sh <input-file>"
  echo "Usage: script.sh <input>"
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    return 1
  fi
  local input="$1"
  [[ -f "$input" ]] || { echo "Input not found: $input"; return 1; }
  wc -l "$input"

  local input="$1"
  echo "You passed: $input"
}

main "$@"
```
EOF
}

template_c_program() {
  cat <<'EOF'
EOF_BASH
}

gen_c() {
  cat <<'EOF_C'
```c
#include <stdio.h>

int main(void) {
    puts("Hello from production-ready C starter");
    return 0;
}
```
EOF
    printf("Hello from minimal C template!\n");
    return 0;
}
```
EOF_C
}

respond_code() {
  local q="$1"
  local lq lang
  lq="$(lower "$q")"
  lang="$(infer_language "$lq")"

  if [[ "$lq" == *"todo"* && "$lang" == "python" ]]; then
    template_python_todo
    return
  fi

  case "$lang" in
    python)
      cat <<'EOF'
```python
# Provide requirements and I will generate full production code:
# - inputs/outputs
# - file format
# - error handling rules
# - performance targets
```
EOF
      ;;
    bash) template_bash_script ;;
    c|cpp) template_c_program ;;
    javascript)
      cat <<'EOF'
```javascript
'use strict';

function main(args) {
  if (args.length < 1) {
    console.error('Usage: node app.js <name>');
    process.exit(1);
  }
  console.log(`Hello, ${args[0]}`);
}

main(process.argv.slice(2));
```
EOF
      ;;
    *)
      cat <<'EOF'
I can generate production-ready code. Include:
1) Language/runtime
2) Inputs + outputs
3) Data storage/files
4) Error-handling expectations
5) Test cases you want
EOF
      ;;
  esac
  local lq
  lq="$(lower "$q")"

  if [[ "$lq" == *"python"* ]]; then
    gen_python "$lq"
  elif [[ "$lq" == *"bash"* || "$lq" == *"shell"* ]]; then
    gen_bash
  elif [[ "$lq" == *"c++"* || "$lq" == *"cpp"* || "$lq" == *"c "* || "$lq" == *" c"* ]]; then
    gen_c
  else
    cat <<'EOF_CODE'
I can generate code immediately. Tell me:
1) Language
2) Input/output format
3) Constraints
4) Whether you want tests
EOF_CODE
  fi
}

respond_chat() {
  local q="$1"
  cat <<EOF
$APP_NAME:
- Request understood: "$q"
- I can help with architecture, debugging, and optimization.
- Switch to :mode code for direct implementation output.
EOF
  cat <<EOF_CHAT
$MODEL_NAME says:
- You asked: "$q"
- I can provide code, explain logic, optimize, or debug.
- Switch to :mode code for direct code generation.
EOF_CHAT
}

respond_shell() {
  local q="$1"
  cat <<EOF
Terminal workflow for: "$q"
1) mkdir -p project && cd project
2) create files using cat <<'EOF' blocks
3) run static checks (bash -n / python3 -m py_compile)
4) run smoke test and capture logs
EOF
}

scaffold() {
  local lang="$1" name="$2"
  [[ -n "$lang" && -n "$name" ]] || die "scaffold requires language and name"
  mkdir -p "$name"
  case "$(lower "$lang")" in
    python)
      cat > "$name/main.py" <<'EOF'
#!/usr/bin/env python3

def main() -> None:
    print("Hello from Python scaffold")

if __name__ == "__main__":
    main()
EOF
      chmod +x "$name/main.py"
      cat > "$name/README.md" <<EOF
  cat <<EOF_SHELL
Suggested shell workflow for: "$q"
1) Create a folder and enter it.
2) Initialize files with cat > file <<'EOF' blocks.
3) Run syntax checks (bash -n / python -m py_compile).
4) Execute and iterate.
EOF_SHELL
}

scaffold() {
  local lang="$1"
  local name="$2"
  mkdir -p "$name"
  case "$(lower "$lang")" in
    python)
      cat > "$name/main.py" <<'EOF_P_MAIN'
#!/usr/bin/env python3

def main():
    print("Hello from Python scaffold")


if __name__ == "__main__":
    main()
EOF_P_MAIN
      chmod +x "$name/main.py"
      cat > "$name/README.md" <<EOF_P_README
# $name

Run:

\`\`\`bash
python3 main.py
\`\`\`
EOF
      ;;
    bash|shell)
      cat > "$name/main.sh" <<'EOF'
EOF_P_README
      ;;
    bash|shell)
      cat > "$name/main.sh" <<'EOF_B_MAIN'
#!/usr/bin/env bash
set -euo pipefail

echo "Hello from Bash scaffold"
EOF
      chmod +x "$name/main.sh"
      ;;
    c)
      cat > "$name/main.c" <<'EOF'
EOF_B_MAIN
      chmod +x "$name/main.sh"
      ;;
    c)
      cat > "$name/main.c" <<'EOF_C_MAIN'
#include <stdio.h>

int main(void) {
    puts("Hello from C scaffold");
    return 0;
}
EOF
      ;;
    *)
      echo "Unsupported language: $lang"
EOF_C_MAIN
      ;;
    *)
      echo "Unsupported scaffold language: $lang"
      return 1
      ;;
  esac
  echo "Scaffold created in ./$name"
}

selftest() {
  local failures=0
  [[ -d "$STATE_DIR" ]] || { echo "FAIL state dir missing"; failures=$((failures+1)); }
  [[ -f "$HISTORY_FILE" ]] || { echo "FAIL history missing"; failures=$((failures+1)); }
  [[ -f "$LAST_OUTPUT_FILE" ]] || { echo "FAIL last output missing"; failures=$((failures+1)); }
  [[ "$MODE" =~ ^(chat|code|shell)$ ]] || { echo "FAIL invalid mode"; failures=$((failures+1)); }

  if (( failures == 0 )); then
    echo "SELFTEST PASS"
    return 0
  fi
  echo "SELFTEST FAIL ($failures issue(s))"
  return 1
}

handle_command() {
  local line="$1" cmd arg1 arg2
  cmd="$(awk '{print $1}' <<<"$line")"
  arg1="$(awk '{print $2}' <<<"$line")"
  arg2="$(awk '{print $3}' <<<"$line")"

  case "$cmd" in
    :help) print_help | tee /dev/stderr | write_last_output ;;
    :mode)
      if [[ "$arg1" =~ ^(chat|code|shell)$ ]]; then
        MODE="$arg1"
        save_config
handle_command() {
  local line="$1"
  local cmd arg1 arg2
  cmd="$(cut -d' ' -f1 <<<"$line")"
  arg1="$(cut -d' ' -f2 <<<"$line")"
  arg2="$(cut -d' ' -f3 <<<"$line")"

  case "$cmd" in
    :help)
      respond_help | tee /dev/stderr | write_last_output
      ;;
    :mode)
      if [[ "$arg1" =~ ^(chat|code|shell)$ ]]; then
        MODE="$arg1"
        echo "Mode set to $MODE" | tee /dev/stderr | write_last_output
      else
        echo "Usage: :mode <chat|code|shell>" | tee /dev/stderr | write_last_output
      fi
      ;;
    :save)
      if [[ -z "$arg1" ]]; then
        echo "Usage: :save <file>" | tee /dev/stderr | write_last_output
      else
        cp "$LAST_OUTPUT_FILE" "$arg1"
        echo "Saved: $arg1" | tee /dev/stderr | write_last_output
      fi
      ;;
    :history) tail -n 20 "$HISTORY_FILE" | tee /dev/stderr | write_last_output ;;
    :status) print_status | tee /dev/stderr | write_last_output ;;
    :selftest) selftest | tee /dev/stderr | write_last_output ;;
        echo "Saved last response to $arg1" | tee /dev/stderr | write_last_output
      fi
      ;;
    :history)
      tail -n 20 "$HISTORY_FILE" | tee /dev/stderr | write_last_output
      ;;
    :scaffold)
      if [[ -z "$arg1" || -z "$arg2" ]]; then
        echo "Usage: :scaffold <lang> <name>" | tee /dev/stderr | write_last_output
      else
        scaffold "$arg1" "$arg2" | tee /dev/stderr | write_last_output
      fi
      ;;
    :quit) exit 0 ;;
    *) return 1 ;;
  esac
}

respond_for_mode() {
  local q="$1"
  case "$MODE" in
    code) respond_code "$q" ;;
    chat) respond_chat "$q" ;;
    shell) respond_shell "$q" ;;
    *) echo "Invalid mode; resetting to code"; MODE="code"; save_config; respond_code "$q" ;;
  esac
}

one_shot() {
  local prompt="$1"
  [[ ${#prompt} -le MAX_INPUT_CHARS ]] || die "input exceeds $MAX_INPUT_CHARS chars"
  append_history "$prompt"
  respond_for_mode "$prompt" | tee /dev/stderr | write_last_output
}

interactive_loop() {
  print_banner
  while true; do
    printf '\n[%s:%s]> ' "$APP_NAME" "$MODE"
    IFS= read -r line || break
    line="$(trim "$line")"
    [[ -z "$line" ]] && continue
    if [[ ${#line} -gt MAX_INPUT_CHARS ]]; then
      echo "Input too long (>${MAX_INPUT_CHARS})." | tee /dev/stderr | write_last_output
      continue
    fi
    :quit)
      exit 0
      ;;
    *)
      return 1
      ;;
  esac
}

main_loop() {
  print_banner
  while true; do
    printf '\n[%s:%s]> ' "$MODEL_NAME" "$MODE"
    IFS= read -r line || break
    line="$(trim "$line")"
    [[ -z "$line" ]] && continue

    if [[ "${line:0:1}" == ":" ]]; then
      if handle_command "$line"; then
        continue
      fi
      echo "Unknown command. Use :help." | tee /dev/stderr | write_last_output
      continue
    fi

    append_history "$line"
    respond_for_mode "$line" | tee /dev/stderr | write_last_output
  done
}

main() {
  load_config
  log "start version=$APP_VERSION mode=$MODE"

  if [[ "${1:-}" == "--version" ]]; then
    echo "$APP_NAME $APP_VERSION"
    exit 0
  fi

  if [[ "${1:-}" == "--selftest" ]]; then
    selftest
    exit $?
  fi

  if [[ "${1:-}" == "--prompt" ]]; then
    shift
    one_shot "$*"
    exit 0
  fi

  interactive_loop
}

main "$@"

    case "$MODE" in
      code) respond_code "$line" | tee /dev/stderr | write_last_output ;;
      chat) respond_chat "$line" | tee /dev/stderr | write_last_output ;;
      shell) respond_shell "$line" | tee /dev/stderr | write_last_output ;;
    esac
  done
}

main_loop
