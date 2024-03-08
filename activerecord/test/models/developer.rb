# frozen_string_literal: true

require "ostruct"

module DeveloperProjectsAssociationExtension2
  def find_least_recent
    order("id ASC").first
  end
end

class Developer < ActiveRecord::Base
  self.ignored_columns = %w(first_name last_name)

  has_and_belongs_to_many :projects do
    def find_most_recent
      order("id DESC").first
    end
  end

  belongs_to :mentor

  accepts_nested_attributes_for :projects

  has_and_belongs_to_many :shared_computers, class_name: "Computer"

  has_and_belongs_to_many :projects_extended_by_name,
      -> { extending(DeveloperProjectsAssociationExtension) },
      class_name: "Project",
      join_table: "developers_projects",
      association_foreign_key: "project_id"

  has_and_belongs_to_many :projects_extended_by_name_twice,
      -> { extending(DeveloperProjectsAssociationExtension, DeveloperProjectsAssociationExtension2) },
      class_name: "Project",
      join_table: "developers_projects",
      association_foreign_key: "project_id"

  has_and_belongs_to_many :projects_extended_by_name_and_block,
      -> { extending(DeveloperProjectsAssociationExtension) },
      class_name: "Project",
      join_table: "developers_projects",
      association_foreign_key: "project_id" do
        def find_least_recent
          order("id ASC").first
        end
      end

  has_and_belongs_to_many :special_projects, join_table: "developers_projects", association_foreign_key: "project_id"
  has_and_belongs_to_many :sym_special_projects,
                          join_table: :developers_projects,
                          association_foreign_key: "project_id",
                          class_name: "SpecialProject"

  has_many :audit_logs
  has_many :contracts
  has_many :firms, through: :contracts, source: :firm
  has_many :comments, ->(developer) { where(body: "I'm #{developer.name}") }
  has_many :ratings, through: :comments
  has_one :ship, dependent: :nullify

  belongs_to :firm
  has_many :contracted_projects, class_name: "Project"

  scope :jamises, -> { where(name: "Jamis") }

  validates_inclusion_of :salary, in: 50000..200000
  validates_length_of    :name, within: 3..20

  before_create do |developer|
    developer.audit_logs.build message: "Computer created"
  end

  attr_accessor :last_name
  define_attribute_method "last_name"

  def log=(message)
    audit_logs.build message: message
  end

  after_find :track_instance_count
  cattr_accessor :instance_count

  def track_instance_count
    self.class.instance_count ||= 0
    self.class.instance_count += 1
  end
  private :track_instance_count
end

class SubDeveloper < Developer
end

class SymbolIgnoredDeveloper < ActiveRecord::Base
  self.table_name = "developers"
  self.ignored_columns = [:first_name, :last_name]

  attr_accessor :last_name
  define_attribute_method "last_name"
end

class AuditLog < ActiveRecord::Base
  belongs_to :developer, validate: true
  belongs_to :unvalidated_developer, class_name: "Developer"
end

class DeveloperWithBeforeDestroyRaise < ActiveRecord::Base
  self.table_name = "developers"
  has_and_belongs_to_many :projects, join_table: "developers_projects", foreign_key: "developer_id"
  before_destroy :raise_if_projects_empty!

  def raise_if_projects_empty!
    raise if projects.empty?
  end
end

class DeveloperWithSelect < ActiveRecord::Base
  self.table_name = "developers"
  default_scope { select("name") }
end

class DeveloperWithIncludes < ActiveRecord::Base
  self.table_name = "developers"
  has_many :audit_logs, foreign_key: :developer_id
  default_scope { includes(:audit_logs) }
end

class DeveloperFilteredOnJoins < ActiveRecord::Base
  self.table_name = "developers"
  has_and_belongs_to_many :projects, -> { order("projects.id") }, foreign_key: "developer_id", join_table: "developers_projects"

  def self.default_scope
    joins(:projects).where(projects: { name: "Active Controller" })
  end
end

class DeveloperOrderedBySalary < ActiveRecord::Base
  self.table_name = "developers"
  default_scope { order("salary DESC") }

  scope :by_name, -> { order("name DESC") }
