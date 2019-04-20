Ruby on Rails 3.1 リリースノート
===============================

Rails 3.1の注目ポイント

* ストリーミング
* 逆進可能なマイグレーション
* アセットパイプラリン
* jQueryがデフォルトのJavaScriptライブラリになった

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GithubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/3-1-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------

Rails 3.1へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 3までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 3.1にアップデートしてください。以下の注意点を参照してからアップデートしてください。

### Rails 3.1ではRuby 1.8.7以上が必要

Rails 3.1ではRuby 1.8.7以上が必須です。これより前のバージョンのRubyのサポートは公式に廃止されたため、速やかにRubyをアップグレードすべきです。Rails 3.1はRuby 1.9.2とも互換性があります。

TIP: Ruby 1.8.7のp248とp249には、Railsクラッシュの原因となるマーシャリングのバグがあります。なおRuby Enterprise Editionでは1.8.7-2010.02のリリースでこの問題が修正されました。現行のRuby 1.9のうち、Ruby 1.9.1はセグメンテーションフォールト（segfault）で完全にダウンするため利用できません。Railsをスムーズに動かすため、Ruby 1.9.xを使いたい場合は1.9.2をお使いください。

### Railsのアップグレード方法

以下の変更点は、アプリケーションをRail 3.1.x系の中で最新のRails 3.1.3にアップグレードする場合を想定しています。

#### Gemfile

`Gemfile`を以下のように変更します。

```ruby
gem 'rails', '= 3.1.3'
gem 'mysql2'

# 新しいアセットパイプラインで必要
group :assets do
  gem 'sass-rails',   "~> 3.1.5"
  gem 'coffee-rails', "~> 3.1.1"
  gem 'uglifier',     ">= 1.0.3"
end

# Rails 3.1ではjQueryがデフォルトのJavaScriptライブラリとなる
gem 'jquery-rails'
```

#### config/application.rb

* アセットパイプラインのために以下の追加が必要です。

    ```ruby
    config.assets.enabled = true
    config.assets.version = '1.0'
    ```

* アプリケーションで、リソースへのルーティングに"/assets"を使っている場合、必要に応じてプレフィックスを変更してアセットのコンフリクトを避けてください。

    ```ruby
    # デフォルトは'/assets'
    config.assets.prefix = '/asset-files'
    ```

#### config/environments/development.rb

* RJSの設定`config.action_view.debug_rjs = true`を削除します。

* アセットパイプラインを有効にする場合は以下を追加します。

    ```ruby
    # アセットを圧縮しない
    config.assets.compress = false

    # アセットを読み込む行を拡大する
    config.assets.debug = true
    ```

#### config/environments/production.rb

