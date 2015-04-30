


Rails アプリケーションのデバッグ
============================

本ガイドでは、Ruby on Rails アプリケーションのさまざまなデバッグ技法をご紹介します。

このガイドの内容:

* デバッグの目的
* テストで特定できない問題がアプリケーションで発生したときの追跡方法
* さまざまなデバッグ方法
* スタックトレースの解析方法

--------------------------------------------------------------------------------

デバッグに利用できるビューヘルパー
--------------------------

変数にどんな値が入っているかを確認する作業は何かと必要になります。Rails では以下の3つのメソッドを利用できます。

* `debug`
* `to_yaml`
* `inspect`

### `debug`

`debug`ヘルパーは\<pre>タグを返します。このタグの中にYAML形式でオブジェクトが出力されます。これにより、あらゆるオブジェクトを人間が読めるデータに変換できます。たとえば、以下のコードがビューにあるとします。

```html+erb
<%= debug @article %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

ここから以下のような出力を得られます。

```yaml
--- !ruby/object Article
attributes:
  updated_at: 2008-09-05 22:55:47
  body: It's a very helpful guide for debugging your Rails app.
  title: Rails debugging guide
  published: t
  id: "1"
  created_at: 2008-09-05 22:55:47
attributes_cache: {}


Title: Rails debugging guide
```

### `to_yaml`

インスタンス変数や、その他のあらゆるオブジェクトやメソッドをYAML形式で表示します。以下のような感じで使用します。

```html+erb
<%= simple_format @article.to_yaml %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

`to_yaml`メソッドは、メソッドをYAML形式に変換して読みやすくし、`simple_format`ヘルパーは出力結果をコンソールのように行ごとに改行します。これが`debug`メソッドのマジックです。

これにより、以下のような結果がビューに表示されます。

```yaml
--- !ruby/object Article
attributes:
updated_at: 2008-09-05 22:55:47
body: It's a very helpful guide for debugging your Rails app.
title: Rails debugging guide
published: t
id: "1"
created_at: 2008-09-05 22:55:47
attributes_cache: {}

Title: Rails debugging guide
```

### `inspect`

オブジェクトの値を表示するのに便利なメソッドとして`inspect`も利用できます。特に、配列やハッシュを扱うときに便利です。このメソッドはオブジェクトの値を文字列として出力します。以下に例を示します。

```html+erb
<%= [1, 2, 3, 4, 5].inspect %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

上のコードから以下の出力を得られます。

```
[1, 2, 3, 4, 5]

Title: Rails debugging guide
```

ロガー
----------

実行時に情報をログに保存できるとさらに便利です。Railsは実行環境ごとに異なるログファイルを出力するようになっています。

### ロガーについて

Railsは`ActiveSupport::Logger`クラスを利用してログ情報を出力します。必要に応じて、`Log4r`など別のロガーに差し替えることもできます。

別のロガーの指定は、`environment.rb`または環境ごとの設定ファイルで行います。

```ruby
Rails.logger = Logger.new(STDOUT)
Rails.logger = Log4r::Logger.new("Application Log")
```

あるいは、`Initializer`セクションに以下の _いずれか_ を追加します。

```ruby
config.logger = Logger.new(STDOUT)
config.logger = Log4r::Logger.new("Application Log")
```

TIP: ログの保存場所は、デフォルトでは`Rails.root/log/`になります。ログのファイル名は、アプリケーションが実行されるときの環境 (development/test/productionなど) が使用されます。

### ログの出力レベル

ログに出力されるメッセージのログレベルが、設定済みのログレベル以上になった場合に、対応するログファイルにそのメッセージが出力されます。現在のログレベルを知りたい場合は、`Rails.logger.level`メソッドを呼び出します。

指定可能なログレベルは`:debug`、`:info`、`:warn`、`:error`、`:fatal`、`:unknown`の6つであり、それぞれ0から5までの数字に対応します。デフォルトのログレベルを変更するには以下のようにします。

```ruby
config.log_level = :warn # 環境ごとのイニシャライザで使用可能
Rails.logger.level = 0 # いつでも使用可能
```

これは、development環境やstating環境ではログを出力し、production環境では不要な情報をログに出力したくない場合などに便利です。

TIP: Railsのデフォルトログレベルは全環境で`debug`です。

### メッセージ送信

コントローラ、モデル、メイラーから現在のログに書き込みたい場合は、`logger.(debug|info|warn|error|fatal)`を使用します。

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
logger.info "Processing the request..."
logger.fatal "Terminating application, raised unrecoverable error!!!"
```

