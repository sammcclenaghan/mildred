# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("fixtures/vcr_cassettes", __dir__)
  config.hook_into :webmock
  config.default_cassette_options = { record: ENV["CI"] ? :none : :once }
  config.allow_http_connections_when_no_cassette = false
end

require "mildred"

Mildred.configure!
