
ビューのレイアウトとレンダリング
==============================

本ガイドでは、Action ControllerとAction Viewによる基本的なレイアウト機能について解説します。

このガイドの内容:

* Railsに組み込まれているさまざまなレンダリング (=レスポンスの出力) 方法の使い方
* コンテンツが複数のセクションからなるレイアウト作成法
* パーシャルを使用してビューをDRYにする方法
* レイアウトをネストする方法 (サブテンプレート)

--------------------------------------------------------------------------------

概要: 部品を組み上げる
-------------------------------------

本ガイドでは、コントローラ、ビュー、モデルによって形成される三角形のうち、コントローラとビューの間でのやりとりを中心に扱います。御存じのように、Railsのコントローラはリクエストを扱うプロセス全体の流れを組織的に調整する責任を負い、(ビジネスロジックのような) 重い処理はモデルの方で行なわせるのが普通ですモデル側での処理が完了し、ユーザーに結果を表示する時がきたら、コントローラは処理結果をビューに渡します。このときの、コントローラからビューへの結果の渡し方こそが本ガイドの主なトピックです。

大きな流れとしては、ユーザーへのレスポンスとして送信すべき内容を決定することと、ユーザーへのレスポンスを作成するために適切なメソッドを呼び出すこともこの作業に含まれます。ユーザーに返すレスポンス画面を完全なビューにするのであれば、Railsはそのビューをさらに別のレイアウトでラッピングし、パーシャルビューとして取り出すでしょう。以後本ガイドではこれらの方法をすべて紹介します。

レスポンスを作成する
------------------

コントローラ側から見ると、HTTPレスポンスの作成方法は以下の3とおりあります。

* `render`を呼び出し、ブラウザに返す完全なレスポンスを作成する
* `redirect_to`を呼び出し、HTTPリダイレクトコードステータスをブラウザに送信する
* `head`を呼び出し、HTTPヘッダーのみで構成されたレスポンスを作成してブラウザに送信する

### デフォルトの出力: アクションにおける「設定より規約」

Railsでは「設定より規約 (CoC: convention over configuration)」というポリシーが推奨されていることをご存じかと思います。デフォルトの出力結果は、CoCのよい例でもあります。Railsのコントローラは、デフォルトでは正しいルーティングに対応する名前を持つビューを自動的に選び、それを使用してレスポンスを出力します。たとえば、`BooksController`というコントローラに以下のコードがあるとします。

```ruby
class BooksController < ApplicationController
end
```

ルーティングファイルに以下が記載されているとします。

```ruby
  resources :books
```

`app/views/books/index.html.erb`ビューファイルの内容が以下のようになっているとします。

```html+erb
<h1>Books are coming soon!</h1>
```

以上のようにすることで、ユーザーがブラウザで`/books`にアクセスすると、Railsは自動的に`app/views/books/index.html.erb`ビューを使用してレスポンスを出力し、その結果「Books are coming soon!」という文字が画面に表示されます。

しかしこの画面だけではほとんど実用性がないので、`Book`モデルを作成し、`BooksController`にindexアクションを追加してみましょう。

```ruby
class BooksController < ApplicationController
  def index
    @books = Book.all
  end
end
```

上のコードでご注目いただきたいのは、「設定より規約」の原則が利いているおかげでindexアクションの最後で明示的に画面出力を指示する必要がないという点です。ここでの原則は、「コントローラのアクションの最終部分で明示的な画面出力が指示されていない場合は、コントローラが使用できるビューのパスから`アクション名.html.erb`というビューテンプレートを探し、それを使用して自動的に出力する」というものです。従って、この場合は`app/views/books/index.html.erb`ファイルが出力されます。

ビューですべての本の属性を表示したい場合は、以下のようにERBを書くことができます。

```html+erb
<h1>Listing Books</h1>

<table>
  <tr>
    <th>Title</th>
    <th>Summary</th>
    <th></th>
    <th></th>
    <th></th>
  </tr>

<% @books.each do |book| %>
  <tr>
    <td><%= book.title %></td>
    <td><%= book.content %></td>
    <td><%= link_to "Show", book %></td>
    <td><%= link_to "Edit", edit_book_path(book) %></td>
    <td><%= link_to "Remove", book, method: :delete, data: { confirm: "Are you sure?" } %></td>
  </tr>
<% end %>
</table>

<br>

<%= link_to "New book", new_book_path %>
```

メモ: 実際のレンダリングは、`ActionView::TemplateHandlers`のサブクラスで行われます。本ガイドではレンダリングの詳細については触れませんが、テンプレートハンドラの選択がビューテンプレートファイルの拡張子によって制御されているという重要な点は理解しておいてください。Rails 2以降におけるビューテンプレートの標準拡張子は、ERB (HTML + eMbedded RuBy) でレンダリングする場合は`.erb`、Builder (XMLジェネレータ) でレンダリングする場合は`.builder`です。

### `render`を使用する

アプリケーションがブラウザで表示するコンテンツのレンダリング (出力) という力仕事は、`ActionController::Base#render`メソッドがほぼ一手に引き受けています。`render`メソッドはさまざまな方法でカスタマイズできます。Railsテンプレートのデフォルトビューを出力することもできますし、特定のテンプレート、ファイル、インラインコードを指定して出力したり、何も出力しないこともできます。テキスト、JSON、XMLを出力することもできます。出力されるレスポンスのcontent typeやHTTPステータスを指定することもできます。

ヒント: 出力結果をブラウザで表示して調べることなく、`render`呼び出しの正確な結果を取得したい場合は、`render_to_string`を呼び出すことができます。このメソッドの動作は`render`と完全に同じであり、出力結果をブラウザに返さずに文字列を返す点だけが異なります。

