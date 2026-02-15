# Mildred

**Be lazier.** Describe your rules in plain English, and Mildred handles the rest. Sandboxed with Apple containers.

Like [Maid](https://github.com/maid/maid), but you write rules in English instead of Ruby. An LLM figures out the file operations and executes them inside a container so nothing unexpected touches your filesystem.

## Requirements

- macOS (Apple containers)
- Ruby 3.1+
- An LLM provider: [Ollama](https://ollama.com), OpenAI, or OpenRouter

## Install

```
gem install mildred
```

## Getting started

Run the interactive setup to pick your provider and model:

```
mildred setup
```

This creates `~/.mildred/config.yml` and a sample `~/.mildred/rules.yml`:

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

Try a dry run first to see what would happen:

```
mildred clean --noop
```

```
▸ Dry run — no changes will be made

▸ Clean Downloads
  → find ~/Downloads -type f -name "*.pdf" -mtime +30
  → rm /Users/you/Downloads/old-invoice.pdf
  ✓ Done

▸ Organize Documents
  → mv /Users/you/Documents/report.pdf /Users/you/Documents/PDFs/
  → mv /Users/you/Documents/budget.xlsx /Users/you/Documents/Spreadsheets/
  ✓ Done

✓ 2/2 jobs completed
```

When you're happy with it, run for real:

```
mildred clean
```

## License

MIT
