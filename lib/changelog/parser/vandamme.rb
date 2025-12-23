# frozen_string_literal: true

require_relative "../parser"

module Vandamme
  class Parser
    attr_reader :parser

    def initialize(changelog: "", version_header_exp: nil, format: nil, match_group: 1)
      @parser = Changelog::Parser.new(
        changelog,
        version_pattern: version_header_exp,
        format: format,
        match_group: match_group
      )
    end

    def parse
      @parser.parse.transform_values { |entry| entry[:content] }
    end

    def to_html
      parsed = parse
      parsed.transform_values { |content| render_html(content) }
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
        raise Changelog::Parser::Error,
          "No markdown renderer found. Install commonmarker, redcarpet, or kramdown."
      end
    end
  end
end