#### 何も出力しない方法

`render`メソッドでできる最も単純な動作は、何も出力しないことでしょう。

```ruby
render nothing: true
```

このレスポンスをcurlコマンドを使用して調べてみると以下のようになっています。

```bash
$ curl -i 127.0.0.1:3000/books
HTTP/1.1 200 OK
Connection: close
Date: Sun, 24 Jan 2010 09:25:18 GMT
Transfer-Encoding: chunked
Content-Type: */*; charset=utf-8
X-Runtime: 0.014297
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache

$
```

レスポンスの内容は空欄になっています (`Cache-Control`行以降にデータがない) が、ステータスコートが200 OKになっているのでリクエストが成功していることがわかります。renderメソッドの`:status`オプションを設定することでレスポンスを変更できます。何も出力しないというレスポンスは、Ajaxリクエストを使用する時に便利です。これを使用することで、リクエストが成功したという確認応答だけをブラウザに送り返すことができるからです。

ヒント: 200 OKヘッダーだけを送信したいのであれば、ここでご紹介した`render :nothing`よりも、本ガイドで後述する`head`メソッドを使用する方がおそらくよいでしょう。`head`メソッドは`render :nothing`よりも柔軟性が高く、HTTPヘッダーだけを生成していることが明確になるからです。

#### Action Viewを出力する

同じコントローラで、デフォルトと異なるテンプレートに対応するビューを出力したい場合は、`render`メソッドでビュー名を指定することができます。

```ruby
  def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render "edit"
  end
end
```

上の`update`アクションでモデルに対する`update`メソッドの呼び出しが失敗すると、同じコントローラに用意しておいた別の`edit.html.erb`テンプレートを使用して出力します。

出力するアクションを指定するには、文字列の他にシンボルを使用することもできます。

```ruby
  def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render :edit
  end
end
```

#### 別のコントローラからアクションのテンプレートを出力する

あるコントローラのアクションから、まったく別のコントローラの配下にあるテンプレートを使用して出力することは可能でしょうか。これも`render`メソッドだけで行なうことができます。`render`メソッドには`app/views`を起点とするフルパスを渡すことができますので、出力したいテンプレートをフルパスで指定します。たとえば、`app/controllers/admin`に置かれている`AdminProducts`コントローラのコードを実行しているとすると、`app/views/products`に置かれているビューテンプレートに対するアクションの実行結果を出力するには以下のようにします。

```ruby
render "products/show"
```

パスにスラッシュ`/`が含まれていると、Railsによってこのビューは異なるコントローラの配下にあると認識されます。異なるコントローラのテンプレートを指定していることをより明示的にしたい場合は、以下のように`:template`オプションを使用することもできます (Rails 2.2以前ではこのオプションは必須でした)。

```ruby
render template: "products/show"
```

#### 任意のファイルを使用して出力する

`render`メソッドで指定するビューは、現在のアプリケーションディレクトリの外部にあっても構いません (2つのRailsアプリケーションでビューを共有しているなどの場合)。

```ruby
render "/u/apps/warehouse_app/current/app/views/products/show"
```

パスがスラッシュ`/`で始まっている場合、Railsはこのコードがファイルの出力であると認識します。ファイルを出力することをより明示的にしたい場合は、以下のように`:file`オプションを使用することもできます (Rails 2.2以前ではこのオプションは必須でした)。

```ruby
render file: "/u/apps/warehouse_app/current/app/views/products/show"
```

`:file`オプションに与えるパスは、ファイルシステムの絶対パスです。当然ながら、コンテンツを出力したいファイルに対して適切なアクセス権が与えられている必要があります。

メモ: ファイルを出力する場合、デフォルトでは現在のレイアウトが適用されません。ファイルの出力を現在のレイアウト内で行いたい場合は、`layout: true`オプションを追加する必要があります。

ヒント: Microsoft Windows上でRailsを実行している場合、ファイルを出力する際に`:file`オプションを省略できません。Windowsのファイル名フォーマットはUnixのファイル名と同じではないためです。

#### まとめ

これまでご紹介した3とおりの出力方法 (コントローラ内の別テンプレートを使用、べコントローラのテンプレートを使用、ファイルシステム上の任意のファイルを使用) は、実際には同一のアクションのバリエーションにすぎません。

実のところ、たとえばBooksControllerクラスのupdateアクション内で、本の更新に失敗したらeditテンプレートを出力したいとすると、以下のどのレンダリング呼び出しを行っても最終的には必ず`views/books`ディレクトリの`edit.html.erb`を使用して出力が行われます。

```ruby
render :edit
render action: :edit
render "edit"
render "edit.html.erb"
render action: "edit"
render action: "edit.html.erb"
render "books/edit"
render "books/edit.html.erb"
render template: "books/edit"
render template: "books/edit.html.erb"
render "/path/to/rails/app/views/books/edit"
render "/path/to/rails/app/views/books/edit.html.erb"
render file: "/path/to/rails/app/views/books/edit"
render file: "/path/to/rails/app/views/books/edit.html.erb"
```

どの呼び出しを使用するかはコーディングのスタイルと規則の問題でしかありませんが、経験上なるべくシンプルな記法を使用する方がコードがわかりやすくなるでしょう。

#### `render`で`:inline`オプションを使用する

`render`メソッドは、メソッド呼び出しの際に`:inline`オプションを使用してERBを与えると、ビューがまったくない状態でも実行することができます。これは完全に有効な方法です。

```ruby
render inline: "<% products.each do |p| %><p><%= p.name %></p><% end %>"
```