例として、ログに別の情報を追加する機能を装備したメソッドを以下に示します。

```ruby
  class ArticlesController < ApplicationController
  # ...

  def create
    @article = Article.new(params[:article])
    logger.debug "新しい記事: #{@article.attributes.inspect}"
    logger.debug "記事が正しいかどうか: #{@article.valid?}"

    if @article.save
      flash[:notice] =  'Article was successfully created.'
      logger.debug "記事は正常に保存され、ユーザーをリダイレクト中..."
      redirect_to(@article)
    else
      render action: "new"
    end
  end

  # ...
end
```

上のコントローラのアクションを実行すると、以下のようなログが生成されます。

``` 
Processing ArticlesController#create (for 127.0.0.1 at 2008-09-08 11:52:54) [POST]
  Session ID: BAh7BzoMY3NyZl9pZCIlMDY5MWU1M2I1ZDRjODBlMzkyMWI1OTg2NWQyNzViZjYiCmZsYXNoSUM6J0FjdGl
vbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhhc2h7AAY6CkB1c2VkewA=--b18cd92fba90eacf8137e5f6b3b06c4d724596a4
  Parameters: {"commit"=>"Create", "article"=>{"title"=>"Debugging Rails",
"body"=>"I'm learning how to print in logs!!!", "published"=>"0"},
"authenticity_token"=>"2059c1286e93402e389127b1153204e0d1e275dd", "action"=>"create", "controller"=>"articles"}
新しい記事: {"updated_at"=>nil, "title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs!!!",
"published"=>false, "created_at"=>nil}
記事が正しいかどうか: true
  Article Create (0.000443)   INSERT INTO "articles" ("updated_at", "title", "body", "published",
"created_at") VALUES('2008-09-08 14:52:54', 'Debugging Rails',
'I''m learning how to print in logs!!!', 'f', '2008-09-08 14:52:54')
記事は正常に保存され、ユーザーをリダイレクト中...
Redirected to # Article:0x20af760>
Completed in 0.01224 (81 reqs/sec) | DB: 0.00044 (3%) | 302 Found [http://localhost/articles]
```

このようにログに独自の情報を追加すると、予想外の異常な動作をログで見つけやすくなります。ログに独自の情報を追加する場合は、productionログが意味のない大量のメッセージでうずまることのないよう、適切なログレベルを使用するようにしてください。

### タグ付きログの出力

ユーザーとアカウントを多数使用するアプリケーションを実行するときに、何らかのカスタムルールを設定してログをフィルタできると便利です。Active Supportの`TaggedLogging`を使用すれば、サブドメインやリクエストIDなどを指定してログを絞り込むことができ、このようなアプリケーションのデバッグがはかどります。

```ruby
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged("BCX") { logger.info "Stuff" }                            # Logs "[BCX] Stuff"
logger.tagged("BCX", "Jason") { logger.info "Stuff" }                   # Logs "[BCX] [Jason] Stuff"
logger.tagged("BCX") { logger.tagged("Jason") { logger.info "Stuff" } } # Logs "[BCX] [Jason] Stuff"
```

### ログがパフォーマンスに与える影響
ログ出力がRailsアプリのパフォーマンスに与える影響は常にわずかです。ログをディスクに保存する場合は特にそうです。ただし、場合によってはそうとは言い切れないことがあります。

ログレベル`:debug`は、`:fatal`と比べてはるかに多くの文字列が評価および(ディスクなどに)出力されるため、パフォーマンスに与える影響がずっと大きくなります。

