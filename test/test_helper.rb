# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "changelog/parser"

require "minitest/autorun"
require "json"

def fixture_path(name)
  File.join(__dir__, "fixtures", name)
end
