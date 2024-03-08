# frozen_string_literal: true

require "isolation/abstract_unit"
require "rack/test"

module ApplicationTests
  class MiddlewareSessionTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::Isolation
    include Rack::Test::Methods

    def setup
      build_app
      FileUtils.rm_rf "#{app_path}/config/environments"
    end

    def teardown
      teardown_app
    end

    def app
      @app ||= Rails.application
    end

    test "config.force_ssl sets cookie to secure only by default" do
      add_to_config "config.force_ssl = true"
      require "#{app_path}/config/environment"
      assert app.config.session_options[:secure], "Expected session to be marked as secure"
    end

    test "config.force_ssl doesn't set cookie to secure only when changed from default" do
      add_to_config "config.force_ssl = true"
      add_to_config "config.ssl_options = { secure_cookies: false }"
      require "#{app_path}/config/environment"
      assert !app.config.session_options[:secure]
    end

    test "session is not loaded if it's not used" do
      make_basic_app

      class ::OmgController < ActionController::Base
        def index
          if params[:flash]
            flash[:notice] = "notice"
          end

          head :ok
        end
      end

      get "/?flash=true"
      get "/"

      assert last_request.env["HTTP_COOKIE"]
      assert !last_response.headers["Set-Cookie"]
    end

    test "session is empty and isn't saved on unverified request when using :null_session protect method" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get  ':controller(/:action)'
          post ':controller(/:action)'
        end
      RUBY

      controller :foo, <<-RUBY
        class FooController < ActionController::Base
          protect_from_forgery with: :null_session

          def write_session
            session[:foo] = 1
            head :ok
          end

          def read_session
            render plain: session[:foo].inspect
          end
        end
      RUBY

      add_to_config <<-RUBY
        config.action_controller.allow_forgery_protection = true
      RUBY

      require "#{app_path}/config/environment"

      get "/foo/write_session"
      get "/foo/read_session"
      assert_equal "1", last_response.body

      post "/foo/read_session"               # Read session using POST request without CSRF token
      assert_equal "nil", last_response.body # Stored value shouldn't be accessible

      post "/foo/write_session" # Write session using POST request without CSRF token
      get "/foo/read_session"   # Session shouldn't be changed
      assert_equal "1", last_response.body
    end

    test "cookie jar is empty and isn't saved on unverified request when using :null_session protect method" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get  ':controller(/:action)'
          post ':controller(/:action)'
        end
      RUBY

      controller :foo, <<-RUBY
        class FooController < ActionController::Base
          protect_from_forgery with: :null_session

          def write_cookie
            cookies[:foo] = '1'
            head :ok
          end

          def read_cookie
            render plain: cookies[:foo].inspect
          end
        end
      RUBY

      add_to_config <<-RUBY
        config.action_controller.allow_forgery_protection = true
      RUBY

      require "#{app_path}/config/environment"

      get "/foo/write_cookie"
      get "/foo/read_cookie"
      assert_equal '"1"', last_response.body

      post "/foo/read_cookie"                # Read cookie using POST request without CSRF token
      assert_equal "nil", last_response.body # Stored value shouldn't be accessible

      post "/foo/write_cookie" # Write cookie using POST request without CSRF token
      get "/foo/read_cookie"   # Cookie shouldn't be changed
      assert_equal '"1"', last_response.body
    end

    test "session using encrypted cookie store" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get ':controller(/:action)'
        end
      RUBY

      controller :foo, <<-RUBY
        class FooController < ActionController::Base
          def write_session
            session[:foo] = 1
            head :ok
          end

          def read_session
            render plain: session[:foo]
          end

          def read_encrypted_cookie
            render plain: cookies.encrypted[:_myapp_session]['foo']
          end

          def read_raw_cookie
            render plain: cookies[:_myapp_session]
          end
        end
      RUBY

      add_to_config <<-RUBY
        # Enable AEAD cookies
        config.action_dispatch.use_authenticated_cookie_encryption = true
      RUBY

      require "#{app_path}/config/environment"

      get "/foo/write_session"
      get "/foo/read_session"
      assert_equal "1", last_response.body

      get "/foo/read_encrypted_cookie"
      assert_equal "1", last_response.body

      cipher = "aes-256-gcm"
      secret = app.key_generator.generate_key("authenticated encrypted cookie")
      encryptor = ActiveSupport::MessageEncryptor.new(secret[0, ActiveSupport::MessageEncryptor.key_len(cipher)], cipher: cipher)

      get "/foo/read_raw_cookie"
      assert_equal 1, encryptor.decrypt_and_verify(last_response.body)["foo"]
    end

    test "session upgrading signature to encryption cookie store works the same way as encrypted cookie store" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get ':controller(/:action)'
        end
      RUBY

      controller :foo, <<-RUBY
        class FooController < ActionController::Base
          def write_session
            session[:foo] = 1
            head :ok
          end

          def read_session
            render plain: session[:foo]
          end

          def read_encrypted_cookie
            render plain: cookies.encrypted[:_myapp_session]['foo']
          end

          def read_raw_cookie
            render plain: cookies[:_myapp_session]
          end
        end
      RUBY

      add_to_config <<-RUBY
        secrets.secret_token = "3b7cd727ee24e8444053437c36cc66c4"

        # Enable AEAD cookies
        config.action_dispatch.use_authenticated_cookie_encryption = true
      RUBY

      require "#{app_path}/config/environment"

      get "/foo/write_session"
      get "/foo/read_session"
      assert_equal "1", last_response.body

      get "/foo/read_encrypted_cookie"
      assert_equal "1", last_response.body

      cipher = "aes-256-gcm"
      secret = app.key_generator.generate_key("authenticated encrypted cookie")
      encryptor = ActiveSupport::MessageEncryptor.new(secret[0, ActiveSupport::MessageEncryptor.key_len(cipher)], cipher: cipher)

      get "/foo/read_raw_cookie"
      assert_equal 1, encryptor.decrypt_and_verify(last_response.body)["foo"]
    end

    test "session upgrading signature to encryption cookie store upgrades session to encrypted mode" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get ':controller(/:action)'
        end
      RUBY

      controller :foo, <<-RUBY
        class FooController < ActionController::Base
          def write_raw_session
            # {"session_id"=>"1965d95720fffc123941bdfb7d2e6870", "foo"=>1}
            cookies[:_myapp_session] = "BAh7B0kiD3Nlc3Npb25faWQGOgZFRkkiJTE5NjVkOTU3MjBmZmZjMTIzOTQxYmRmYjdkMmU2ODcwBjsAVEkiCGZvbwY7AEZpBg==--315fb9931921a87ae7421aec96382f0294119749"
            head :ok
          end

          def write_session
            session[:foo] = session[:foo] + 1
            head :ok
          end

          def read_session
            render plain: session[:foo]
          end

          def read_encrypted_cookie
            render plain: cookies.encrypted[:_myapp_session]['foo']
          end

          def read_raw_cookie
            render plain: cookies[:_myapp_session]
          end
        end
      RUBY

      add_to_config <<-RUBY
        secrets.secret_token = "3b7cd727ee24e8444053437c36cc66c4"

        # Enable AEAD cookies
        config.action_dispatch.use_authenticated_cookie_encryption = true
      RUBY

      require "#{app_path}/config/environment"

      get "/foo/write_raw_session"
      get "/foo/read_session"
      assert_equal "1", last_response.body

      get "/foo/write_session"
      get "/foo/read_session"
      assert_equal "2", last_response.body

      get "/foo/read_encrypted_cookie"
      assert_equal "2", last_response.body

      cipher = "aes-256-gcm"
      secret = app.key_generator.generate_key("authenticated encrypted cookie")
      encryptor = ActiveSupport::MessageEncryptor.new(secret[0, ActiveSupport::MessageEncryptor.key_len(cipher)], cipher: cipher)

      get "/foo/read_raw_cookie"
      assert_equal 2, encryptor.decrypt_and_verify(last_response.body)["foo"]
    end

    test "session upgrading from AES-CBC-HMAC encryption to AES-GCM encryption" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get ':controller(/:action)'
        end
      RUBY

      controller :foo, <<-RUBY
        class FooController < ActionController::Base
          def write_raw_session
            # AES-256-CBC with SHA1 HMAC
            # {"session_id"=>"1965d95720fffc123941bdfb7d2e6870", "foo"=>1}
            cookies[:_myapp_session] = "TlgrdS85aUpDd1R2cDlPWlR6K0FJeGExckwySjZ2Z0pkR3d2QnRObGxZT25aalJWYWVvbFVLcHF4d0VQVDdSaFF2QjFPbG9MVjJzeWp3YjcyRUlKUUU2ZlR4bXlSNG9ZUkJPRUtld0E3dVU9LS0xNDZXbGpRZ3NjdW43N2haUEZJSUNRPT0=--3639b5ce54c09495cfeaae928cd5634e0c4b2e96"
            head :ok
          end

          def write_session
            session[:foo] = session[:foo] + 1
            head :ok
          end

          def read_session
            render plain: session[:foo]
          end

          def read_encrypted_cookie
            render plain: cookies.encrypted[:_myapp_session]['foo']
          end

          def read_raw_cookie
            render plain: cookies[:_myapp_session]
          end
        end
      RUBY

      add_to_config <<-RUBY
        # Use a static key
        Rails.application.credentials.secret_key_base = "known key base"

        # Enable AEAD cookies
        config.action_dispatch.use_authenticated_cookie_encryption = true
      RUBY

      begin
        old_rails_env, ENV["RAILS_ENV"] = ENV["RAILS_ENV"], "production"

        require "#{app_path}/config/environment"

        get "/foo/write_raw_session"
        get "/foo/read_session"
        assert_equal "1", last_response.body

        get "/foo/write_session"
        get "/foo/read_session"
        assert_equal "2", last_response.body

        get "/foo/read_encrypted_cookie"
        assert_equal "2", last_response.body

        cipher = "aes-256-gcm"
        secret = app.key_generator.generate_key("authenticated encrypted cookie")
        encryptor = ActiveSupport::MessageEncryptor.new(secret[0, ActiveSupport::MessageEncryptor.key_len(cipher)], cipher: cipher)

        get "/foo/read_raw_cookie"
        assert_equal 2, encryptor.decrypt_and_verify(last_response.body)["foo"]
      ensure
        ENV["RAILS_ENV"] = old_rails_env
      end
    end

    test "session upgrading legacy signed cookies to new signed cookies" do
      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get ':controller(/:action)'
        end
      RUBY

      controller :foo, <<-RUBY
        class FooController < ActionController::Base
          def write_raw_session
            # {"session_id"=>"1965d95720fffc123941bdfb7d2e6870", "foo"=>1}
            cookies[:_myapp_session] = "BAh7B0kiD3Nlc3Npb25faWQGOgZFRkkiJTE5NjVkOTU3MjBmZmZjMTIzOTQxYmRmYjdkMmU2ODcwBjsAVEkiCGZvbwY7AEZpBg==--315fb9931921a87ae7421aec96382f0294119749"
            head :ok
          end

          def write_session
            session[:foo] = session[:foo] + 1
            head :ok
          end

          def read_session
            render plain: session[:foo]
          end

          def read_signed_cookie
            render plain: cookies.signed[:_myapp_session]['foo']
          end

          def read_raw_cookie
            render plain: cookies[:_myapp_session]
          end
        end
      RUBY

      add_to_config <<-RUBY
        secrets.secret_token = "3b7cd727ee24e8444053437c36cc66c4"
        Rails.application.credentials.secret_key_base = nil
      RUBY

      begin
        old_rails_env, ENV["RAILS_ENV"] = ENV["RAILS_ENV"], "production"

        require "#{app_path}/config/environment"

        get "/foo/write_raw_session"
        get "/foo/read_session"
        assert_equal "1", last_response.body

        get "/foo/write_session"
        get "/foo/read_session"
        assert_equal "2", last_response.body

        get "/foo/read_signed_cookie"
        assert_equal "2", last_response.body

        verifier = ActiveSupport::MessageVerifier.new(app.secrets.secret_token)

        get "/foo/read_raw_cookie"
        assert_equal 2, verifier.verify(last_response.body)["foo"]
      ensure
        ENV["RAILS_ENV"] = old_rails_env
      end
    end

    test "calling reset_session on request does not trigger an error for API apps" do
      add_to_config "config.api_only = true"

      controller :test, <<-RUBY
        class TestController < ApplicationController
          def dump_flash
            request.reset_session
            render plain: 'It worked!'
          end
        end
      RUBY

      app_file "config/routes.rb", <<-RUBY
        Rails.application.routes.draw do
          get '/dump_flash' => "test#dump_flash"
        end
      RUBY

      require "#{app_path}/config/environment"

      get "/dump_flash"

      assert_equal 200, last_response.status
      assert_equal "It worked!", last_response.body

      assert_not_includes Rails.application.middleware, ActionDispatch::Flash
    end

    test "cookie_only is set to true even if user tries to overwrite it" do
      add_to_config "config.session_store :cookie_store, key: '_myapp_session', cookie_only: false"
      require "#{app_path}/config/environment"
      assert app.config.session_options[:cookie_only], "Expected cookie_only to be set to true"
    end
  end
end
