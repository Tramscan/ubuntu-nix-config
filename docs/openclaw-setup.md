# OpenClaw Setup with Local AI Models

Setup guide for running OpenClaw with local models (Qwen, Llama, etc.) on a Nix-managed Ubuntu system.

---

## What This Is

OpenClaw is a personal AI assistant that can run locally with open-source models. This guide explains how to:
1. Install OpenClaw
2. Configure it with local models (Qwen3.5-35B-A3B or alternatives)
3. Integrate it with your Nix/NVIDIA debugging workflow

---

## Prerequisites

- Nix flakes enabled
- NVIDIA GPU with proprietary drivers (recommended for local models)
- At least 16GB RAM, ideally 32GB+ for larger models
- ~20GB free disk space for model downloads

---

## 1. Install OpenClaw

### Option A: Via Nix (Recommended)

```nix
# Add to your home.nix packages
home.packages = with pkgs; [
  # ... existing packages ...
  openclaw
  # OR build from source:
  # (pkgs.callPackage ./openclaw.nix {})
];
```

### Option B: Manual Installation

```bash
# Clone OpenClaw
git clone https://github.com/openclaw/openclaw.git ~/Projects/openclaw
cd ~/Projects/openclaw

# Install if using npm/node
npm install -g

# Or run directly
./openclaw
```

---

## 2. Configure Local Models

### OpenClaw Configuration File

Create `~/.openclaw/openclaw.json`:

```json
{
  "meta": {
    "lastTouchedVersion": "2026.2.15",
    "lastTouchedAt": "2026-03-14T00:00:00Z"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434/v1",
        "api": "openai-completions",
        "models": [
          {
            "id": "qwen3.5-35b-a3b",
            "name": "Qwen3.5-35B-A3B (Local)",
            "alias": "qwen-local",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 131072,
            "maxTokens": 8192
          },
          {
            "id": "llama3.2",
            "name": "Llama 3.2 (Local)",
            "alias": "llama-local",
            "reasoning": false,
            "cost": { "input": 0, "output": 0 },
            "contextWindow": 128000,
            "maxTokens": 4096
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen3.5-35b-a3b"
      },
      "models": {
        "ollama/qwen3.5-35b-a3b": {
          "alias": "qwen-local"
        },
        "ollama/llama3.2": {
          "alias": "llama-local"
        }
      },
      "workspace": "~/.openclaw/workspace",
      "maxConcurrent": 2
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "your-secure-token-here"
    },
    "nodes": {
      "denyCommands": [
        "camera.snap",
        "camera.clip",
        "screen.record"
      ]
    }
  }
}
```

---

## 3. Install Ollama (Model Runner)

Ollama is the easiest way to run local models on Linux.

### Via Nix

```nix
# Add to home.nix
home.packages = with pkgs; [
  ollama
];

home-manager switch --flake ~/.config/nix
```

### Start Ollama Service

```bash
# Run ollama server
ollama serve

# Test via API
curl http://localhost:11434/api/tags
```

---

## 4. Download Models

### Qwen3.5-35B-A3B (Requires 32GB+ RAM)

```bash
# Pull the model
ollama pull qwen3.5:35b-a3b

# Or smaller variants for testing
ollama pull qwen3.5:7b
ollama pull qwen3.5:14b
ollama pull qwen3.5:32b
```

### Alternative Models (Smaller, Faster)

```bash
# Llama 3 variants
ollama pull llama3.2
ollama pull llama3.2:1b
ollama pull llama3.1:8b

# Mistral variants
ollama pull mistral
ollama pull mistral-nemo

# Code-focused
ollama pull codellama:7b
ollama pull deepseek-coder:6.7b
```

### Verify Installation

```bash
ollama list
ollama run qwen3.5:7b
```

---

## 5. Integrate with Nix Debugging Workflow

### Create Debug Session Script

Save as `~/.config/nix/scripts/openclaw-debug.sh`:

```bash
#!/usr/bin/env bash
# openclaw-debug.sh - Launch OpenClaw for Nix debugging

# Ensure ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
  echo "Starting ollama..."
  ollama serve &
  sleep 5
fi

export OPENCLAW_WORKSPACE="$HOME/.openclaw/workspace"
export OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
export OPENCLAW_MODEL="ollama/qwen3.5-35b-a3b"

echo "Starting OpenClaw with Nix debugging profile..."
openclaw --workspace "$OPENCLAW_WORKSPACE" \
         --config "$OPENCLAW_CONFIG" \
         --agent main
```

```bash
chmod +x ~/.config/nix/scripts/openclaw-debug.sh
```

---

## 6. Using OpenClaw for Debugging

### How OpenClaw Helps

When you encounter issues, OpenClaw can:

1. **Read your config files** - `~/.config/nix/home-manager/home.nix`
2. **Analyze errors** - Parse home-manager switch output
3. **Suggest fixes** - Propose Nix language changes
4. **Run commands** - Check git status, file diffs, etc.
5. **Track changes** - Update MEMORY.md with fixes

### Example Interaction

**You:** "I'm getting infinite recursion error in home.nix"

**OpenClaw:**
1. Reads `home.nix` for duplicate definitions
2. Checks imported modules for conflicts
3. Searches for `home.sessionVariables` across files
4. Identifies the recursion source
5. Suggests `lib.mkDefault` fix

### Commands OpenClaw Can Run

```bash
# Check for duplicate definitions
grep -r "home\.sessionVariables" ~/.config/nix/

# Verify config syntax
nix eval ~/.config/nix#homeConfigurations.$(hostname).activationPackage

# Check git status
cd ~/.config/nix && git status
```

---

## Model Recommendations

| Model | Size | RAM | Speed | Use |
|-------|------|-----|-------|-----|
| qwen3.5:35b-a3b | 22GB | 32GB+ | Slow | Best overall |
| qwen3.5:14b | 9GB | 16GB | Medium | Good balance |
| qwen3.5:7b | 5GB | 8GB | Fast | Quick tasks |
| llama3.2 | 5GB | 8GB | Fast | General use |
| codellama:7b | 4GB | 8GB | Fast | Code debugging |

---

## Troubleshooting

### "CUDA out of memory"

```bash
pkill ollama
ollama pull llama3.2:1b
```

### OpenClaw can't find ollama

```bash
curl http://localhost:11434/api/tags
ollama serve &
```

### Model responses slow

```bash
nvidia-smi
ollama pull qwen3.5:7b-q4_0
```
