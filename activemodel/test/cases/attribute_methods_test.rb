# frozen_string_literal: true

require "cases/helper"

class ModelWithAttributes
  include ActiveModel::AttributeMethods

  class << self
    define_method(:bar) do
      "original bar"
    end
  end

  def attributes
    { foo: "value of foo", baz: "value of baz" }
  end

private
  def attribute(name)
    attributes[name.to_sym]
  end
end

class ModelWithAttributes2
  include ActiveModel::AttributeMethods

  attr_accessor :attributes

  attribute_method_suffix "_test"

private
  def attribute(name)
    attributes[name.to_s]
  end

  alias attribute_test attribute

  def private_method
    "<3 <3"
  end

protected

  def protected_method
    "O_o O_o"
  end
end

class ModelWithAttributesWithSpaces
  include ActiveModel::AttributeMethods

  def attributes
    { 'foo bar': "value of foo bar" }
  end

private
  def attribute(name)
    attributes[name.to_sym]
  end
end

class ModelWithWeirdNamesAttributes
  include ActiveModel::AttributeMethods

  class << self
    define_method(:'c?d') do
      "original c?d"
    end
  end

  def attributes
    { 'a?b': "value of a?b" }
  end

private
  def attribute(name)
    attributes[name.to_sym]
  end
end

class ModelWithRubyKeywordNamedAttributes
  include ActiveModel::AttributeMethods

  def attributes
    { begin: "value of begin", end: "value of end" }
  end

private
  def attribute(name)
    attributes[name.to_sym]
  end
end

class ModelWithoutAttributesMethod
  include ActiveModel::AttributeMethods
end

