Ruby on Rails 3.2 リリースノート
===============================

Rails 3.2の注目ポイント

* developmentモードの高速化
* 新しいルーティングエンジン
* クエリの自動explain
* ログ出力へのタグ付け

本リリースノートでは、主要な変更についてのみ説明します。多数のバグ修正および変更点については、GithubのRailsリポジトリにある[コミットリスト](https://github.com/rails/rails/commits/3-2-stable)のchangelogを参照してください。

--------------------------------------------------------------------------------

Rails 3.2へのアップグレード
----------------------

既存のアプリケーションをアップグレードするのであれば、その前に質のよいテストカバレッジを用意するのはよい考えです。アプリケーションがRails 3.1までアップグレードされていない場合は先にそれを完了し、アプリケーションが正常に動作することを十分確認してからRails 3.2にアップデートしてください。以下の注意点を参照してからアップデートしてください。

### Rails 3.2ではRuby 1.8.7以上が必要

Rails 3.2ではRuby 1.8.7以上が必須です。これより前のバージョンのRubyのサポートは公式に廃止されたため、速やかにRubyをアップグレードすべきです。Rails 3.2はRuby 1.9.2とも互換性があります。

TIP: Ruby 1.8.7のp248とp249には、Railsクラッシュの原因となるマーシャリングのバグがあります。なおRuby Enterprise Editionでは1.8.7-2010.02のリリースでこの問題が修正されました。現行のRuby 1.9のうち、Ruby 1.9.1はセグメンテーションフォールト（segfault）で完全にダウンするため利用できません。Railsをスムーズに動かすため、Ruby 1.9.xを使いたい場合は1.9.2 または1.9.3をお使いください。

### Railsのアップグレード方法

* Gemfileを以下の依存関係に更新します。
    * `rails = 3.2.0`
    * `sass-rails ~> 3.2.3`
    * `coffee-rails ~> 3.2.1`
    * `uglifier >= 1.0.3`

* Rails 3.2では`vendor/plugins`が非推奨化されました（Rails 4.0で完全に廃止される予定です）。プラグインをgemに切り出してGemfileに追加することで、プラグインを置き換えられます。プラグインをgem化しないのであれば、プラグインを`lib/my_plugin/*`などに移動し、`config/initializers/my_plugin.rb`などの適切なイニシャライザを追加してください。

* Railsの設定項目で多数の変更が行われました。`config/environments/development.rb`で追加しておきたいであろう項目は以下のとおりです。

    ```ruby
    # Active Recordモデルのmass assignment保護で例外を発生する
    config.active_record.mass_assignment_sanitizer = :strict

    # クエリ送信時のクエリプランのログ出力をより詳細にする
    # （SQLite、MySQL、PostgreSQLで利用可能）
    config.active_record.auto_explain_threshold_in_seconds = 0.5
    ```

    `config/environments/test.rb`にも以下のように`mass_assignment_sanitizer`を追加する必要があります。

    ```ruby
    # Active Recordモデルのmass assignment保護で例外を発生する
    config.active_record.mass_assignment_sanitizer = :strict
    ```

### エンジンのアップグレード方法

`script/rails`のコメントより下の行にあるコードを以下に置き換えます。

```ruby
ENGINE_ROOT = File.expand_path('../..', __FILE__)
ENGINE_PATH = File.expand_path('../../lib/your_engine_name/engine', __FILE__)

require 'rails/all'
require 'rails/engine/commands'
```

Rails 3.2アプリケーションを作成する
--------------------------------

```bash
# 'rails' RubyGemがインストールされている状態で行うこと
$ rails new myapp
$ cd myapp
```

### gemのベンダリング（vendoring）

今回からRailsのアプリケーションルートディレクトリに`Gemfile`が置かれるようになりました。アプリケーション起動時に必要なgemは今後ここで決定されます。`Gemfile`の処理は[Bundler](https://github.com/carlhuda/bundler)というgemで行われます。今後はBundlerがすべての依存gemをインストールします。依存gemをアプリケーションディレクトリにローカルインストールして、システムのgem（OS環境にあるgem）に依存しないようにすることも可能です（訳注: Rails開発ではこの方法が主流です）。

詳細情報: [Bundlerホームページ](https://bundler.io/)

### 最新のgemを使う

`Bundler`と`Gemfile`のおかげで、専用の`bundle`コマンド一発でRailsアプリケーションのgemを簡単に安定させることができます。Gitリポジトリから直接bundleしたい場合は`--edge`フラグを追加します。

```
$ rails new myapp --edge
```

Railsアプリケーションのリポジトリをローカルにチェックアウトしたものがあり、それを使ってアプリケーションを生成したい場合は、`--dev`フラグを追加します。

```
$ ruby /path/to/rails/railties/bin/rails new m
```

主要な機能
--------------

### developmentモードやルーティングの高速化

Rails 3.2のdevelopmentモードが著しく高速になりました。[Active Reload](https://github.com/paneq/active_reload)からヒントを得て、ファイルが実際に変更された場合のみクラスを再読み込みするようになりました。アプリが大規模になればなるほど、劇的に高速化します。ルーティングの認識も、新しい[Journey](https://github.com/rails/journey)エンジンによって大きく高速化されました。

### クエリの自動explain

Rails 3.2では便利なクエリexplain機能が導入されました。explainは`ActiveRecord::Relation`の`explain`メソッドで定義され、Arelで生成されます。たとえば、`puts Person.active.limit(5).explain`のようなコードを実行すると、Arelで生成されるクエリでexplainが行われます。explainは、インデックス化が正しいかどうかをチェックしたり、最適化をさらに進めたりするのに役立ちます。

developmentモードでは、実行完了に1秒以上かかるクエリで**自動的に**explainが走るようになります。閾値はもちろん変更可能です。


### ログ出力へのタグ付け

マルチユーザーのアプリケーションやマルチアカウントのアプリケーションを実行する場合、誰が何を行ったかをログでフィルタできると非常に助かります。Active SupportのTaggedLogging機能はまさにこのためのものであり、ログ出力にサブドメインやリクエストidなど任意の項目を追加してアプリケーションのデバッグを支援します。

ドキュメント
-------------

Rails 3.2以降、iPad/iPhone/Mac/AndroidなどのKindleまたは無料のKindleリーダーアプリで本Railsガイド（英語版）を読めるようになりました。

Railties
--------

* 依存ファイル変更時にのみクラスを再読み込みすることで高速化されました。`config.reload_classes_only_on_change`を`false`に設定することでオフにできます。

* 新しいアプリケーションでは環境構築ファイルに`config.active_record.auto_explain_threshold_in_seconds`というフラグが置かれます。`development.rb`では値が`0.5`に設定され、`production.rb`ではコメントアウトされています。`test.rb`では特に記載はありません。

* `config.exceptions_app`が追加されました。これは例外発生時に`ShowException`ミドルウェアで呼び出される例外時のアプリケーションを設定します。デフォルトは`ActionDispatch::PublicExceptions.new(Rails.public_path)`です。

* `DebugExceptions`ミドルウェアが追加されました。ここには`ShowExceptions`ミドルウェアから切り出された機能を含みます。

* `rake routes`の実行結果にマウント中のエンジンのルーティングも表示されるようになりました。

* `config.railties_order`でrailtiesの読み込み順を以下のように変更できるようになりました。

    ```ruby
    config.railties_order = [Blog::Engine, :main_app, :all]
    ```

* scaffoldがコンテンツのない場合に「204 No Content for API requests」を返すようになりました。これでjQueryでscaffoldをすぐ使えるようになります。

* `Rails::Rack::Logger`ミドルウェアが更新され、`config.log_tags`で設定した任意のタグを`ActiveSupport::TaggedLogging`に適用するようになりました。これにより、サブドメインやリクエストidといったマルチユーザーのproductionアプリケーションで有用なデバッグ情報をログにタグ付けするのが簡単になります。

* `rails new`のデフォルトオプションを`~/.railsrc`で設定できるようになりました。`rails new`を実行するたびに利用するコマンドラインオプションをホームディレクトリの`.railsrc`設定ファイルで指定できます。

* `destroy`のエイリアス`d`が追加されました。これはエンジンでも利用できます。

* scaffoldジェネレータやモデルジェネレータのデフォルトの属性が`string`になりました。これにより、`rails g scaffold Post title body:text author`のように実行できます。

* caffoldジェネレータ/モデルジェネレータ/マイグレーションジェネレータで「index」や「uniq」を指定できるようになりました。例:

    ```ruby
    rails g scaffold Post title:string:index author:uniq price:decimal{7,2}
    ```

    上の前者は`title`と`author`でインデックスを作成し、後者はuniqueインデックスを作成します。「decimal」などの型ではカスタムオプションも指定できます。上の例では`price`でdecimalカラムの精度（全体の桁）を7、桁（小数点以下の桁）を2に指定しています。

* デフォルトのGemfileからturn gemが削除されました。

* 旧来の`rails generate plugin` プラグインジェネレータが削除されました。今後は`rails plugin new`をお使いください。

* 旧来の`config.paths.app.controller` APIが削除されました。今後は`config.paths["app/controller"]`をお使いください。

#### 非推奨

* `Rails::Plugin`が非推奨化され、Rails 4.0で削除されます。今後は`vendor/plugins`にプラグインを追加するのではなく、gemやbundlerでパスやgit dependencyを指定してください。

Action Mailer
-------------

* `mail`のバージョンが2.4.0にアップグレードされました。

* Rails 3.0で非推奨化されたAction Mailer APIが削除されました。

Action Pack
-----------

### Action Controller

* `ActionController::Base`のデフォルトモジュールが`ActiveSupport::Benchmarkable`になりました。これにより、以前のようにコントローラのコンテキストで`#benchmark`メソッドを利用できるようになりました。

* `caches_page`に`:gzip`オプションが追加されました。`page_cache_compression`を使ってこのオプションのデフォルト値をグローバルに設定できます。

* レイアウトの指定に`:only`条件や`:except`条件を用いてそれらの条件が失敗した場合にデフォルトのレイアウト（layouts/applicationなど）が使われるようになりました。

    ```ruby
    class CarsController
      layout 'single_car', :only => :show
    end
    ```

    上の例では、`:show`アクションの場合に`layouts/single_car`が使われ、それ以外のアクションでは`layouts/application`（`layouts/cars`がある場合はそちら）が使われます。

* `form_for`が変更され、`:as`オプションが指定されると`#{action}_#{as}`をCSSのクラスやidとして用いるようになりました。なお、従来は`#{as}_#{action}`でした。

* `attr_accessible`属性が設定されている場合に、Active Recordモデルの`ActionController::ParamsWrapper`で`attr_accessible`属性のみをラップするようになりました。設定されてない場合は、`attribute_names`クラスメソッドが返す属性のみをラップします。これにより、ネストした属性を`attr_accessible`に追加した場合のネスト属性のラップ方法が修正されます。

* コールバックが停止するたびに「Filter chain halted as コールバック名 rendered or redirected」がログに出力されるようになりました。

* `ActionDispatch::ShowExceptions`がリファクタリングされました。このコントローラは例外を表示するかどうかの選択を受け持ちます。コントローラで`show_detailed_exceptions?`を上書きすれば、リクエストのエラー時にデバッグ情報を返すべきかどうかを指定できます。

* レスポンスのbodyが空の場合にレスポンダが「204 No Content for API requests」を返すようになりました（新しいscaffoldと同様です）。

* `ActionController::TestCase`のcookieがリファクタリングされました。今後、テストケースでのcookieの代入には以下のように`cookies[]`をお使いください。


    ```ruby
    cookies[:email] = 'user@example.com'
    get :index
    assert_equal 'user@example.com', cookies[:email]
    ```

    cookieをクリアするには`clear`を使います。

    ```ruby
    cookies.clear
    get :index
    assert_nil cookies[:email]
    ```

    今後`HTTP_COOKIE`は出力されません。cookie jarはリクエスト間で保たれるため、テスト時に環境を人為的に操作する場合は、cookie jarの作成前に行う必要があります。
    
* `send_file`で`:type`が指定されていない場合にファイル拡張子からMIMEタイプを推測するようになりました。

* PDFやZIPなどのMIMEタイプが追加されました。

* `fresh_when/stale?`がオプションハッシュの代わりにレコードを1件取るようになりました。

* CSRFトークンが見当たらない場合のwarningログレベルが`:debug`から`:warn`に変更されました。

* アセットはリクエストプロトコルをデフォルトで使います。リクエストが利用できない場合はデフォルトで相対を使います。

#### 非推奨

* 親のレイアウトが明示的に設定されているコントローラでの暗黙のレイアウト探索が非推奨になりました。

    ```ruby
    class ApplicationController
      layout "application"
    end

    class PostsController < ApplicationController
    end
    ```

    上の例では、`PostsController`は今後postレイアウトを自動で探索しなくなります。自動探索が必要な場合は、`ApplicationController`の`layout "application"`を削除するか、`PostsController`で明示的にレイアウトを`nil`に設定してください。

* `ActionController::UnknownAction`が非推奨化されました。今後は`AbstractController::ActionNotFound`をお使いください。

* `ActionController::DoubleRenderError`が非推奨化されました。今後は`AbstractController::DoubleRenderError`をお使いください。

* アクションが見当たらない場合の`method_missing`が非推奨化されました。今後は`action_missing`をお使いください。

* `ActionController#rescue_action`、`ActionController#initialize_template_class`、`ActionController#assign_shortcuts`が非推奨化されました。

### Action Dispatch

* `ActionDispatch::Response`のデフォルト文字セットを設定する`config.action_dispatch.default_charset`が追加されました。

* `ActionDispatch::RequestId`ミドルウェアが追加されました。これはレスポンスで一意のX-Request-Idヘッダーを有効にして`ActionDispatch::Request#uuid`メソッドを使えるようにします。これにより、スタック内のエンドツーエンドでのリクエストの追跡や、Syslogのようにさまざまなログが混在しているログで個別のリクエストを特定するのが容易になります。

* `ShowExceptions`ミドルウェアで、アプリケーションが失敗した場合の例外レンダリングを受け持つ「例外アプリケーション」を指定できるようになりました。この例外アプリケーションは`ShowExceptions`の例外のコピー

* The `ShowExceptions` middleware now accepts an exceptions application that is responsible to render an exception when the application fails. The application is invoked with a copy of the exception in `env["action_dispatch.exception"]` and with the `PATH_INFO` rewritten to the status code.

* Allow rescue responses to be configured through a railtie as in `config.action_dispatch.rescue_responses`.

#### Deprecations

* Deprecated the ability to set a default charset at the controller level, use the new `config.action_dispatch.default_charset` instead.

### Action View

* Add `button_tag` support to `ActionView::Helpers::FormBuilder`. This support mimics the default behavior of `submit_tag`.

    ```erb
    <%= form_for @post do |f| %>
      <%= f.button %>
    <% end %>
    ```

* Date helpers accept a new option `:use_two_digit_numbers => true`, that renders select boxes for months and days with a leading zero without changing the respective values. For example, this is useful for displaying ISO 8601-style dates such as '2011-08-01'.

* You can provide a namespace for your form to ensure uniqueness of id attributes on form elements. The namespace attribute will be prefixed with underscore on the generated HTML id.

    ```erb
    <%= form_for(@offer, :namespace => 'namespace') do |f| %>
      <%= f.label :version, 'Version' %>:
      <%= f.text_field :version %>
    <% end %>
    ```

* Limit the number of options for `select_year` to 1000. Pass `:max_years_allowed` option to set your own limit.

* `content_tag_for` and `div_for` can now take a collection of records. It will also yield the record as the first argument if you set a receiving argument in your block. So instead of having to do this:

    ```ruby
    @items.each do |item|
      content_tag_for(:li, item) do
         Title: <%= item.title %>
      end
    end
    ```

    You can do this:

    ```ruby
    content_tag_for(:li, @items) do |item|
      Title: <%= item.title %>
    end
    ```

* Added `font_path` helper method that computes the path to a font asset in `public/fonts`.

#### Deprecations

* Passing formats or handlers to render :template and friends like `render :template => "foo.html.erb"` is deprecated. Instead, you can provide :handlers and :formats directly as options: ` render :template => "foo", :formats => [:html, :js], :handlers => :erb`.

### Sprockets

* Adds a configuration option `config.assets.logger` to control Sprockets logging. Set it to `false` to turn off logging and to `nil` to default to `Rails.logger`.

Active Record
-------------

* Boolean columns with 'on' and 'ON' values are type cast to true.

* When the `timestamps` method creates the `created_at` and `updated_at` columns, it makes them non-nullable by default.

* Implemented `ActiveRecord::Relation#explain`.

* Implements `AR::Base.silence_auto_explain` which allows the user to selectively disable automatic EXPLAINs within a block.

* Implements automatic EXPLAIN logging for slow queries. A new configuration parameter `config.active_record.auto_explain_threshold_in_seconds` determines what's to be considered a slow query. Setting that to nil disables this feature. Defaults are 0.5 in development mode, and nil in test and production modes. Rails 3.2 supports this feature in SQLite, MySQL (mysql2 adapter), and PostgreSQL.

* Added `ActiveRecord::Base.store` for declaring simple single-column key/value stores.

    ```ruby
    class User < ActiveRecord::Base
      store :settings, accessors: [ :color, :homepage ]
    end

    u = User.new(color: 'black', homepage: '37signals.com')
    u.color                          # Accessor stored attribute
    u.settings[:country] = 'Denmark' # Any attribute, even if not specified with an accessor
    ```

* Added ability to run migrations only for a given scope, which allows to run migrations only from one engine (for example to revert changes from an engine that need to be removed).

    ```
    rake db:migrate SCOPE=blog
    ```

* Migrations copied from engines are now scoped with engine's name, for example `01_create_posts.blog.rb`.

* Implemented `ActiveRecord::Relation#pluck` method that returns an array of column values directly from the underlying table. This also works with serialized attributes.

    ```ruby
    Client.where(:active => true).pluck(:id)
    # SELECT id from clients where active = 1
    ```

* Generated association methods are created within a separate module to allow overriding and composition. For a class named MyModel, the module is named `MyModel::GeneratedFeatureMethods`. It is included into the model class immediately after the `generated_attributes_methods` module defined in Active Model, so association methods override attribute methods of the same name.

* Add `ActiveRecord::Relation#uniq` for generating unique queries.

    ```ruby
    Client.select('DISTINCT name')
    ```

    ..can be written as:

    ```ruby
    Client.select(:name).uniq
    ```

    This also allows you to revert the uniqueness in a relation:

    ```ruby
    Client.select(:name).uniq.uniq(false)
    ```

* Support index sort order in SQLite, MySQL and PostgreSQL adapters.

* Allow the `:class_name` option for associations to take a symbol in addition to a string. This is to avoid confusing newbies, and to be consistent with the fact that other options like `:foreign_key` already allow a symbol or a string.

    ```ruby
    has_many :clients, :class_name => :Client # Note that the symbol need to be capitalized
    ```

* In development mode, `db:drop` also drops the test database in order to be symmetric with `db:create`.

* Case-insensitive uniqueness validation avoids calling LOWER in MySQL when the column already uses a case-insensitive collation.

* Transactional fixtures enlist all active database connections. You can test models on different connections without disabling transactional fixtures.

* Add `first_or_create`, `first_or_create!`, `first_or_initialize` methods to Active Record. This is a better approach over the old `find_or_create_by` dynamic methods because it's clearer which arguments are used to find the record and which are used to create it.

    ```ruby
    User.where(:first_name => "Scarlett").first_or_create!(:last_name => "Johansson")
    ```

* Added a `with_lock` method to Active Record objects, which starts a transaction, locks the object (pessimistically) and yields to the block. The method takes one (optional) parameter and passes it to `lock!`.

    This makes it possible to write the following:

    ```ruby
    class Order < ActiveRecord::Base
      def cancel!
        transaction do
          lock!
          # ... cancelling logic
        end
      end
    end
    ```

    as:

    ```ruby
    class Order < ActiveRecord::Base
      def cancel!
        with_lock do
          # ... cancelling logic
        end
      end
    end
    ```

### Deprecations

* Automatic closure of connections in threads is deprecated. For example the following code is deprecated:

    ```ruby
    Thread.new { Post.find(1) }.join
    ```

    It should be changed to close the database connection at the end of the thread:

    ```ruby
    Thread.new {
      Post.find(1)
      Post.connection.close
    }.join
    ```

    Only people who spawn threads in their application code need to worry about this change.

* The `set_table_name`, `set_inheritance_column`, `set_sequence_name`, `set_primary_key`, `set_locking_column` methods are deprecated. Use an assignment method instead. For example, instead of `set_table_name`, use `self.table_name=`.

    ```ruby
    class Project < ActiveRecord::Base
      self.table_name = "project"
    end
    ```

    Or define your own `self.table_name` method:

    ```ruby
    class Post < ActiveRecord::Base
      def self.table_name
        "special_" + super
      end
    end

    Post.table_name # => "special_posts"

    ```

Active Model
------------

* Add `ActiveModel::Errors#added?` to check if a specific error has been added.

* Add ability to define strict validations with `strict => true` that always raises exception when fails.

* Provide mass_assignment_sanitizer as an easy API to replace the sanitizer behavior. Also support both :logger (default) and :strict sanitizer behavior.

### Deprecations

* Deprecated `define_attr_method` in `ActiveModel::AttributeMethods` because this only existed to support methods like `set_table_name` in Active Record, which are themselves being deprecated.

* Deprecated `Model.model_name.partial_path` in favor of `model.to_partial_path`.

Active Resource
---------------

* Redirect responses: 303 See Other and 307 Temporary Redirect now behave like 301 Moved Permanently and 302 Found.

Active Support
--------------

* Added `ActiveSupport:TaggedLogging` that can wrap any standard `Logger` class to provide tagging capabilities.

    ```ruby
    Logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))

    Logger.tagged("BCX") { Logger.info "Stuff" }
    # Logs "[BCX] Stuff"

    Logger.tagged("BCX", "Jason") { Logger.info "Stuff" }
    # Logs "[BCX] [Jason] Stuff"

    Logger.tagged("BCX") { Logger.tagged("Jason") { Logger.info "Stuff" } }
    # Logs "[BCX] [Jason] Stuff"
    ```

* The `beginning_of_week` method in `Date`, `Time` and `DateTime` accepts an optional argument representing the day in which the week is assumed to start.

* `ActiveSupport::Notifications.subscribed` provides subscriptions to events while a block runs.

* Defined new methods `Module#qualified_const_defined?`, `Module#qualified_const_get` and `Module#qualified_const_set` that are analogous to the corresponding methods in the standard API, but accept qualified constant names.

* Added `#deconstantize` which complements `#demodulize` in inflections. This removes the rightmost segment in a qualified constant name.

* Added `safe_constantize` that constantizes a string but returns `nil` instead of raising an exception if the constant (or part of it) does not exist.

* `ActiveSupport::OrderedHash` is now marked as extractable when using `Array#extract_options!`.

* Added `Array#prepend` as an alias for `Array#unshift` and `Array#append` as an alias for `Array#<<`.

* The definition of a blank string for Ruby 1.9 has been extended to Unicode whitespace. Also, in Ruby 1.8 the ideographic space U`3000 is considered to be whitespace.

* The inflector understands acronyms.

* Added `Time#all_day`, `Time#all_week`, `Time#all_quarter` and `Time#all_year` as a way of generating ranges.

    ```ruby
    Event.where(:created_at => Time.now.all_week)
    Event.where(:created_at => Time.now.all_day)
    ```

* Added `instance_accessor: false` as an option to `Class#cattr_accessor` and friends.

* `ActiveSupport::OrderedHash` now has different behavior for `#each` and `#each_pair` when given a block accepting its parameters with a splat.

* Added `ActiveSupport::Cache::NullStore` for use in development and testing.

* Removed `ActiveSupport::SecureRandom` in favor of `SecureRandom` from the standard library.

### Deprecations

* `ActiveSupport::Base64` is deprecated in favor of `::Base64`.

* Deprecated `ActiveSupport::Memoizable` in favor of Ruby memoization pattern.

* `Module#synchronize` is deprecated with no replacement. Please use monitor from ruby's standard library.

* Deprecated `ActiveSupport::MessageEncryptor#encrypt` and `ActiveSupport::MessageEncryptor#decrypt`.

* `ActiveSupport::BufferedLogger#silence` is deprecated. If you want to squelch logs for a certain block, change the log level for that block.

* `ActiveSupport::BufferedLogger#open_log` is deprecated. This method should not have been public in the first place.

* `ActiveSupport::BufferedLogger's` behavior of automatically creating the directory for your log file is deprecated. Please make sure to create the directory for your log file before instantiating.

* `ActiveSupport::BufferedLogger#auto_flushing` is deprecated. Either set the sync level on the underlying file handle like this. Or tune your filesystem. The FS cache is now what controls flushing.

    ```ruby
    f = File.open('foo.log', 'w')
    f.sync = true
    ActiveSupport::BufferedLogger.new f
    ```

* `ActiveSupport::BufferedLogger#flush` is deprecated. Set sync on your filehandle, or tune your filesystem.

Credits
-------

See the [full list of contributors to Rails](http://contributors.rubyonrails.org/) for the many people who spent many hours making Rails, the stable and robust framework it is. Kudos to all of them.

Rails 3.2 Release Notes were compiled by [Vijay Dev](https://github.com/vijaydev.)