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
    assert_includes stdout, "--format FORMAT"
  end

  def test_gem_version_flag
    stdout, _, status = run_cli("--gem-version")
    assert status.success?
    assert_match(/\d+\.\d+\.\d+/, stdout.strip)
  end

  def test_parse_file
    stdout, _, status = run_cli(fixture)
    assert status.success?

    result = JSON.parse(stdout)
    assert_equal 4, result.size
    assert_includes result.keys, "1.0.0"
  end

  def test_parse_stdin
    content = File.read(fixture)
    stdout, _, status = run_cli("-", stdin: content)
    assert status.success?

    result = JSON.parse(stdout)
    assert_equal 4, result.size
  end

  def test_list_versions
    stdout, _, status = run_cli("--list", fixture)
    assert status.success?

    versions = stdout.strip.split("\n")
    assert_equal 4, versions.size
    assert_includes versions, "1.0.0"
    assert_includes versions, "Unreleased"
  end

  def test_specific_version
    stdout, _, status = run_cli("--version", "1.0.0", fixture)
    assert status.success?

    result = JSON.parse(stdout)
    assert_equal 1, result.size
    assert_includes result.keys, "1.0.0"
  end

  def test_content_output
    stdout, _, status = run_cli("--version", "1.0.0", "--content", fixture)
    assert status.success?
    assert_includes stdout, "Initial release"
  end

  def test_pretty_json
    stdout, _, status = run_cli("--pretty", fixture)
    assert status.success?
    assert_includes stdout, "\n  " # Indented JSON
  end

  def test_file_not_found
    _, stderr, status = run_cli("nonexistent.md")
    refute status.success?
    assert_includes stderr, "File not found"
  end

  def test_version_not_found
    _, stderr, status = run_cli("--version", "99.99.99", fixture)
    refute status.success?
    assert_includes stderr, "Version not found"
  end

  def test_content_requires_version
    _, stderr, status = run_cli("--content", fixture)
    refute status.success?
    assert_includes stderr, "--content requires --version"
  end
end
