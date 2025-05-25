![ChatGPT Image May 25, 2025, 12_21_58 AM](https://github.com/user-attachments/assets/7ce8d403-cfc7-4cbf-8346-04b2adaa8bb9)

# Mildred - AI-Powered File Management Assistant

Mildred is a Ruby-based AI file management assistant that helps you organize, maintain, and clean up your filesystem. Think of it as an AI-powered version of the classic Ruby Maid gem, with interactive and scripting capabilities.

## Features

- 🤖 AI-powered file organization
- 📂 Interactive file management
- 📜 Scriptable operations
- 🔍 Disk space analysis
- 🔒 Safe operation with dry-run mode

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/mildred.git
cd mildred
```

2. Install dependencies:
```bash
bundle install
```

3. Set up your environment variables:
```bash
cp .env.example .env
# Edit .env and add your AI API key
```

## Usage
![ChatGPT Image May 25, 2025, 12_21_58 AM](https://github.com/user-attachments/assets/3830ee57-2e9c-43e6-9dec-951171bb74a9)

### Interactive Mode

Run Mildred in interactive mode:

```bash
ruby run.rb
```

Or with dry-run mode to safely test operations:

```bash
ruby run.rb --dry-run
```

### Script Mode

Run a file management script:

```bash
ruby run.rb path/to/script.txt
```

Example script (`examples/cleanup_script.txt`):
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

### File Operations
- `navigate` - Change current directory
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

Create text files with one command per line. Use `#` for comments:

```
# Step 1: Create directories
make directory project
make directory project/src

# Step 2: Move files
move file *.rb to project/src

# Step 3: Verify
list current directory
```

## Example Scripts

Check the `examples/` directory for sample scripts:
- `cleanup_script.txt` - Organize downloads folder
- `organize_project.txt` - Set up project structure
- `test_paths.txt` - Test directory operations

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Requirements

- Ruby 3.0 or higher
- Bundler
- AI API key (supported providers: OpenAI, DeepSeek, Anthropic)

## Acknowledgments

- Inspired by the Ruby Maid gem
- Built with RubyLLM for AI capabilities

## Author

Your Name (@sammcclenaghan)
