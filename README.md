# Mildred - Your Personal AI File System Maid

Remember the scandalous affair between Arnold Schwarzenegger and his housekeeper Mildred? Well, meet Mildred, your own personal AI file system maid - but this one's all about keeping your directories clean and organized, not causing tabloid headlines! 

## What Makes Mildred Special?

Unlike other file management tools, Mildred is designed to be personal, interactive, and dare we say... a bit flirty with your file system. She's here to:

- 🧹 Clean up your messy directories
- 📂 Organize your digital life
- 💅 Add some sass to your file management
- 🔍 Find those files you "lost"
- 🗑️ Take out the digital trash

## Getting Started with Your New Maid

### Installation

```bash
git clone https://github.com/yourusername/mildred.git
cd mildred
bundle install
```

### Setting Up Your Relationship

```bash
cp .env.example .env
# Add your AI API key - Mildred needs to know who to talk to!
```

## How to Interact with Mildred

### Interactive Mode (For Those Personal Moments)

```bash
ruby run.rb
```

Want to test the waters first? Use dry-run mode:
```bash
ruby run.rb --dry-run
```

### Script Mode (When You Need Discretion)

```bash
ruby run.rb path/to/script.txt
```

## Mildred's Special Skills

### File Operations
- `navigate` - Let Mildred guide you through your directories
- `list` - Have her show you what's where
- `move` - She'll relocate your files with care
- `copy` - Perfect duplicates, every time
- `remove` - When it's time to let go
- `make directory` - Creating new spaces for your digital life

### Analysis & Organization
- `analyze disk space` - She'll tell you who's taking up too much space
- `search` - Finding what you need, when you need it
- `sort` - Because chaos is so last season

## Safety First

Mildred is discreet and careful:
- Dry run mode to preview changes
- Path validation to prevent accidents
- Detailed logging of all activities
- Careful error handling

## Example Tasks

Here's how Mildred can help:

```bash
# Organizing Downloads
make directory Downloads/vacation_pics
move file *.jpg to Downloads/vacation_pics

# Setting up a new project
make directory new_project
make directory new_project/src
make directory new_project/tests

# Cleaning up old files
analyze disk space in Documents
remove file Documents/old_drafts/*
```

## Requirements

- Ruby 3.0 or higher
- Bundler
- AI API key (Mildred needs her communication device!)

## License

MIT License - Feel free to have your own affair with Mildred!

## Special Thanks

Inspired by:
- The original Mildred (sorry, Arnold!)
- Ruby Maid gem (but with more personality)
- Every messy directory that needed a caring touch

## Author

Your Name (@yourusername) - Bringing personal assistance back to file management!

---

Remember: What happens in your file system, stays in your file system! 😉