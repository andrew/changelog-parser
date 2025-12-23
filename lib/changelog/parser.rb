# frozen_string_literal: true

require_relative "parser/version"

module Changelog
  class Parser
    class Error < StandardError; end
    class ParseError < Error; end

    # Keep a Changelog format: ## [1.0.0] - 2024-01-15 or ## [Unreleased]
    KEEP_A_CHANGELOG = /^##\s+\[([^\]]+)\](?:\s+-\s+(\d{4}-\d{2}-\d{2}))?/

    # Markdown headers with version: ## 1.0.0 or ### v1.0.0 (2024-01-15)
    MARKDOWN_HEADER = /^\#{1,3}\s+v?([\w.+-]+\.[\w.+-]+[a-zA-Z0-9])(?:\s+\((\d{4}-\d{2}-\d{2})\))?/

    # Underline style: 1.0.0\n===== or 1.0.0\n-----
    UNDERLINE_HEADER = /^([\w.+-]+\.[\w.+-]+[a-zA-Z0-9])\n[=-]+/

    FORMATS = {
      keep_a_changelog: KEEP_A_CHANGELOG,
      markdown: MARKDOWN_HEADER,
      underline: UNDERLINE_HEADER
    }.freeze

    # Common changelog filenames in priority order (from Dependabot)
    CHANGELOG_FILENAMES = %w[
      changelog
      news
      changes
      history
      release
      whatsnew
      releases
    ].freeze

    attr_reader :changelog, :version_pattern, :match_group

    def initialize(changelog, format: nil, version_pattern: nil, match_group: 1)
      @changelog = changelog.to_s
      @version_pattern = resolve_pattern(format, version_pattern)
      @match_group = match_group
    end

    def parse
      return {} if changelog.empty?

      versions = {}
      matches = find_version_matches

      matches.each_with_index do |match, index|
        version = match[:version]
        start_pos = match[:end_pos]
        end_pos = matches[index + 1]&.dig(:start_pos) || changelog.length

        content = changelog[start_pos...end_pos].strip
        versions[version] = build_entry(match, content)
      end

      versions
    end

    def versions
      parse.keys
    end

    def [](version)
      parse[version]
    end

    def to_h
      parse
    end

    def to_json(*)
      require "json"
      parse.to_json
    end

    def to_html
      parse.transform_values do |entry|
        {
          date: entry[:date],
          content: render_html(entry[:content])
        }
      end
    end

    def render_html(content)
      return content if content.nil? || content.empty?

      if defined?(Commonmarker)
        Commonmarker.to_html(content)
      elsif defined?(CommonMarker)
        CommonMarker.render_html(content)
      elsif defined?(Redcarpet)
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
        markdown.render(content)
      elsif defined?(Kramdown)
        Kramdown::Document.new(content).to_html
      else
        raise Error, "No markdown renderer found. Install commonmarker, redcarpet, or kramdown."
      end
    end

    def between(old_version, new_version)
      old_line = line_for_version(old_version)
      new_line = line_for_version(new_version)
      lines = changelog.split("\n")

      range = if old_line && new_line
        old_line < new_line ? (old_line..-1) : (new_line..old_line - 1)
      elsif old_line
        old_line.zero? ? nil : (0..old_line - 1)
      elsif new_line
        (new_line..-1)
      end

      return nil unless range

      lines[range]&.join("\n")&.rstrip
    end

    def line_for_version(version)
      return nil unless version

      version = version.to_s.gsub(/^v/i, "")
      escaped = Regexp.escape(version)
      lines = changelog.split("\n")

      lines.find_index.with_index do |line, index|
        next false unless line.match?(/(?<!\.)#{escaped}(?![.\-\w])/)
        next false if line.match?(/#{escaped}\.\./)

        next true if line.start_with?("#", "!", "==")
        next true if line.match?(/^v?#{escaped}:?\s/)
        next true if line.match?(/^\[#{escaped}\]/)
        next true if line.match?(/^[\+\*\-]\s+(version\s+)?#{escaped}/i)
        next true if line.match?(/^\d{4}-\d{2}-\d{2}/)
        next true if lines[index + 1]&.match?(/^[=\-\+]{3,}\s*$/)

        false
      end
    end

    def self.parse(changelog, **options)
      new(changelog, **options).parse
    end

    def self.parse_file(path, **options)
      content = File.read(path)
      new(content, **options).parse
    end

    def self.find_changelog(directory = ".")
      files = Dir.entries(directory).select { |f| File.file?(File.join(directory, f)) }

      CHANGELOG_FILENAMES.each do |name|
        pattern = /\A#{name}(\.(md|txt|rst|rdoc|markdown))?\z/i
        candidates = files.select { |f| f.match?(pattern) }
        candidates = candidates.reject { |f| f.end_with?(".sh") }

        return File.join(directory, candidates.first) if candidates.one?

        candidates.each do |candidate|
          path = File.join(directory, candidate)
          size = File.size(path)
          next if size > 1_000_000 || size < 100

          return path
        end
      end

      nil
    end

    def self.find_and_parse(directory = ".", **options)
      path = find_changelog(directory)
      return nil unless path

      parse_file(path, **options)
    end

    def resolve_pattern(format, custom_pattern)
      return custom_pattern if custom_pattern
      return FORMATS.fetch(format) if format

      detect_format
    end

    def detect_format
      return KEEP_A_CHANGELOG if changelog.match?(KEEP_A_CHANGELOG)
      return UNDERLINE_HEADER if changelog.match?(UNDERLINE_HEADER)

      MARKDOWN_HEADER
    end

    def find_version_matches
      matches = []
      scanner = StringScanner.new(changelog)

      while scanner.scan_until(version_pattern)
        matched = scanner.matched
        match_data = matched.match(version_pattern)

        matches << {
          version: match_data[match_group],
          date: extract_date(match_data),
          start_pos: scanner.pos - matched.length,
          end_pos: scanner.pos
        }
      end

      matches
    end

    def extract_date(match_data)
      return nil if match_data.captures.length < 2

      date_str = match_data[match_group + 1]
      return nil unless date_str

      Date.parse(date_str) rescue nil
    end

    def build_entry(match, content)
      {
        date: match[:date],
        content: content
      }
    end
  end
end

require "strscan"
require "date"
