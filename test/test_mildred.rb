# frozen_string_literal: true

require "test_helper"
require "mildred"

class TestMildred < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Mildred::VERSION
  end

  def test_hello_world
    assert_equal "Hello World", Mildred.hi()
  end
end
