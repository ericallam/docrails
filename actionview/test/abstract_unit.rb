# frozen_string_literal: true

$:.unshift File.expand_path("lib", __dir__)
$:.unshift File.expand_path("fixtures/helpers", __dir__)
$:.unshift File.expand_path("fixtures/alternate_helpers", __dir__)

ENV["TMPDIR"] = File.expand_path("tmp", __dir__)

require "active_support/core_ext/kernel/reporting"

# These are the normal settings that will be set up by Railties
# TODO: Have these tests support other combinations of these values
silence_warnings do
  Encoding.default_internal = Encoding::UTF_8
  Encoding.default_external = Encoding::UTF_8
end

require "active_support/testing/autorun"
require "active_support/testing/method_call_assertions"
require "action_controller"
require "action_view"
require "action_view/testing/resolvers"
require "active_support/dependencies"
require "active_model"
require "active_record"

require "pp" # require 'pp' early to prevent hidden_methods from not picking up the pretty-print methods until too late

ActiveSupport::Dependencies.hook!

Thread.abort_on_exception = true

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

# Disable available locale checks to avoid warnings running the test suite.
I18n.enforce_available_locales = false

# Register danish language for testing
I18n.backend.store_translations "da", {}
I18n.backend.store_translations "pt-BR", {}
ORIGINAL_LOCALES = I18n.available_locales.map(&:to_s).sort

FIXTURE_LOAD_PATH = File.expand_path("fixtures", __dir__)

module RenderERBUtils
  def view
    @view ||= begin
      path = ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH)
      view_paths = ActionView::PathSet.new([path])
      ActionView::Base.new(view_paths)
    end
  end

  def render_erb(string)
    @virtual_path = nil

    template = ActionView::Template.new(
      string.strip,
      "test template",
      ActionView::Template::Handlers::ERB,
      {})

    template.render(self, {}).strip
  end
end

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

module ActionDispatch
  module SharedRoutes
    def before_setup
      @routes = SharedTestRoutes
      super
    end
  end

  # Hold off drawing routes until all the possible controller classes
  # have been loaded.
  module DrawOnce
    class << self
      attr_accessor :drew
    end
    self.drew = false

    def before_setup
      super
      return if DrawOnce.drew

      ActiveSupport::Deprecation.silence do
        SharedTestRoutes.draw do
          get ":controller(/:action)"
        end

        ActionDispatch::IntegrationTest.app.routes.draw do
          get ":controller(/:action)"
        end
      end

      DrawOnce.drew = true
    end
  end
end

class RoutedRackApp
  attr_reader :routes

  def initialize(routes, &blk)
    @routes = routes
    @stack = ActionDispatch::MiddlewareStack.new(&blk).build(@routes)
  end

  def call(env)
    @stack.call(env)
  end
end

class BasicController
  attr_accessor :request

  def config
    @config ||= ActiveSupport::InheritableOptions.new(ActionController::Base.config).tap do |config|
      # VIEW TODO: View tests should not require a controller
      public_dir = File.expand_path("fixtures/public", __dir__)
      config.assets_dir = public_dir
      config.javascripts_dir = "#{public_dir}/javascripts"
      config.stylesheets_dir = "#{public_dir}/stylesheets"
      config.assets          = ActiveSupport::InheritableOptions.new(prefix: "assets")
      config
    end
  end
end

class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  include ActionDispatch::SharedRoutes

  def self.build_app(routes = nil)
    RoutedRackApp.new(routes || ActionDispatch::Routing::RouteSet.new) do |middleware|
      middleware.use ActionDispatch::ShowExceptions, ActionDispatch::PublicExceptions.new("#{FIXTURE_LOAD_PATH}/public")
      middleware.use ActionDispatch::DebugExceptions
      middleware.use ActionDispatch::Callbacks
      middleware.use ActionDispatch::Cookies
      middleware.use ActionDispatch::Flash
      middleware.use Rack::Head
      yield(middleware) if block_given?
    end
  end

  self.app = build_app

  def with_routing(&block)
    temporary_routes = ActionDispatch::Routing::RouteSet.new
    old_app, self.class.app = self.class.app, self.class.build_app(temporary_routes)
    old_routes = SharedTestRoutes
    silence_warnings { Object.const_set(:SharedTestRoutes, temporary_routes) }

    yield temporary_routes
  ensure
    self.class.app = old_app
    silence_warnings { Object.const_set(:SharedTestRoutes, old_routes) }
  end
end

ActionView::RoutingUrlFor.include(ActionDispatch::Routing::UrlFor)

module ActionController
  class Base
    # This stub emulates the Railtie including the URL helpers from a Rails application
    include SharedTestRoutes.url_helpers
    include SharedTestRoutes.mounted_helpers

    self.view_paths = FIXTURE_LOAD_PATH

    def self.test_routes(&block)
      routes = ActionDispatch::Routing::RouteSet.new
      routes.draw(&block)
      include routes.url_helpers
    end
  end

  class TestCase
    include ActionDispatch::TestProcess
    include ActionDispatch::SharedRoutes
  end
end

module ActionView
  class TestCase
    # Must repeat the setup because AV::TestCase is a duplication
    # of AC::TestCase
    include ActionDispatch::SharedRoutes
  end
end

class Workshop
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_accessor :id

  def initialize(id)
    @id = id
  end

  def persisted?
    id.present?
  end

  def to_s
    id.to_s
  end
end

module ActionDispatch
  class DebugExceptions
    private
      remove_method :stderr_logger
      # Silence logger
      def stderr_logger
        nil
      end
  end
end

class ActiveSupport::TestCase
  include ActionDispatch::DrawOnce
  include ActiveSupport::Testing::MethodCallAssertions

  # Skips the current run on Rubinius using Minitest::Assertions#skip
  private def rubinius_skip(message = "")
    skip message if RUBY_ENGINE == "rbx"
  end
  # Skips the current run on JRuby using Minitest::Assertions#skip
  private def jruby_skip(message = "")
    skip message if defined?(JRUBY_VERSION)
  end
end
