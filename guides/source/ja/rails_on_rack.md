Rails と Rack
=============

このガイドでは、RailsとRackの関係、Railsと他のRackコンポーネントとの関係について説明します。

このガイドの内容:

* RackのミドルウェアをRailsで使う方法
* Action Pack内のミドルウェアスタックについて
* 独自のミドルウェアスタックを定義する方法

--------------------------------------------------------------------------------


WARNING: このガイドはRackのミドルウェア、urlマップ、`Rack::Builder`といったRackのプロトコルや概念に関する実用的な知識を身につけていることを前提にしています。

Rack入門
--------------------

Rackは、RubyのWebアプリケーションに対して、モジュール化された最小限のインターフェイスを提供して、インターフェイスを広範囲に使えるようにします。RackはHTTPリクエストとレスポンスを可能なかぎり簡単な方法でラッピングすることで、Webサーバー、Webフレームワーク、その間に位置するソフトウェア（ミドルウェアと呼ばれています）のAPIを1つのメソッド呼び出しの形にまとめます。

Rackに関する解説はこのガイドの範疇を超えてしまいます。Rackに関する基本的な知識が不足している場合は、下記の[リソース](#参考資料) を参照してください。

RailsとRack
-------------

### RailsアプリケーションのRackオブジェクト

`Rails.application`は、Railsアプリケーションにおける主要なRackアプリケーションです。Rackに準拠したWebサーバーで、Railsアプリケーションを提供するには、`Rails.application`オブジェクトを使う必要があります。

### `bin/rails server`コマンド

`bin/rails server`コマンドは、`Rack::Server`のオブジェクトを作成し、Webサーバーを起動します。

`bin/rails server`コマンドは、以下のように`Rack::Server`のオブジェクトを作成します。

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server`クラスは`Rack::Server`クラスを継承しており、以下のように`Rack::Server#start`を呼び出します。

```ruby
class Server < ::Rack::Server
  def start
    # ...
    super
  end
end
```

### `rackup`コマンド

Railsの`bin/rails server`コマンドの代わりに`rackup`コマンドを使うときは、以下の内容を`config.ru`に記述して、Railsアプリケーションのルートディレクトリに保存します。

```ruby
# Rails.root/config.ru
require_relative 'config/environment'
run Rails.application
```

続いて、サーバーを起動します。

```bash
$ rackup config.ru
```

`rackup`の他のオプションについて詳しく知りたいときは、以下を実行します。

```bash
$ rackup --help
```

### 開発中の自動再読み込みについて

一度読み込まれたミドルウェアは、変更が発生しても検出されません。現在実行中のアプリケーションでミドルウェアの変更を反映するには、サーバーの再起動が必要です。

Action Dispatcherのミドルウェアスタック
----------------------------------

Action Dispatcher内部のコンポーネントの多くは、「Rackミドルウェア」として実装されています。`Rails::Application`は、`ActionDispatch::MiddlewareStack`を用いて内部ミドルウェアや外部ミドルウェアを組み合わせることで、完全なRailsのRackアプリケーションを構築します。

NOTE: Railsの`ActionDispatch::MiddlewareStack`クラスは`Rack::Builder`クラスと同等ですが、Railsアプリケーションの要求を満たすために柔軟性が高く多機能です。

### ミドルウェアスタックを調べる

Railsには、ミドルウェアスタックを調べるための便利なタスクがあります。

```bash
$ bin/rails middleware
```

作成直後のRailsアプリケーションでは、以下のように出力されるはずです。

```ruby
use ActionDispatch::HostAuthorization
use Rack::Sendfile
use ActionDispatch::Static
use ActionDispatch::Executor
use ActionDispatch::ServerTiming
use ActiveSupport::Cache::Strategy::LocalCache::Middleware
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use ActionDispatch::RemoteIp
use Sprockets::Rails::QuietAssets
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use WebConsole::Middleware
use ActionDispatch::DebugExceptions
use ActionDispatch::ActionableExceptions
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActiveRecord::Migration::CheckPending
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use ActionDispatch::ContentSecurityPolicy::Middleware
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
use Rack::TempfileReaper
run MyApp::Application.routes
```

デフォルトのミドルウェアを含むいくつかのミドルウェアの概要については、[ミドルウェアスタックの内部](#ミドルウェアスタックの内部)を参照してください。

### ミドルウェアスタックを設定する

Railsが提供するシンプルな[`config.middleware`][]を用いることで、ミドルウェアスタックにミドルウェアを追加・削除・変更できます。これは`application.rb`設定ファイルで行うことも、環境ごとの`environments/<環境名>.rb`設定ファイルで行うこともできます。

[`config.middleware`]: configuring.html#config-middleware

#### ミドルウェアを追加する

次のメソッドを使うと、ミドルウェアスタックに新しいミドルウェアを追加できます。

* `config.middleware.use(new_middleware, args)`: ミドルウェアスタックの末尾に新しいミドルウェアを追加します。

* `config.middleware.insert_before(existing_middleware, new_middleware, args)`: 新しいミドルウェアを、（第1引数で）指定された既存のミドルウェアの直前に追加します。

* `config.middleware.insert_after(existing_middleware, new_middleware, args)`: 新しいミドルウェアを、（第1引数で）指定された既存のミドルウェアの直後に追加します。

```ruby
# config/application.rb

# Rack::BounceFaviconを末尾に追加する
config.middleware.use Rack::BounceFavicon

# ActionDispatch::Executorの直後にLifo::Cacheを追加する
# Lifo::Cacheに引数{ page_cache: false }を渡す
config.middleware.insert_after ActionDispatch::Executor, Lifo::Cache, page_cache: false
```

#### ミドルウェアを置き換える

`config.middleware.swap`を使って、ミドルウェアスタック内にあるミドルウェアを置き換えられます。

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsで置き換える
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### ミドルウェアを移動する

ミドルウェアスタック内の既存のミドルウェアを移動して順序を変更するには、`config.middleware.move_before`と`config.middleware.move_after`を使います。

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsの前に移動
config.middleware.move_before Lifo::ShowExceptions, ActionDispatch::ShowExceptions
```

```ruby
# config/application.rb

# ActionDispatch::ShowExceptionsをLifo::ShowExceptionsの後に移動
config.middleware.move_after Lifo::ShowExceptions, ActionDispatch::ShowExceptions
```

#### ミドルウェアを削除する

アプリケーションの設定に以下のコードを追加します。

```ruby
# config/application.rb
config.middleware.delete Rack::Runtime
```

ミドルウェアスタックを調べると、`Rack::Runtime`が消えていることが分かります。

```bash
$ bin/rails middleware
(in /Users/lifo/Rails/blog)
use ActionDispatch::Static
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x00000001c304c8>
...
run Rails.application.routes
```

セッション関連のミドルウェアを削除するには、次のように書きます。

```ruby
# config/application.rb
config.middleware.delete ActionDispatch::Cookies
config.middleware.delete ActionDispatch::Session::CookieStore
config.middleware.delete ActionDispatch::Flash
```

ブラウザ関連のミドルウェアを削除するには次のように書きます。

```ruby
# config/application.rb
config.middleware.delete Rack::MethodOverride
```

存在しないミドルウェアを削除しようとするとエラーが発生するようにするには、`delete!`を代わりに使います。

```ruby
# config/application.rb
config.middleware.delete! ActionDispatch::Executor
```

### ミドルウェアスタックの内部

Action Controllerの機能の多くはミドルウェアとして実装されています。それぞれの役割について以下のリストで説明します。

**`ActionDispatch::HostAuthorization`**

* リクエストの送信先ホストを明示的に許可することで、DNSリバインディング攻撃から保護します。設定方法については、[設定ガイド](configuring.html#actiondispatch-hostauthorization)を参照してください。

**`Rack::Sendfile`**

* X-Sendfile headerを設定します。[`config.action_dispatch.x_sendfile_header`][]オプション経由で設定を変更できます。

[`config.action_dispatch.x_sendfile_header`]: configuring.html#config-action-dispatch-x-sendfile-header

**`ActionDispatch::Static`**

* 静的ファイルの配信に使います。[`config.public_file_server.enabled`][]`を`false`にするとオフになります。

[`config.public_file_server.enabled`]: configuring.html#config-public-file-server-enabled

**`Rack::Lock`**

* `env["rack.multithread"]`を`false`に設定し、アプリケーションをMutexでラップします。

**`ActionDispatch::Executor`**

* スレッドセーフのコードを開発中にリロードするときに使います。

**`ActionDispatch::ServerTiming`**

* リクエストのパフォーマンスメトリクスを含む [`Server-Timing`](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Server-Timing)ヘッダーを設定します。

**`ActiveSupport::Cache::Strategy::LocalCache::Middleware`**

* メモリキャッシュで用います。このキャッシュはスレッドセーフではありません。

**`Rack::Runtime`**

* X-Runtimeヘッダーを設定します。このヘッダーには、リクエストの処理にかかった時間が秒単位で表示されます。

**`Rack::MethodOverride`**

* `params[:_method]`が設定されている場合に（HTTP）メソッドが上書きされるようになります。HTTPのPUTメソッド、DELETEメソッドを実現するためのミドルウェアです。

**`ActionDispatch::RequestId`**

* レスポンスで`X-Request-Id`ヘッダーを有効にして`ActionDispatch::Request#request_id`メソッドが使えるようにします。

**`ActionDispatch::RemoteIp`**

* IPスプーフィング攻撃をチェックします。

**`Sprockets::Rails::QuietAssets`**

* アセットリクエストでのログ書き出しを抑制します。

**`Rails::Rack::Logger`**

* リクエストの処理が開始されたことをログに出力します。リクエストが完了すると、すべてのログをフラッシュします。

**`ActionDispatch::ShowExceptions`**

* アプリケーションが返すすべての例外をrescueし、例外処理用アプリケーション （エンドユーザー向けに例外を整形するアプリケーション） を起動します。

**`ActionDispatch::DebugExceptions`**

* 例外をログに出力します。ローカルからのリクエストの場合は、デバッグ用ページも表示します。

**`ActionDispatch::Reloader`**

* development環境でコードの再読み込みを行うために、prepareコールバックとcleanupコールバックを提供します。

**`ActionDispatch::Callbacks`**

* リクエストをディスパッチする直前および直後に実行されるコールバックを提供します。

**`ActiveRecord::Migration::CheckPending`**

* 未実行のマイグレーションがないか確認します。未実行のものがあった場合は、`ActiveRecord::PendingMigrationError`を発生させます。

**`ActionDispatch::Cookies`**

* cookie機能を提供します。

**`ActionDispatch::Session::CookieStore`**

* セッションをcookieに保存する役割を担当します。

**`ActionDispatch::Flash`**

* flashのキーをセットアップします（訳注: flashは連続するリクエスト間でメッセージを共有表示する機能です）。これは、[`config.session_store`][]に値が設定されている場合にのみ有効です。

[`config.session_store`]: configuring.html#config-session-store

**`ActionDispatch::ContentSecurityPolicy::Middleware`**

* Content-Security-Policyヘッダー設定用のDSLを提供します。

**`Rack::Head`**

* すべての`HEAD`リクエストに対して空のbodyを返します。その他のリクエストは変更しません。

**`Rack::ConditionalGet`**

* 「条件付き`GET`（Conditional `GET`）」機能を提供します。"条件付き `GET`"が有効になっていると、リクエストされたページで変更が発生していない場合に空のbodyを返します。

**`Rack::ETag`**

* bodyが文字列のみのレスポンスにETagヘッダを追加します。ETagはキャッシュのバリデーションに使われます。

**`Rack::TempfileReaper`**

* マルチパートリクエストをバッファするのに使われる一時ファイルをクリーンアップします。

TIP: これらのミドルウェアはいずれも、独自のRackスタックで利用することも可能です。

参考資料
---------

### Rackについて詳しく学ぶ

* [Rack公式サイト](https://rack.github.io)
* [Rack入門](http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html)

### ミドルウェアを理解する

* [Railscast on Rack Middlewares](http://railscasts.com/episodes/151-rack-middleware)
