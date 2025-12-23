# frozen_string_literal: true

require "test_helper"
require "changelog/parser/vandamme"

class TestVandammeCompatibility < Minitest::Test
  def test_initialize_with_changelog_keyword
    parser = Vandamme::Parser.new(changelog: "## [1.0.0] - 2024-01-01\n\nContent")
    result = parser.parse

    assert_equal 1, result.size
    assert_includes result.keys, "1.0.0"
  end

  def test_initialize_with_version_header_exp
    changelog = "Version 1.0.0\n\nContent"
    pattern = /^Version ([\d.]+)/
    parser = Vandamme::Parser.new(changelog: changelog, version_header_exp: pattern)
    result = parser.parse

    assert_includes result.keys, "1.0.0"
  end

  def test_initialize_with_format
    changelog = "## 1.0.0 (2024-01-01)\n\nContent"
    parser = Vandamme::Parser.new(changelog: changelog, format: :markdown)
    result = parser.parse

    assert_includes result.keys, "1.0.0"
  end

  def test_parse_returns_plain_strings
    changelog = "## [1.0.0] - 2024-01-01\n\nContent here"
    parser = Vandamme::Parser.new(changelog: changelog)
    result = parser.parse

    assert_instance_of String, result["1.0.0"]
    assert_equal "Content here", result["1.0.0"]
  end

  def test_parse_does_not_include_dates
    changelog = "## [1.0.0] - 2024-01-01\n\nContent"
    parser = Vandamme::Parser.new(changelog: changelog)
    result = parser.parse

    refute result["1.0.0"].is_a?(Hash)
  end

  def test_multiple_versions
    changelog = <<~CHANGELOG
      ## [2.0.0] - 2024-02-01

      Second release

      ## [1.0.0] - 2024-01-01

      First release
    CHANGELOG

    parser = Vandamme::Parser.new(changelog: changelog)
    result = parser.parse

    assert_equal 2, result.size
    assert_equal "Second release", result["2.0.0"]
    assert_equal "First release", result["1.0.0"]
  end

  def test_empty_changelog
    parser = Vandamme::Parser.new(changelog: "")
    result = parser.parse

    assert_equal({}, result)
  end

  def test_match_group_option
    changelog = "Release v1.0.0\n\nContent"
    pattern = /^(Release) v([\d.]+)/
    parser = Vandamme::Parser.new(
      changelog: changelog,
      version_header_exp: pattern,
      match_group: 2
    )
    result = parser.parse

    assert_includes result.keys, "1.0.0"
  end
end

class TestVandammeToHtml < Minitest::Test
  def setup
    @changelog = "## [1.0.0] - 2024-01-01\n\n- Feature one\n- Feature two"
    @parser = Vandamme::Parser.new(changelog: @changelog)
  end

  def test_to_html_raises_without_markdown_gem
    skip if markdown_gem_available?

    assert_raises(Changelog::Parser::Error) do
      @parser.to_html
    end
  end

  def test_to_html_returns_html_with_markdown_gem
    skip unless markdown_gem_available?

    result = @parser.to_html
    assert_instance_of String, result["1.0.0"]
    assert_includes result["1.0.0"], "<li>"
  end

  def markdown_gem_available?
    defined?(Commonmarker) || defined?(CommonMarker) || defined?(Redcarpet) || defined?(Kramdown)
  end
end
