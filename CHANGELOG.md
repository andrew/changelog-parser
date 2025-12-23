## [Unreleased]

## [0.2.0] - 2025-12-23

### Added

- `between(old_version, new_version)` method to extract content between versions
- `line_for_version(version)` method with Dependabot-style pattern matching
- `find_changelog(directory)` class method to locate changelog files
- `find_and_parse(directory)` class method for one-step discovery and parsing
- `to_html` method for markdown to HTML conversion (requires optional markdown gem)
- Vandamme compatibility layer (`require "changelog/parser/vandamme"`)
- CLI now accepts directories and auto-finds changelog files
- CLI `between` command for extracting content between versions
- CLI `validate` command for checking Keep a Changelog format compliance

### Changed

- CLI now uses subcommands (`parse`, `list`, `show`, `between`) instead of flags
- Version matching now uses negative lookahead to avoid substring matches (e.g., won't match 1.0.1 when looking for 1.0.10)

## [0.1.0] - 2025-12-23

### Added

- Core changelog parsing with auto-format detection
- Support for Keep a Changelog, markdown headers, and underline formats
- Custom regex pattern support for non-standard formats
- CLI with JSON output, version listing, and content extraction
