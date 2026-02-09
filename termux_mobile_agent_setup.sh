#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

if [[ "${PREFIX:-}" != *"com.termux"* ]]; then
  fail "This installer must run inside Termux."
fi

BASE_DIR="$HOME/mobile-coder-agent"
BIN_DIR="$BASE_DIR/bin"
MODELS_DIR="$BASE_DIR/models"
MEMORY_DIR="$BASE_DIR/memory"
WORKSPACES_DIR="$BASE_DIR/workspaces"
LOGS_DIR="$BASE_DIR/logs"
VENV_DIR="$BASE_DIR/.venv"
LLAMA_DIR="$BASE_DIR/llama.cpp"

mkdir -p "$BIN_DIR" "$MODELS_DIR" "$MEMORY_DIR" "$WORKSPACES_DIR" "$LOGS_DIR"

log "Updating packages..."
pkg update -y && pkg upgrade -y

log "Installing dependencies..."
pkg install -y \
  git cmake make clang python nodejs-lts wget curl jq libandroid-spawn \
  openssl-tool termux-api

if ! command -v termux-setup-storage >/dev/null 2>&1; then
  warn "termux-setup-storage unavailable; continuing without shared storage link"
else
  log "Requesting storage access (safe to ignore if already granted)..."
  termux-setup-storage || true
fi

if [[ ! -d "$VENV_DIR" ]]; then
  log "Creating Python virtual environment..."
  python -m venv "$VENV_DIR"
fi

# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

log "Installing Python packages..."
pip install --upgrade pip wheel setuptools
pip install --upgrade \
  llama-cpp-python==0.2.90 \
  rich typer prompt-toolkit watchdog pyyaml orjson

if [[ ! -d "$LLAMA_DIR" ]]; then
  log "Cloning llama.cpp..."
  git clone --depth 1 https://github.com/ggerganov/llama.cpp "$LLAMA_DIR"
else
  log "Updating llama.cpp..."
  git -C "$LLAMA_DIR" pull --ff-only || warn "Could not fast-forward llama.cpp; keeping current state"
fi

log "Building llama.cpp binaries..."
cmake -S "$LLAMA_DIR" -B "$LLAMA_DIR/build" -DLLAMA_NATIVE=ON -DLLAMA_OPENMP=ON
cmake --build "$LLAMA_DIR/build" -j"$(nproc)"

MODEL_FILE="$MODELS_DIR/codegemma-2b-it-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/lmstudio-community/codegemma-2b-it-GGUF/resolve/main/codegemma-2b-it-Q4_K_M.gguf"

if [[ ! -f "$MODEL_FILE" ]]; then
  log "Downloading 2B coding model (CodeGemma Q4_K_M GGUF)..."
  wget -O "$MODEL_FILE" "$MODEL_URL" || fail "Model download failed. Re-run when network is stable."
else
  ok "Model already present: $MODEL_FILE"
fi

cat > "$BASE_DIR/agent_config.yaml" <<CFG
model_path: "$MODEL_FILE"
threads: 4
ctx_size: 4096
temperature: 0.2
top_p: 0.9
repeat_penalty: 1.1
workspace_dir: "$WORKSPACES_DIR"
memory_dir: "$MEMORY_DIR"
logs_dir: "$LOGS_DIR"
CFG

cat > "$BASE_DIR/agent.py" <<'PY'
#!/usr/bin/env python3
import json
import os
import shlex
import subprocess
from datetime import datetime
from pathlib import Path

import typer
import yaml
from llama_cpp import Llama
from rich import print
from rich.console import Console
from rich.panel import Panel

console = Console()
app = typer.Typer(help="Mobile Coder Agent for Termux")

SYSTEM_PROMPT = """You are MobileCoder, an autonomous local coding agent running offline on Android Termux.
Goals:
- Plan first, then execute step-by-step.
- Create/edit multi-file projects safely.
- Prefer minimal, correct changes.
- Return shell commands and file patches when requested.
- Keep outputs concise and actionable.
"""