* 以下の変更のほとんどもアセットパイプライン用です。詳しくは[アセットパイプライン](asset_pipeline.html)ガイドを参照してください。

    ```ruby
    # JavaScriptsとCSSの圧縮
    config.assets.compress = true

    # プリコンパイル済みアセットがない場合はアセットパイプラインにフォールバックしない
    config.assets.compile = false

    # アセットURL用のダイジェストを生成する
    config.assets.digest = true

    # デフォルトはRails.root.join("public/assets")
    # config.assets.manifest = YOUR_PATH

    # 追加のアセットをプリコンパイルする（application.js、application.css、およびすべてのnon-JS/CSSは既に追加済み）
    # config.assets.precompile `= %w( search.js )


    # アプリへの全アクセスのSSL、Strict-Transport-Security、secure cookieを強制する
    # config.force_ssl = true
    ```

#### config/environments/test.rb

```ruby
# テストの静的アセットサーバーをCache-Controlで構成（パフォーマンス向上用）
config.serve_static_assets = true
config.static_cache_control = "public, max-age=3600"
```

#### config/initializers/wrap_parameters.rb

* パラメータをラップしてネスト済みハッシュにしたい場合は、以下の内容のファイルを追加します。新規アプリケーションでは今後これがデフォルトになります。

    ```ruby
    # このファイルを変更したら必ずサーバーをリスタートすること
    # このファイルに含まれるActionController::ParamsWrapperの設定は
    # デフォルトで有効になる

    # JSONパラメーターのラップを有効にする
    # 空配列に:formatを設定すると無効にできる
    ActiveSupport.on_load(:action_controller) do
      wrap_parameters :format => [:json]
    end

    # JSONのroot要素を無効にする（デフォルト）
    ActiveSupport.on_load(:active_record) do
      self.include_root_in_json = false
    end
    ```

#### ビューのアセットヘルパー参照から`:cache`と`:concat`オプションを削除する

* アセットパイプラインの`:cache`と`:concat`オプションは今後使われないので、このオプションをビューから削除します。

Rails 3.1アプリケーションを作成する
--------------------------------

```bash
# 以下を実行する前に'rails RubyGemをインストールしておくこと
$ rails new myapp
$ cd myapp
```

### gemに移行する

現在のRailsでは、アプリケーションのルートディレクトリに置かれる`Gemfile`を使って、アプリケーションの起動に必要なgemを指定します。この`Gemfile`は[Bundler](https://github.com/carlhuda/bundler)というgemによって処理され、依存関係のある必要なgemをすべてインストールします。依存するgemをそのアプリケーションの中にだけインストールして、OS環境にある既存のgemに影響を与えないようにすることもできます。

詳細情報: [Bundlerホームページ](https://bundler.io/)

### 最新のgemを使う

`Bundler`と`Gemfile`のおかげで、専用の`bundle`コマンド一発でRailsアプリケーションのgemを簡単に安定させることができます。Gitリポジトリから直接bundleしたい場合は`--edge`フラグを追加します。

```
$ rails new myapp --edge
```

Railsアプリケーションのリポジトリをローカルにチェックアウトしたものがあり、それを使ってアプリケーションを生成したい場合は、`--dev`フラグを追加します。

```
$ ruby /path/to/rails/railties/bin/rails new myapp --dev
```

Railsアーキテクチャの変更点
---------------------------

### アセットパイプライン

アセットパイプライン（Assets Pipeline）はRails 3.1の大きな変更点です。アセットパイプラインは、CSSやJavaScriptのコードを第一級市民として扱い、プラグインやエンジンの利用を含めて正式に編成できるようにします。

アセットパイプラインは[Sprockets](https://github.com/sstephenson/sprockets)によって強化されています。また、[アセットパイプライン](asset_pipeline.html)ガイドに解説があります。

### HTTPストリーミング

HTTPストリーミングもRails 3.1の変更点のひとつです。これにより、サーバーがレスポンス生成の途中でもスタイルシートやJavaScriptファイルをブラウザからダウンロードできるようになります。利用にはRuby 1.9.2の他に、Webサーバーでのサポートも必要ですが、よく使われているNginxとUnicornの組み合わせで利用可能です。

### デフォルトのJSライブラリがjQueryになった

Rails 3.1で同梱されるデフォルトのJavaScriptがjQueryになりました。Prototype.jsを使いたい場合は以下のように簡単に切り替えられます。

```bash
$ rails new myapp -j prototype
```

### Identity Map

Rails 3.1のActive RecordにIdentity Mapが搭載されました。Identity Mapは直前にインスタンス化された複数のレコードを保持し、次のアクセス時にそのレコードに関連付けられたオブジェクトを返します。Identity Mapはリクエストごとに作成され、リクエストの完了時に破棄されます。

Rails 3.1のIdentity Mapはデフォルトでオフになっています（訳注: Identity Mapはその後Rails 4.0で削除されました）。

Railties
--------

* jQueryが新たにデフォルトのJavaScriptライブラリになりました。

* jQueryやPrototype.jsは今後ベンダリングされません。代わりにjquery-rails gemやprototype-rails gemで提供されます。

* アプリケーションジェネレータで、任意の文字列を取れる`-j`オプションを使えるようになりました。"foo"を渡すと`Gemfile`に"foo-rails" gemが追加され、アプリケーションのJavaScriptマニフェストで"foo"と"foo_ujs"がrequireされます。現時点では"prototype-rails"と"jquery-rails"のみが存在し、それらのファイルはアセットパイプライン経由で提供されます。

* アプリやプラグインの生成時に`--skip-gemfile`や`--skip-bundle`を指定しない場合、`bundle install`を実行します。

* コントローラやリソースをジェネレータで生成すると、アセットのスタブが自動で作成されるようになりました（`--skip-assets`でオフにできます）。CoffeeScriptやSassのライブラリが利用可能な場合、生成されたスタブでCoffeeScriptやSassが使われます。

* scaffoldやアプリをRuby 1.9で生成すると、ハッシュのスタイルがRuby 1.9のスタイルになります。`--old-style-hash`を渡すと従来のハッシュスタイルで生成できます。

* scaffoldのコントローラジェネレータが、XMLフォーマットブロックに代えてJSONフォーマットブロックを生成するようになりました。

* コンソールでActive RecordログがSTDOUTにインライン出力されるようになりました。

* 設定に`config.force_ssl`が追加されました。これは`Rack::SSL`ミドルウェアを読み込んであらゆるリクエストを強制的にHTTPSプロトコルにします。

* Railsプラグインを生成する`rails plugin new`コマンドが追加されました。生成されるプラグインにはgemspec、テスト、テスト用ダミーアプリケーションが含まれます。

* `Rack::Etag`と`Rack::ConditionalGet`がデフォルトのミドルウェアスタックに追加されました。

* `Rack::Cache`がデフォルトのミドルウェアスタックに追加されます。

* エンジンでメジャーアップデートが行われました。任意のパスをマウントする、アセットの有効化、ジェネレータの実行などを含みます。

Action Pack
-----------

### Action Controller

* CSRFトークンの認証を照合できない場合にwarningが出力されるようになりました。

* 特定のコントローラで`force_ssl`を指定すると、そのコントローラからブラウザにHTTPSプロトコルによるデータ通信を強制できるようになりました。HTTPSを特定のアクションに限定する`:only`や`:except`も利用できます。

* （個人情報などの）重要な情報を含むクエリ文字列パラメータを`config.filter_parameters`で指定すると、そのリクエストパスをクエリのログから除外できるようになりました。

* `to_param`すると`nil`を返すURLパラメータは、クエリ文字列から削除されるようになりました。

* パラメータをラップしてnestedハッシュにする`ActionController::ParamsWrapper`が追加されました。かつ、新しいアプリのJSONリクエストではこの機能がデフォルトでオンになります。`config/initializers/wrap_parameters.rb`でカスタマイズできます。

* `config.action_controller.include_all_helpers`が追加されました。デフォルトでは、`ActionController::Base`で`helper :all`が適用されます（デフォルトですべてのヘルパーを含む）。`include_all_helpers`設定を`false`にすると、`application_helper`と、コントローラ名に対応するヘルパー（例: foo_controllerの場合はfoo_helper）だけが含まれます。

* `url_for`や名前付きURLヘルパーで`:subdomain`オプションや`:domain`オプションを指定できるようになりました。

* `Base.http_basic_authenticate_with`が追加されました。このクラスメソッドを1度呼び出すだけでシンプルなHTTP BASIC認証を行えます。

    ```ruby
    class PostsController < ApplicationController
      USER_NAME, PASSWORD = "dhh", "secret"

      before_filter :authenticate, :except => [ :index ]

      def index
        render :text => "ここは誰でも見える！"
      end

      def edit
        render :text => "ここはパスワードを知らないと見えない"
      end

      private
        def authenticate
          authenticate_or_request_with_http_basic do |user_name, password|
            user_name == USER_NAME && password == PASSWORD
          end
        end
    end
    ```

    上のコードは以下のように書けます。

    ```ruby
    class PostsController < ApplicationController
      http_basic_authenticate_with :name => "dhh", :password => "secret", :except => :index

      def index
        render :text => "ここは誰でも見える！"
      end

      def edit
        render :text => "ここはパスワードを知らないと見えない"
      end
    end
    ```

* ストリーミングのサポートが追加されました。有効にするには以下のようにします。

    ```ruby
    class PostsController < ActionController::Base
      stream
    end
    ```

    `:only`や`:except`を用いてストリーミングを特定のアクションに限定できます。詳しくは[`ActionController::Streaming`](http://api.rubyonrails.org/v3.1.0/classes/ActionController/Streaming.html)を参照してください。

* ルーティングの`redirect`メソッドが、対象URLの一部のみを変更するオプションハッシュを1つ受け取ることも、呼び出しに応答できるオブジェクト（リダイレクトで再利用できる）を1つ受け取ることもできるようになりました。

### Action Dispatch

* `config.action_dispatch.x_sendfile_header`がデフォルトで`nil`になりました。なおこの設定は`config/environments/production.rb`にはデフォルトで値が設定されません。

* `config.action_dispatch.x_sendfile_header` now defaults to `nil` and `config/environments/production.rb` doesn't set any particular value for it. This allows servers to set it through `X-Sendfile-Type`.

* `ActionDispatch::MiddlewareStack` now uses composition over inheritance and is no longer an array.

* Added `ActionDispatch::Request.ignore_accept_header` to ignore accept headers.

* Added `Rack::Cache` to the default stack.

* Moved etag responsibility from `ActionDispatch::Response` to the middleware stack.

* Rely on `Rack::Session` stores API for more compatibility across the Ruby world. This is backwards incompatible since `Rack::Session` expects `#get_session` to accept four arguments and requires `#destroy_session` instead of simply `#destroy`.

