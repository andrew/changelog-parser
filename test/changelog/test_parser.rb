# frozen_string_literal: true

require "test_helper"

class TestParser < Minitest::Test
  def test_version_number
    refute_nil Changelog::Parser::VERSION
  end

  def test_parse_empty_changelog
    result = Changelog::Parser.parse("")
    assert_equal({}, result)
  end

  def test_parse_nil_changelog
    result = Changelog::Parser.parse(nil)
    assert_equal({}, result)
  end
end

class TestKeepAChangelogFormat < Minitest::Test
  def setup
    @changelog = File.read(fixture_path("keep_a_changelog.md"))
    @parser = Changelog::Parser.new(@changelog)
  end

  def test_detects_keep_a_changelog_format
    assert_equal Changelog::Parser::KEEP_A_CHANGELOG, @parser.version_pattern
  end

  def test_parses_all_versions
    result = @parser.parse
    assert_equal 4, result.size
    assert_includes result.keys, "Unreleased"
    assert_includes result.keys, "1.1.0"
    assert_includes result.keys, "1.0.1"
    assert_includes result.keys, "1.0.0"
  end

  def test_extracts_dates
    result = @parser.parse
    assert_nil result["Unreleased"][:date]
    assert_equal Date.new(2024, 3, 15), result["1.1.0"][:date]
    assert_equal Date.new(2024, 2, 1), result["1.0.1"][:date]
    assert_equal Date.new(2024, 1, 15), result["1.0.0"][:date]
  end

  def test_extracts_content
    result = @parser.parse
    assert_includes result["1.1.0"][:content], "User authentication system"
    assert_includes result["1.1.0"][:content], "Memory leak in connection pool"
    assert_includes result["1.0.0"][:content], "Initial release"
  end

  def test_versions_method
    assert_equal ["Unreleased", "1.1.0", "1.0.1", "1.0.0"], @parser.versions
  end

  def test_bracket_accessor
    entry = @parser["1.0.1"]
    assert_equal Date.new(2024, 2, 1), entry[:date]
    assert_includes entry[:content], "Critical bug"
  end

  def test_to_h
    assert_equal @parser.parse, @parser.to_h
  end

  def test_to_json
    json = @parser.to_json
    parsed = JSON.parse(json)
    assert_equal 4, parsed.size
    assert_includes parsed.keys, "1.0.0"
  end
end

class TestMarkdownHeaderFormat < Minitest::Test
  def setup
    @changelog = File.read(fixture_path("markdown_header.md"))
    @parser = Changelog::Parser.new(@changelog, format: :markdown)
  end

  def test_parses_versions_with_parenthesized_dates
    result = @parser.parse
    assert_includes result.keys, "2.0.0"
    assert_equal Date.new(2024, 3, 1), result["2.0.0"][:date]
  end

  def test_parses_versions_without_dates
    result = @parser.parse
    assert_includes result.keys, "1.5.0"
    assert_nil result["1.5.0"][:date]
  end

  def test_parses_h3_headers
    result = @parser.parse
    assert_includes result.keys, "1.4.2"
  end

  def test_extracts_content_correctly
    result = @parser.parse
    assert_includes result["2.0.0"][:content], "Breaking changes"
    assert_includes result["1.5.0"][:content], "caching layer"
  end
end

class TestUnderlineFormat < Minitest::Test
  def setup
    @changelog = File.read(fixture_path("underline.md"))
    @parser = Changelog::Parser.new(@changelog, format: :underline)
  end

  def test_parses_equals_underline
    result = @parser.parse
    assert_includes result.keys, "3.0.0"
    assert_includes result.keys, "2.0.0"
  end

  def test_parses_dash_underline
    result = @parser.parse
    assert_includes result.keys, "2.1.0"
  end

  def test_extracts_content
    result = @parser.parse
    assert_includes result["3.0.0"][:content], "Complete rewrite"
    assert_includes result["2.1.0"][:content], "Bug fixes"
  end
