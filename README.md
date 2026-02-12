# Mildred

AI file organizer that runs in a sandboxed [Apple Container](https://github.com/apple/container). Define cleanup jobs in a YAML config and let an LLM sort your files.

## Requirements

- macOS 26+ (Apple Silicon)
- [Apple Container CLI](https://github.com/apple/container)
- [Ollama](https://ollama.com) with a model pulled (default: `qwen3:latest`)
- Ruby 3.0+

## Install

```bash
gem install mildred
```

## Quick Start

```bash
# Generate a starter config
mildred init

# Edit mildred.yml to your liking, then run
mildred clean
```

## Commands

| Command | Description |
|---------|-------------|
| `mildred init` | Generate a starter `mildred.yml` |
| `mildred clean` | Run file organization jobs |
| `mildred clean -n` | Dry run — preview without moving files |
| `mildred build` | Rebuild the container image |

## Configuration

`mildred.yml` defines your settings and jobs:

```yaml
settings:
  provider: ollama
  model: granite4:latest

  ollama:
    port: 11434

jobs:
  - name: Desktop Cleanup
    directory: ~/Desktop
    tasks:
      - Organize files into folders by type (Documents, Images, Archives)
      - Delete screenshots older than 30 days
```

Each job targets a directory and runs a list of natural-language tasks against it using the LLM.

## Working with Ollama

Mildred uses Ollama as its LLM backend. The container connects to Ollama on your host machine through the Apple Container network gateway (`192.168.64.1`).

### Setup

1. **Install Ollama** from [ollama.com](https://ollama.com)

2. **Pull a model** (Mildred defaults to `qwen3` -- it needs good tool-calling support):

   ```bash
   ollama pull qwen3
   ```

3. **Start Ollama** — if Ollama is already running as a macOS app, it should work out of the box. If you're running it manually via the CLI, make sure it binds to all interfaces so the container can reach it:

   ```bash
   OLLAMA_HOST=0.0.0.0 ollama serve
   ```

   > By default `ollama serve` only listens on `127.0.0.1`, which isn't reachable from inside a container. The Ollama macOS app already listens on all interfaces.

4. **Run Mildred**:

   ```bash
   mildred clean
   ```

   Mildred checks that Ollama is reachable before starting any jobs and will tell you if something is wrong.

### Using a different model

Set the model in `mildred.yml`:

```yaml
settings:
  model: llama3.2:latest
```

### Custom Ollama host/port

If Ollama is running on a non-default port or a different machine:

```yaml
settings:
  ollama:
    host: 192.168.64.1
    port: 11434
```

## How It Works

1. Mildred reads your `mildred.yml` config
2. Builds a lightweight Linux container image (first run only, auto-rebuilds when source changes)
3. For each job, spins up a sandboxed container with your target directory mounted at `/workspace`
4. Sends each task to the LLM, which uses tool calls (list files, read files, move files, create directories) to organize your files
5. The container is removed after each job completes

Your files are the only thing mounted into the container — the LLM agent can only see and touch what you point it at.

## License

MIT