* Template lookup now searches further up in the inheritance chain.

### Action View

* Added an `:authenticity_token` option to `form_tag` for custom handling or to omit the token by passing `:authenticity_token => false`.

* Created `ActionView::Renderer` and specified an API for `ActionView::Context`.

* In place `SafeBuffer` mutation is prohibited in Rails 3.1.

* Added HTML5 `button_tag` helper.

* `file_field` automatically adds `:multipart => true` to the enclosing form.

* Added a convenience idiom to generate HTML5 data-* attributes in tag helpers from a `:data` hash of options:

    ```ruby
    tag("div", :data => {:name => 'Stephen', :city_state => %w(Chicago IL)})
    # => <div data-name="Stephen" data-city-state="[&quot;Chicago&quot;,&quot;IL&quot;]" />
    ```

Keys are dasherized. Values are JSON-encoded, except for strings and symbols.

* `csrf_meta_tag` is renamed to `csrf_meta_tags` and aliases `csrf_meta_tag` for backwards compatibility.

* The old template handler API is deprecated and the new API simply requires a template handler to respond to call.

* rhtml and rxml are finally removed as template handlers.

* `config.action_view.cache_template_loading` is brought back which allows to decide whether templates should be cached or not.

* The submit form helper does not generate an id "object_name_id" anymore.