end

class TestCustomPattern < Minitest::Test
  def test_custom_regex_pattern
    changelog = <<~CHANGELOG
      Version 1.2.0 released 2024-01-01
      - Feature A

      Version 1.1.0 released 2023-12-01
      - Feature B
    CHANGELOG

    pattern = /^Version ([\d.]+) released (\d{4}-\d{2}-\d{2})/
    parser = Changelog::Parser.new(changelog, version_pattern: pattern)
    result = parser.parse

    assert_equal 2, result.size
    assert_includes result.keys, "1.2.0"
    assert_includes result.keys, "1.1.0"
    assert_equal Date.new(2024, 1, 1), result["1.2.0"][:date]
  end

  def test_custom_match_group
    changelog = <<~CHANGELOG
      ## Release v1.0.0

      Content here

      ## Release v0.9.0

      More content
    CHANGELOG

    pattern = /^## Release v([\d.]+)/
    parser = Changelog::Parser.new(changelog, version_pattern: pattern)
    result = parser.parse

    assert_equal 2, result.size
    assert_includes result.keys, "1.0.0"
    assert_includes result.keys, "0.9.0"
  end
end

class TestClassMethods < Minitest::Test
  def test_parse_class_method
    changelog = "## [1.0.0] - 2024-01-01\n\nContent"
    result = Changelog::Parser.parse(changelog)

    assert_equal 1, result.size
    assert_includes result.keys, "1.0.0"
  end

  def test_parse_file_class_method
    result = Changelog::Parser.parse_file(fixture_path("keep_a_changelog.md"))

    assert_equal 4, result.size
    assert_includes result.keys, "1.0.0"
  end
end

class TestToHtml < Minitest::Test
  def setup
    @changelog = "## [1.0.0] - 2024-01-01\n\n- Feature one\n- Feature two"
    @parser = Changelog::Parser.new(@changelog)
  end

  def test_to_html_raises_without_markdown_gem
    skip if markdown_gem_available?

    assert_raises(Changelog::Parser::Error) do
      @parser.to_html
    end
  end

  def test_to_html_returns_hash_structure_with_markdown_gem
    skip unless markdown_gem_available?

    result = @parser.to_html
    assert_instance_of Hash, result["1.0.0"]
    assert result["1.0.0"].key?(:date)
    assert result["1.0.0"].key?(:content)
  end

  def test_to_html_converts_markdown_with_markdown_gem
    skip unless markdown_gem_available?

    result = @parser.to_html
    assert_includes result["1.0.0"][:content], "<li>"
  end

  def test_to_html_preserves_date
    skip unless markdown_gem_available?

    result = @parser.to_html
    assert_equal Date.new(2024, 1, 1), result["1.0.0"][:date]
  end

  def markdown_gem_available?
    defined?(Commonmarker) || defined?(CommonMarker) || defined?(Redcarpet) || defined?(Kramdown)
  end
end

class TestFormatDetection < Minitest::Test
  def test_auto_detects_keep_a_changelog
    changelog = "## [1.0.0] - 2024-01-01\n\nContent"
    parser = Changelog::Parser.new(changelog)
    assert_equal Changelog::Parser::KEEP_A_CHANGELOG, parser.version_pattern
  end

  def test_auto_detects_underline_format
    changelog = "1.0.0\n=====\n\nContent"
    parser = Changelog::Parser.new(changelog)
    assert_equal Changelog::Parser::UNDERLINE_HEADER, parser.version_pattern
  end

  def test_falls_back_to_markdown_header
    changelog = "## 1.0.0\n\nContent"
    parser = Changelog::Parser.new(changelog)
    assert_equal Changelog::Parser::MARKDOWN_HEADER, parser.version_pattern
  end
end

