Rails のキャッシュ機構
===============================

本ガイドでは、キャッシュを導入してRailsアプリケーションを高速化する方法をご紹介します。

「キャッシュ（caching）」とは、リクエスト・レスポンスのサイクルの中で生成されたコンテンツを保存しておき、次回同じようなリクエストが発生したときのレスポンスでそのコンテンツを再利用することを指します。

多くの場合、キャッシュはアプリケーションのパフォーマンスを効果的に増大するのに最適な方法です。キャッシュを導入することで、単一サーバー、単一データベースのwebサイトでも数千ユーザーの同時接続による負荷に耐えられるようになります。

Railsには、すぐ利用できるキャッシュ機能がいくつも用意されています。本ガイドでは、それぞれの機能について目的を解説します。Railsのキャッシュ機能を使いこなすことで、応答時間の低下や高額なサーバー使用料に悩まされずに、Railsアプリケーションが数百万ビューを配信できるようになります。

このガイドの内容:

* フラグメントキャッシュとロシアンドールキャッシュ
* キャッシュの依存関係の管理
* 代替キャッシュストア
* 条件付きGETのサポート

--------------------------------------------------------------------------------


基本的なキャッシュ
-------------

ここでは、キャッシュの手法を3種類ご紹介します。「ページキャッシュ」「アクションキャッシュ」「フラグメントキャッシュ」です。Railsのフラグメントキャッシュは本体に組み込まれており、デフォルトで利用できます。ページキャッシュやアクションキャッシュを利用するには、`Gemfile`に`actionpack-page_caching` gemや`actionpack-action_caching` gemを追加する必要があります。

キャッシュは、デフォルトではproduction環境でのみ有効になります。ローカルでキャッシュを使ってみたい場合は、対応する`config/environments/*.rb`ファイルで`config.action_controller.perform_caching`を`true`に設定します。

```ruby
config.action_controller.perform_caching = true
```

