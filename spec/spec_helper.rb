require 'rack/file'
require 'capybara/rspec'
require 'turnip'
require 'turnip/capybara'

Dir.glob("spec/**/*steps.rb") { |f| load f, true }
Dir.glob("spec/support/**/*.rb") { |f| load f, true }

RSpec.configure do |config|
  config.color = true
end

Capybara.app = Rack::File.new(File.expand_path('../../guides/output', __FILE__))
