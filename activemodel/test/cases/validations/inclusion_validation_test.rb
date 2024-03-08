# frozen_string_literal: true

require "cases/helper"
require "active_support/all"

require "models/topic"
require "models/person"

class InclusionValidationTest < ActiveModel::TestCase
  def teardown
    Topic.clear_validators!
  end

  def test_validates_inclusion_of_range
    Topic.validates_inclusion_of(:title, in: "aaa".."bbb")
    assert Topic.new("title" => "bbc", "content" => "abc").invalid?
    assert Topic.new("title" => "aa", "content" => "abc").invalid?
    assert Topic.new("title" => "aaab", "content" => "abc").invalid?
    assert Topic.new("title" => "aaa", "content" => "abc").valid?
    assert Topic.new("title" => "abc", "content" => "abc").valid?
    assert Topic.new("title" => "bbb", "content" => "abc").valid?
  end

  def test_validates_inclusion_of_time_range
    range_begin = 1.year.ago
    range_end = Time.now
    Topic.validates_inclusion_of(:created_at, in: range_begin..range_end)
    assert Topic.new(title: "aaa", created_at: 2.years.ago).invalid?
    assert Topic.new(title: "aaa", created_at: 3.months.ago).valid?
    assert Topic.new(title: "aaa", created_at: 37.weeks.from_now).invalid?
    assert Topic.new(title: "aaa", created_at: range_begin).valid?
    assert Topic.new(title: "aaa", created_at: range_end).valid?
  end

  def test_validates_inclusion_of_date_range
    range_begin = 1.year.until(Date.today)
    range_end = Date.today
    Topic.validates_inclusion_of(:created_at, in: range_begin..range_end)
    assert Topic.new(title: "aaa", created_at: 2.years.until(Date.today)).invalid?
    assert Topic.new(title: "aaa", created_at: 3.months.until(Date.today)).valid?
    assert Topic.new(title: "aaa", created_at: 37.weeks.since(Date.today)).invalid?
    assert Topic.new(title: "aaa", created_at: 1.year.until(Date.today)).valid?
    assert Topic.new(title: "aaa", created_at: Date.today).valid?
    assert Topic.new(title: "aaa", created_at: range_begin).valid?
    assert Topic.new(title: "aaa", created_at: range_end).valid?
  end

  def test_validates_inclusion_of_date_time_range
    range_begin = 1.year.until(DateTime.current)
    range_end = DateTime.current
    Topic.validates_inclusion_of(:created_at, in: range_begin..range_end)
    assert Topic.new(title: "aaa", created_at: 2.years.until(DateTime.current)).invalid?
    assert Topic.new(title: "aaa", created_at: 3.months.until(DateTime.current)).valid?
    assert Topic.new(title: "aaa", created_at: 37.weeks.since(DateTime.current)).invalid?
    assert Topic.new(title: "aaa", created_at: range_begin).valid?
    assert Topic.new(title: "aaa", created_at: range_end).valid?
  end

  def test_validates_inclusion_of
    Topic.validates_inclusion_of(:title, in: %w( a b c d e f g ))

    assert Topic.new("title" => "a!", "content" => "abc").invalid?
    assert Topic.new("title" => "a b", "content" => "abc").invalid?
    assert Topic.new("title" => nil, "content" => "def").invalid?

    t = Topic.new("title" => "a", "content" => "I know you are but what am I?")
    assert t.valid?
    t.title = "uhoh"
    assert t.invalid?
    assert t.errors[:title].any?
    assert_equal ["is not included in the list"], t.errors[:title]

    assert_raise(ArgumentError) { Topic.validates_inclusion_of(:title, in: nil) }
    assert_raise(ArgumentError) { Topic.validates_inclusion_of(:title, in: 0) }

    assert_nothing_raised { Topic.validates_inclusion_of(:title, in: "hi!") }
    assert_nothing_raised { Topic.validates_inclusion_of(:title, in: {}) }
    assert_nothing_raised { Topic.validates_inclusion_of(:title, in: []) }
  end

  def test_validates_inclusion_of_with_allow_nil
    Topic.validates_inclusion_of(:title, in: %w( a b c d e f g ), allow_nil: true)

    assert Topic.new("title" => "a!", "content" => "abc").invalid?
    assert Topic.new("title" => "",   "content" => "abc").invalid?
    assert Topic.new("title" => nil,  "content" => "abc").valid?
  end

  def test_validates_inclusion_of_with_formatted_message
    Topic.validates_inclusion_of(:title, in: %w( a b c d e f g ), message: "option %{value} is not in the list")

    assert Topic.new("title" => "a", "content" => "abc").valid?

    t = Topic.new("title" => "uhoh", "content" => "abc")
    assert t.invalid?
    assert t.errors[:title].any?
    assert_equal ["option uhoh is not in the list"], t.errors[:title]
  end

  def test_validates_inclusion_of_with_within_option
    Topic.validates_inclusion_of(:title, within: %w( a b c d e f g ))

    assert Topic.new("title" => "a", "content" => "abc").valid?

    t = Topic.new("title" => "uhoh", "content" => "abc")
    assert t.invalid?
    assert t.errors[:title].any?
  end

  def test_validates_inclusion_of_for_ruby_class
    Person.validates_inclusion_of :karma, in: %w( abe monkey )

    p = Person.new
    p.karma = "Lifo"
    assert p.invalid?

    assert_equal ["is not included in the list"], p.errors[:karma]

    p.karma = "monkey"
    assert p.valid?
  ensure
    Person.clear_validators!
  end

  def test_validates_inclusion_of_with_lambda
    Topic.validates_inclusion_of :title, in: lambda { |topic| topic.author_name == "sikachu" ? %w( monkey elephant ) : %w( abe wasabi ) }

    t = Topic.new
    t.title = "wasabi"
    t.author_name = "sikachu"
    assert t.invalid?

    t.title = "elephant"
    assert t.valid?
  end

  def test_validates_inclusion_of_with_symbol
    Person.validates_inclusion_of :karma, in: :available_karmas

    p = Person.new
    p.karma = "Lifo"

    def p.available_karmas
      %w()
    end

    assert p.invalid?
    assert_equal ["is not included in the list"], p.errors[:karma]

    p = Person.new
    p.karma = "Lifo"

    def p.available_karmas
      %w(Lifo)
    end

    assert p.valid?
  ensure
    Person.clear_validators!
  end
end