警告: このオプションを実際に使用する意味はほぼないと思われます。コントローラのコードにERBを混在させると、RailsのMVC指向が崩されるだけでなく、開発者がプロジェクトのロジックを追いかけることが困難になってしまいます。通常のERBビューを使用してください。

インラインでは、デフォルトでERBを使用して出力を行います。`:type`オプションで:builderを指定すると、ERBに代えてBuilderが使用されます。

```ruby
render inline: "xml.p {'Horrid coding practice!'}", type: :builder
```

#### テキストを出力する

`render`で`:plain`オプションを使用すると、平文テキストをマークアップせずにブラウザに送信することができます。

```ruby
render plain: "OK"
```

ヒント: 平文テキストの出力は、AjaxやWebサービスリクエストに応答するときに最も有用です。これらではHTML以外の応答を期待しています。

メモ: デフォルトでは、`:plain`オプションを使用すると出力結果に現在のレイアウトが適用されません。テキストの出力を現在のレイアウト内で行いたい場合は、`layout: true`オプションを追加する必要があります。

#### HTMLを出力する

`render`で`:html`オプションを使用すると、HTML文字列を直接ブラウザに送信することができます。

```ruby 
render html: "<strong>Not Found</strong>".html_safe
```

ヒント: この手法は、HTMLコードのごく小規模なスニペットを出力したい場合に便利です。
スニペットのマークアップが複雑になるようであれば、早めにテンプレートファイルに移行することをご検討ください。

メモ: このオプションを使用すると、文字列が「HTML safe」でない場合にHTML要素をエスケープします。

#### JSONを出力する

JSONはJavaScriptのデータ形式の一種で、多くのAjaxライブラリで使用されています。Railsでは、オブジェクトからJSON形式への変換と、変換されたJSONをブラウザに送信する機能がビルトインでサポートされています。

```ruby
render json: @product
```

ヒント: 出力するオブジェクトに対して`to_json`を呼び出す必要はありません。`:json`オプションが指定されていれば、`render`によって`to_json`が自動的に呼び出されるようになっています。

#### XMLを出力する

Railsでは、オブジェクトからXML形式への変換と、変換されたXMLをブラウザに送信する機能がビルトインでサポートされています。

```ruby
render xml: @product
```

ヒント: 出力するオブジェクトに対して`to_xml`を呼び出す必要はありません。`:xml`オプションが指定されていれば、`render`によって`to_xml`が自動的に呼び出されるようになっています。

#### Vanilla JavaScriptを出力する

Railsはvanilla JavaScriptを出力することもできます。

```ruby
render js: "alert('Hello Rails');"
```

上のコードは、引数で与えられた文字列をMIMEタイプ`text/javascript`でブラウザに送信します。

#### 生のコンテンツを出力する

`render`で`:body`オプションを指定することで、content typeを一切指定しない生のコンテンツをブラウザに送信することができます。

```ruby
render body: "raw"
```

ヒント: このオプションを使用するのは、レスポンスのcontent typeがどんなものであってもよい場合のみにしてください。ほとんどの場合、`:plain`や`:html`などを使用する方が適切です。

メモ: このオプションを使用してブラウザに送信されるレスポンスは、上書きされない限り`text/html`が使用されます。これはAction Dispatchによるレスポンスのデフォルトのcontent typeであるためです。

#### `render`のオプション

`render`メソッドに対する呼び出しでは、一般に以下の4つのオプションが使用できます。

* `:content_type`
* `:layout`
* `:location`
* `:status`

##### `:content_type`オプション

Railsがデフォルトで出力する結果のMIME content-typeは、デフォルトで`text/html`になります (ただし`:json`を指定した場合には`application/json`、`:xml`を使用した場合は`application/xml`になります)。content-typeを変更したい場合は、`:content_type`オプションを指定します。

```ruby
render file: filename, content_type: "application/rss"
```

##### `:layout`オプション

`render`で指定できるほとんどのオプションでは、出力されるコンテンツは現在のレイアウトの一部としてブラウザ上で表示されます。これより、レイアウトの詳細と利用法について本ガイドで説明します。

`:layout`オプションを指定すると、現在のアクションに対して特定のファイルをレイアウトとして使用します。

```ruby
render layout: "special_layout"
```

出力時にレイアウトをまったく使用しないよう指定することもできます。

```ruby
render layout: false
```

##### `:location`オプション

`:location`を使用することで、HTTPの`Location`ヘッダーを設定できます。

```ruby
render xml: photo, location: photo_url(photo)
```

##### `:status`オプション

Railsが返すレスポンスのHTTPステータスコードは自動的に生成されます (ほとんどの場合`200 OK`となります)。`:status`オプションを使用することで、レスポンスのステータスコードを変更できます。

```ruby
render status: 500
render status: :forbidden
```

ステータスコードは数字で指定する他に、以下に示すシンボルで指定することもできます。