NOTE: `config.action_controller.perform_caching`値の変更は、Action Controllerコンポーネントで提供されるキャッシュでのみ有効になります。つまり、後述する[低レベルキャッシュ](#低レベルキャッシュ)の動作には影響しません。

### ページキャッシュ

Railsのページキャッシュは、apacheやnginxなどのwebサーバーによって生成されるページへのリクエストを（Railsスタック全体を経由せずに）キャッシュするメカニズムです。ページキャッシュはきわめて高速ですが、常に有効とは限りません。たとえば、認証にはページキャッシュは適用されません。また、webサーバーはファイルシステムから直接ファイルを読み出して利用するので、キャッシュの有効期限の実装も必要です。

INFO: ページキャッシュ機能は、Rails 4本体から取り除かれ、gem化されました。[actionpack-page_caching gem](https://github.com/rails/actionpack-page_caching)をご覧ください。

### アクションキャッシュ

ページキャッシュは、before_filterのあるアクション（認証の必要なページなど）には適用できません。アクションキャッシュは、このような場合に使います。アクションキャッシュの動作は、ページキャッシュと似ていますが、webサーバーへのリクエストがRailsスタックにヒットしたときに、`before_filter`を実行してからキャッシュを返す点が異なります。これによって、キャッシュの恩恵を受けながら、認証などの制限をかけられるようになります。

INFO: アクションキャッシュ機能は、Rails 4から削除されました。[actionpack-action_caching gem](https://github.com/rails/actionpack-action_caching)をご覧ください。推奨される新しい方法については、[DHH's key-based cache expiration overview](https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works) をご覧ください。

### フラグメントキャッシュ

通常、動的なWebアプリケーションでは、ページのキャッシュ時の特性が異なるさまざまなコンポーネントによってページが生成されます。ページ内のさまざまなパーツごとにキャッシュや有効期限を個別に設定したい場合は、フラグメントキャッシュを使います。

フラグメントキャッシュでは、ビューのロジックのフラグメントをキャッシュブロックでラップし、次回のリクエストでそれをキャッシュストアから取り出して送信します。

たとえば、ページ内で表示する製品（product）を個別にキャッシュしたい場合は、次のように書けます。

```html+erb
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

Railsアプリケーションが最初のリクエストを受信すると、一意のキーを備えた新しいキャッシュが保存されます。生成されるキーは次のようなものになります。

```
views/products/index:bea67108094918eeba42cd4a6e786901/products/1
```

キーの途中にある文字列は、テンプレートツリーのダイジェストです。これは、キャッシュするビューフラグメントのコンテンツを元に算出されたハッシュダイジェストです。ビューフラグメントが変更されると（HTMLが変更されるなど）、このダイジェストも変更されて既存のファイルが無効になります。

productレコードから派生したキャッシュバージョンは、キャッシュエントリに保存されます。
productが変更されるとキャッシュバージョンが変更され、以前のバージョンを含むキャッシュフラグメントはすべて無視されます。

TIP: Memcachedなどのキャッシュストアは、古いキャッシュファイルを自動削除します。

条件を指定してフラグメントをキャッシュしたい場合は、`cache_if`や`cache_unless`を利用できます。

```erb
<% cache_if admin?, product do %>
  <%= render product %>
<% end %>
```

#### コレクションキャッシュ

`render`ヘルパーは、コレクションでレンダリングされた個別のテンプレートをキャッシュすることもできます。上の`each`を使っているコード例では、すべてのキャッシュテンプレートを（個別に読み出す代わりに）一括で読み出すこともできます。この機能を利用するには、コレクションをレンダリングするときに`cached: true`を指定します。

```html+erb
<%= render partial: 'products/product', collection: @products, cached: true %>
```

これにより、前回までにレンダリングされたすべてのキャッシュテンプレートが一括で読み出され、劇的に速度が向上します。さらに、それまでキャッシュされていなかったテンプレートもキャッシュに追加され、次回のレンダリングでまとめて読み出されるようになります。

### ロシアンドールキャッシュ

フラグメントキャッシュ内で、さらにフラグメントをキャッシュしたいことがあります。このようにキャッシュをネストする手法を、マトリョーシカ人形のイメージになぞらえて「ロシアンドールキャッシュ」（Russian doll caching）と呼びます。

ロシアンドールキャッシュのメリットは、たとえば内側のフラグメントで製品（product）が1件だけ更新された場合に、内側の他のフラグメントを捨てずに再利用し、外側のフラグメントは通常どおり再生成できることです。

前節で解説したように、キャッシュされたファイルは、そのファイルが直接依存しているレコードの`updated_at`の値が変わると期限切れになりますが、そのフラグメント内でネストするキャッシュは期限切れになりません。

次のビューを例に説明します。

```erb
<% cache product do %>
  <%= render product.games %>
<% end %>
```

上のビューをレンダリングした後、次のビューをレンダリングします。

```erb
<% cache game do %>
  <%= render game %>
<% end %>
```

gameの属性で変更が発生すると、`updated_at`値が現在時刻で更新され、キャッシュが無効になります。しかし、productオブジェクトの`updated_at`は変更されないので、productのキャッシュは無効にならず、アプリケーションは古いデータを返します。これを修正したい場合は、次のように`touch`メソッドでモデル同士を結びつけます。

```ruby
class Product < ApplicationRecord
  has_many :games
end

class Game < ApplicationRecord
  belongs_to :product, touch: true
end
```

`touch`を`true`に設定すると、あるgameレコードの`updated_at`を更新するアクションを実行すると、関連付けられているproductの`updated_at`も同様に更新して、キャッシュを無効にします。

### パーシャルキャッシュの共有

パーシャルのキャッシュや関連付けのキャッシュを異なる複数のMIMEタイプ間で共有できます。たとえば、パーシャルキャッシュの共有を使うと、テンプレートライターがHTMLとJavaScript間でパーシャルキャッシュを共有できるようになります。複数のテンプレートがテンプレートリゾルバのファイルパスにコレクションされるときは、テンプレート言語の拡張子のみがそこに含まれ、MIMEタイプは含まれません。これによって、テンプレートを複数のMIMEタイプで利用できます。HTMLリクエストとJavaScriptリクエストは、いずれも以下のコードにレスポンスを返します。

```ruby
render(partial: 'hotels/hotel', collection: @hotels, cached: true)
```

上のコードは`hotels/hotel.erb`という名前のファイルを読み込みます。

別の方法として、レンダリングするパーシャルの完全なファイル名を指定することも可能です。

```ruby
render(partial: 'hotels/hotel.html.erb', collection: @hotels, cached: true)
```

上のコードは、ファイルのMIMEタイプにかかわらず`hotels/hotel.html.erb`という名前のファイルを読み込み、たとえばJavaScriptファイルでこのパーシャルをインクルードできます。

### 依存関係の管理

キャッシュを正しく無効にするには、キャッシュの依存関係を適切に定義する必要があります。多くの場合、Railsでは依存関係が適切に処理されるので、特別な対応は不要です。ただし、カスタムヘルパーでキャッシュを扱うなどの場合は、明示的に依存関係を定義する必要があります。

#### 暗黙の依存関係

ほとんどの場合、テンプレートの依存関係は、テンプレート自身で呼び出される`render`によって発生します。以下の例は、デコード方法を取り扱う`ActionView::Digestor`でrender呼び出しする方法です。

```ruby
render partial: "comments/comment", collection: commentable.comments
render "comments/comments"
render 'comments/comments'
render('comments/comments')

render "header" translates to render("comments/header")

render(@topic)         translates to render("topics/topic")
render(topics)         translates to render("topics/topic")
render(message.topics) translates to render("topics/topic")
```

ただし、一部の呼び出しについては、キャッシュが適切に動作するための変更が必要です。たとえば、独自のコレクションを渡す場合は、次のように変更する必要があります。

```ruby
render @project.documents.where(published: true)
```

上のコードを次のように変更します。

```ruby
render partial: "documents/document", collection: @project.documents.where(published: true)
```

#### 明示的な依存関係

テンプレートの依存関係を自動的に導出できないことがあります。これは、ヘルパー内でレンダリングする場合が典型的です。以下に例を示します。

```html+erb
<%= render_sortable_todolists @project.todolists %>
```

このような呼び出しには、次の特殊なコメント形式で明示的に依存関係を示す必要があります。

```html+erb
<%# Template Dependency: todolists/todolist %>
<%= render_sortable_todolists @project.todolists %>
```

場合によっては（単一テーブル継承など）、 こうした明示的な依存関係を 多数書かなければならなくなる可能性もあります。テンプレートごとに依存関係を書く代わりに、ディレクトリの任意のテンプレートにマッチする

```html+erb
<%# Template Dependency: events/* %>
<%= render_categorizable_events @person.events %>
```

コレクションのキャッシュでは、パーシャルの冒頭でクリーンなキャッシュ呼び出しを行わない場合は、以下の特殊コメント形式をテンプレートのどこかに追加することで、コレクションキャッシュを引き続き有効にできます。

```html+erb
<%# Template Collection: notification %>
<% my_helper_that_calls_cache(some_arg, notification) do %>
  <%= notification.name %>
<% end %>
```

#### 外部の依存関係

たとえば、キャッシュされたブロック内でヘルパーメソッドを利用すると、このヘルパーを更新するときにキャッシュも更新しなければならなくなります。キャッシュの更新方法は実際には問題ではありませんが、テンプレートファイルのMD5を変更しなければなりません。推奨されている方法のひとつは、次のようにコメントで明示的に更新を示すことです。

```html+erb
<%# Helper Dependency Updated: Jul 28, 2015 at 7pm %>
<%= some_helper_method(person) %>
```

### 低レベルキャッシュ

ビューのフラグメントをキャッシュするのではなく、特定の値やクエリ結果だけをキャッシュしたいことがあります。Railsのキャッシュメカニズムでは、どんな情報でもキャッシュに保存できます。

低レベルキャッシュの最も効果的な実装方法は、`Rails.cache.fetch`メソッドを利用することです。このメソッドは、キャッシュの書き込みと読み出しの両方に対応しています。引数を1つだけ渡すと、キーを読み出し、キャッシュから値を取り出して返します。ブロックを渡すと、キャッシュにヒットしなかった場合にブロックが実行されます。ブロックの戻り値は、指定のキャッシュキーの配下にあるキャッシュに書き込まれます。キャッシュにヒットした場合は、ブロックを実行せずにキャッシュの値を返します。

次の例を考えてみましょう。アプリケーションに`Product`モデルがあり、競合webサイトの製品価格を検索するインスタンスメソッドがそのモデルにあるとします。このメソッドが返すデータは、低レベルキャッシュに最適です。

```ruby
class Product < ApplicationRecord
  def competing_price
    Rails.cache.fetch("#{cache_key_with_version}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```

NOTE: 上の例では`cache_key_with_version `メソッドを使っているので、キャッシュキーは`products/233-20140225082222765838000/competing_price`のような形式になります。`cache_key_with_version `は、モデルのクラス名と`id`と`updated_at`属性を元に文字列を生成します。この生成ルールは一般的に使われており、productが更新されるたびにキャッシュが無効になるというメリットがあります。一般に、インスタンスレベルの情報に低レベルキャッシュを適用する場合、キャッシュキーを生成する必要があります。

### SQLキャッシュ

Railsのクエリキャッシュは、各クエリによって返った結果セットをキャッシュする機能です。リクエストによって以前と同じクエリが発生すると、データベースへのクエリを実行する代わりに、キャッシュされた結果セットを利用します。

以下に例を示します。

```ruby
class ProductsController < ApplicationController

def index
    # 検索クエリの実行
    @products = Product.all

    ...

    # 同じクエリの再実行
    @products = Product.all
  end

end
```

データベースに対して同じクエリが再度実行されると、実際にはデータベースにアクセスしません。1回目のクエリでは、結果をメモリ上のクエリキャッシュに保存し、2回目のクエリではメモリから結果を読み出します。

ただし、ここで重要なのは、クエリキャッシュはアクションの開始時に作成され、アクションの終了時に破棄されるので、キャッシュはアクションの実行中しか保持されないという点です。低レベルキャッシュを利用すると、より長期間持続するクエリ結果を保存できます。

キャッシュストア
------------

Railsには、キャッシュデータの保存場所がいくつも用意されています。なお、SQLキャッシュやページキャッシュはこの中に含まれません。

### 設定

アプリケーションのデフォルトのキャッシュストアは、`config.cache_store`オプションで設定できます。キャッシュストアのコンストラクタには、引数として他のパラメータも渡せます。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

NOTE: または、構成ブロックの外部で`ActionController::Base.cache_store`を呼び出すこともできます。

キャッシュにアクセスするには、`Rails.cache`を呼び出します。

### ActiveSupport::Cache::Store

このクラスは、Railsのキャッシュにアクセスするための基盤を提供します。抽象クラスであるため、直接利用できません。クラスを利用するには、ストレージエンジンに関連するクラスを実装する必要があります。Railsでは以下が実装されています。

主要なメソッドは、`read`、`write`、`delete`、`exist?`、`fetch`です。`fetch`メソッドはブロックを1つ受け取り、キャッシュにある既存の値を返します。既存の値がキャッシュにない場合は、ブロックを評価して結果をキャッシュに書き込みます。

いくつかのオプションは、キャッシュのすべての実装で共通で利用できます。それらのオプションは、コンストラクタに渡すことも、エントリーにアクセスするさまざまなメソッドに渡すこともできます。

* `:namespace`: キャッシュストア内で名前空間を作成します。特に、キャッシュを他のアプリケーションと共有する場合に有用です。

* `:compress`: デフォルトで有効です。キャッシュエントリを圧縮してメモリ上の同じフットプリントに保存できるデータを増やすことで、キャッシュeviction（立ち退き）を削減してヒット率を高めます。

* `:compress_threshold`: デフォルトは1KBです。キャッシュエントリがしきい値（バイト数を指定）を超えると圧縮します。

* `:expires_in`: そのキャッシュエントリの有効期限を指定するオプションです（単位は秒）。このオプションがキャッシュストアでサポートされていれば、キャッシュから自動で削除されます。

* `:race_condition_ttl`: `:expires_in`と併用します。マルチプロセスで同じエントリが同時に再生成されてキャッシュが無効になる（dog pile効果とも呼ばれます）ときに発生する競合状態を防止するのに使います。このオプションは、新しい値の再生成が完了していない状態で、無効になったエントリを再利用してよい時間を秒で指定します。`:expires_in`オプションを利用する場合は、このオプションにも値を設定するとよいでしょう。

* `:coder`: このオプションを使うと、デフォルトのキャッシュシリアライズメカニズムをカスタムのメカニズムに置き換えられます。この`coder`は`dump`と`load`に応答しなければならず、カスタムコーダーを渡すと自動的に圧縮が無効になります。

#### コネクションプールのオプション

`MemCacheStore`と`RedisCacheStore`は、デフォルトではプロセスごとにひとつのコネクションを利用します。これは、Puma（または別のスレッド化サーバー）を使うと、コネクションを待つ複数のスレッドを利用可能にできるということです。
利用可能なコネクション数を増やすには、コネクションプールを有効にします。

最初に、Gemfileに`connection_pool` gemを追加します。

```ruby
gem 'connection_pool'
```

次に、`config.cache_store`設定に`:pool_size`オプションや`:pool_timeout`オプションを渡します。

```ruby
config.cache_store = :mem_cache_store, "cache.example.com", { pool_size: 5, pool_timeout: 5 }
```

* `:pool_size`: プロセス1個あたりのコネクション数を指定します（デフォルトは5）

* `:pool_timeout`: コネクションごとの待ち時間を秒で指定します（デフォルトは5）。タイムアウトまでにコネクションを利用できない場合は、`Timeout::Error` エラーが発生します。

#### カスタムのキャッシュストア

キャッシュストアを独自に作成するには、`ActiveSupport::Cache::Store`を拡張して適切なメソッドを実装します。これにより、Railsアプリケーションでさまざまなキャッシュ技術に差し替えられるようになります。

カスタムのキャッシュストアを利用するには、自作クラスの新しいインスタンスにキャッシュストアを設定します。

```ruby
config.cache_store = MyCacheStore.new
```

### ActiveSupport::Cache::MemoryStore

このキャッシュストアは、エントリーを同じRubyプロセス内のメモリに保持します。キャッシュストアのサイズを制限するには、イニシャライザで`:size`オプションを指定します（デフォルトは32MB）。キャッシュがこのサイズを超えるとクリーンアップが開始され、最近利用が最も少ないエントリから削除されます（LRU: Least Recently Used）。

```ruby
config.cache_store = :memory_store, { size: 64.megabytes }
```

Ruby on Railsサーバーのプロセスを複数実行している場合（Phusion PassengerやPumaをクラスタモードで利用している場合）、Railsサーバーのキャッシュデータはプロセスのインスタンス間で共有できなくなります。このキャッシュストアは、アプリケーションを大規模にデプロイするには向いていません。ただし、小規模でトラフィックの少ないサイトでサーバープロセスを数個動かす程度であれば問題なく動作します。もちろん、development環境やtest環境でも動作します。

新規Railsプロジェクトでは、development環境でこの実装をデフォルトで使うよう設定されます。

NOTE: `:memory_store`を使うとキャッシュデータがプロセス間で共有されないため、Railsコンソールから手動でキャッシュを読み書きすることも無効にすることもできません。

### ActiveSupport::Cache::FileStore

このキャッシュストアは、エントリをファイルシステムに保存します。ファイル保存場所へのパスは、キャッシュを初期化するときに指定する必要があります。

```ruby
config.cache_store = :file_store, "/path/to/cache/directory"
```

このキャッシュストアを使うと、複数のサーバープロセス間でキャッシュを共有できるようになります。トラフィックが中規模程度のサイトを1、2個程度ホストする場合に向いています。異なるホストで実行するサーバープロセス間のキャッシュを共有ファイルシステムで共有することも一応可能ですが、おすすめできません。

キャッシュはディスクが満杯になるまで増加するため、古いエントリを定期的に削除することをおすすめします。

`config.cache_store`を明示的に指定しない場合は、デフォルトのキャッシュストア実装（`"#{root}/tmp/cache/"`）提供されます。

### ActiveSupport::Cache::MemCacheStore

このキャッシュストアは、アプリケーションキャッシュの保存先をDangaの`memcached`サーバーに一元化します。Railsでは、本体にバンドルされている`dalli` gemがデフォルトで使われます。`dalli`は、現時点でproduction Webサイトで最も広く利用されているキャッシュストアです。高性能かつ高冗長性を備えており、単一のキャッシュストアも共有キャッシュクラスタも提供できます。

キャッシュを初期化するときは、クラスタ内の全memcachedサーバーのアドレスを指定するか、`MEMCACHE_SERVERS`環境変数を適切に設定しておく必要があります。

```ruby
config.cache_store = :mem_cache_store, "cache-1.example.com", "cache-2.example.com"
```

どちらも指定されていない場合は、memcachedがlocalhostのデフォルトポート（`127.0.0.1:11211`）実行されていると仮定しますが、これは大規模サイトのセットアップには理想的ではありません。

```ruby
config.cache_store = :mem_cache_store # Will fallback to $MEMCACHE_SERVERS, then 127.0.0.1:11211
```

サポートされているアドレスの種類について詳しくは[`Dalli::Client`のドキュメント](https://www.rubydoc.info/github/mperham/dalli/Dalli%2FClient:initialize)を参照してください。

このキャッシュの`write`メソッドや`fetch`メソッドでは、memcached固有の機能を利用するオプションを2つ指定できます。シリアライズを行わずに値を直接サーバーに送信するには、`:raw`を指定します（送信する値は文字列か数値でなければなりません）。値を`:raw`に指定した場合にのみ、`increment`や`decrement`などを指定してmemcachedを直接操作できます。memcachedが既存のエントリを上書きしないようにするには、`:unless_exist`を指定します。

### ActiveSupport::Cache::RedisCacheStore

Redisキャッシュストアは、メモリ使用量が最大に達したときにRedisの自動eviction（立ち退き）を利用して、Memcachedキャッシュサーバーと同様の機能を実現しています。

デプロイに関するメモ: Redisのキーはデフォルトでは無期限なので、専用のRedisキャッシュサーバーを使うときはご注意ください。永続化用のRedisサーバーに期限付きのキャッシュデータを保存してはいけません。詳しくは[Redis cache server setup guide](https://redis.io/topics/lru-cache)（英語）をご覧ください。

「キャッシュのみ」のRedisサーバーでは、`maxmemory-policy`にいずれかのallkeysを設定してください。Redis 4以降では`allkeys-lfu`によるLFU（Least Frequently Uaed）evictionアルゴリズムがサポートされており、これはデフォルトの選択肢として非常によいものです。Redis 3およびそれ以前では、`allkeys-lru`を用いてLRU（Least Recently Used）アルゴリズムにすべきです。

キャッシュの読み書きのタイムアウトは、やや低めに設定しましょう。キャッシュの取り出しで1秒以上待つよりも、キャッシュ値を再生成する方が高速になることがよくあります。読み書きのデフォルトタイムアウト値は1秒ですが、ネットワークのレイテンシが常に低い場合は値を小さくするとよい場合があります。

キャッシュの読み書きでは決して例外が発生せず、単に`nil`を返してあたかも何もキャッシュされていないかのように振る舞います。キャッシュで例外が生じているかどうかを測定するには、`error_handler`を渡して例外収集サービスにレポートを送信してもよいでしょう。収集サービスは、「`method`（最初に呼び出されたキャッシュストアメソッド名、）」「`returning`（ユーザーに返した値（通常は`nil`）」「`exception`（rescueされた例外）」の3つの引数を受け取れる必要があります。。

Redisを利用するには、まず`Gemfile`にredis gemを追加します。

```ruby
gem 'redis'
```

より高速な[hiredis](https://github.com/redis/hiredis)によるRubyラッパーを`Gemfile`に追加すると、hiredisコネクションライブラリによるサポートを有効にできます。

```ruby
gem 'hiredis'
```

hiredisが利用可能になっていれば、Redisキャッシュストアによって自動的にhiredisが`require`されます。その他の設定は不要です。

最後に、関連する`config/environments/*.rb`ファイルに以下の設定を追加します。

```ruby
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

少し複雑なproduction向けRedisキャッシュストアは以下のような感じになります。

```ruby
cache_servers = %w(redis://cache-01:6379/0 redis://cache-02:6379/0)
config.cache_store = :redis_cache_store, { url: cache_servers,

  connect_timeout:    30,  # Defaults to 20 seconds
  read_timeout:       0.2, # Defaults to 1 second
  write_timeout:      0.2, # Defaults to 1 second
  reconnect_attempts: 1,   # Defaults to 0

  error_handler: -> (method:, returning:, exception:) {
    # エラーをwarningとしてSentryに送信する
    Raven.capture_exception exception, level: 'warning',
      tags: { method: method, returning: returning }
  }
}
```

### ActiveSupport::Cache::NullStore

このキャッシュストアは個別のWebリクエストを対象とし、リクエストが終了すると保存された値をクリアするので、development環境やtest環境での利用のみを想定しています。`Rails.cache`と直接やりとりするコードを使っていて、キャッシュが原因でコード変更の結果が反映されなくなる場合にこのキャッシュストアを使うと非常に便利です。

```ruby
config.cache_store = :null_store
```

キャッシュのキー
----------

このキャッシュで使われるキーには、`cache_key`と`to_param`に応答する任意のオブジェクトが使えます。自分のクラスで`cache_key`メソッドを実装すると、カスタムキーを生成できるようになります。Active Recordは、このクラス名とレコードidに基づいてキーを生成します。

キャッシュのキーとして、値のハッシュと配列を指定できます。

```ruby
# 通常のキャッシュキー
Rails.cache.read(site: "mysite", owners: [owner_1, owner_2])
```

`Rails.cache`で使うキーは、ストレージエンジンで実際に使われるキーと同じになりません。。実際のキーは、名前空間で修飾されたり、バックエンドの技術的制約に合わせて変更されていたりする可能性もあります。そのため、`Rails.cache`で値を保存してから`dalli` gemで値を取り出すことはできません。その代わり、memcachedのサイズ制限超過や構文規則違反を気にする必要もありません。

条件付きGETのサポート
-----------------------

条件付きGETは、HTTP仕様で定められた機能です。「GETリクエストへのレスポンスが前回リクエストのレスポンスから変更されていなければ、ブラウザ内キャッシュを安全に利用できる」とWebサーバーからブラウザに通知します。

この機能は、`HTTP_IF_NONE_MATCH`ヘッダと`HTTP_IF_MODIFIED_SINCE`ヘッダを使って、一意のコンテンツidや最終変更タイムスタンプをやり取りします。コンテンツid（[ETag](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/ETag)）または最終更新タイムスタンプがサーバー側のバージョンと一致する場合は、「変更なし」ステータスのみを持つ空レスポンスをサーバーが返すだけで済みます。

最終更新タイムスタンプや`if-none-match`ヘッダの有無を確認して、完全なレスポンスを返す必要があるかどうかを決定するのは、サーバー側（つまり開発者）の責任です。Railsでは、次のように条件付きGETを比較的簡単に利用できます。

```ruby
class ProductsController < ApplicationController

  def show
    @product = Product.find(params[:id])

    # 指定のタイムスタンプやETag値によって、リクエストが古いことがわかった場合
    # （再処理が必要な場合）、このブロックを実行する
    if stale?(last_modified: @product.updated_at.utc, etag: @product.cache_key_with_version)
      respond_to do |wants|
        # ... 通常のレスポンス処理
      end
    end

    # リクエストが新鮮な（つまり前回から変更されていない）場合は
    # 処理不要。デフォルトのレンダリングでは、前回の`stale?`呼び出しの結果に基いて
    # 処理が必要かどうかを判断して :not_modifiedを送信するだけでよい。
  end
end
```

オプションハッシュの代わりに、単にモデルを渡すこと可能です。Railsの`last_modified`や`etag`の設定では、`updated_at`メソッドや`cache_key_with_version`メソッドが使われます。

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    if stale?(@product)
      respond_to do |wants|
        # ... 通常のレスポンス処理
      end
    end
  end
end
```

特殊なレスポンス処理を使わずにデフォルトのレンダリングメカニズムを利用する（つまり`respond_to`も使わず独自レンダリングもしない）場合は、`fresh_when`ヘルパーで簡単に処理できます。

```ruby
class ProductsController < ApplicationController

  # リクエストが古くなければ自動的に:not_modifiedを返す
  # 古い場合はデフォルトのテンプレート（product.*）を返す

  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, etag: @product
  end
end
```

たとえば有効期限のない静的ページでキャッシュを有効にしたいことがあります。その場合は、`http_cache_forever`ヘルパーでブラウザやプロキシでキャッシュを無期限にできます。

キャッシュのレスポンスはデフォルトではprivateになっており、キャッシュはユーザーのWebブラウザでのみ行われます。プロキシでレスポンスをキャッシュ可能にするには、`public: true`を設定してすべてのユーザーへのレスポンスがキャッシュされるようにします。

このヘルパーメソッドを使うと、`last_modified`ヘッダーは`Time.new(2011, 1, 1).utc`に設定され、`expires`ヘッダーは100年に設定されます。

WARNING: このメソッドの利用には十分ご注意ください。ブラウザやプロキシにキャッシュされたレスポンスは、ブラウザのキャッシュを強制的にクリアしない限り無効にできません。

```ruby
class HomeController < ApplicationController
  def index
    http_cache_forever(public: true) do
      render
    end
  end
end
```

### 強いETagと弱いETag

Railsでは、デフォルトで「弱い」ETagを使います。弱いETagでは、レスポンスのbodyが微妙に異なる場合にも同じETagを与えることで、事実上同じレスポンスとして扱えるようになります。レスポンスbodyのごく一部が変更されたときにページを再生成したくない場合に便利です。

弱いETagの冒頭には`W/`が追加されるので、強いETagと区別できます。

```
  W/"618bbc92e2d35ea1945008b42799b0e7" → 弱いETag
  "618bbc92e2d35ea1945008b42799b0e7" → 強いETag
```

強いETagは、弱いETagと異なり、レスポンスがバイトレベルで完全一致しなければなりません。強いETagは巨大な動画やPDFファイル内でRangeリクエストを実行する場合に便利です。Akamaiなど一部のCDNでは、強いETagのみをサポートしています。強いETagの生成がどうしても必要な場合は、次のようにできます。

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when last_modified: @product.published_at.utc, strong_etag: @product
  end
end
```

次のように、レスポンスに強いETagを直接設定することもできます。

```ruby
response.strong_etag = response.body # => "618bbc92e2d35ea1945008b42799b0e7"
```

development環境のキャッシュ
----------------------

アプリケーションのキャッシュ戦略をdevelopmentモードでテストしたくなることがよくあります。Railsコマンド`dev:cache`を使うと、developmentモードのキャッシュを手軽にオンオフできます。

```bash
$ rails dev:cache
Development mode is now being cached.
$ rails dev:cache
Development mode is no longer being cached.
```

NOTE: Railsのdevelopmentモードでは、デフォルトでキャッシュが**オフ**になります。Railsは
[`ActiveSupport::Cache::NullStore`](#activesupport-cache-nullstore)を利用します。

参考
----------

* [DHHによるキーベースのキャッシュ無効化に関する記事](https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works)（英語）
* [Ryan BatesのRailsCast: キャッシュダイジェストについて](http://railscasts.com/episodes/387-cache-digests)（英語）