他にも、以下のように`Logger`の呼び出しを多数実行した場合には落とし穴に注意する必要があります。

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
```

上の例では、たとえログ出力レベルをdebugにしなかった場合でもパフォーマンスが低下します。その理由は、上のコードでは文字列を評価する必要があり、その際に比較的動作が重い`String`オブジェクトのインスタンス化と、実行に時間のかかる変数の式展開 (interpolation) が行われているからです。
したがって、ロガーメソッドに渡すものはブロックの形にしておくことをお勧めします。ブロックとして渡しておけば、ブロックの評価は出力レベルが設定レベル以上になった場合にしか行われない (遅延読み込みなど) ためです。これに従って上のコードを書き直すと以下のようになります。

```ruby
logger.debug {"Person attributes hash: #{@person.attributes.inspect}"}
```

渡したブロックの内容 (ここでは文字列の式展開) は、debug が有効になっている場合にしか評価されません。この方法によるパフォーマンスの改善は、大量のログを出力しているときでないとそれほど実感できないかもしれませんが、それでも採用する価値があります。

`byebug` gemを使用してデバッグする
---------------------------------

コードが期待どおりに動作しない場合は、ログやコンソールに出力して問題を診断することができます。ただし、この方法ではエラー追跡を何度も繰り返さねばならず、根本的な原因を突き止めるには能率がよいとは言えません。
実行中のコードに探りを入れる必要があるのであれば、最も頼りになるのはやはりデバッガーです。

デバッガーは、Railsのソースコードを追うときに、そのコードをどこで開始するのかがを知りたいときにも有用です。アプリケーションへのリクエストをすべてデバッグし、自分が書いたコードからRailsのもっと深いところへダイブする方法を本ガイドから学びましょう。

### 設定

`byebug` gemを使用すると、Railsコードにブレークポイントを設定してステップ実行できます。次を実行するだけでインストールできます。

```bash
$ gem install byebug
```

後はRailsアプリケーション内で`byebug`メソッドを呼び出せばいつでもデバッガーを起動できます。

以下に例を示します。

```ruby
class PeopleController < ApplicationController
  def new
    byebug
　@person = Person.new
  end
end
``` 

### シェル

アプリケーションで`byebug`を呼び出すと、アプリケーションサーバーを実行しているターミナルウィンドウ内のデバッガーシェルで即座にデバッガーが起動し、`(byebug)`というプロンプトが表示されます。
実行しようとしている行の前後のコードがプロンプトの前に表示され、'=>'で現在の行が示されます。以下に例を示します。

``` 
[1, 10] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

ブラウザからのリクエストによってデバッグ行に到達した場合、リクエストしたブラウザのタブ上の処理は、デバッガが終了してリクエストの処理が完全に終了するまで中断します。

以下に例を示します。

```bash
=> Booting WEBrick
=> Rails 5.0.0 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
=> Notice: server is listening on all interfaces (0.0.0.0). Consider using 127.0.0.1 (--binding option)
=> Ctrl-C to shutdown server
[2014-04-11 13:11:47] INFO  WEBrick 1.3.1
[2014-04-11 13:11:47] INFO  ruby 2.1.1 (2014-02-24) [i686-linux]
[2014-04-11 13:11:47] INFO  WEBrick::HTTPServer#start: pid=6370 port=3000


Started GET "/" for 127.0.0.1 at 2014-04-11 13:11:48 +0200
  ActiveRecord::SchemaMigration Load (0.2ms)  SELECT "schema_migrations".* FROM "schema_migrations"
Processing by ArticlesController#index as HTML

[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

それではアプリケーションの奥深くにダイブしてみましょう。まずはデバッガーのヘルプを表示してみるのがよいでしょう。`help`と入力します。

``` 
(byebug) help

byebug 2.7.0

Type 'help <command-name>' for help on a specific command

Available commands:
backtrace  delete   enable  help       list    pry next  restart  source     up
break      disable  eval    info       method  ps        save     step       var
catch      display  exit    interrupt  next    putl      set      thread
condition  down     finish  irb        p       quit      show     trace
continue   edit     frame   kill       pp      reload    skip     undisplay
```

TIP: 個別のコマンドのヘルプを表示するには、デバッガーのプロンプトで`help <コマンド名>`と入力します。（例: _`help list`_）デバッグ用コマンドは、他のコマンドと区別できる程度に短縮できます。たとえば`list`コマンドの代わりに`l`と入力することもできます。

前の10行を表示するには、`list-` (または `l-`) と入力します。

```
(byebug) l-

[1, 10] in /PathTo/project/app/controllers/articles_controller.rb
   1  class ArticlesController < ApplicationController
   2    before_action :set_article, only: [:show, :edit, :update, :destroy]
   3
   4    # GET /articles
   5    # GET /articles.json
   6    def index
   7      byebug
   8      @articles = Article.find_recent
   9
   10      respond_to do |format|

```

上に示したように、該当のファイルに移動して、`byebug`呼び出しを追加した行の前を表示できます。最後に、`list=`と入力して現在の位置を再び表示してみましょう。

```
(byebug) list=