| レスポンスクラス      | HTTPステータスコード | シンボル                           |
| ------------------- | ---------------- | -------------------------------- |
| **Informational**   | 100              | :continue                        |
|                     | 101              | :switching_protocols             |
|                     | 102              | :processing                      |
| **Success**         | 200              | :ok                              |
|                     | 201              | :created                         |
|                     | 202              | :accepted                        |
|                     | 203              | :non_authoritative_information   |
|                     | 204              | :no_content                      |
|                     | 205              | :reset_content                   |
|                     | 206              | :partial_content                 |
|                     | 207              | :multi_status                    |
|                     | 208              | :already_reported                |
|                     | 226              | :im_used                         |
| **Redirection**     | 300              | :multiple_choices                |
|                     | 301              | :moved_permanently               |
|                     | 302              | :found                           |
|                     | 303              | :see_other                       |
|                     | 304              | :not_modified                    |
|                     | 305              | :use_proxy                       |
|                     | 306              | :reserved                        |
|                     | 307              | :temporary_redirect              |
|                     | 308              | :permanent_redirect              |
| **Client Error**    | 400              | :bad_request                     |
|                     | 401              | :unauthorized                    |
|                     | 402              | :payment_required                |
|                     | 403              | :forbidden                       |
|                     | 404              | :not_found                       |
|                     | 405              | :method_not_allowed              |
|                     | 406              | :not_acceptable                  |
|                     | 407              | :proxy_authentication_required   |
|                     | 408              | :request_timeout                 |
|                     | 409              | :conflict                        |
|                     | 410              | :gone                            |
|                     | 411              | :length_required                 |
|                     | 412              | :precondition_failed             |
|                     | 413              | :request_entity_too_large        |
|                     | 414              | :request_uri_too_long            |
|                     | 415              | :unsupported_media_type          |
|                     | 416              | :requested_range_not_satisfiable |
|                     | 417              | :expectation_failed              |
|                     | 422              | :unprocessable_entity            |
|                     | 423              | :locked                          |
|                     | 424              | :failed_dependency               |
|                     | 426              | :upgrade_required                |
|                     | 428              | :precondition_required           |
|                     | 429              | :too_many_requests               |
|                     | 431              | :request_header_fields_too_large |
| **Server Error**    | 500              | :internal_server_error           |
|                     | 501              | :not_implemented                 |
|                     | 502              | :bad_gateway                     |
|                     | 503              | :service_unavailable             |
|                     | 504              | :gateway_timeout                 |
|                     | 505              | :http_version_not_supported      |
|                     | 506              | :variant_also_negotiates         |
|                     | 507              | :insufficient_storage            |
|                     | 508              | :loop_detected                   |
|                     | 510              | :not_extended                    |
|                     | 511              | :network_authentication_required |

#### レイアウトの探索順序

Railsはが現在のレイアウトを探索する場合、最初に現在のコントローラと同じ基本名を持つレイアウトが`app/views/layouts`ディレクトリにあるかどうかを調べます。たとえば、`PhotosController`クラスのアクションから出力するのであれば、`app/views/layouts/photos.html.erb`または`app/views/layouts/photos.builder`を探します。該当のコントローラに属するレイアウトがない場合、`app/views/layouts/application.html.erb`または`app/views/layouts/application.builder`を使用します。`.erb`レイアウトがない場合、`.builder`レイアウトがあればそれを使用します。Railsには、各コントローラやアクションに割り当てる特定のレイアウトをもっと正確に指定する方法がいくつも用意されています。

##### コントローラ用のレイアウトを指定する

`layout`宣言を使用することで、デフォルトのレイアウト名ルールを上書きすることができます。例: 

```ruby
class ProductsController < ApplicationController
  layout "inventory"
  #...
end
```

この宣言によって、`ProductsController`からの出力で使用されるレイアウトは`app/views/layouts/inventory.html.erb`になります。

アプリケーション全体で特定のレイアウトを使用したい場合は、`ApplicationController`クラスで`layout`を宣言します。

```ruby
class ApplicationController < ActionController::Base
  layout "main"
  #...
end
```

この宣言によって、アプリケーションのすべてのビューで使用されるレイアウトは`app/views/layouts/main.html.erb`になります。

##### 実行時にレイアウトを指定する

レイアウトの指定にシンボルを使用することで、リクエストが実際に処理されるときまでレイアウトを確定せず、選択を遅延することができます。

```ruby
class ProductsController < ApplicationController
  layout :products_layout

  def show
    @product = Product.find(params[:id])
  end

  private
    def products_layout
      @current_user.special? ? "special" : "products"
    end

end
```

上のコードは、現在のユーザーが特別なユーザーの場合、そのユーザーが製品ページを見るときに特別なレイアウトを適用します。

レイアウトを決定する際に、Procなどのインラインメソッドを使用することもできます。たとえばProcオブジェクトを渡すと、Procを渡されたブロックには`controller`インスタンスが渡されます。これにより、現在のリクエストを元にしてレイアウトを決定することができます。

```ruby
class ProductsController < ApplicationController
  layout Proc.new { |controller| controller.request.xhr? ? "popup" : "application" }
end
```

##### 条件付きレイアウト

コントローラレベルで指定されたレイアウトでは、`:only`オプションと`:except`オプションがサポートされています。これらのオプションは、単一のメソッド名またはメソッド名の配列を引数として受け取ります。渡すメソッド名はコントローラ内のメソッド名に対応します。

```ruby
class ProductsController < ApplicationController
  layout "product", except: [:index, :rss]
end
```

With this declaration, the `product` layout would be used for everything but the `rss` and `index` methods.

##### Layout Inheritance

Layout declarations cascade downward in the hierarchy, and more specific layout declarations always override more general ones. 例：

* `application_controller.rb`

```ruby 
class ApplicationController < ActionController::Base
      layout "main"
  end
    ```

* `posts_controller.rb`

```ruby 
    class PostsController < ApplicationController
  end
    ```

* `special_posts_controller.rb`

```ruby 
    class SpecialPostsController < PostsController
      layout "special"
  end
    ```

* `old_posts_controller.rb`

```ruby 
    class OldPostsController < SpecialPostsController
      layout false

  def show
        @post = Post.find(params[:id])
  end

  def index
        @old_posts = Post.older
        render layout: "old"
  end
      # ...
  end
    ```

