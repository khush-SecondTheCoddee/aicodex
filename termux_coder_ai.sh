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
==========================================================
  TermuxCoderAI - Offline, No-Dependency Coding Assistant
==========================================================
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
  echo "Usage: script.sh <input>"
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    return 1
  fi

  local input="$1"
  echo "You passed: $input"
}

main "$@"
```
EOF_BASH
}

gen_c() {
  cat <<'EOF_C'
```c
#include <stdio.h>

int main(void) {
    printf("Hello from minimal C template!\n");
    return 0;
}
```
EOF_C
}

respond_code() {
  local q="$1"
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
  cat <<EOF_CHAT
$MODEL_NAME says:
- You asked: "$q"
- I can provide code, explain logic, optimize, or debug.
- Switch to :mode code for direct code generation.
EOF_CHAT
}

respond_shell() {
  local q="$1"
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
EOF_P_README
      ;;
    bash|shell)
      cat > "$name/main.sh" <<'EOF_B_MAIN'
#!/usr/bin/env bash
set -euo pipefail

echo "Hello from Bash scaffold"
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
EOF_C_MAIN
      ;;
    *)
      echo "Unsupported scaffold language: $lang"
      return 1
      ;;
  esac
  echo "Scaffold created in ./$name"
}

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

    case "$MODE" in
      code) respond_code "$line" | tee /dev/stderr | write_last_output ;;
      chat) respond_chat "$line" | tee /dev/stderr | write_last_output ;;
      shell) respond_shell "$line" | tee /dev/stderr | write_last_output ;;
    esac
  done
}

main_loop