end

class DeveloperCalledDavid < ActiveRecord::Base
  self.table_name = "developers"
  default_scope { where("name = 'David'") }
end

class LazyLambdaDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = "developers"
  default_scope lambda { where(name: "David") }
end

class LazyBlockDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = "developers"
  default_scope { where(name: "David") }
end

class CallableDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = "developers"
  default_scope OpenStruct.new(call: where(name: "David"))
end

class ClassMethodDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = "developers"

  def self.default_scope
    where(name: "David")
  end
end

class ClassMethodReferencingScopeDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = "developers"
  scope :david, -> { where(name: "David") }

  def self.default_scope
    david
  end
end

class LazyBlockReferencingScopeDeveloperCalledDavid < ActiveRecord::Base
  self.table_name = "developers"
  scope :david, -> { where(name: "David") }
  default_scope { david }
end

class DeveloperCalledJamis < ActiveRecord::Base
  self.table_name = "developers"

  default_scope { where(name: "Jamis") }
  scope :poor, -> { where("salary < 150000") }
  scope :david, -> { where name: "David" }
  scope :david2, -> { unscoped.where name: "David" }
end

class PoorDeveloperCalledJamis < ActiveRecord::Base
  self.table_name = "developers"

  default_scope -> { where(name: "Jamis", salary: 50000) }
end

class InheritedPoorDeveloperCalledJamis < DeveloperCalledJamis
  self.table_name = "developers"

  default_scope -> { where(salary: 50000) }
end

class MultiplePoorDeveloperCalledJamis < ActiveRecord::Base
  self.table_name = "developers"

  default_scope -> { where(name: "Jamis") }
  default_scope -> { where(salary: 50000) }
end

module SalaryDefaultScope
  extend ActiveSupport::Concern

  included { default_scope { where(salary: 50000) } }
end

class ModuleIncludedPoorDeveloperCalledJamis < DeveloperCalledJamis
  self.table_name = "developers"

  include SalaryDefaultScope
end

class EagerDeveloperWithDefaultScope < ActiveRecord::Base
  self.table_name = "developers"
  has_and_belongs_to_many :projects, -> { order("projects.id") }, foreign_key: "developer_id", join_table: "developers_projects"

  default_scope { includes(:projects) }
end

class EagerDeveloperWithClassMethodDefaultScope < ActiveRecord::Base
  self.table_name = "developers"
  has_and_belongs_to_many :projects, -> { order("projects.id") }, foreign_key: "developer_id", join_table: "developers_projects"

  def self.default_scope
    includes(:projects)
  end
end

class EagerDeveloperWithLambdaDefaultScope < ActiveRecord::Base
  self.table_name = "developers"
  has_and_belongs_to_many :projects, -> { order("projects.id") }, foreign_key: "developer_id", join_table: "developers_projects"

  default_scope lambda { includes(:projects) }
end

class EagerDeveloperWithBlockDefaultScope < ActiveRecord::Base
  self.table_name = "developers"
  has_and_belongs_to_many :projects, -> { order("projects.id") }, foreign_key: "developer_id", join_table: "developers_projects"

  default_scope { includes(:projects) }
end

class EagerDeveloperWithCallableDefaultScope < ActiveRecord::Base
  self.table_name = "developers"
  has_and_belongs_to_many :projects, -> { order("projects.id") }, foreign_key: "developer_id", join_table: "developers_projects"

  default_scope OpenStruct.new(call: includes(:projects))
end

class ThreadsafeDeveloper < ActiveRecord::Base
  self.table_name = "developers"

  def self.default_scope
    Thread.current[:default_scope_delay].call
    limit(1)
  end
end

class CachedDeveloper < ActiveRecord::Base
  self.table_name = "developers"
  self.cache_timestamp_format = :number
end

class DeveloperWithIncorrectlyOrderedHasManyThrough < ActiveRecord::Base
  self.table_name = "developers"
  has_many :companies, through: :contracts
  has_many :contracts, foreign_key: :developer_id
end
