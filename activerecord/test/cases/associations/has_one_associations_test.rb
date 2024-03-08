# frozen_string_literal: true

require "cases/helper"
require "models/developer"
require "models/computer"
require "models/project"
require "models/company"
require "models/ship"
require "models/pirate"
require "models/car"
require "models/bulb"
require "models/author"
require "models/image"
require "models/post"

class HasOneAssociationsTest < ActiveRecord::TestCase
  self.use_transactional_tests = false unless supports_savepoints?
  fixtures :accounts, :companies, :developers, :projects, :developers_projects, :ships, :pirates, :authors, :author_addresses

  def setup
    Account.destroyed_account_ids.clear
  end

  def test_has_one
    assert_equal companies(:first_firm).account, Account.find(1)
    assert_equal Account.find(1).credit_limit, companies(:first_firm).account.credit_limit
  end

  def test_has_one_does_not_use_order_by
    ActiveRecord::SQLCounter.clear_log
    companies(:first_firm).account
  ensure
    log_all = ActiveRecord::SQLCounter.log_all
    assert log_all.all? { |sql| /order by/i !~ sql }, "ORDER BY was used in the query: #{log_all}"
  end

  def test_has_one_cache_nils
    firm = companies(:another_firm)
    assert_queries(1) { assert_nil firm.account }
    assert_queries(0) { assert_nil firm.account }

    firms = Firm.all.merge!(includes: :account).to_a
    assert_queries(0) { firms.each(&:account) }
  end

  def test_with_select
    assert_equal Firm.find(1).account_with_select.attributes.size, 2
    assert_equal Firm.all.merge!(includes: :account_with_select).find(1).account_with_select.attributes.size, 2
  end

  def test_finding_using_primary_key
    firm = companies(:first_firm)
    assert_equal Account.find_by_firm_id(firm.id), firm.account
    firm.firm_id = companies(:rails_core).id
    assert_equal accounts(:rails_core_account), firm.account_using_primary_key
  end

  def test_update_with_foreign_and_primary_keys
    firm = companies(:first_firm)
    account = firm.account_using_foreign_and_primary_keys
    assert_equal Account.find_by_firm_name(firm.name), account
    firm.save
    firm.reload
    assert_equal account, firm.account_using_foreign_and_primary_keys
  end

  def test_can_marshal_has_one_association_with_nil_target
    firm = Firm.new
    assert_nothing_raised do
      assert_equal firm.attributes, Marshal.load(Marshal.dump(firm)).attributes
    end

    firm.account
    assert_nothing_raised do
      assert_equal firm.attributes, Marshal.load(Marshal.dump(firm)).attributes
    end
  end

  def test_proxy_assignment
    company = companies(:first_firm)
    assert_nothing_raised { company.account = company.account }
  end

  def test_type_mismatch
    assert_raise(ActiveRecord::AssociationTypeMismatch) { companies(:first_firm).account = 1 }
    assert_raise(ActiveRecord::AssociationTypeMismatch) { companies(:first_firm).account = Project.find(1) }
  end

  def test_natural_assignment
    apple = Firm.create("name" => "Apple")
    citibank = Account.create("credit_limit" => 10)
    apple.account = citibank
    assert_equal apple.id, citibank.firm_id
  end

  def test_natural_assignment_to_nil
    old_account_id = companies(:first_firm).account.id
    companies(:first_firm).account = nil
    companies(:first_firm).save
    assert_nil companies(:first_firm).account
    # account is dependent, therefore is destroyed when reference to owner is lost
    assert_raise(ActiveRecord::RecordNotFound) { Account.find(old_account_id) }
  end

  def test_nullification_on_association_change
    firm = companies(:rails_core)
    old_account_id = firm.account.id
    firm.account = Account.new(credit_limit: 5)
    # account is dependent with nullify, therefore its firm_id should be nil
    assert_nil Account.find(old_account_id).firm_id
  end

  def test_nullification_on_destroyed_association
    developer = Developer.create!(name: "Someone")
    ship = Ship.create!(name: "Planet Caravan", developer: developer)
    ship.destroy
    assert !ship.persisted?
    assert !developer.persisted?
  end

  def test_natural_assignment_to_nil_after_destroy
    firm = companies(:rails_core)
    old_account_id = firm.account.id
    firm.account.destroy
    firm.account = nil
    assert_nil companies(:rails_core).account
    assert_raise(ActiveRecord::RecordNotFound) { Account.find(old_account_id) }
  end

  def test_association_change_calls_delete
    companies(:first_firm).deletable_account = Account.new(credit_limit: 5)
    assert_equal [], Account.destroyed_account_ids[companies(:first_firm).id]
  end

  def test_association_change_calls_destroy
    companies(:first_firm).account = Account.new(credit_limit: 5)
    assert_equal [companies(:first_firm).id], Account.destroyed_account_ids[companies(:first_firm).id]
  end

  def test_natural_assignment_to_already_associated_record
    company = companies(:first_firm)
    account = accounts(:signals37)
    assert_equal company.account, account
    company.account = account
    company.reload
    account.reload
    assert_equal company.account, account
  end

  def test_dependence
    num_accounts = Account.count

    firm = Firm.find(1)
    assert_not_nil firm.account
    account_id = firm.account.id
    assert_equal [], Account.destroyed_account_ids[firm.id]

    firm.destroy
    assert_equal num_accounts - 1, Account.count
    assert_equal [account_id], Account.destroyed_account_ids[firm.id]
  end

  def test_exclusive_dependence
    num_accounts = Account.count

    firm = ExclusivelyDependentFirm.find(9)
    assert_not_nil firm.account
    assert_equal [], Account.destroyed_account_ids[firm.id]

    firm.destroy
    assert_equal num_accounts - 1, Account.count
    assert_equal [], Account.destroyed_account_ids[firm.id]
  end

  def test_dependence_with_nil_associate
    firm = DependentFirm.new(name: "nullify")
    firm.save!
    assert_nothing_raised { firm.destroy }
  end

  def test_restrict_with_exception
    firm = RestrictedWithExceptionFirm.create!(name: "restrict")
    firm.create_account(credit_limit: 10)

    assert_not_nil firm.account

    assert_raise(ActiveRecord::DeleteRestrictionError) { firm.destroy }
    assert RestrictedWithExceptionFirm.exists?(name: "restrict")
    assert firm.account.present?
  end

  def test_restrict_with_error
    firm = RestrictedWithErrorFirm.create!(name: "restrict")
    firm.create_account(credit_limit: 10)

    assert_not_nil firm.account

    firm.destroy

    assert !firm.errors.empty?
    assert_equal "Cannot delete record because a dependent account exists", firm.errors[:base].first
    assert RestrictedWithErrorFirm.exists?(name: "restrict")
    assert firm.account.present?
  end

  def test_restrict_with_error_with_locale
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations "en", activerecord: { attributes: { restricted_with_error_firm: { account: "firm account" } } }
    firm = RestrictedWithErrorFirm.create!(name: "restrict")
    firm.create_account(credit_limit: 10)

    assert_not_nil firm.account

    firm.destroy

    assert !firm.errors.empty?
    assert_equal "Cannot delete record because a dependent firm account exists", firm.errors[:base].first
    assert RestrictedWithErrorFirm.exists?(name: "restrict")
    assert firm.account.present?
  ensure
    I18n.backend.reload!
  end

  def test_successful_build_association
    firm = Firm.new("name" => "GlobalMegaCorp")
    firm.save

    account = firm.build_account("credit_limit" => 1000)
    assert account.save
    assert_equal account, firm.account
  end

  def test_build_association_dont_create_transaction
    assert_no_queries(ignore_none: false) {
      Firm.new.build_account
    }
  end

  def test_building_the_associated_object_with_implicit_sti_base_class
    firm = DependentFirm.new
    company = firm.build_company
    assert_kind_of Company, company, "Expected #{company.class} to be a Company"
  end

  def test_building_the_associated_object_with_explicit_sti_base_class
    firm = DependentFirm.new
    company = firm.build_company(type: "Company")
    assert_kind_of Company, company, "Expected #{company.class} to be a Company"
  end

  def test_building_the_associated_object_with_sti_subclass
    firm = DependentFirm.new
    company = firm.build_company(type: "Client")
    assert_kind_of Client, company, "Expected #{company.class} to be a Client"
  end

  def test_building_the_associated_object_with_an_invalid_type
    firm = DependentFirm.new
    assert_raise(ActiveRecord::SubclassNotFound) { firm.build_company(type: "Invalid") }
  end

  def test_building_the_associated_object_with_an_unrelated_type
    firm = DependentFirm.new
    assert_raise(ActiveRecord::SubclassNotFound) { firm.build_company(type: "Account") }
  end

  def test_build_and_create_should_not_happen_within_scope
    pirate = pirates(:blackbeard)
    scope = pirate.association(:foo_bulb).scope.where_values_hash

    bulb = pirate.build_foo_bulb
    assert_not_equal scope, bulb.scope_after_initialize.where_values_hash

    bulb = pirate.create_foo_bulb
    assert_not_equal scope, bulb.scope_after_initialize.where_values_hash

    bulb = pirate.create_foo_bulb!
    assert_not_equal scope, bulb.scope_after_initialize.where_values_hash
  end

  def test_create_association
    firm = Firm.create(name: "GlobalMegaCorp")
    account = firm.create_account(credit_limit: 1000)
    assert_equal account, firm.reload.account
  end

  def test_create_association_with_bang
    firm = Firm.create(name: "GlobalMegaCorp")
    account = firm.create_account!(credit_limit: 1000)
    assert_equal account, firm.reload.account
  end

  def test_create_association_with_bang_failing
    firm = Firm.create(name: "GlobalMegaCorp")
    assert_raise ActiveRecord::RecordInvalid do
      firm.create_account!
    end
    account = firm.account
    assert_not_nil account
    account.credit_limit = 5
    account.save
    assert_equal account, firm.reload.account
  end

  def test_create_with_inexistent_foreign_key_failing
    firm = Firm.create(name: "GlobalMegaCorp")

    assert_raises(ActiveRecord::UnknownAttributeError) do
      firm.create_account_with_inexistent_foreign_key
    end
  end

  def test_create_when_parent_is_new_raises
    firm = Firm.new
    error = assert_raise(ActiveRecord::RecordNotSaved) do
      firm.create_account
    end

    assert_equal "You cannot call create unless the parent is saved", error.message
  end

  def test_reload_association
    odegy = companies(:odegy)

    assert_equal 53, odegy.account.credit_limit
    Account.where(id: odegy.account.id).update_all(credit_limit: 80)
    assert_equal 53, odegy.account.credit_limit

    assert_equal 80, odegy.reload_account.credit_limit
  end

  def test_build
    firm = Firm.new("name" => "GlobalMegaCorp")
    firm.save

    firm.account = account = Account.new("credit_limit" => 1000)
    assert_equal account, firm.account
    assert account.save
    assert_equal account, firm.account
  end

  def test_create
    firm = Firm.new("name" => "GlobalMegaCorp")
    firm.save
    firm.account = account = Account.create("credit_limit" => 1000)
    assert_equal account, firm.account
  end

  def test_create_before_save
    firm = Firm.new("name" => "GlobalMegaCorp")
    firm.account = account = Account.create("credit_limit" => 1000)
    assert_equal account, firm.account
  end

  def test_dependence_with_missing_association
    Account.destroy_all
    firm = Firm.find(1)
    assert_nil firm.account
    firm.destroy
  end

  def test_dependence_with_missing_association_and_nullify
    Account.destroy_all
    firm = DependentFirm.first
    assert_nil firm.account
    firm.destroy
  end

  def test_finding_with_interpolated_condition
    firm = Firm.first
    superior = firm.clients.create(name: "SuperiorCo")
    superior.rating = 10
    superior.save
    assert_equal 10, firm.clients_with_interpolated_conditions.first.rating
  end

  def test_assignment_before_child_saved
    firm = Firm.find(1)
    firm.account = a = Account.new("credit_limit" => 1000)
    assert a.persisted?
    assert_equal a, firm.account
    assert_equal a, firm.account
    firm.association(:account).reload
    assert_equal a, firm.account
  end

  def test_save_still_works_after_accessing_nil_has_one
    jp = Company.new name: "Jaded Pixel"
    jp.dummy_account.nil?

    assert_nothing_raised do
      jp.save!
    end
  end

  def test_cant_save_readonly_association
    assert_raise(ActiveRecord::ReadOnlyRecord) { companies(:first_firm).readonly_account.save!  }
    assert companies(:first_firm).readonly_account.readonly?
  end

  def test_has_one_proxy_should_not_respond_to_private_methods
    assert_raise(NoMethodError) { accounts(:signals37).private_method }
    assert_raise(NoMethodError) { companies(:first_firm).account.private_method }
  end

  def test_has_one_proxy_should_respond_to_private_methods_via_send
    accounts(:signals37).send(:private_method)
    companies(:first_firm).account.send(:private_method)
  end

  def test_save_of_record_with_loaded_has_one
    @firm = companies(:first_firm)
    assert_not_nil @firm.account

    assert_nothing_raised do
      Firm.find(@firm.id).save!
      Firm.all.merge!(includes: :account).find(@firm.id).save!
    end

    @firm.account.destroy

    assert_nothing_raised do
      Firm.find(@firm.id).save!
      Firm.all.merge!(includes: :account).find(@firm.id).save!
    end
  end

  def test_build_respects_hash_condition
    account = companies(:first_firm).build_account_limit_500_with_hash_conditions
    assert account.save
    assert_equal 500, account.credit_limit
  end

  def test_create_respects_hash_condition
    account = companies(:first_firm).create_account_limit_500_with_hash_conditions
    assert       account.persisted?
    assert_equal 500, account.credit_limit
  end

  def test_attributes_are_being_set_when_initialized_from_has_one_association_with_where_clause
    new_account = companies(:first_firm).build_account(firm_name: "Account")
    assert_equal new_account.firm_name, "Account"
  end

  def test_creation_failure_without_dependent_option
    pirate = pirates(:blackbeard)
    orig_ship = pirate.ship

    assert_equal ships(:black_pearl), orig_ship
    new_ship = pirate.create_ship
    assert_not_equal ships(:black_pearl), new_ship
    assert_equal new_ship, pirate.ship
    assert new_ship.new_record?
    assert_nil orig_ship.pirate_id
    assert !orig_ship.changed? # check it was saved
  end

  def test_creation_failure_with_dependent_option
    pirate = pirates(:blackbeard).becomes(DestructivePirate)
    orig_ship = pirate.dependent_ship

    new_ship = pirate.create_dependent_ship
    assert new_ship.new_record?
    assert orig_ship.destroyed?
  end

  def test_creation_failure_due_to_new_record_should_raise_error
    pirate = pirates(:redbeard)
    new_ship = Ship.new

    error = assert_raise(ActiveRecord::RecordNotSaved) do
      pirate.ship = new_ship
    end

    assert_equal "Failed to save the new associated ship.", error.message
    assert_nil pirate.ship
    assert_nil new_ship.pirate_id
  end

  def test_replacement_failure_due_to_existing_record_should_raise_error
    pirate = pirates(:blackbeard)
    pirate.ship.name = nil

    assert !pirate.ship.valid?
    error = assert_raise(ActiveRecord::RecordNotSaved) do
      pirate.ship = ships(:interceptor)
    end

    assert_equal ships(:black_pearl), pirate.ship
    assert_equal pirate.id, pirate.ship.pirate_id
    assert_equal "Failed to remove the existing associated ship. " \
                 "The record failed to save after its foreign key was set to nil.", error.message
  end

  def test_replacement_failure_due_to_new_record_should_raise_error
    pirate = pirates(:blackbeard)
    new_ship = Ship.new

    error = assert_raise(ActiveRecord::RecordNotSaved) do
      pirate.ship = new_ship
    end

    assert_equal "Failed to save the new associated ship.", error.message
    assert_equal ships(:black_pearl), pirate.ship
    assert_equal pirate.id, pirate.ship.pirate_id
    assert_equal pirate.id, ships(:black_pearl).reload.pirate_id
    assert_nil new_ship.pirate_id
  end

  def test_association_keys_bypass_attribute_protection
    car = Car.create(name: "honda")

    bulb = car.build_bulb
    assert_equal car.id, bulb.car_id

    bulb = car.build_bulb car_id: car.id + 1
    assert_equal car.id, bulb.car_id

    bulb = car.create_bulb
    assert_equal car.id, bulb.car_id

    bulb = car.create_bulb car_id: car.id + 1
    assert_equal car.id, bulb.car_id
  end

  def test_association_protect_foreign_key
    pirate = Pirate.create!(catchphrase: "Don' botharrr talkin' like one, savvy?")

    ship = pirate.build_ship
    assert_equal pirate.id, ship.pirate_id

    ship = pirate.build_ship pirate_id: pirate.id + 1
    assert_equal pirate.id, ship.pirate_id

    ship = pirate.create_ship
    assert_equal pirate.id, ship.pirate_id

    ship = pirate.create_ship pirate_id: pirate.id + 1
    assert_equal pirate.id, ship.pirate_id
  end

  def test_build_with_block
    car = Car.create(name: "honda")

    bulb = car.build_bulb { |b| b.color = "Red" }
    assert_equal "RED!", bulb.color
  end

  def test_create_with_block
    car = Car.create(name: "honda")

    bulb = car.create_bulb { |b| b.color = "Red" }
    assert_equal "RED!", bulb.color
  end

  def test_create_bang_with_block
    car = Car.create(name: "honda")

    bulb = car.create_bulb! { |b| b.color = "Red" }
    assert_equal "RED!", bulb.color
  end

  def test_association_attributes_are_available_to_after_initialize
    car = Car.create(name: "honda")
    bulb = car.create_bulb

    assert_equal car.id, bulb.attributes_after_initialize["car_id"]
  end

  def test_has_one_transaction
    company = companies(:first_firm)
    account = Account.find(1)

    company.account # force loading
    assert_no_queries { company.account = account }

    company.account = nil
    assert_no_queries { company.account = nil }
    account = Account.find(2)
    assert_queries { company.account = account }

    assert_no_queries { Firm.new.account = account }
  end

  def test_has_one_assignment_dont_trigger_save_on_change_of_same_object
    pirate = Pirate.create!(catchphrase: "Don' botharrr talkin' like one, savvy?")
    ship = pirate.build_ship(name: "old name")
    ship.save!

    ship.name = "new name"
    assert ship.changed?
    assert_queries(1) do
      # One query for updating name, not triggering query for updating pirate_id
      pirate.ship = ship
    end

    assert_equal "new name", pirate.ship.reload.name
  end

  def test_has_one_assignment_triggers_save_on_change_on_replacing_object
    pirate = Pirate.create!(catchphrase: "Don' botharrr talkin' like one, savvy?")
    ship = pirate.build_ship(name: "old name")
    ship.save!

    new_ship = Ship.create(name: "new name")
    assert_queries(2) do
      # One query to nullify the old ship, one query to update the new ship
      pirate.ship = new_ship
    end

    assert_equal "new name", pirate.ship.reload.name
  end

  def test_has_one_autosave_with_primary_key_manually_set
    post = Post.create(id: 1234, title: "Some title", body: "Some content")
    author = Author.new(id: 33, name: "Hank Moody")

    author.post = post
    author.save
    author.reload

    assert_not_nil author.post
    assert_equal author.post, post
  end

  def test_has_one_loading_for_new_record
    post = Post.create!(author_id: 42, title: "foo", body: "bar")
    author = Author.new(id: 42)
    assert_equal post, author.post
  end

  def test_has_one_relationship_cannot_have_a_counter_cache
    assert_raise(ArgumentError) do
      Class.new(ActiveRecord::Base) do
        has_one :thing, counter_cache: true
      end
    end
  end

  def test_with_polymorphic_has_one_with_custom_columns_name
    post = Post.create! title: "foo", body: "bar"
    image = Image.create!

    post.main_image = image
    post.reload

    assert_equal image, post.main_image
  end

  test "dangerous association name raises ArgumentError" do
    [:errors, "errors", :save, "save"].each do |name|
      assert_raises(ArgumentError, "Association #{name} should not be allowed") do
        Class.new(ActiveRecord::Base) do
          has_one name
        end
      end
    end
  end

  class SpecialBook < ActiveRecord::Base
    self.table_name = "books"
    belongs_to :author, class_name: "SpecialAuthor"
    has_one :subscription, class_name: "SpecialSupscription", foreign_key: "subscriber_id"
  end

  class SpecialAuthor < ActiveRecord::Base
    self.table_name = "authors"
    has_one :book, class_name: "SpecialBook", foreign_key: "author_id"
  end

  class SpecialSupscription < ActiveRecord::Base
    self.table_name = "subscriptions"
    belongs_to :book, class_name: "SpecialBook"
  end

  def test_association_enum_works_properly
    author = SpecialAuthor.create!(name: "Test")
    book = SpecialBook.create!(status: "published")
    author.book = book

    refute_equal 0, SpecialAuthor.joins(:book).where(books: { status: "published" }).count
  end

  def test_association_enum_works_properly_with_nested_join
    author = SpecialAuthor.create!(name: "Test")
    book = SpecialBook.create!(status: "published")
    author.book = book

    where_clause = { books: { subscriptions: { subscriber_id: nil } } }
    assert_nothing_raised do
      SpecialAuthor.joins(book: :subscription).where.not(where_clause)
    end
  end

  class DestroyByParentBook < ActiveRecord::Base
    self.table_name = "books"
    belongs_to :author, class_name: "DestroyByParentAuthor"
    before_destroy :dont, unless: :destroyed_by_association

    def dont
      throw(:abort)
    end
  end

  class DestroyByParentAuthor < ActiveRecord::Base
    self.table_name = "authors"
    has_one :book, class_name: "DestroyByParentBook", foreign_key: "author_id", dependent: :destroy
  end

  test "destroyed_by_association set in child destroy callback on parent destroy" do
    author = DestroyByParentAuthor.create!(name: "Test")
    book = DestroyByParentBook.create!(author: author)

    author.destroy

    assert_not DestroyByParentBook.exists?(book.id)
  end

  test "destroyed_by_association set in child destroy callback on replace" do
    author = DestroyByParentAuthor.create!(name: "Test")
    book = DestroyByParentBook.create!(author: author)

    author.book = DestroyByParentBook.create!
    author.save!

    assert_not DestroyByParentBook.exists?(book.id)
  end
end
