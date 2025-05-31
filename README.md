
<p align="center">
  <img src="https://github.com/user-attachments/assets/c0196b3a-3091-4c7c-85bd-548f28d24ecb" />
</p>

# Mildred - AI-Powered File Management Assistant

Mildred is a Ruby-based AI file management assistant that helps you organize, maintain, and clean up your filesystem. Think of it as an AI-powered version of the classic Ruby Maid gem, with interactive and scripting capabilities.

## Features


- 🤖 AI-powered file organization
- 📂 Interactive file management
- 📜 Scriptable operations
- 🔍 Disk space analysis
- 🔒 Safe operation with dry-run mode


## Getting Started with Your New Maid

### Installation

```bash
git clone https://github.com/sammcclenaghan/mildred.git
cd mildred
bundle install
```

### Setting Up Your Environment

```bash
cp .env.example .env
# Add your AI API key - Mildred needs to know who to talk to!
```

## Usage

### Run mildred in interactive mode

```bash
ruby run.rb
```

Or with dry-run mode to safely test operations:
```bash
ruby run.rb --dry-run
```

### Script Mode

```bash
ruby run.rb path/to/script.txt
```

Example script (`examples/cleanup_script.txt`):Add commentMore actions
```
# Create organized directories
make directory Downloads/images
make directory Downloads/documents

# Move files to appropriate directories
move file *.jpg to images
move file *.pdf to documents

# Verify organization
list current directory
```

## Available Tools
 `navigate` - Change current directoryAdd commentMore actions
- `list` - List directory contents
- `move` - Move files or directories
- `copy` - Copy files or directories
- `remove` - Delete files or directories
- `make directory` - Create new directories

### Analysis Tools
- `analyze disk space` - Get storage usage statistics
- Search for files by pattern
- List directory contents with details

## Safety Features
- Dry run mode for testing operations
- Path validation to prevent accidental modifications
- Clear logging of all operations
- Error handling and reporting

## Writing Scripts
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

## Example Scripts

Check the `examples/` directory for sample scripts:
- `cleanup_script.txt` - Organize downloads folder
- `organize_project.txt` - Set up project structure
- `test_paths.txt` - Test directory operations

## Requirements

- Ruby 3.0 or higher
- Bundler
- AI API key (supported providers: OpenAI, DeepSeek, Anthropic)

## Acknowledgments

- Inspired by the Ruby Maid gem
- Built with RubyLLM for AI capabilities

## Author
Sam McClenaghan (@sammcclenaghan)