[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

### コンテキスト

アプリケーションのデバッグ中は、通常と異なる「コンテキスト」に置かれます。具体的には、スタックの別の部分を通って進むコンテキストです。

デバッガーは、停止位置やイベントに到達するときに「コンテキスト」を作成します。作成されたコンテキストには、中断しているプログラムに関する情報が含まれており、デバッガーはこの情報を使用して、フレームスタックの検査やデバッグ中のプログラムにおける変数の評価を行います。また、デバッグ中のプログラムが停止している位置の情報もコンテキストに含まれます。

`backtrace`コマンド (またはそのエイリアスである`where`コマンド) を使用すれば、いつでもアプリケーションのバックトレースを出力できます。これは、コードのその位置に至るまでの経過を知るうえで非常に便利です。コードのある行にたどりついたとき、その経緯を知りたければ`backtrace`でわかります。

```
(byebug) where
--> #0  ArticlesController.index
      at /PathTo/project/test_app/app/controllers/articles_controller.rb:8
    #1  ActionController::ImplicitRender.send_action(method#String, *args#Array)
      at /PathToGems/actionpack-5.0.0/lib/action_controller/metal/implicit_render.rb:4
    #2  AbstractController::Base.process_action(action#NilClass, *args#Array)
      at /PathToGems/actionpack-5.0.0/lib/abstract_controller/base.rb:189
    #3  ActionController::Rendering.process_action(action#NilClass, *args#NilClass)
      at /PathToGems/actionpack-5.0.0/lib/action_controller/metal/rendering.rb:10
...
```

現在のフレームは`-->`で示されます。`frame `_n_コマンド (_n_はフレーム番号) を使用すれば、トレース内のどのコンテキストにも自由に移動できます。このコマンドを実行すると、`byebug`は新しいコンテキストを表示します。

```
(byebug) frame 2

[184, 193] in /PathToGems/actionpack-5.0.0/lib/abstract_controller/base.rb
   184:       # is the intended way to override action dispatching.
   185:       #
   186:       # Notice that the first argument is the method to be dispatched
   187:       # which is *not* necessarily the same as the action name.
   188:       def process_action(method_name, *args)
=> 189:         send_action(method_name, *args)
   190:       end
   191:
   192:       # Actually call the method associated with the action. Override
   193:       # this method if you wish to change how action methods are called,

(byebug)
```

コードを1行ずつ実行していた場合、利用できる変数は同一です。つまり、これこそがデバッグという作業です。

`up [n]` (短縮形の`u`も可) コマンドや`down [n]`コマンドを使用して、スタックを _n_ フレーム上または下に移動し、コンテキストを切り替えることもできます。upはスタックフレーム番号の大きい方に進み、downは小さい方に進みます。

### スレッド

デバッガーで`thread`(短縮形は`th`) コマンドを使用すると、スレッド実行中にスレッドのリスト表示/停止/再開/切り替えを行えます。このコマンドには以下のささやかなオプションがあります。

* `thread`は現在のスレッドを表示します。
* `thread list`はすべてのスレッドのリストをステータス付きで表示します。現在実行中のスレッドは「+」記号と数字で示されます。
* `thread stop `_n_ はスレッド _n_ を停止します。
* `thread resume `_n_ はスレッド _n_ を再開します。
* `thread switch `_n_ は現在のスレッドコンテキストを _n_ に切り替えます。

このコマンドは他の場合にも非常に便利です。同時実行スレッドのデバッグ中に、競合状態が発生していないかどうかを確認する必要がある場合にも使えます。

### 変数の検査

すべての式は、現在のコンテキストで評価されます。式を評価するには、単にその式を入力します。

次の例では、現在のコンテキスト内で定義されたインスタンス変数を出力する方法を示しています。

```
[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug) instance_variables
[:@_action_has_layout, :@_routes, :@_headers, :@_status, :@_request, :@_response, :@_env, :@_prefixes, :@_lookup_context, :@_action_name, :@_response_body, :@marked_for_same_origin_verification, :@_config]
```

見ての通り、コントローラからアクセスできるすべての変数が表示されています。表示される変数リストは、コードの実行に伴って動的に更新されます。
たとえば、`next`コマンドで次の行に進んだとします (このコマンドの詳細については後述します)。

```
(byebug) next
[5, 14] in /PathTo/project/app/controllers/articles_controller.rb
   5     # GET /articles.json
   6     def index
   7       byebug
   8       @articles = Article.find_recent
   9
=> 10       respond_to do |format|
   11         format.html # index.html.erb
   12        format.json { render json: @articles }
   13      end
   14    end
   15
(byebug)
```

それではinstance_variablesをもう一度調べてみましょう。

```
(byebug) instance_variables.include? "@articles"
true
```

定義行が実行されたことによって、今度は`@articles`もインスタンス変数に表示されます。

TIP: `irb`コマンドを使用することで、**irb**モードで実行できます。
これにより、呼び出し中のコンテキスト内でirbセッションが開始されます。ただし、この機能はまだ実験中の段階です。

変数と値のリストを表示するのに便利なのは何と言っても`var`メソッドでしょう。
`byebug`でこのメソッドを使ってみましょう。

```
(byebug) help var
v[ar] cl[ass]                   show class variables of self
v[ar] const <object>            show constants of object
v[ar] g[lobal]                  show global variables
v[ar] i[nstance] <object>       show instance variables of object
v[ar] l[ocal]                   show local variables
```

このメソッドは、現在のコンテキストでの変数の値を検査するのにうってつけの方法です。たとえば、現時点でローカル変数が何も定義されていないことを確認してみましょう。

```
(byebug) var local
(byebug)
```

以下の方法でオブジェクトのメソッドを検査することもできます。

```
(byebug) var instance Article.new
@_start_transaction_state = {}
@aggregation_cache = {}
@association_cache = {}
@attributes = {"id"=>nil, "created_at"=>nil, "updated_at"=>nil}
@attributes_cache = {}
@changed_attributes = nil
...
```

TIP: `p` (print) コマンドとa`pp` (pretty print) コマンドを使用して
Rubyの式を評価し、変数の値をコンソールに出力することができます。

`display`コマンドを使用して変数をウォッチすることもできます。これは、デバッガーで実行を進めながら変数の値の移り変わりを追跡するのに大変便利です。

```
(byebug) display @articles
1: @articles = nil
```

スタック内で移動するたびに、そのときの変数と値のリストが出力されます。変数の表示を止めるには、`undisplay `_n_ (_n_ は変数番号) を実行します。上の例では変数番号は 1 になっています。

### ステップ実行

これで、トレース実行中に現在の実行位置を確認し、利用可能な変数をいつでも確認できるようになりました。アプリケーションの実行について引き続き学んでみましょう。

`step`コマンド (短縮形は`s`) を使用すると、プログラムの実行を継続し、次の論理的な停止行まで進んだらデバッガーに制御を返します。

`step`とよく似た`next`を使用することももちろんできますが、`next`はそのコードの行に関数やメソッドがあっても止まらずにそれらの関数やメソッドを実行してしまう点が異なります。

TIP: `step n`や`next n`と入力することで、`n`ステップずつ進めることもできます。

`next`と`step`の違いは次のとおりです。`step`は次のコード行を実行したらそこで止まるので、常に一度に1行だけを実行します。`next`はメソッドがあってもその中に潜らずに次の行に進みます。

たとえば、次のような状況を考えてみましょう

```ruby
Started GET "/" for 127.0.0.1 at 2014-04-11 13:39:23 +0200
Processing by ArticlesController#index as HTML

[1, 8] in /home/davidr/Proyectos/test_app/app/models/article.rb
   1: class Article < ActiveRecord::Base
   2:
   3:   def self.find_recent(limit = 10)
   4:     byebug
=> 5:     where('created_at > ?', 1.week.ago).limit(limit)
   6:   end
   7:
   8: end

(byebug)
```

`next`を使用していて、メソッド呼び出しに潜ってみたいとしましょう。しかしbyebugは、潜る代わりに単に同じコンテキストの次の行に進みます。この例の場合、次の行とはそのメソッドの最終行になります。従って、`byebug`は前のフレームにある次の次の行にジャンプします。

```
(byebug) next
前のフレームの実行が完了するので、Nextによって1つ上のフレームに移動する

[4, 13] in /PathTo/project/test_app/app/controllers/articles_controller.rb
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     @articles = Article.find_recent
    8:
=>  9:     respond_to do |format|
   10:       format.html # index.html.erb
   11:       format.json { render json: @articles }
   12:     end
   13:   end

(byebug)
```

同じ状況で`step`を使用すると、文字通り「Rubyコードの、実行すべき次の行」に進みます。ここではactivesupportの`week`メソッドに潜って進むことになります。

```
(byebug) step

[50, 59] in /PathToGems/activesupport-5.0.0/lib/active_support/core_ext/numeric/time.rb
   50:     ActiveSupport::Duration.new(self * 24.hours, [[:days, self]])
   51:   end
   52:   alias :day :days
   53:
   54:   def weeks
=> 55:     ActiveSupport::Duration.new(self * 7.days, [[:days, self * 7]])
   56:   end
   57:   alias :week :weeks
   58:
   59:   def fortnights

(byebug)
```

これは自分のコードの、ひいてはRuby on Railsのバグを見つけ出す方法として非常に優れています。

### ブレークポイント

ブレークポイントとは、アプリケーションの実行がプログラムの特定の場所に達した時に停止する位置を指します。そしてその場所でデバッガーシェルが起動します。

`break` (または`b`) コマンドを使用してブレークポイントを動的に追加できます。
手動でブレークポイントを追加する方法は次の 3 とおりです。

* `break line`: 現在のソースファイルの _line_ で示した行にブレークポイントを設定します。
* `break file:line [if expression]`: _file_ ファイルの _line_ 行目にブレークポイントを設定します。_expression_ が与えられた場合、デバッガを起動するにはこれが _true_ と評価される必要があります。
* `break class(.|\#)method [if expression]`: _class_ クラスに定義されている _method_ メソッドにブレークポイントを設定します (「.」と「\#」はそれぞれクラスとインスタンスメソッドを指す)。_expression_の動作はfile:lineの場合と同じです。


さっきと同じ状況を例に説明します。

```
[4, 13] in /PathTo/project/app/controllers/articles_controller.rb
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     @articles = Article.find_recent
    8:
=>  9:     respond_to do |format|
   10:       format.html # index.html.erb
   11:       format.json { render json: @articles }
   12:     end
   13:   end

(byebug) break 11
Created breakpoint 1 at /PathTo/project/app/controllers/articles_controller.rb:11

```

Use `info breakpoints _n_` or `info break _n_` to list breakpoints. If you supply a number, it lists that breakpoint. Otherwise it lists all breakpoints.

``` 
(byebug) info breakpoints
Num Enb What
1   y   at /PathTo/project/app/controllers/articles_controller.rb:11
``` 

To delete breakpoints: use the command `delete _n_` to remove the breakpoint number _n_. If no number is specified, it deletes all breakpoints that are currently active.

``` 
(byebug) delete 1
(byebug) info breakpoints
No breakpoints.
``` 

You can also enable or disable breakpoints:

* `enable breakpoints`: allow a _breakpoints_ list or all of them if no list is specified, to stop your program. This is the default state when you create a breakpoint.
* `disable breakpoints`: the _breakpoints_ will have no effect on your program.

### Catching Exceptions

The command `catch exception-name` (or just `cat exception-name`) can be used to intercept an exception of type _exception-name_ when there would otherwise be no handler for it.

To list all active catchpoints use `catch`.

### Resuming Execution

There are two ways to resume execution of an application that is stopped in the debugger:

* `continue` [line-specification] \(or `c`): resume program execution, at the address where your script last stopped; any breakpoints set at that address are bypassed. The optional argument line-specification allows you to specify a line number to set a one-time breakpoint which is deleted when that breakpoint is reached.
* `finish` [frame-number] \(or `fin`): execute until the selected stack frame returns. If no frame number is given, the application will run until the currently selected frame returns. The currently selected frame starts out the most-recent frame or 0 if no frame positioning (e.g up, down or frame) has been performed. If a frame number is given it will run until the specified frame returns.

### Editing

Two commands allow you to open code from the debugger into an editor:

* `edit [file:line]`: edit _file_ using the editor specified by the EDITOR environment variable. A specific _line_ can also be given.

### Quitting

To exit the debugger, use the `quit` command (abbreviated `q`), or its alias `exit`.

A simple quit tries to terminate all threads in effect. Therefore your server will be stopped and you will have to start it again.

### Settings

`byebug` has a few available options to tweak its behaviour:

* `set autoreload`: Reload source code when changed (defaults: true).
* `set autolist`: Execute `list` command on every breakpoint (defaults: true).
* `set listsize _n_`: Set number of source lines to list by default to _n_ (defaults: 10)
* `set forcestep`: Make sure the `next` and `step` commands always move to a new line.

You can see the full list by using `help set`. Use `help set _subcommand_` to learn about a particular `set` command.

TIP: You can save these settings in an `.byebugrc` file in your home directory.
The debugger reads these global settings when it starts. 以下に例を示します。

```bash
set forcestep
set listsize 25
``` 

Debugging with the `web-console` gem
------------------------------------

Web Console is a bit like `byebug`, but it runs in the browser. In any page you are developing, you can request a console in the context of a view or a controller. The console would be rendered next to your HTML content.

### Console

Inside any controller action or view, you can then invoke the console by calling the `console` method.

For example, in a controller:

```ruby
class PostsController < ApplicationController
  def new
    console
    @post = Post.new
  end
end
``` 

Or in a view:

```html+erb
<% console %>

<h2>New Post</h2>
``` 

This will render a console inside your view. You don't need to care about the location of the `console` call; it won't be rendered on the spot of its invocation but next to your HTML content.

The console executes pure Ruby code. You can define and instantiate custom classes, create new models and inspect variables.

NOTE: Only one console can be rendered per request. Otherwise `web-console` will raise an error on the second `console` invocation.

### Inspecting Variables

You can invoke `instance_variables` to list all the instance variables available in your context. If you want to list all the local variables, you can do that with `local_variables`.

### Settings

* `config.web_console.whitelisted_ips`: Authorized list of IPv4 or IPv6 addresses and networks (defaults: `127.0.0.1/8, ::1`).
* `config.web_console.whiny_requests`: Log a message when a console rendering is prevented (defaults: `true`).

Since `web-console` evaluates plain Ruby code remotely on the server, don't try to use it in production.

Debugging Memory Leaks
----------------------

A Ruby application (on Rails or not), can leak memory - either in the Ruby code or at the C code level.

In this section, you will learn how to find and fix such leaks by using tool such as Valgrind.

### Valgrind

[Valgrind](http://valgrind.org/) is a Linux-only application for detecting C-based memory leaks and race conditions.

There are Valgrind tools that can automatically detect many memory management and threading bugs, and profile your programs in detail. For example, if a C extension in the interpreter calls `malloc()` but doesn't properly call `free()`, this memory won't be available until the app terminates.

For further information on how to install Valgrind and use with Ruby, refer to [Valgrind and Ruby](http://blog.evanweaver.com/articles/2008/02/05/valgrind-and-ruby/) by Evan Weaver.

Plugins for Debugging
---------------------

There are some Rails plugins to help you to find errors and debug your application. Here is a list of useful plugins for debugging:

* [Footnotes](https://github.com/josevalim/rails-footnotes) Every Rails page has footnotes that give request information and link back to your source via TextMate.
* [Query Trace](https://github.com/ruckus/active-record-query-trace/tree/master) Adds query origin tracing to your logs.
* [Query Reviewer](https://github.com/nesquena/query_reviewer) This rails plugin not only runs "EXPLAIN" before each of your select queries in development, but provides a small DIV in the rendered output of each page with the summary of warnings for each query that it analyzed.
* [Exception Notifier](https://github.com/smartinez87/exception_notification/tree/master) Provides a mailer object and a default set of templates for sending email notifications when errors occur in a Rails application.
* [Better Errors](https://github.com/charliesome/better_errors) Replaces the standard Rails error page with a new one containing more contextual information, like source code and variable inspection.
* [RailsPanel](https://github.com/dejan/rails_panel) Chrome extension for Rails development that will end your tailing of development.log. Have all information about your Rails app requests in the browser - in the Developer Tools panel.
Provides insight to db/rendering/total times, parameter list, rendered views and more.

参考資料
----------

* [ruby-debug Homepage](http://bashdb.sourceforge.net/ruby-debug/home-page.html)
* [debugger Homepage](https://github.com/cldwalker/debugger)
* [byebug Homepage](https://github.com/deivid-rodriguez/byebug)
* [web-console Homepage](https://github.com/rails/web-console)
* [Article: Debugging a Rails application with ruby-debug](http://www.sitepoint.com/debug-rails-app-ruby-debug/)
* [Ryan Bates' debugging ruby (revised) screencast](http://railscasts.com/episodes/54-debugging-ruby-revised)
* [Ryan Bates' stack trace screencast](http://railscasts.com/episodes/24-the-stack-trace)
* [Ryan Bates' logger screencast](http://railscasts.com/episodes/56-the-logger)
* [Debugging with ruby-debug](http://bashdb.sourceforge.net/ruby-debug.html)