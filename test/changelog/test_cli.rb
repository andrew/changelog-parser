# frozen_string_literal: true

require "test_helper"
require "open3"

class TestCLI < Minitest::Test
  def cli_path
    File.expand_path("../../exe/changelog-parser", __dir__)
  end

  def fixture
    fixture_path("keep_a_changelog.md")
  end

  def run_cli(*args, stdin: nil)
    cmd = [RbConfig.ruby, cli_path, *args].join(" ")
    Open3.capture3(cmd, stdin_data: stdin)
  end

  def test_help_flag
    stdout, _, status = run_cli("--help")
    assert status.success?
    assert_includes stdout, "Usage: changelog-parser"
    assert_includes stdout, "Commands:"
    assert_includes stdout, "parse"
    assert_includes stdout, "list"
    assert_includes stdout, "show"
    assert_includes stdout, "between"
  end

  def test_version_flag
    stdout, _, status = run_cli("--version")
    assert status.success?
    assert_match(/\d+\.\d+\.\d+/, stdout.strip)
  end

  def test_parse_file
    stdout, _, status = run_cli("parse", fixture)
    assert status.success?

    result = JSON.parse(stdout)
    assert_equal 4, result.size
    assert_includes result.keys, "1.0.0"
  end

  def test_parse_stdin
    content = File.read(fixture)
    stdout, _, status = run_cli("parse", "-", stdin: content)
    assert status.success?

    result = JSON.parse(stdout)
    assert_equal 4, result.size
  end

  def test_parse_is_default_command
    stdout, _, status = run_cli(fixture)
    assert status.success?

    result = JSON.parse(stdout)
    assert_equal 4, result.size
  end

  def test_list_versions
    stdout, _, status = run_cli("list", fixture)
    assert status.success?

    versions = stdout.strip.split("\n")
    assert_equal 4, versions.size
    assert_includes versions, "1.0.0"
    assert_includes versions, "Unreleased"
  end

  def test_show_version
    stdout, _, status = run_cli("show", "1.0.0", fixture)
    assert status.success?
    assert_includes stdout, "Initial release"
  end

  def test_show_version_not_found
    _, stderr, status = run_cli("show", "99.99.99", fixture)
    refute status.success?
    assert_includes stderr, "Version not found"
  end

  def test_show_requires_version
    _, stderr, status = run_cli("show", fixture)
    refute status.success?
    assert_includes stderr, "requires a version"
  end

  def test_between_versions
    stdout, _, status = run_cli("between", "1.0.0", "1.1.0", fixture)
    assert status.success?
    assert_includes stdout, "1.1.0"
  end

  def test_between_requires_two_versions
    _, stderr, status = run_cli("between", "1.0.0", fixture)
    refute status.success?
    assert_includes stderr, "requires two version"
  end

  def test_pretty_json
    stdout, _, status = run_cli("parse", "--pretty", fixture)
    assert status.success?
    assert_includes stdout, "\n  "
  end

  def test_file_not_found
    _, stderr, status = run_cli("parse", "nonexistent.md")
    refute status.success?
    assert_includes stderr, "not found"
  end

  def test_parse_directory
    stdout, _, status = run_cli("list", ".")
    assert status.success?
    assert_includes stdout, "0.2.0"
  end

  def test_directory_no_changelog
    Dir.mktmpdir do |dir|
      _, stderr, status = run_cli("parse", dir)
      refute status.success?
      assert_includes stderr, "No changelog found"
    end
  end

  def test_validate_valid_changelog
    stdout, _, status = run_cli("validate", fixture)
    assert status.success?
    assert_includes stdout, "Valid changelog"
  end

  def test_validate_missing_unreleased
    Dir.mktmpdir do |dir|
      path = File.join(dir, "CHANGELOG.md")
      File.write(path, "## [1.0.0] - 2024-01-01\n\nContent")
      _, stderr, status = run_cli("validate", path)
      assert status.success?
      assert_includes stderr, "No [Unreleased] section"
    end
  end

  def test_validate_empty_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "CHANGELOG.md")
      File.write(path, "# Changelog\n\nNothing here")
      _, stderr, status = run_cli("validate", path)
      refute status.success?
      assert_includes stderr, "No versions found"
    end
  end

  def test_validate_missing_date
    Dir.mktmpdir do |dir|
      path = File.join(dir, "CHANGELOG.md")
      File.write(path, "## [1.0.0]\n\nContent without date")
      _, stderr, status = run_cli("validate", path)
      assert status.success?
      assert_includes stderr, "has no date"
    end
  end
end