class TestEdgeCases < Minitest::Test
  def test_version_with_prerelease
    changelog = "## [1.0.0-beta.1] - 2024-01-01\n\nBeta content"
    result = Changelog::Parser.parse(changelog)

    assert_includes result.keys, "1.0.0-beta.1"
  end

  def test_version_with_build_metadata
    changelog = "## [1.0.0+build.123] - 2024-01-01\n\nBuild content"
    result = Changelog::Parser.parse(changelog)

    assert_includes result.keys, "1.0.0+build.123"
  end

  def test_complex_prerelease_version
    changelog = "## [2.0.0-x.7.z.92] - 2024-01-01\n\nComplex prerelease"
    result = Changelog::Parser.parse(changelog)

    assert_includes result.keys, "2.0.0-x.7.z.92"
  end

  def test_empty_version_content
    changelog = <<~CHANGELOG
      ## [2.0.0] - 2024-02-01

      ## [1.0.0] - 2024-01-01

      Some content
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_equal "", result["2.0.0"][:content]
    assert_includes result["1.0.0"][:content], "Some content"
  end

  def test_preserves_version_order
    changelog = <<~CHANGELOG
      ## [3.0.0] - 2024-03-01
      ## [1.0.0] - 2024-01-01
      ## [2.0.0] - 2024-02-01
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_equal ["3.0.0", "1.0.0", "2.0.0"], result.keys
  end

  def test_preserves_markdown_links
    changelog = <<~CHANGELOG
      ## [1.0.0] - 2024-01-01

      - Added [feature](https://example.com)
      - See [docs](https://docs.example.com) for details
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_includes result["1.0.0"][:content], "[feature](https://example.com)"
  end

  def test_preserves_inline_code
    changelog = <<~CHANGELOG
      ## [1.0.0] - 2024-01-01

      - Fixed `bug_in_function` method
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_includes result["1.0.0"][:content], "`bug_in_function`"
  end

  def test_ignores_link_references
    changelog = <<~CHANGELOG
      ## [1.0.0] - 2024-01-01

      Content here

      [1.0.0]: https://github.com/example/repo/releases/tag/v1.0.0
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_equal 1, result.size
    assert_includes result["1.0.0"][:content], "[1.0.0]: https://github.com"
  end

  def test_handles_mixed_list_markers
    changelog = <<~CHANGELOG
      ## [1.0.0] - 2024-01-01

      - Dash item
      * Asterisk item
      - Another dash
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_includes result["1.0.0"][:content], "- Dash item"
    assert_includes result["1.0.0"][:content], "* Asterisk item"
  end

  def test_handles_nested_lists
    changelog = <<~CHANGELOG
      ## [1.0.0] - 2024-01-01

      - Main item
        - Sub item one
        - Sub item two
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_includes result["1.0.0"][:content], "- Sub item one"
  end

  def test_version_with_v_prefix
    changelog = "## v1.0.0\n\nContent"
    result = Changelog::Parser.parse(changelog, format: :markdown)

    assert_includes result.keys, "1.0.0"
  end

  def test_unreleased_section
    changelog = <<~CHANGELOG
      ## [Unreleased]

      - Work in progress

      ## [1.0.0] - 2024-01-01

      - Released feature
    CHANGELOG

    result = Changelog::Parser.parse(changelog)
    assert_includes result.keys, "Unreleased"
    assert_nil result["Unreleased"][:date]
    assert_includes result["Unreleased"][:content], "Work in progress"
  end

  def test_version_with_label
    changelog = "## [1.0.0] - 2024-01-01 - Codename Phoenix\n\nContent"
    result = Changelog::Parser.parse(changelog)

    assert_includes result.keys, "1.0.0"
    assert_equal Date.new(2024, 1, 1), result["1.0.0"][:date]
  end

  def test_comprehensive_fixture
    result = Changelog::Parser.parse_file(fixture_path("comprehensive.md"))

    assert_equal 8, result.size
    assert_includes result.keys, "Unreleased"
    assert_includes result.keys, "2.0.0-x.7.z.92"
    assert_includes result.keys, "1.5.0-beta.2"
    assert_includes result.keys, "1.0.0"
  end
end
