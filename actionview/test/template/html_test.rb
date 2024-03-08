# frozen_string_literal: true

require "abstract_unit"

class HTMLTest < ActiveSupport::TestCase
  test "formats returns symbol for recognized MIME type" do
    assert_equal [:html], ActionView::Template::HTML.new("", :html).formats
  end

  test "formats returns string for recognized MIME type when MIME does not have symbol" do
    foo = Mime::Type.lookup("foo")
    assert_nil foo.to_sym
    assert_equal ["foo"], ActionView::Template::HTML.new("", foo).formats
  end

  test "formats returns string for unknown MIME type" do
    assert_equal ["foo"], ActionView::Template::HTML.new("", "foo").formats
  end
end
