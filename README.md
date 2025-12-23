# Changelog::Parser

[![Gem Version](https://badge.fury.io/rb/changelog-parser.svg)](https://rubygems.org/gems/changelog-parser)

A Ruby gem for parsing changelog files into structured data. Supports the Keep a Changelog format, markdown headers, and custom patterns.

Inspired by [vandamme](https://github.com/tech-angels/vandamme).

## Installation

```bash
gem install changelog-parser
```

Or add to your Gemfile:

```ruby
gem "changelog-parser"
```

## Usage

### Ruby API

```ruby
require "changelog/parser"

# Parse a string
changelog = File.read("CHANGELOG.md")
parser = Changelog::Parser.new(changelog)
result = parser.parse

# Or use the class method
result = Changelog::Parser.parse(changelog)

# Or parse a file directly
result = Changelog::Parser.parse_file("CHANGELOG.md")
```

The result is a hash where keys are version strings and values contain the date and content:

```ruby
{
  "Unreleased" => { date: nil, content: "### Added\n- New feature" },
  "1.0.0" => { date: #<Date: 2024-01-15>, content: "### Added\n- Initial release" }
}
```

### Accessing versions

```ruby
parser = Changelog::Parser.new(changelog)

# Get all version strings
parser.versions
# => ["Unreleased", "1.0.0"]

# Get a specific version
parser["1.0.0"]
# => { date: #<Date: 2024-01-15>, content: "..." }

# Convert to JSON
parser.to_json

# Convert to HTML (requires a markdown gem)
parser.to_html
```

### HTML conversion

The `to_html` method converts markdown content to HTML. It requires one of these optional gems to be installed separately:

- [commonmarker](https://github.com/gjtorikian/commonmarker)
- [redcarpet](https://github.com/vmg/redcarpet)
- [kramdown](https://github.com/gettalong/kramdown)

```ruby
gem "commonmarker" # Add to your Gemfile

parser.to_html
# => { "1.0.0" => { date: #<Date>, content: "<ul><li>Feature</li></ul>" } }
```

### Formats

The parser auto-detects the changelog format. You can also specify it explicitly:

```ruby
# Keep a Changelog: ## [1.0.0] - 2024-01-15
Changelog::Parser.new(content, format: :keep_a_changelog)

# Markdown headers: ## 1.0.0 or ### v1.0.0 (2024-01-15)
Changelog::Parser.new(content, format: :markdown)

# Underline style: 1.0.0\n=====
Changelog::Parser.new(content, format: :underline)
```

### Extracting content between versions

Extract changelog content between two versions (like Dependabot does for PR descriptions):

```ruby
parser = Changelog::Parser.new(changelog)

# Get content between old and new version
parser.between("1.0.0", "2.0.0")

# Get content from a version to the end
parser.between(nil, "1.5.0")

# Get content from start to a version
parser.between("1.5.0", nil)
```

### Finding changelog files

Automatically find and parse changelog files in a directory:

```ruby
# Find changelog file (searches for CHANGELOG.md, NEWS, HISTORY, etc.)
path = Changelog::Parser.find_changelog("/path/to/project")

# Find and parse in one step
result = Changelog::Parser.find_and_parse("/path/to/project")
```

### Custom patterns

For changelogs with non-standard formats, provide a custom regex:

```ruby
# Custom format: "Version 1.0.0 released 2024-01-15"
pattern = /^Version ([\d.]+) released (\d{4}-\d{2}-\d{2})/
parser = Changelog::Parser.new(content, version_pattern: pattern)
```

The first capture group should be the version string. The second capture group (if present) is parsed as a date.

## CLI

The gem includes a command-line interface:

```bash
# Parse a changelog and output JSON
changelog-parser parse CHANGELOG.md

# Parse from a directory (auto-finds CHANGELOG.md, NEWS, HISTORY, etc.)
changelog-parser parse /path/to/project

# List versions only
changelog-parser list CHANGELOG.md

# Show content for a specific version
changelog-parser show 1.0.0 CHANGELOG.md

# Show content between two versions (for PR descriptions)
changelog-parser between 1.0.0 2.0.0 CHANGELOG.md

# Validate against Keep a Changelog format
changelog-parser validate CHANGELOG.md

# Pretty print JSON
changelog-parser parse --pretty CHANGELOG.md

# Read from stdin
cat CHANGELOG.md | changelog-parser parse -

# Custom regex pattern
changelog-parser parse --pattern "^## v([\d.]+)" CHANGELOG.md
```

### Commands

```
parse    Parse changelog and output JSON (default)
list     List version numbers only
show     Show content for a specific version
between  Show content between two versions
validate Validate changelog against Keep a Changelog format
```

### Options

```
-f, --format FORMAT      Changelog format (keep_a_changelog, markdown, underline)
-p, --pattern REGEX      Custom version header regex pattern
-m, --match-group N      Regex capture group for version (default: 1)
    --pretty             Pretty print JSON output
-h, --help               Show help message
    --version            Show gem version
```

## Supported formats

### Keep a Changelog

The default format follows the [Keep a Changelog](https://keepachangelog.com) specification:

```markdown
## [Unreleased]

## [1.0.0] - 2024-01-15

### Added
- New feature
```

### Markdown headers

Standard markdown headers with optional dates:

```markdown
## 1.0.0 (2024-01-15)

### v0.9.0
```

### Underline style

Setext-style headers:

```markdown
1.0.0
=====
```

## Vandamme compatibility

For projects migrating from the [vandamme](https://github.com/tech-angels/vandamme) gem, a compatibility layer is provided:

```ruby
require "changelog/parser/vandamme"

parser = Vandamme::Parser.new(
  changelog: content,
  version_header_exp: /^## ([\d.]+)/,
  format: :markdown,
  match_group: 1
)

# Returns plain strings like vandamme (no date hash)
parser.parse
# => { "1.0.0" => "### Added\n- Feature" }

# HTML conversion (requires markdown gem)
parser.to_html
# => { "1.0.0" => "<h3>Added</h3><ul><li>Feature</li></ul>" }
```

## Development

```bash
bin/setup
rake test
```

## License

MIT
