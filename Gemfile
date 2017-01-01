source 'https://rubygems.org'
ruby '2.4.0'

gem 'bundler'
gem 'jekyll'
gem 'rack-jekyll'
gem 'kramdown'
gem 'unicorn'

# Gems to generate RailsGuides HTML from MD
gem 'rake'
gem 'activesupport'
gem 'actionpack'
gem 'nokogiri'

# Monitoring tools
gem 'newrelic_rpm'

group :development do
  gem 'gtt-downloader'
end

group :development, :test do
  gem 'rb-readline'
  gem 'pry-byebug'
end

group :test do
  gem 'capybara'
  gem 'rspec'
  gem 'turnip'
  gem 'wraith'
end

group :kindle do
  gem 'kindlerb', '0.1.1'
end
