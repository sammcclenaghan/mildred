# Mildred

[![CI](https://github.com/sammcclenaghan/mildred/actions/workflows/ci.yml/badge.svg)](https://github.com/sammcclenaghan/mildred/actions/workflows/ci.yml)

A small AI file organizer that runs in a sandboxed [Apple Container](https://github.com/apple/container). Describe cleanup jobs in plain English in a YAML file, and a local model sorts your files. Only the folders you name are mounted into the container, so the model cannot see or touch anything else.

## Requirements

- macOS 26+ on Apple Silicon
- [Apple Container CLI](https://github.com/apple/container)
- [Ollama](https://ollama.com) with a model pulled (default `qwen2.5:7b`)
- Ruby 3.0+

## Quick start

```bash
gem install mildred
mildred init      # writes a starter mildred.yml
mildred clean -n  # preview what would happen
mildred clean     # do it
```

The first `clean` builds the container image, which takes a minute.

## Commands

| Command | What it does |
|---|---|
| `mildred init [path]` | Write a starter `mildred.yml` |
| `mildred clean` | Run every job in `mildred.yml` |
| `mildred clean -n` | Dry run. Shows what would move, moves nothing |
| `mildred clean -c other.yml` | Use a different config file |
| `mildred clean -j "Sort Downloads"` | Run a single job by name |
| `mildred build` | Rebuild the container image (run after upgrading the gem) |

## Configuration

```yaml
settings:
  model: qwen2.5:7b

jobs:
  - name: Desktop Cleanup
    directory: ~/Desktop
    tasks:
      - Organize files into folders by type (Documents, Images, Archives)
      - Move screenshots into a Screenshots folder

  - name: Sort Downloads
    directories:
      downloads: ~/Downloads
      documents: ~/Documents
      pictures: ~/Pictures
    tasks:
      - Move PDFs and Word docs from downloads to documents
      - Move images from downloads to pictures
```

Each job mounts one or more folders and runs its tasks in order. Use `directory` for a single folder, or `directories` to name several so the agent can move files between them. Inside the container the agent sees them by name: `downloads/`, `documents/`, `pictures/`. A single `directory` is mounted under its own lowercased folder name, so `~/Desktop` shows up as `desktop/`.

## Ollama

The container reaches Ollama on your Mac through the container network gateway (`192.168.64.1`), so Ollama has to listen on all interfaces. In the Ollama macOS app, open Settings and turn on "Expose Ollama to the network". If you run it from the CLI:

```bash
OLLAMA_HOST=0.0.0.0 ollama serve
```

Mildred checks the connection before starting and tells you if it cannot get through.

Pick a model with solid tool calling. `qwen2.5:7b` is the default and works well at temperature 0. `qwen2.5:14b` is more careful and slower. If a model describes moves without making them, try another. Set a different host or port under `settings.ollama` if you need to:

```yaml
settings:
  ollama:
    host: 192.168.64.1
    port: 11434
```

## Running on a schedule

Like [maid](https://github.com/maid/maid), Mildred is happy to run from cron. Add a line with `crontab -e`:

```cron
PATH=/usr/local/bin:/usr/bin:/bin
*/30 * * * * /path/to/mildred clean -c /Users/you/mildred.yml >> /Users/you/Library/Logs/mildred.log 2>&1
```

Three things trip people up:

- **Absolute paths.** Cron runs with a bare environment. Use the full path to `mildred` (see `which mildred`) and to the config. `/usr/local/bin` has to be on PATH for the `container` CLI.
- **Full Disk Access.** macOS blocks cron from Desktop, Documents, and Downloads until you add `/usr/sbin/cron` under System Settings → Privacy & Security → Full Disk Access. Press Cmd+Shift+G in the file picker to type the path.
- **The container service.** `container system start` has to have been run since the last boot. Add it as a login item, or put `/usr/local/bin/container system start;` in front of the mildred command.

Use `-j` to schedule jobs at different rates, for example Downloads every half hour and Desktop nightly.

## How it works

The agent has four tools: `list_files`, `read_file`, `move_file`, and `move_folder`. `list_files` shows each file's size and modified date and hides dotfiles, and the prompt includes today's date, so tasks like "archive anything older than a month" work. For each task the model lists the folders, decides what goes where, and moves things. Every tool call is printed as it happens, followed by the model's one-line summary.

`move_file` only moves single files, creates missing folders, and refuses to overwrite an existing file, so a name collision is reported rather than silently losing a file. Folders need `move_folder`, which the model is told to use only when a task explicitly asks for it. That way a broad rule like "move everything older than 30 days" cannot sweep a folder along by accident. The container is thrown away when the job ends.

The whole thing is two small Ruby files on the host side and two inside the container. Read them.

## Development

```bash
git clone https://github.com/sammcclenaghan/mildred
cd mildred
bundle install
rake test      # runs the suite, no container or model needed
rake install   # builds the gem, installs it, rebuilds the image
```

The tools and the host CLI are unit tested with minitest. The agent loop is tested against a real Ollama conversation recorded with VCR into `test/cassettes`, so the model's tool calls replay offline while the file moves happen for real in a temp directory. To re-record it, delete the cassette and run `rake test` with Ollama running locally and a model set in `MILDRED_MODEL`.

## Roadmap

- Other providers (OpenAI, Anthropic) alongside Ollama
- Undo, via a manifest of every move
- Scheduled runs with launchd

## License

MIT
