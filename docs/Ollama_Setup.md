# TelOS Local Models via Ollama (Windows + WSL)

This slice wires TelOS Io -> C -> embedded Python -> Ollama HTTP. Use it to run local `gguf` models.

## Install Ollama

- Windows (PowerShell):
  1. Download and install from https://ollama.com/download
  2. Start Ollama: it runs a local server on `http://localhost:11434`.

- WSL (Ubuntu):
  - `curl -fsSL https://ollama.com/install.sh | sh`

## Create local models for personas (Modelfiles)

We use your provided GGUFs and wrap them as named Ollama models:

- ROBIN → `telos/robin` from `C:\EntropicGarden\TelOS-Python-Archive\models\gemma-3-4b-it-Q8_0.gguf`
- BRICK → `telos/brick` from `C:\EntropicGarden\TelOS-Python-Archive\models\Mistral-7B-Instruct-v0.3-Q5_K_M.gguf`
- ALFRED → `telos/alfred` from `C:\EntropicGarden\TelOS-Python-Archive\models\phi-4-mini-instruct-q8_0.gguf`
- BABS → `telos/babs` from `C:\EntropicGarden\TelOS-Python-Archive\models\Qwen3-1.7B-Q8_0.gguf`

Modelfiles live in `tools/ollama/Modelfile.*`. Create the models:

```powershell
ollama create telos/robin -f tools/ollama/Modelfile.robin
ollama create telos/brick -f tools/ollama/Modelfile.brick
ollama create telos/alfred -f tools/ollama/Modelfile.alfred
ollama create telos/babs -f tools/ollama/Modelfile.babs
```

## Run the Smoke Test

From the repo root in PowerShell:

- Build or use the provided `io` binary per README/roadmap (WSL recommended for now).
- Run the sample Io script:

```
io samples/telos/ollama_smoke.io
```

Expected output:

- A line `[llm/ollama] -> telos/brick` (or your mapped persona model)
- A non-empty `[OLLAMA REPLY] ...` single-sentence answer.

## Troubleshooting

- If you see `[OLLAMA_ERROR] request failed`:
  - Ensure Ollama is running: `Invoke-WebRequest http://localhost:11434/api/tags` should return JSON.
  - Confirm the model is pulled.
  - Check firewall prompts on first run.

- To switch models per persona, edit `Telos personaModels` in `libs/Telos/io/IoTelos.io`.

## Notes

- Vision input is not fully wired; `ROBIN` uses textual UI snapshots for now.
- The bridge uses Python stdlib HTTP to avoid external deps.
- All calls are synchronous and non-streaming in this slice.
