# Mildred
---

There's nothing wrong with being lazy. Mildred can go above and beyond, following plain english prompts safely inside Apple Containers.

**macOS only.** Requires Apple containers.

## Install

```
gem install mildred
```

## Setup

```
mildred setup
```

This walks you through picking a provider (ollama, openai, or openrouter) and writes config to `~/.mildred/`.

## Usage

Define jobs in `~/.mildred/rules.yml`:

```yaml
jobs:
  - name: Clean Downloads
    directory: ~/Downloads
    tasks:
      - Delete duplicate files
      - Remove files older than 30 days

  - name: Organize Documents
    directory: ~/Documents
    destinations:
      - ~/Documents/PDFs
      - ~/Documents/Spreadsheets
    tasks:
      - Move PDF files to the PDFs folder
      - Move spreadsheet files to the Spreadsheets folder
```

Then run:

```
mildred clean
```

Use `--noop` for a dry run.

## Commands

```
mildred clean    # Organize files using rules
mildred setup    # Interactive first-time setup
mildred sample   # Generate sample config and rules
mildred logs     # Show or tail the log file
mildred version  # Show version
```

## License

MIT
