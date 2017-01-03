source 'https://rubygems.org'
ruby '2.4.0'

gem 'bundler'
gem 'jekyll'
gem 'rack-jekyll', '~> 0.5'
gem 'kramdown'
gem 'puma'

# Gems to generate RailsGuides HTML from MD
gem 'rake'
gem 'activesupport'
gem 'actionpack'
gem 'nokogiri'

# Monitoring tools
gem 'newrelic_rpm'

# Need latest json for using Ruby 2.4.0
gem 'json', '~> 2.0'

# SSL in Production
gem 'acme_challenge'
gem 'rack-rewrite', '~> 1.5.0'
gem 'rack-contrib', '~> 1.4'

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