In this application:

* In general, views will be rendered in the `main` layout
* `PostsController#index` will use the `main` layout
* `SpecialPostsController#index` will use the `special` layout
* `OldPostsController#show` will use no layout at all
* `OldPostsController#index` will use the `old` layout

#### Avoiding Double Render Errors

Sooner or later, most Rails developers will see the error message "Can only render or redirect once per action". While this is annoying, it's relatively easy to fix. Usually it happens because of a fundamental misunderstanding of the way that `render` works.

For example, here's some code that will trigger this error:

```ruby 
  def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
  render action: "regular_show"
  end
```

If `@book.special?` evaluates to `true`, Rails will start the rendering process to dump the `@book` variable into the `special_show` view. But this will _not_ stop the rest of the code in the `show` action from running, and when Rails hits the end of the action, it will start to render the `regular_show` view - and throw an error. The solution is simple: make sure that you have only one call to `render` or `redirect` in a single code path. One thing that can help is `and return`. Here's a patched version of the method:

```ruby 
  def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show" and return
  end
  render action: "regular_show"
  end
```

Make sure to use `and return` instead of `&& return` because `&& return` will not work due to the operator precedence in the Ruby Language.

Note that the implicit render done by ActionController detects if `render` has been called, so the following will work without errors:

```ruby 
  def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
  end
```

This will render a book with `special?` set with the `special_show` template, while other books will render with the default `show` template.

### Using `redirect_to`

Another way to handle returning responses to an HTTP request is with `redirect_to`. As you've seen, `render` tells Rails which view (or other asset) to use in constructing a response. The `redirect_to` method does something completely different: it tells the browser to send a new request for a different URL. For example, you could redirect from wherever you are in your code to the index of photos in your application with this call:

```ruby 
redirect_to photos_url
```

You can use `redirect_to` with any arguments that you could use with `link_to` or `url_for`. There's also a special redirect that sends the user back to the page they just came from:

```ruby 
      redirect_to :back
```

#### Getting a Different Redirect Status Code

Rails uses HTTP status code 302, a temporary redirect, when you call `redirect_to`. If you'd like to use a different status code, perhaps 301, a permanent redirect, you can use the `:status` option:

```ruby 
redirect_to photos_path, status: 301
```

Just like the `:status` option for `render`, `:status` for `redirect_to` accepts both numeric and symbolic header designations.

#### The Difference Between `render` and `redirect_to`

Sometimes inexperienced developers think of `redirect_to` as a sort of `goto` command, moving execution from one place to another in your Rails code. This is _not_ correct. Your code stops running and waits for a new request for the browser. It just happens that you've told the browser what request it should make next, by sending back an HTTP 302 status code.

Consider these actions to see the difference:

```ruby 
  def index
  @books = Book.all
  end

  def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    render action: "index"
  end
  end
```

With the code in this form, there will likely be a problem if the `@book` variable is `nil`. Remember, a `render :action` doesn't run any code in the target action, so nothing will set up the `@books` variable that the `index` view will probably require. One way to fix this is to redirect instead of rendering:

```ruby 
  def index
  @books = Book.all
  end

  def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    redirect_to action: :index
  end
  end
```

With this code, the browser will make a fresh request for the index page, the code in the `index` method will run, and all will be well.

The only downside to this code is that it requires a round trip to the browser: the browser requested the show action with `/books/1` and the controller finds that there are no books, so the controller sends out a 302 redirect response to the browser telling it to go to `/books/`, the browser complies and sends a new request back to the controller asking now for the `index` action, the controller then gets all the books in the database and renders the index template, sending it back down to the browser which then shows it on your screen.

While in a small application, this added latency might not be a problem, it is something to think about if response time is a concern. We can demonstrate one way to handle this with a contrived example:

```ruby 
  def index
  @books = Book.all
  end

  def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    @books = Book.all
    flash.now[:alert] = "Your book was not found"
    render "index"
  end
  end
```

This would detect that there are no books with the specified ID, populate the `@books` instance variable with all the books in the model, and then directly render the `index.html.erb` template, returning it to the browser with a flash alert message to tell the user what happened.

### Using `head` To Build Header-Only Responses

