# frozen_string_literal: true

require "isolation/abstract_unit"
require "rack/test"
require "base64"

module ApplicationTests
  class MailerPreviewsTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::Isolation
    include Rack::Test::Methods

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    test "/rails/mailers is accessible in development" do
      app("development")
      get "/rails/mailers"
      assert_equal 200, last_response.status
    end

    test "/rails/mailers is not accessible in production" do
      app("production")
      get "/rails/mailers"
      assert_equal 404, last_response.status
    end

    test "/rails/mailers is accessible with correct configuration" do
      add_to_config "config.action_mailer.show_previews = true"
      app("production")
      get "/rails/mailers", {}, { "REMOTE_ADDR" => "4.2.42.42" }
      assert_equal 200, last_response.status
    end

    test "/rails/mailers is not accessible with show_previews = false" do
      add_to_config "config.action_mailer.show_previews = false"
      app("development")
      get "/rails/mailers"
      assert_equal 404, last_response.status
    end

    test "/rails/mailers is accessible with globbing route present" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get '*foo', to: 'foo#index'
        end
      RUBY
      app("development")
      get "/rails/mailers"
      assert_equal 200, last_response.status
    end

    test "mailer previews are loaded from the default preview_path" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers"
      assert_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body
      assert_match '<li><a href="/rails/mailers/notifier/foo">foo</a></li>', last_response.body
    end

    test "mailer previews are loaded from a custom preview_path" do
      add_to_config "config.action_mailer.preview_path = '#{app_path}/lib/mailer_previews'"

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      app_file "lib/mailer_previews/notifier_preview.rb", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers"
      assert_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body
      assert_match '<li><a href="/rails/mailers/notifier/foo">foo</a></li>', last_response.body
    end

    test "mailer previews are reloaded across requests" do
      app("development")

      get "/rails/mailers"
      assert_no_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      get "/rails/mailers"
      assert_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body

      remove_file "test/mailers/previews/notifier_preview.rb"
      sleep(1)

      get "/rails/mailers"
      assert_no_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body
    end

    test "mailer preview actions are added and removed" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers"
      assert_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body
      assert_match '<li><a href="/rails/mailers/notifier/foo">foo</a></li>', last_response.body
      assert_no_match '<li><a href="/rails/mailers/notifier/bar">bar</a></li>', last_response.body

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end

          def bar
            mail to: "to@example.net"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      text_template "notifier/bar", <<-RUBY
        Goodbye, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end

          def bar
            Notifier.bar
          end
        end
      RUBY

      sleep(1)

      get "/rails/mailers"
      assert_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body
      assert_match '<li><a href="/rails/mailers/notifier/foo">foo</a></li>', last_response.body
      assert_match '<li><a href="/rails/mailers/notifier/bar">bar</a></li>', last_response.body

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      remove_file "app/views/notifier/bar.text.erb"

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      sleep(1)

      get "/rails/mailers"
      assert_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body
      assert_match '<li><a href="/rails/mailers/notifier/foo">foo</a></li>', last_response.body
      assert_no_match '<li><a href="/rails/mailers/notifier/bar">bar</a></li>', last_response.body
    end

    test "mailer previews are reloaded from a custom preview_path" do
      add_to_config "config.action_mailer.preview_path = '#{app_path}/lib/mailer_previews'"

      app("development")

      get "/rails/mailers"
      assert_no_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      app_file "lib/mailer_previews/notifier_preview.rb", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      get "/rails/mailers"
      assert_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body

      remove_file "lib/mailer_previews/notifier_preview.rb"
      sleep(1)

      get "/rails/mailers"
      assert_no_match '<h3><a href="/rails/mailers/notifier">Notifier</a></h3>', last_response.body
    end

    test "mailer preview not found" do
      app("development")
      get "/rails/mailers/notifier"
      assert last_response.not_found?
      assert_match "Mailer preview &#39;notifier&#39; not found", last_response.body
    end

    test "mailer preview email not found" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/bar"
      assert last_response.not_found?
      assert_match "Email &#39;bar&#39; not found in NotifierPreview", last_response.body
    end

    test "mailer preview NullMail" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            # does not call +mail+
          end
        end
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo"
      assert_match "You are trying to preview an email that does not have any content.", last_response.body
      assert_match "notifier#foo", last_response.body
    end

    test "mailer preview email part not found" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo?part=text%2Fhtml"
      assert last_response.not_found?
      assert_match "Email part &#39;text/html&#39; not found in NotifierPreview#foo", last_response.body
    end

    test "message header uses full display names" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "Ruby on Rails <core@rubyonrails.org>"

          def foo
            mail to: "Andrew White <andyw@pixeltrix.co.uk>",
                 cc: "David Heinemeier Hansson <david@heinemeierhansson.com>"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo"
      assert_equal 200, last_response.status
      assert_match "Ruby on Rails &lt;core@rubyonrails.org&gt;", last_response.body
      assert_match "Andrew White &lt;andyw@pixeltrix.co.uk&gt;", last_response.body
      assert_match "David Heinemeier Hansson &lt;david@heinemeierhansson.com&gt;", last_response.body
    end

    test "part menu selects correct option" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      html_template "notifier/foo", <<-RUBY
        <p>Hello, World!</p>
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo.html"
      assert_equal 200, last_response.status
      assert_match '<option selected value="?part=text%2Fhtml">View as HTML email</option>', last_response.body

      get "/rails/mailers/notifier/foo.txt"
      assert_equal 200, last_response.status
      assert_match '<option selected value="?part=text%2Fplain">View as plain-text email</option>', last_response.body
    end

    test "mailer previews create correct links when loaded on a subdirectory" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers", {}, { "SCRIPT_NAME" => "/my_app" }
      assert_match '<h3><a href="/my_app/rails/mailers/notifier">Notifier</a></h3>', last_response.body
      assert_match '<li><a href="/my_app/rails/mailers/notifier/foo">foo</a></li>', last_response.body
    end

    test "mailer preview receives query params" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo(name)
            @name = name
            mail to: "to@example.org"
          end
        end
      RUBY

      html_template "notifier/foo", <<-RUBY
        <p>Hello, <%= @name %>!</p>
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, <%= @name %>!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo(params[:name] || "World")
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo.txt"
      assert_equal 200, last_response.status
      assert_match '<iframe seamless name="messageBody" src="?part=text%2Fplain">', last_response.body
      assert_match '<option selected value="?part=text%2Fplain">', last_response.body
      assert_match '<option  value="?part=text%2Fhtml">', last_response.body

      get "/rails/mailers/notifier/foo?part=text%2Fplain"
      assert_equal 200, last_response.status
      assert_match %r[Hello, World!], last_response.body

      get "/rails/mailers/notifier/foo.html?name=Ruby"
      assert_equal 200, last_response.status
      assert_match '<iframe seamless name="messageBody" src="?name=Ruby&amp;part=text%2Fhtml">', last_response.body
      assert_match '<option selected value="?name=Ruby&amp;part=text%2Fhtml">', last_response.body
      assert_match '<option  value="?name=Ruby&amp;part=text%2Fplain">', last_response.body

      get "/rails/mailers/notifier/foo?name=Ruby&part=text%2Fhtml"
      assert_equal 200, last_response.status
      assert_match %r[<p>Hello, Ruby!</p>], last_response.body
    end

    test "plain text mailer preview with attachment" do
      image_file "pixel.png", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEWzIioca/JlAAAACklEQVQI12NgAAAAAgAB4iG8MwAAAABJRU5ErkJgggo="

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            attachments['pixel.png'] = File.read("#{app_path}/public/images/pixel.png", mode: 'rb')
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo"
      assert_equal 200, last_response.status
      assert_match %r[<iframe seamless name="messageBody"], last_response.body

      get "/rails/mailers/notifier/foo?part=text/plain"
      assert_equal 200, last_response.status
      assert_match %r[Hello, World!], last_response.body
    end

    test "multipart mailer preview with attachment" do
      image_file "pixel.png", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEWzIioca/JlAAAACklEQVQI12NgAAAAAgAB4iG8MwAAAABJRU5ErkJgggo="

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            attachments['pixel.png'] = File.read("#{app_path}/public/images/pixel.png", mode: 'rb')
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      html_template "notifier/foo", <<-RUBY
        <p>Hello, World!</p>
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo"
      assert_equal 200, last_response.status
      assert_match %r[<iframe seamless name="messageBody"], last_response.body

      get "/rails/mailers/notifier/foo?part=text/plain"
      assert_equal 200, last_response.status
      assert_match %r[Hello, World!], last_response.body

      get "/rails/mailers/notifier/foo?part=text/html"
      assert_equal 200, last_response.status
      assert_match %r[<p>Hello, World!</p>], last_response.body
    end

    test "multipart mailer preview with inline attachment" do
      image_file "pixel.png", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEWzIioca/JlAAAACklEQVQI12NgAAAAAgAB4iG8MwAAAABJRU5ErkJgggo="

      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            attachments['pixel.png'] = File.read("#{app_path}/public/images/pixel.png", mode: 'rb')
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      html_template "notifier/foo", <<-RUBY
        <p>Hello, World!</p>
        <%= image_tag attachments['pixel.png'].url %>
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo"
      assert_equal 200, last_response.status
      assert_match %r[<iframe seamless name="messageBody"], last_response.body

      get "/rails/mailers/notifier/foo?part=text/plain"
      assert_equal 200, last_response.status
      assert_match %r[Hello, World!], last_response.body

      get "/rails/mailers/notifier/foo?part=text/html"
      assert_equal 200, last_response.status
      assert_match %r[<p>Hello, World!</p>], last_response.body
      assert_match %r[src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEWzIioca/JlAAAACklEQVQI12NgAAAAAgAB4iG8MwAAAABJRU5ErkJgggo="], last_response.body
    end

    test "multipart mailer preview with attached email" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            message = ::Mail.new do
              from    'foo@example.com'
              to      'bar@example.com'
              subject 'Important Message'

              text_part do
                body 'Goodbye, World!'
              end

              html_part do
                body '<p>Goodbye, World!</p>'
              end
            end

            attachments['message.eml'] = message.to_s
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
        Hello, World!
      RUBY

      html_template "notifier/foo", <<-RUBY
        <p>Hello, World!</p>
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo"
      assert_equal 200, last_response.status
      assert_match %r[<iframe seamless name="messageBody"], last_response.body

      get "/rails/mailers/notifier/foo?part=text/plain"
      assert_equal 200, last_response.status
      assert_match %r[Hello, World!], last_response.body

      get "/rails/mailers/notifier/foo?part=text/html"
      assert_equal 200, last_response.status
      assert_match %r[<p>Hello, World!</p>], last_response.body
    end

    test "multipart mailer preview with empty parts" do
      mailer "notifier", <<-RUBY
        class Notifier < ActionMailer::Base
          default from: "from@example.com"

          def foo
            mail to: "to@example.org"
          end
        end
      RUBY

      text_template "notifier/foo", <<-RUBY
      RUBY

      html_template "notifier/foo", <<-RUBY
      RUBY

      mailer_preview "notifier", <<-RUBY
        class NotifierPreview < ActionMailer::Preview
          def foo
            Notifier.foo
          end
        end
      RUBY

      app("development")

      get "/rails/mailers/notifier/foo?part=text/plain"
      assert_equal 200, last_response.status

      get "/rails/mailers/notifier/foo?part=text/html"
      assert_equal 200, last_response.status
    end

    private
      def build_app
        super
        app_file "config/routes.rb", "Rails.application.routes.draw do; end"
      end

      def mailer(name, contents)
        app_file("app/mailers/#{name}.rb", contents)
      end

      def mailer_preview(name, contents)
        app_file("test/mailers/previews/#{name}_preview.rb", contents)
      end

      def html_template(name, contents)
        app_file("app/views/#{name}.html.erb", contents)
      end

      def text_template(name, contents)
        app_file("app/views/#{name}.text.erb", contents)
      end

      def image_file(name, contents)
        app_file("public/images/#{name}", Base64.strict_decode64(contents), "wb")
      end
  end
end