* Allows `FormHelper#form_for` to specify the `:method` as a direct option instead of through the `:html` hash. `form_for(@post, remote: true, method: :delete)` instead of `form_for(@post, remote: true, html: { method: :delete })`.

* Provided `JavaScriptHelper#j()` as an alias for `JavaScriptHelper#escape_javascript()`. This supersedes the `Object#j()` method that the JSON gem adds within templates using the JavaScriptHelper.

* Allows AM/PM format in datetime selectors.

* `auto_link` has been removed from Rails and extracted into the [rails_autolink gem](https://github.com/tenderlove/rails_autolink)

Active Record
-------------

* Added a class method `pluralize_table_names` to singularize/pluralize table names of individual models. Previously this could only be set globally for all models through `ActiveRecord::Base.pluralize_table_names`.

    ```ruby
    class User < ActiveRecord::Base
      self.pluralize_table_names = false
    end
    ```

* Added block setting of attributes to singular associations. The block will get called after the instance is initialized.

    ```ruby
    class User < ActiveRecord::Base
      has_one :account
    end

    user.build_account{ |a| a.credit_limit = 100.0 }
    ```

* Added `ActiveRecord::Base.attribute_names` to return a list of attribute names. This will return an empty array if the model is abstract or the table does not exist.

* CSV Fixtures are deprecated and support will be removed in Rails 3.2.0.

* `ActiveRecord#new`, `ActiveRecord#create` and `ActiveRecord#update_attributes` all accept a second hash as an option that allows you to specify which role to consider when assigning attributes. This is built on top of Active Model's new mass assignment capabilities:

    ```ruby
    class Post < ActiveRecord::Base
      attr_accessible :title
      attr_accessible :title, :published_at, :as => :admin
    end

    Post.new(params[:post], :as => :admin)
    ```

* `default_scope` can now take a block, lambda, or any other object which responds to call for lazy evaluation.

* Default scopes are now evaluated at the latest possible moment, to avoid problems where scopes would be created which would implicitly contain the default scope, which would then be impossible to get rid of via Model.unscoped.

* PostgreSQL adapter only supports PostgreSQL version 8.2 and higher.

* `ConnectionManagement` middleware is changed to clean up the connection pool after the rack body has been flushed.

* Added an `update_column` method on Active Record. This new method updates a given attribute on an object, skipping validations and callbacks. It is recommended to use `update_attributes` or `update_attribute` unless you are sure you do not want to execute any callback, including the modification of the `updated_at` column. It should not be called on new records.

* Associations with a `:through` option can now use any association as the through or source association, including other associations which have a `:through` option and `has_and_belongs_to_many` associations.

* The configuration for the current database connection is now accessible via `ActiveRecord::Base.connection_config`.

* limits and offsets are removed from COUNT queries unless both are supplied.

    ```ruby
    People.limit(1).count           # => 'SELECT COUNT(*) FROM people'
    People.offset(1).count          # => 'SELECT COUNT(*) FROM people'
    People.limit(1).offset(1).count # => 'SELECT COUNT(*) FROM people LIMIT 1 OFFSET 1'
    ```

* `ActiveRecord::Associations::AssociationProxy` has been split. There is now an `Association` class (and subclasses) which are responsible for operating on associations, and then a separate, thin wrapper called `CollectionProxy`, which proxies collection associations. This prevents namespace pollution, separates concerns, and will allow further refactorings.

* Singular associations (`has_one`, `belongs_to`) no longer have a proxy and simply returns the associated record or `nil`. This means that you should not use undocumented methods such as `bob.mother.create` - use `bob.create_mother` instead.

* Support the `:dependent` option on `has_many :through` associations. For historical and practical reasons, `:delete_all` is the default deletion strategy employed by `association.delete(*records)`, despite the fact that the default strategy is `:nullify` for regular has_many. Also, this only works at all if the source reflection is a belongs_to. For other situations, you should directly modify the through association.

* The behavior of `association.destroy` for `has_and_belongs_to_many` and `has_many :through` is changed. From now on, 'destroy' or 'delete' on an association will be taken to mean 'get rid of the link', not (necessarily) 'get rid of the associated records'.

* Previously, `has_and_belongs_to_many.destroy(*records)` would destroy the records themselves. It would not delete any records in the join table. Now, it deletes the records in the join table.

* Previously, `has_many_through.destroy(*records)` would destroy the records themselves, and the records in the join table. [Note: This has not always been the case; previous version of Rails only deleted the records themselves.] Now, it destroys only the records in the join table.

* Note that this change is backwards-incompatible to an extent, but there is unfortunately no way to 'deprecate' it before changing it. The change is being made in order to have consistency as to the meaning of 'destroy' or 'delete' across the different types of associations. If you wish to destroy the records themselves, you can do `records.association.each(&:destroy)`.

* Add `:bulk => true` option to `change_table` to make all the schema changes defined in a block using a single ALTER statement.

    ```ruby
    change_table(:users, :bulk => true) do |t|
      t.string :company_name
      t.change :birthdate, :datetime
    end
    ```

* Removed support for accessing attributes on a `has_and_belongs_to_many` join table. `has_many :through` needs to be used.

* Added a `create_association!` method for `has_one` and `belongs_to` associations.

* Migrations are now reversible, meaning that Rails will figure out how to reverse your migrations. To use reversible migrations, just define the `change` method.

    ```ruby
    class MyMigration < ActiveRecord::Migration
      def change
        create_table(:horses) do |t|
          t.column :content, :text
          t.column :remind_at, :datetime
        end
      end
    end
    ```

* Some things cannot be automatically reversed for you. If you know how to reverse those things, you should define `up` and `down` in your migration. If you define something in change that cannot be reversed, an `IrreversibleMigration` exception will be raised when going down.

* Migrations now use instance methods rather than class methods:

    ```ruby
    class FooMigration < ActiveRecord::Migration
      def up # Not self.up
        ...
      end
    end
    ```

* Migration files generated from model and constructive migration generators (for example, add_name_to_users) use the reversible migration's `change` method instead of the ordinary `up` and `down` methods.

* Removed support for interpolating string SQL conditions on associations. Instead, a proc should be used.

    ```ruby
    has_many :things, :conditions => 'foo = #{bar}'          # before
    has_many :things, :conditions => proc { "foo = #{bar}" } # after
    ```

    Inside the proc, `self` is the object which is the owner of the association, unless you are eager loading the association, in which case `self` is the class which the association is within.

    You can have any "normal" conditions inside the proc, so the following will work too:

    ```ruby
    has_many :things, :conditions => proc { ["foo = ?", bar] }
    ```

* Previously `:insert_sql` and `:delete_sql` on `has_and_belongs_to_many` association allowed you to call 'record' to get the record being inserted or deleted. This is now passed as an argument to the proc.

* Added `ActiveRecord::Base#has_secure_password` (via `ActiveModel::SecurePassword`) to encapsulate dead-simple password usage with BCrypt encryption and salting.

    ```ruby
    # Schema: User(name:string, password_digest:string, password_salt:string)
    class User < ActiveRecord::Base
      has_secure_password
    end
    ```

* When a model is generated `add_index` is added by default for `belongs_to` or `references` columns.

* Setting the id of a `belongs_to` object will update the reference to the object.

* `ActiveRecord::Base#dup` and `ActiveRecord::Base#clone` semantics have changed to closer match normal Ruby dup and clone semantics.

* Calling `ActiveRecord::Base#clone` will result in a shallow copy of the record, including copying the frozen state. No callbacks will be called.

* Calling `ActiveRecord::Base#dup` will duplicate the record, including calling after initialize hooks. Frozen state will not be copied, and all associations will be cleared. A duped record will return `true` for `new_record?`, have a `nil` id field, and is saveable.

* The query cache now works with prepared statements. No changes in the applications are required.

Active Model
------------

* `attr_accessible` accepts an option `:as` to specify a role.

* `InclusionValidator`, `ExclusionValidator`, and `FormatValidator` now accepts an option which can be a proc, a lambda, or anything that respond to `call`. This option will be called with the current record as an argument and returns an object which respond to `include?` for `InclusionValidator` and `ExclusionValidator`, and returns a regular expression object for `FormatValidator`.

* Added `ActiveModel::SecurePassword` to encapsulate dead-simple password usage with BCrypt encryption and salting.

* `ActiveModel::AttributeMethods` allows attributes to be defined on demand.

* Added support for selectively enabling and disabling observers.

* Alternate `I18n` namespace lookup is no longer supported.

Active Resource
---------------

* The default format has been changed to JSON for all requests. If you want to continue to use XML you will need to set `self.format = :xml` in the class. For example,

    ```ruby
    class User < ActiveResource::Base
      self.format = :xml
    end
    ```

Active Support
--------------

* `ActiveSupport::Dependencies`で既存の定数が`load_missing_constant`にある場合に`NameError`をraiseするようになりました。

* レポート用メソッド`Kernel#quietly`が新たに追加されました。これは`STDOUT`と`STDERR`を両方とも抑制します。

* `String#inquiry`が追加されました。これは文字列を`StringInquirer`オブジェクトに変換するのに便利です。

* `Object#in?`が追加されました。これはオブジェクトが別のオブジェクトに含まれているかどうかをテストします。

* `LocalCache`ストラテジーが、無名クラスではなくミドルウェアに実在するクラスになりました。

* `ActiveSupport::Dependencies::ClassCache`クラスが導入されました。再読み込み可能なクラスへの参照がこのクラスに保持されます。

* `ActiveSupport::Dependencies::Reference`がリファクタリングされ、新しい`ClassCache`を直接利用するようになりました。

* `Range#cover?`がRuby 1.8の`Range#include?`のエイリアスとしてバックポートされました。

* Date/DateTime/Timeに`weeks_ago`と`prev_week`が追加されました。

* `before_remove_const`コールバックが`ActiveSupport::Dependencies.remove_unloadable_constants!`に追加されました。

非推奨化:

* `ActiveSupport::SecureRandom`が非推奨化されました。今後はRuby標準ライブラリの`SecureRandom`が推奨されます。

クレジット表記
-------

Railsを頑丈かつ安定したフレームワークにするために多大な時間を費やしてくださった多くの開発者については、[Railsコントリビューターの完全なリスト](http://contributors.rubyonrails.org/)を参照してください。これらの方々全員に敬意を表明いたします。

Rails 3.1リリースノートの編集は[Vijay Dev](https://github.com/vijaydev)が担当しました。