# frozen_string_literal: true

require "cases/helper"
require "models/owner"
require "models/pet"

class ReloadModelsTest < ActiveRecord::TestCase
  include ActiveSupport::Testing::Isolation

  fixtures :pets, :owners

  def test_has_one_with_reload
    pet = Pet.find_by_name("parrot")
    pet.owner = Owner.find_by_name("ashley")

    # Reload the class Owner, simulating auto-reloading of model classes in a
    # development environment. Note that meanwhile the class Pet is not
    # reloaded, simulating a class that is present in a plugin.
    Object.class_eval { remove_const :Owner }
    Kernel.load(File.expand_path("../models/owner.rb", __dir__))

    pet = Pet.find_by_name("parrot")
    pet.owner = Owner.find_by_name("ashley")
    assert_equal pet.owner, Owner.find_by_name("ashley")
  end
end unless in_memory_db?