The `head` method can be used to send responses with only headers to the browser. It provides a more obvious alternative to calling `render :nothing`. The `head` method accepts a number or symbol (see [reference table](#the-status-option)) representing a HTTP status code. The options argument is interpreted as a hash of header names and values. For example, you can return only an error header:

```ruby 
head :bad_request
```

This would produce the following header:

```
HTTP/1.1 400 Bad Request
Connection: close
Date: Sun, 24 Jan 2010 12:15:53 GMT
Transfer-Encoding: chunked
Content-Type: text/html; charset=utf-8
X-Runtime: 0.013483
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

Or you can use other HTTP headers to convey other information:

```ruby 
head :created, location: photo_path(@photo)
```

Which would produce:

```
HTTP/1.1 201 Created
Connection: close
Date: Sun, 24 Jan 2010 12:16:44 GMT
Transfer-Encoding: chunked
Location: /photos/1
Content-Type: text/html; charset=utf-8
X-Runtime: 0.083496
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

Structuring Layouts
-------------------

When Rails renders a view as a response, it does so by combining the view with the current layout, using the rules for finding the current layout that were covered earlier in this guide. Within a layout, you have access to three tools for combining different bits of output to form the overall response:

* Asset tags
* `yield` and `content_for`
* Partials

### Asset Tag Helpers

Asset tag helpers provide methods for generating HTML that link views to feeds, JavaScript, stylesheets, images, videos and audios. There are six asset tag helpers available in Rails:

* `auto_discovery_link_tag`
* `javascript_include_tag`
{0}<%={/0} {1}stylesheet_link_tag{/1} {2}.{/2}{1}.{/1}{2}.{/2}
* `image_tag`
* `video_tag`
* `audio_tag`

You can use these tags in layouts or other views, although the `auto_discovery_link_tag`, `javascript_include_tag`, and `stylesheet_link_tag`, are most commonly used in the `<head>` section of a layout.

WARNING: The asset tag helpers do _not_ verify the existence of the assets at the specified locations; they simply assume that you know what you're doing and generate the link.

#### Linking to Feeds with the `auto_discovery_link_tag`

The `auto_discovery_link_tag` helper builds HTML that most browsers and feed readers can use to detect the presence of RSS or Atom feeds. It takes the type of the link (`:rss` or `:atom`), a hash of options that are passed through to url_for, and a hash of options for the tag:

    ```erb
<%= auto_discovery_link_tag(:rss, {action: "feed"},
  {title: "RSS Feed"}) %>
```

There are three tag options available for the `auto_discovery_link_tag`:

* `:rel` specifies the `rel` value in the link. The default value is "alternate".
* `:type` specifies an explicit MIME type. Rails will generate an appropriate MIME type automatically.
* `:title` specifies the title of the link. The default value is the uppercase `:type` value, for example, "ATOM" or "RSS".

#### Linking to JavaScript Files with the `javascript_include_tag`

The `javascript_include_tag` helper returns an HTML `script` tag for each source provided.

If you are using Rails with the [Asset Pipeline](asset_pipeline.html) enabled, this helper will generate a link to `/assets/javascripts/` rather than `public/javascripts` which was used in earlier versions of Rails. This link is then served by the asset pipeline.

A JavaScript file within a Rails application or Rails engine goes in one of three locations: `app/assets`, `lib/assets` or `vendor/assets`. These locations are explained in detail in the [Asset Organization section in the Asset Pipeline Guide](asset_pipeline.html#asset-organization)

You can specify a full path relative to the document root, or a URL, if you prefer. For example, to link to a JavaScript file that is inside a directory called `javascripts` inside of one of `app/assets`, `lib/assets` or `vendor/assets`, you would do this:

    ```erb
<%= javascript_include_tag "main" %>
```

Rails will then output a `script` tag such as this:

```html
<script src='/assets/main.js'></script>
```

The request to this asset is then served by the Sprockets gem.

To include multiple files such as `app/assets/javascripts/main.js` and `app/assets/javascripts/columns.js` at the same time:

    ```erb
<%= javascript_include_tag "main", "columns" %>
```

To include `app/assets/javascripts/main.js` and `app/assets/javascripts/photos/columns.js`:

    ```erb
<%= javascript_include_tag "main", "/photos/columns" %>
```

To include `http://example.com/main.js`:

    ```erb
<%= javascript_include_tag "http://example.com/main.js" %>
```

#### Linking to CSS Files with the `stylesheet_link_tag`

The `stylesheet_link_tag` helper returns an HTML `<link>` tag for each source provided.

If you are using Rails with the "Asset Pipeline" enabled, this helper will generate a link to `/assets/stylesheets/`. This link is then processed by the Sprockets gem. A stylesheet file can be stored in one of three locations: `app/assets`, `lib/assets` or `vendor/assets`.

You can specify a full path relative to the document root, or a URL. For example, to link to a stylesheet file that is inside a directory called `stylesheets` inside of one of `app/assets`, `lib/assets` or `vendor/assets`, you would do this:

    ```erb
<%= stylesheet_link_tag "main" %>
```

To include `app/assets/stylesheets/main.css` and `app/assets/stylesheets/columns.css`:

    ```erb
<%= stylesheet_link_tag "main", "columns" %>
```

To include `app/assets/stylesheets/main.css` and `app/assets/stylesheets/photos/columns.css`:

    ```erb
<%= stylesheet_link_tag "main", "photos/columns" %>
```

To include `http://example.com/main.css`:

    ```erb
<%= stylesheet_link_tag "http://example.com/main.css" %>
```

By default, the `stylesheet_link_tag` creates links with `media="screen" rel="stylesheet"`. You can override any of these defaults by specifying an appropriate option (`:media`, `:rel`):

    ```erb
<%= stylesheet_link_tag "main_print", media: "print" %>
```

#### Linking to Images with the `image_tag`

The `image_tag` helper builds an HTML `<img />` tag to the specified file. By default, files are loaded from `public/images`.

WARNING: Note that you must specify the extension of the image.

    ```erb
<%= image_tag "header.png" %>
```

You can supply a path to the image if you like:

    ```erb
<%= image_tag "icons/delete.gif" %>
```

You can supply a hash of additional HTML options:

    ```erb
<%= image_tag "icons/delete.gif", {height: 45} %>
```

You can supply alternate text for the image which will be used if the user has images turned off in their browser. If you do not specify an alt text explicitly, it defaults to the file name of the file, capitalized and with no extension. For example, these two image tags would return the same code:

    ```erb
<%= image_tag "home.gif" %>
<%= image_tag "home.gif", alt: "Home" %>
```

You can also specify a special size tag, in the format "{width}x{height}":

    ```erb
<%= image_tag "home.gif", size: "50x20" %>
```

In addition to the above special tags, you can supply a final hash of standard HTML options, such as `:class`, `:id` or `:name`:

    ```erb
<%= image_tag "home.gif", alt: "Go Home",
                          id: "HomeImage",
                          class: "nav_bar" %>
```

#### Linking to Videos with the `video_tag`

The `video_tag` helper builds an HTML 5 `<video>` tag to the specified file. By default, files are loaded from `public/videos`.

    ```erb
<%= video_tag "movie.ogg" %>
```

Produces

    ```erb
<video src="/videos/movie.ogg" />
```

Like an `image_tag` you can supply a path, either absolute, or relative to the `public/videos` directory. Additionally you can specify the `size: "#{width}x#{height}"` option just like an `image_tag`. Video tags can also have any of the HTML options specified at the end (`id`, `class` et al).

The video tag also supports all of the `<video>` HTML options through the HTML options hash, including:

* `poster: "image_name.png"`, provides an image to put in place of the video before it starts playing.
* `autoplay: true`, starts playing the video on page load.
* `loop: true`, loops the video once it gets to the end.
* `controls: true`, provides browser supplied controls for the user to interact with the video.
* `autobuffer: true`, the video will pre load the file for the user on page load.

You can also specify multiple videos to play by passing an array of videos to the `video_tag`:

    ```erb
<%= video_tag ["trailer.ogg", "movie.ogg"] %>
```

This will produce:

    ```erb
<video><source src="trailer.ogg" /><source src="movie.ogg" /></video>
```

#### Linking to Audio Files with the `audio_tag`

The `audio_tag` helper builds an HTML 5 `<audio>` tag to the specified file. By default, files are loaded from `public/audios`.

    ```erb
<%= audio_tag "music.mp3" %>
```

You can supply a path to the audio file if you like:

    ```erb
<%= audio_tag "music/first_song.mp3" %>
```

You can also supply a hash of additional options, such as `:id`, `:class` etc.

Like the `video_tag`, the `audio_tag` has special options:

* `autoplay: true`, starts playing the audio on page load
* `controls: true`, provides browser supplied controls for the user to interact with the audio.
* `autobuffer: true`, the audio will pre load the file for the user on page load.

### Understanding `yield`

Within the context of a layout, `yield` identifies a section where content from the view should be inserted. The simplest way to use this is to have a single `yield`, into which the entire contents of the view currently being rendered is inserted:

```html+erb
<html>
<head>
</head>
  <body>
{0}<%={/0} {1}yield{/1} {0}%>{/0}
  </body>
</html> 
```

You can also create a layout with multiple yielding regions:

```html+erb
<html>
<head>
  <%= yield :head %>
</head>
  <body>
{0}<%={/0} {1}yield{/1} {0}%>{/0}
  </body>
</html> 
```

The main body of the view will always render into the unnamed `yield`. To render content into a named `yield`, you use the `content_for` method.

### Using the `content_for` Method

The `content_for` method allows you to insert content into a named `yield` block in your layout. For example, this view would work with the layout that you just saw:

```html+erb
<% content_for :head do %>
  <title>A simple page</title>
<% end %>

<p>Hello, Rails!</p>
```

The result of rendering this page into the supplied layout would be this HTML:

```html+erb
<html>
<head>
  <title>A simple page</title>
</head>
  <body>
  <p>Hello, Rails!</p>
{0} {/0}{1}</body>{/1}
</html> 
```

The `content_for` method is very helpful when your layout contains distinct regions such as sidebars and footers that should get their own blocks of content inserted. It's also useful for inserting tags that load page-specific JavaScript or css files into the header of an otherwise generic layout.

### Using Partials

Partial templates - usually just called "partials" - are another device for breaking the rendering process into more manageable chunks. With a partial, you can move the code for rendering a particular piece of a response to its own file.

#### Naming Partials

To render a partial as part of a view, you use the `render` method within the view:

```ruby 
<%= render "menu" %>
```

This will render a file named `_menu.html.erb` at that point within the view being rendered. Note the leading underscore character: partials are named with a leading underscore to distinguish them from regular views, even though they are referred to without the underscore. This holds true even when you're pulling in a partial from another folder:

```ruby 
<%= render "shared/menu" %>
```

That code will pull in the partial from `app/views/shared/_menu.html.erb`.

#### Using Partials to Simplify Views

One way to use partials is to treat them as the equivalent of subroutines: as a way to move details out of a view so that you can grasp what's going on more easily. For example, you might have a view that looked like this:

    ```erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
...

<%= render "shared/footer" %>
```

Here, the `_ad_banner.html.erb` and `_footer.html.erb` partials could contain content that is shared among many pages in your application. You don't need to see the details of these sections when you're concentrating on a particular page.

TIP: For content that is shared among all pages in your application, you can use partials directly from layouts.

#### Partial Layouts

A partial can use its own layout file, just as a view can use a layout. For example, you might call a partial like this:

    ```erb
<%= render partial: "link_area", layout: "graybar" %>
```

This would look for a partial named `_link_area.html.erb` and render it using the layout `_graybar.html.erb`. Note that layouts for partials follow the same leading-underscore naming as regular partials, and are placed in the same folder with the partial that they belong to (not in the master `layouts` folder).

Also note that explicitly specifying `:partial` is required when passing additional options such as `:layout`.

#### Passing Local Variables

You can also pass local variables into partials, making them even more powerful and flexible. For example, you can use this technique to reduce duplication between new and edit pages, while still keeping a bit of distinct content:

* `new.html.erb`

```html+erb
    <h1>New zone</h1>
    <%= render partial: "form", locals: {zone: @zone} %>
    ```

* `edit.html.erb`

```html+erb
    <h1>Editing zone</h1>
    <%= render partial: "form", locals: {zone: @zone} %>
    ```

* `_form.html.erb`

```html+erb
    <%= form_for(zone) do |f| %>
      <p>
        <b>Zone name</b><br>
{0}<%={/0} {1}f{/1}{2}.{/2}{1}text_field{/1} {3}:name{/3} {0}%>{/0}
</p>
  <p>
    <%= f.submit %>
</p>
<% end %>
    ```

Although the same partial will be rendered into both views, Action View's submit helper will return "Create Zone" for the new action and "Update Zone" for the edit action.

Every partial also has a local variable with the same name as the partial (minus the underscore). You can pass an object in to this local variable via the `:object` option:

    ```erb
<%= render partial: "customer", object: @new_customer %>
```

Within the `customer` partial, the `customer` variable will refer to `@new_customer` from the parent view.

If you have an instance of a model to render into a partial, you can use a shorthand syntax:

    ```erb
<%= render @customer %>
```

Assuming that the `@customer` instance variable contains an instance of the `Customer` model, this will use `_customer.html.erb` to render it and will pass the local variable `customer` into the partial which will refer to the `@customer` instance variable in the parent view.

#### Rendering Collections

Partials are very useful in rendering collections. When you pass a collection to a partial via the `:collection` option, the partial will be inserted once for each member in the collection:

* `index.html.erb`

```html+erb
    <h1>Products</h1>
    <%= render partial: "product", collection: @products %>
    ```

* `_product.html.erb`

```html+erb
    <p>Product Name: <%= product.name %></p>
    ```

When a partial is called with a pluralized collection, then the individual instances of the partial have access to the member of the collection being rendered via a variable named after the partial. In this case, the partial is `_product`, and within the `_product` partial, you can refer to `product` to get the instance that is being rendered.

There is also a shorthand for this. Assuming `@products` is a collection of `product` instances, you can simply write this in the `index.html.erb` to produce the same result:

```html+erb
<h1>Products</h1>
<%= render @products %>
```

Rails determines the name of the partial to use by looking at the model name in the collection. In fact, you can even create a heterogeneous collection and render it this way, and Rails will choose the proper partial for each member of the collection:

* `index.html.erb`

```html+erb
    <h1>Contacts</h1>
    <%= render [customer1, employee1, customer2, employee2] %>
    ```

* `customers/_customer.html.erb`

```html+erb
    <p>Customer: <%= customer.name %></p>
    ```

* `employees/_employee.html.erb`

```html+erb
    <p>Employee: <%= employee.name %></p>
    ```

In this case, Rails will use the customer or employee partials as appropriate for each member of the collection.

In the event that the collection is empty, `render` will return nil, so it should be fairly simple to provide alternative content.

```html+erb
<h1>Products</h1>
<%= render(@products) || "There are no products available." %>
```

#### Local Variables

To use a custom local variable name within the partial, specify the `:as` option in the call to the partial:

    ```erb
<%= render partial: "product", collection: @products, as: :item %>
```

With this change, you can access an instance of the `@products` collection as the `item` local variable within the partial.

You can also pass in arbitrary local variables to any partial you are rendering with the `locals: {}` option:

    ```erb
<%= render partial: "product", collection: @products,
           as: :item, locals: {title: "Products Page"} %>
```

In this case, the partial will have access to a local variable `title` with the value "Products Page".

TIP: Rails also makes a counter variable available within a partial called by the collection, named after the member of the collection followed by `_counter`. For example, if you're rendering `@products`, within the partial you can refer to `product_counter` to tell you how many times the partial has been rendered. This does not work in conjunction with the `as: :value` option.

You can also specify a second partial to be rendered between instances of the main partial by using the `:spacer_template` option:

#### Spacer Templates

    ```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

Rails will render the `_product_ruler` partial (with no data passed in to it) between each pair of `_product` partials.

#### Collection Partial Layouts

When rendering collections it is also possible to use the `:layout` option:

    ```erb
<%= render partial: "product", collection: @products, layout: "special_layout" %>
```

The layout will be rendered together with the partial for each item in the collection. The current object and object_counter variables will be available in the layout as well, the same way they do within the partial.

### Using Nested Layouts

You may find that your application requires a layout that differs slightly from your regular application layout to support one particular controller. Rather than repeating the main layout and editing it, you can accomplish this by using nested layouts (sometimes called sub-templates). 下が例です：

Suppose you have the following `ApplicationController` layout:

* `app/views/layouts/application.html.erb`

```html+erb
<html>
<head>
      <title><%= @page_title or "Page Title" %></title>
      <%= stylesheet_link_tag "layout" %>
      <style><%= yield :stylesheets %></style>
</head>
  <body>
      <div id="top_menu">Top menu items here</div>
      <div id="menu">Menu items here</div>
      <div id="content"><%= content_for?(:content) ? yield(:content) : yield %></div>
  </body>
</html> 
    ```

On pages generated by `NewsController`, you want to hide the top menu and add a right menu:

* `app/views/layouts/news.html.erb`

```html+erb
    <% content_for :stylesheets do %>
      #top_menu {display: none}
      #right_menu {float: right; background-color: yellow; color: black}
<% end %>
    <% content_for :content do %>
      <div id="right_menu">Right menu items here</div>
      <%= content_for?(:news_content) ? yield(:news_content) : yield %>
<% end %>
    <%= render template: "layouts/application" %>
    ```

これだけなんです。The News views will use the new layout, hiding the top menu and adding a new right menu inside the "content" div.

There are several ways of getting similar results with different sub-templating schemes using this technique. Note that there is no limit in nesting levels. One can use the `ActionView::render` method via `render template: 'layouts/news'` to base a new layout on the News layout. If you are sure you will not subtemplate the `News` layout, you can replace the `content_for?(:news_content) ? yield(:news_content) : yield` with simply `yield`.