class AttributeMethodsTest < ActiveModel::TestCase
  test "method missing works correctly even if attributes method is not defined" do
    assert_raises(NoMethodError) { ModelWithoutAttributesMethod.new.foo }
  end

  test "unrelated classes should not share attribute method matchers" do
    assert_not_equal ModelWithAttributes.send(:attribute_method_matchers),
                     ModelWithAttributes2.send(:attribute_method_matchers)
  end

  test "#define_attribute_method generates attribute method" do
    begin
      ModelWithAttributes.define_attribute_method(:foo)

      assert_respond_to ModelWithAttributes.new, :foo
      assert_equal "value of foo", ModelWithAttributes.new.foo
    ensure
      ModelWithAttributes.undefine_attribute_methods
    end
  end

  test "#define_attribute_method does not generate attribute method if already defined in attribute module" do
    klass = Class.new(ModelWithAttributes)
    klass.send(:generated_attribute_methods).module_eval do
      def foo
        "<3"
      end
    end
    klass.define_attribute_method(:foo)

    assert_equal "<3", klass.new.foo
  end

  test "#define_attribute_method generates a method that is already defined on the host" do
    klass = Class.new(ModelWithAttributes) do
      def foo
        super
      end
    end
    klass.define_attribute_method(:foo)

    assert_equal "value of foo", klass.new.foo
  end

  test "#define_attribute_method generates attribute method with invalid identifier characters" do
    begin
      ModelWithWeirdNamesAttributes.define_attribute_method(:'a?b')

      assert_respond_to ModelWithWeirdNamesAttributes.new, :'a?b'
      assert_equal "value of a?b", ModelWithWeirdNamesAttributes.new.send("a?b")
    ensure
      ModelWithWeirdNamesAttributes.undefine_attribute_methods
    end
  end

  test "#define_attribute_methods works passing multiple arguments" do
    begin
      ModelWithAttributes.define_attribute_methods(:foo, :baz)

      assert_equal "value of foo", ModelWithAttributes.new.foo
      assert_equal "value of baz", ModelWithAttributes.new.baz
    ensure
      ModelWithAttributes.undefine_attribute_methods
    end
  end

  test "#define_attribute_methods generates attribute methods" do
    begin
      ModelWithAttributes.define_attribute_methods(:foo)

      assert_respond_to ModelWithAttributes.new, :foo
      assert_equal "value of foo", ModelWithAttributes.new.foo
    ensure
      ModelWithAttributes.undefine_attribute_methods
    end
  end

  test "#alias_attribute generates attribute_aliases lookup hash" do
    klass = Class.new(ModelWithAttributes) do
      define_attribute_methods :foo
      alias_attribute :bar, :foo
    end

    assert_equal({ "bar" => "foo" }, klass.attribute_aliases)
  end

  test "#define_attribute_methods generates attribute methods with spaces in their names" do
    begin
      ModelWithAttributesWithSpaces.define_attribute_methods(:'foo bar')

      assert_respond_to ModelWithAttributesWithSpaces.new, :'foo bar'
      assert_equal "value of foo bar", ModelWithAttributesWithSpaces.new.send(:'foo bar')
    ensure
      ModelWithAttributesWithSpaces.undefine_attribute_methods
    end
  end

  test "#alias_attribute works with attributes with spaces in their names" do
    begin
      ModelWithAttributesWithSpaces.define_attribute_methods(:'foo bar')
      ModelWithAttributesWithSpaces.alias_attribute(:'foo_bar', :'foo bar')

      assert_equal "value of foo bar", ModelWithAttributesWithSpaces.new.foo_bar
    ensure
      ModelWithAttributesWithSpaces.undefine_attribute_methods
    end
  end

  test "#alias_attribute works with attributes named as a ruby keyword" do
    begin
      ModelWithRubyKeywordNamedAttributes.define_attribute_methods([:begin, :end])
      ModelWithRubyKeywordNamedAttributes.alias_attribute(:from, :begin)
      ModelWithRubyKeywordNamedAttributes.alias_attribute(:to, :end)

      assert_equal "value of begin", ModelWithRubyKeywordNamedAttributes.new.from
      assert_equal "value of end", ModelWithRubyKeywordNamedAttributes.new.to
    ensure
      ModelWithRubyKeywordNamedAttributes.undefine_attribute_methods
    end
  end

  test "#undefine_attribute_methods removes attribute methods" do
    ModelWithAttributes.define_attribute_methods(:foo)
    ModelWithAttributes.undefine_attribute_methods

    assert !ModelWithAttributes.new.respond_to?(:foo)
    assert_raises(NoMethodError) { ModelWithAttributes.new.foo }
  end

  test "accessing a suffixed attribute" do
    m = ModelWithAttributes2.new
    m.attributes = { "foo" => "bar" }

    assert_equal "bar", m.foo
    assert_equal "bar", m.foo_test
  end

  test "should not interfere with method_missing if the attr has a private/protected method" do
    m = ModelWithAttributes2.new
    m.attributes = { "private_method" => "<3", "protected_method" => "O_o" }

    # dispatches to the *method*, not the attribute
    assert_equal "<3 <3",   m.send(:private_method)
    assert_equal "O_o O_o", m.send(:protected_method)

    # sees that a method is already defined, so doesn't intervene
    assert_raises(NoMethodError) { m.private_method }
    assert_raises(NoMethodError) { m.protected_method }
  end

  class ClassWithProtected
    protected
      def protected_method
      end
  end

  test "should not interfere with respond_to? if the attribute has a private/protected method" do
    m = ModelWithAttributes2.new
    m.attributes = { "private_method" => "<3", "protected_method" => "O_o" }

    assert !m.respond_to?(:private_method)
    assert m.respond_to?(:private_method, true)

    c = ClassWithProtected.new

    # This is messed up, but it's how Ruby works at the moment. Apparently it will be changed
    # in the future.
    assert_equal c.respond_to?(:protected_method), m.respond_to?(:protected_method)
    assert m.respond_to?(:protected_method, true)
  end

  test "should use attribute_missing to dispatch a missing attribute" do
    m = ModelWithAttributes2.new
    m.attributes = { "foo" => "bar" }

    def m.attribute_missing(match, *args, &block)
      match
    end

    match = m.foo_test

    assert_equal "foo",            match.attr_name
    assert_equal "attribute_test", match.target
    assert_equal "foo_test",       match.method_name
  end
end
