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

    def self.parse(changelog, **options)
      new(changelog, **options).parse
    end

    def self.parse_file(path, **options)
      content = File.read(path)
      new(content, **options).parse
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
