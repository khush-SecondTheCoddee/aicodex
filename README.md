# MobileCoder 2B (Termux)

## SECTION 1 — System overview (short)
MobileCoder 2B is a fully local AI coding agent for Android Termux. It installs llama.cpp, downloads a quantized 2B coding model (CodeGemma 2B Q4_K_M GGUF), creates a Python-based autonomous coding CLI, configures memory/workspaces, and gives you a single launch command. After install, it runs offline.

## SECTION 2 — One-command auto installer
```bash
curl -fsSL https://raw.githubusercontent.com/REPLACE_WITH_YOUR_REPO/main/termux_mobile_agent_setup.sh -o termux_mobile_agent_setup.sh && bash termux_mobile_agent_setup.sh
```

If you are running from a local clone of this repository:
```bash
bash termux_mobile_agent_setup.sh
```

## SECTION 3 — Full setup script
```bash
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
bash termux_mobile_agent_setup.sh
```

## SECTION 4 — Launch command
```bash
source ~/.bashrc
mobilecoder
```

Start a named workspace:
```bash
mobilecoder myproject
```

## SECTION 5 — Example commands to use agent
Inside `mobilecoder` prompt:
```text
build a modern portfolio website with responsive navbar and dark mode
create a fastapi backend with auth and sqlite models
fix this code for null pointer and add tests
optimize my python project structure for production
```

Direct shell execution inside workspace:
```text
!sh python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
!sh pytest -q
!sh npm create vite@latest . -- --template react
```

## SECTION 6 — Optional upgrades (voice/web/ui)
Voice (Termux API text-to-speech + speech-to-text wrappers):
```bash
pkg install termux-api -y
```

Optional local web UI (Open WebUI style alternative):
```bash
# Keep lightweight for mobile: use CLI by default.
# If desired, install streamlit panel around agent later.
pip install streamlit
```

Optional Ollama path (instead of llama.cpp) when supported by your device:
```bash
# If Ollama builds/runs on your Termux environment, swap backend in agent.py
# and pull a 2B model there.
```

## SECTION 7 — Performance optimization tips
- Use Q4_K_M quantization for best speed/quality on 6–12GB RAM devices.
- Keep context at 2048–4096 tokens to avoid memory spikes.
- Set threads to little cores count for thermal stability (e.g., 4).
- Close background apps while running inference.
- Keep projects in small workspaces and ask for stepwise edits.
- Use `!sh` for tests/builds and keep model strictly for reasoning/planning.