def load_config(base: Path):
    cfg_path = base / "agent_config.yaml"
    if not cfg_path.exists():
        raise SystemExit(f"Missing config: {cfg_path}. Run setup script first.")
    with cfg_path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_memory(memory_file: Path):
    if not memory_file.exists():
        return []
    with memory_file.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_memory(memory_file: Path, data):
    memory_file.parent.mkdir(parents=True, exist_ok=True)
    with memory_file.open("w", encoding="utf-8") as f:
        json.dump(data[-100:], f, indent=2)


def make_llm(cfg):
    return Llama(
        model_path=cfg["model_path"],
        n_threads=int(cfg.get("threads", 4)),
        n_ctx=int(cfg.get("ctx_size", 4096)),
        verbose=False,
    )


def chat_reply(llm, prompt, cfg):
    out = llm.create_chat_completion(
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ],
        temperature=float(cfg.get("temperature", 0.2)),
        top_p=float(cfg.get("top_p", 0.9)),
        repeat_penalty=float(cfg.get("repeat_penalty", 1.1)),
    )
    return out["choices"][0]["message"]["content"]


@app.command()
def run(workspace: str = typer.Option("default", help="Workspace name")):
    base = Path(os.environ.get("MOBILE_CODER_BASE", str(Path.home() / "mobile-coder-agent")))
    cfg = load_config(base)
    ws = Path(cfg["workspace_dir"]) / workspace
    ws.mkdir(parents=True, exist_ok=True)
    memory_file = Path(cfg["memory_dir"]) / f"{workspace}.json"

    console.print(Panel.fit(f"[bold green]MobileCoder Agent[/bold green]\nWorkspace: {ws}"))
    llm = make_llm(cfg)

    while True:
        try:
            user = input("\nmobilecoder> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nbye")
            break
        if not user:
            continue
        if user in {"exit", "quit"}:
            break
        if user.startswith("!sh "):
            cmd = user[4:]
            console.print(f"[cyan]$ {cmd}[/cyan]")
            proc = subprocess.run(cmd, cwd=ws, shell=True, text=True)
            console.print(f"[dim]exit code: {proc.returncode}[/dim]")
            continue

        memory = load_memory(memory_file)
        prompt = (
            f"Current workspace: {ws}\n"
            f"Recent memory: {json.dumps(memory[-8:], ensure_ascii=False)}\n"
            f"User request: {user}\n"
            "Respond with:\n"
            "1) PLAN\n2) ACTIONS\n3) CODE (if needed)\n4) TESTS\n"
        )

        reply = chat_reply(llm, prompt, cfg)
        console.print(Panel(reply, title="Agent"))

        memory.append(
            {
                "ts": datetime.utcnow().isoformat(),
                "user": user,
                "agent": reply,
            }
        )
        save_memory(memory_file, memory)


@app.command()
def exec_cmd(command: str, workspace: str = "default"):
    base = Path(os.environ.get("MOBILE_CODER_BASE", str(Path.home() / "mobile-coder-agent")))
    cfg = load_config(base)
    ws = Path(cfg["workspace_dir"]) / workspace
    ws.mkdir(parents=True, exist_ok=True)
    subprocess.run(command, cwd=ws, shell=True, check=False)


if __name__ == "__main__":
    app()
PY

chmod +x "$BASE_DIR/agent.py"

cat > "$BIN_DIR/mobilecoder" <<'LAUNCH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
BASE_DIR="$HOME/mobile-coder-agent"
source "$BASE_DIR/.venv/bin/activate"
export MOBILE_CODER_BASE="$BASE_DIR"
python "$BASE_DIR/agent.py" run --workspace "${1:-default}"
LAUNCH
chmod +x "$BIN_DIR/mobilecoder"

if ! grep -q 'mobile-coder-agent/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/mobile-coder-agent/bin:$PATH"' >> "$HOME/.bashrc"
fi

ok "Install complete."
echo
cat <<MSG
Next steps:
1) Restart Termux or run: source ~/.bashrc
2) Start agent: mobilecoder
3) In agent shell, try: build a todo app in python flask

Offline mode:
- Works fully offline after first successful install + model download.
MSG
