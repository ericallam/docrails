Rails で JavaScript を利用する
================================

本ガイドでは、RailsにビルトインされているAjax/JavaScript機能などについて解説します。これらを活用して、リッチな動的Ajaxアプリケーションをお手軽に作ることができます。

このガイドの内容:

* Ajaxの基礎
* 「控えめなJavaScript」について
* Railsのビルトインヘルパーの活用方法
* サーバー側でAjaxを扱う方法
* Turbolinks gem
* CSRFトークンを独自にリクエストヘッダーに含める方法

-------------------------------------------------------------------------------


はじめてのAjax
------------------------

Ajaxを理解するには、Webブラウザの基本的な動作について理解しておく必要があります。

ブラウザのアドレスバーに`http://localhost:3000`と入力して'Go'を押すと、ブラウザ （つまりクライアント）はサーバーに対してリクエストを1つ送信します。ブラウザは、サーバーから受け取ったレスポンスを解析し、続いて必要なすべてのアセット（JavaScriptファイル、スタイルシート、画像）をサーバーから取得します。続いてブラウザはページを組み立てます。ブラウザに表示されているリンクをクリックすると、同じプロセスが実行されます。ブラウザはページを取得し、続いてアセットを取得し、それらをすべてまとめてから結果を表示します。これが、いわゆる「リクエスト-レスポンス」サイクルです。

JavaScriptも、上と同様にサーバーにリクエストを送信し、レスポンスを解析することができます。JavaScriptはページ上の情報を更新することもできます。JavaScriptの開発者は、ブラウザとJavaScriptという2つの力を1つに結集させることで、現在のWebページの一部だけを更新できます。必要なWebページをサーバーからすべて取得する必要はありません。この強力な技法が、Ajaxと呼ばれているものです。

Railsには、JavaScriptをさらに使いやすくしたCoffeeScriptがデフォルトで組み込まれています。以後、本ガイドではすべての例をCoffeeScriptで記述します。もちろん、これらのレッスンはすべて通常のJavaScriptにも適用できます。

以下は、Ajaxリクエストを送信するJavaScriptコード例です。

```js
fetch("/test")
  .then((data) => data.text())
  .then((html) => {
    const results = document.querySelector("#results");
    results.insertAdjacentHTML("beforeend", html);
  });
```

上のコードは「/test」からデータを取得し、結果をWebページ上のidが`results`の要素に`append`します。

Railsには、この手法でWebページを構築するためのサポートが多数組み込まれています。したがって、こうしたコードをすべて自分で作成する必要はほとんどありません。この後、このような手法でRails Webサイトを作成する方法をご紹介します。これらの手法は、いずれもシンプルな基本テクニックのうえに成り立っています。

「控えめなJavaScript」
-------------------------------------

Railsでは、JavaScriptをDOMに追加する際の手法を「UJS: Unobtrusive（控えめな）JavaScript」と呼んでいます。これは一般にフロントエンド開発者コミュニティでベストプラクティスであると見なされていますが、ここではもう少し違う角度から説明したいと思います。

最もシンプルなJavaScriptを例にとって考えてみましょう。以下のような書き方は「インラインJavaScript」と呼ばれています。

```html
<a href="#" onclick="this.style.backgroundColor='#990000';event.preventDefault();">Paint it red</a>
```

このリンクをクリックすると、背景が赤くなります。しかし早くもここで問題が生じ始めます。クリックした時にJavaScriptでもっといろんなことをさせるとどうなるでしょうか。

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';event.preventDefault();">Paint it green</a>
```

だいぶ乱雑になってきました。この関数定義はclickハンドラの外に移動して関数することが可能です。

```js
window.paintIt = function(event, backgroundColor, textColor) {
  event.preventDefault();
  event.target.style.backgroundColor = backgroundColor;
  if (textColor) {
    event.target.style.color = textColor;
  }
}
```

ページの内容を以下に変更します。

```html
<a href="#" onclick="paintIt(event, '#990000')">Paint it red</a>
```

これでコードが少し改善されました。しかし、同じ効果を複数のリンクに与えるとどうなるでしょうか。

```html
<a href="#" onclick="paintIt(event, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(event, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(event, '#000099', '#FFFFFF')">Paint it blue</a>
```

これではDRYとは言えません。今度はイベントを活用して改良してみましょう。最初に`data-*`属性をリンクに追加しておきます。続いて、この属性を持つすべてのリンクで発生するクリックイベントにハンドラをバインドします。

```js
function paintIt(element, backgroundColor, textColor) {
  element.style.backgroundColor = backgroundColor;
  if (textColor) {
    element.style.color = textColor;
  }
}

window.addEventListener("load", () => {
  const links = document.querySelectorAll(
    "a[data-background-color]"
  );
  links.forEach((element) => {
    element.addEventListener("click", (event) => {
      event.preventDefault();

      const {backgroundColor, textColor} = element.dataset;
      paintIt(element, backgroundColor, textColor);
    });
  });
});
```

```html
<a href="#" data-background-color="#990000">Paint it red</a>
<a href="#" data-background-color="#009900" data-text-color="#FFFFFF">Paint it green</a>
<a href="#" data-background-color="#000099" data-text-color="#FFFFFF">Paint it blue</a>
```

私たちはこの手法を「UJS: Unobtrusive（控えめな）JavaScript」と呼んでいます。この名称は、HTMLの中にJavaScriptを混入させないという意図に由来しています。関心を正しく分離できたので、今後の変更が楽になります。以後は、この`data-*`属性をリンクタグに追加するだけでこの動作を簡単に追加できます。あらゆるJavaScriptは、最小化機能と結合機能を経て実行できます。作成したJavaScriptコード全体はRailsのあらゆるWebページで利用できます。つまり、ページが最初にブラウザに読み込まれるときにダウンロードされ、以後はブラウザでキャッシュされます。これにより多くのメリットが得られます。

Railsチームは、本ガイドでご紹介した方法でCoffeeScriptやJavaScriptを用いることを強く推奨します。多くのJavaScriptライブラリもこの方法で利用できることが期待できます。

組み込みヘルパー
----------------------

### remote要素

HTMLを簡単に生成できるようにするため、Rubyで記述されたさまざまなビューヘルパーメソッドが用意されています。それらのHTML要素にAjaxコードを若干追加したくなったときにも、Railsがサポートしてくれます。

RailsのAjaxヘルパーは、「控えめなJavaScript」原則に基いて、JavaScriptとRubyという2つの要素で構成されています。

アセットパイプラインを無効にしない限り、[rails-ujs](https://github.com/rails/rails/tree/main/actionview/app/assets/javascripts)はJavaScriptの他に通常のRubyビューヘルパーも提供して、DOMに適切なタグを追加します。

アプリケーション内の`remote`要素を扱うその他の発火イベントについては以下をご覧ください。

#### form_with

[`form_with`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_with)はフォーム作成を支援するヘルパーです。`form_with`では、デフォルトでAjaxをフォームで使えることが前提になっています。`form_with`に`:local`オプションを渡すことでこの振る舞いを変更できます。

```erb
<%= form_with(model: @article, id: "new-article", local: false) do |form| %>
  ...
<% end %>
```

上のコードから以下のHTMLが生成されます。

```html
<form id="new-article" action="/articles" accept-charset="UTF-8" method="post" data-remote="true">
  ...
</form>
```

formタグに`data-remote="true"`という属性が追加されていることにご注目ください。これにより、フォームの送信がブラウザによる通常の送信メカニズムではなくAjaxによって送信されるようになります。

`<form>`タグの中身を埋めただけでおしまいだとは思わないでしょう。フォーム送信が成功した場合に何らかの表示を行いたいものです。これを行なうには、`ajax:success`イベントをバインドします。送信に失敗した場合は`ajax:error`を使います。実際に見てみましょう。

```js
window.addEventListener("load", () => {
  const element = document.querySelector("#new-article");
  element.addEventListener("ajax:success", (event) => {
    const [_data, _status, xhr] = event.detail;
    element.insertAdjacentHTML("beforeend", xhr.responseText);
  });
  element.addEventListener("ajax:error", () => {
    element.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });
});
```

もちろん実際にはもっと洗練された表示にしたいと思うことでしょう。上はあくまで出発点です。

#### link_to

[`link_to`](https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to)はリンクの生成を支援するヘルパーです。このメソッドには`:remote`オプションがあり、以下のように使えます。

```erb
<%= link_to "記事", @article, remote: true %>
```

上のコードによって以下が生成されます。

```html
<a href="/articles/1" data-remote="true">記事</a>
```

`form_with`の場合と同様、同じAjaxイベントをバインドできます。例を以下に示します。1クリックで削除できる記事の一覧があるとします。このHTMLは以下のような感じになります。

```erb
<%= link_to "記事を削除", @article, remote: true, method: :delete %>
```

上の他に、以下のようなJavaScriptも作成します。

```js
window.addEventListener("load", () => {
  const links = document.querySelectorAll("a[data-remote]");
  links.forEach((element) => {
    element.addEventListener("ajax:success", () => {
      alert("この記事を削除しました");
    });
  });
});
```

#### button_to

[`button_to`](https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to)はボタン作成を支援するヘルパーです。このメソッドには`:remote`オプションがあり、以下のように使えます。

```erb
<%= button_to "記事", @article, remote: true %>
```

上のコードによって以下が生成されます。

```html
<form action="/articles/1" class="button_to" data-remote="true" method="post">
  <input type="submit" value="記事" />
</form>
```

作成されるのは通常の`<form>`なので、`form_with`に関する情報はすべて`button_to`にも適用されます。

### `remote`要素をカスタマイズする

`data-remote`属性を用いることで、JavaScriptを1行も書かずに要素の振る舞いをカスタマイズできます。他の`data-`属性を指定する方法も使えます。

#### `data-method`

ハイパーリンクをクリックすると、常にHTTP GETリクエストが発生します。しかし実際には、[RESTful](https://ja.wikipedia.org/wiki/Representational_State_Transfer)なアプリケーションのリンクの中には、クリックするとサーバーのデータを変更するものもあり、そうした操作はGET以外のリクエストで行わなければなりません。この`data-method`属性は、そうしたリンクのHTTPメソッドにPOSTやPUTやDELETEを明示的に指定できます。

この仕組みは次のとおりです。リンクをクリックすると、ドキュメント内にリンクの`href`値に対応する「action」属性や`data-method`値に対応するHTTPメソッドを含む「隠しフォーム」を作成してから、そのフォームが送信されます。

NOTE: GETやPOST以外のHTTPメソッドによるフォーム送信をサポートするブラウザは多くないため、実際にはそうした他のHTTPメソッドは`_method`パラメータで指定する形で`POST`メソッドとして送信されます。Railsはこうした点を自動検出してカバーします。

#### `data-url`と`data-params`

ページの特定の要素が実際にはどのURLを参照していなくても、これを用いてAjax呼び出しをトリガしたいことがあります。`data-remote`と`data-url`属性を指定すると、そこで指定されたURLを用いてAjax呼び出しをトリガできます。`data-params`属性を介してこの他にもパラメータを指定できます。

たとえば、チェックボックスを操作したときに何らかの操作をトリガできると便利な場合があります。

```html
<input type="checkbox" data-remote="true"
    data-url="/update" data-params="id=10" data-method="put">
```

#### `data-type`

`data-type`属性を用いると、`data-remote`を用いるリクエストを実行する際にAjaxの`dataType`属性を明示的に定義することも可能です。

### 確認ダイアログ

リンクやフォームに`data-confirm`属性を追加することで、確認ダイアログをさらに表示できます。ユーザーに表示されるのはJavaScriptの`confirm()`ダイアログで、この属性のテキストがダイアログに表示されます。ユーザーがダイアログをキャンセルすると、その操作は実行されません。

`data-confirm`属性をリンクに追加すると、クリック時にダイアログがトリガされます。フォームに追加すると、フォームの送信時にトリガされます。次の例をご覧ください。

```erb
<%= link_to "Dangerous zone", dangerous_zone_path,
  data: { confirm: 'よろしいですか？' } %>
```

上のコードから以下が生成されます。

```html
<a href="..." data-confirm="よろしいですか？">Dangerous zone</a>
```

`data-confirm`属性はフォームの送信ボタンにも使えます。これを用いて、クリックしたボタンに応じた警告メッセージを変更できます。ただし、この場合はフォームそのものに`data-confirm`属性を**追加してはいけません**。

### 入力を自動で無効にする

`data-disable-with`属性を用いて、フォームを送信するときに入力フィールドを自動で無効にすることも可能です。これは、ユーザーがフォームの送信ボタンを誤ってダブルクリックするのを防ぐためのものです。送信ボタンがダブルクリックされるとHTTPリクエストの重複をバックエンド側で検出できなくなる可能性があります。`data-disable-with`属性の値は、無効状態になったボタンテキストの新しい値になります。

`data-disable-with`属性は、`data-method`属性を持つリンクでも使えます。

次の例をご覧ください。

```erb
<%= form_with(model: Article.new) do |form| %>
  <%= form.submit data: { disable_with: "保存しています..." } %>
<% end %>
```

上のコードから以下のフォームが生成されます。

```html
<input data-disable-with="保存しています..." type="submit">
```

### rails-ujsのイベントハンドラ

Rails 5.1ではrails-ujsが導入され、jQueryに依存しなくなりました。この結果、UJSドライバが書き直されてjQueryなしで使えるようになりました。rails-ujsが導入されたことで、リクエスト中に発火する`custom events`に若干変更が生じます。

NOTE: UJSイベントハンドラ呼び出しのシグネチャが変更されました。jQueryの場合と異なり、あらゆるカスタムイベントは`event`パラメータだけを返します。このパラメータには`detail`という属性が追加されており、追加パラメータの配列がその中に1つ含まれています。Rails 5で従来使われていた`jquery-ujs`について詳しくは、[`jquery-ujs` wiki](https://github.com/rails/jquery-ujs/wiki/ajax)を参照してください。


| イベント名          | 追加のパラメータ（`event.detail`） | 発火のタイミング                                                       |
|---------------------|---------------------------------|-------------------------------------------------------------|
| `ajax:before`       |                                 | Ajax全体が作動する前                             |
| `ajax:beforeSend`   | [xhr, options]                  | リクエストが送信される前                                 |
| `ajax:send`         | [xhr]                           | リクエストの送信時                                   |
| `ajax:stopped`      |                                 | リクエストの停止時                                |
| `ajax:success`      | [response, status, xhr]         | 完了後、レスポンス成功時            |
| `ajax:error`        | [response, status, xhr]         | 完了後、レスポンスエラー時             |
| `ajax:complete`     | [xhr, status]                   | リクエスト完了時（結果にかかわらず）|

利用例は次のとおりです。

```js
document.body.addEventListener("ajax:success", (event) => {
  const [data, status, xhr] = event.detail;
});
```

### 停止可能なイベント

`ajax:before`ハンドラメソッドや`ajax:beforeSend`ハンドラメソッドで`event.preventDefault()`を実行すると、以後のAjaxリクエストの実行を停止できます。`ajax:before`イベントはシリアライズ前のフォームのデータを操作可能で、独自のリクエストヘッダを追加するには`ajax:beforeSend`が便利です。

`ajax:aborted:file`イベントを停止すると、ブラウザがフォームを通常の方法（Ajaxを用いない送信など）で送信するときのデフォルトの振る舞いがキャンセルされ、以後そのフォームは送信されなくなります。これは、ファイルアップロードを独自のAjaxで実装するときの回避方法として便利です。

なお、`jquery-ujs`のイベントを抑制するには`return false`を、 `rails-ujs`のイベントを抑制するには`e.preventDefault()`を使うべきです。

サーバー側で考慮すべき点
--------------------

Ajaxはクライアント側だけでなく、サーバー側でのサポートもある程度必要です。Ajaxリクエストに対してレスポンスを返す際の形式は、HTMLよりもJSONを使うことが好まれています。ここではそのために必要なものについて解説します。

### シンプルな例

表示したいユーザーリストがあり、そのページに新規ユーザーを作成するフォームも置きたいとします。このコントローラのindexアクションは以下のようになります。

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

indexビュー (`app/views/users/index.html.erb`) の内容は以下のようになります。

```erb
<b>Users</b>

<ul id="users">
<%= render @users %>
</ul>

<br>

<%= form_with model: @user do |form| %>
  <%= form.label :name %><br>
  <%= form.text_field :name %>
  <%= form.submit %>
<% end %>
```

`app/views/users/_user.html.erb`パーシャルの内容は以下のようになります。

```erb
<li><%= user.name %></li>
```

indexページの上部にはユーザーの一覧が表示され、下部にはユーザー作成用のフォームが表示されます。

下部のフォームは`UsersController`の`create`アクションを呼び出します。フォームの`remote`オプションがオンになっているので、リクエストはAjaxリクエストとして`UsersController`に渡され、JavaScriptコードを探索します。コントローラ内でリクエストに応答する`create`アクションは以下のようになります。

```ruby
  # app/controllers/users_controller.rb
  # ......
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.js
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

`respond_to`ブロックの中にある`format.js`にご注目ください。これによって、コントローラがAjaxリクエストに応答できるようになります。続いて、対応する`app/views/users/create.js.erb`ビューファイルを作成します。実際のJavaScriptはこのビューで生成され、クライアントに送信されてそこで実行されます。

```js
var users = document.querySelector("#users");
users.insertAdjacentHTML("beforeend", "<%= j render(@user) %>");
```

NOTE: JavaScriptのビューレンダリングではプリプロセスが行われないため、ここではES6構文を使うべきではありません。

Turbolinks
----------

Railsには[Turbolinksライブラリ](https://github.com/turbolinks/turbolinks)が同梱されており、Ajaxを利用して多くのアプリケーションでページのレンダリングを高速化しています。

### Turbolinksの動作原理

Turbolinksは、ページにあるすべての`<a>`タグにクリックハンドラを1つずつ追加します。ブラウザで[PushState](https://developer.mozilla.org/ja/docs/Web/API/History_API#The_pushState%28%29_method)がサポートされている場合、Turbolinksはそのページ用のAjaxリクエストを生成し、サーバーからのレスポンスを解析して、そのページの`<body>`全体をレスポンスの`<body>`で置き換えます。続いて、TurbolinksはPushStateを使ってURLを正しいものに書き換えます。これによってリフレッシュのセマンティクスを維持しながらきれいなURLを得られます。

Turbolinksを特定のリンクでのみ無効にしたい場合は、タグに`data-turbolinks="false"`属性を追加します。

```html
<a href="..." data-turbolinks="false">ここではTurbolinksをオフにする</a>。
```

### ページ変更イベント

ページ読み込みに関連する処理を追加したくなることがよくあります。たとえばDOMを使って以下のように書いたとします。

```js
window.addEventListener("load", () => {
  alert("page has loaded!");
});
```

しかし、通常のページ読み込みプロセスはTurbolinksによって上書きされてしまうため、ページ読み込みに依存するイベントはトリガされません。このようなコードがある場合は、以下のように書き換えなければなりません。

```js
document.addEventListener("turbolinks:load", () => {
  alert("page has loaded!");
});
```

この他にバインド可能なイベントなどの詳細については、[Turbolinks README](https://github.com/turbolinks/turbolinks/blob/master/README.md)を参照してください。

AjaxのCSRF（Cross-Site Request Forgery）トークン
----

Ajax呼び出しのために別のライブラリを使う場合、そのライブラリでのAjax呼び出しにセキュリティトークンをデフォルトヘッダーのひとつとして追加する必要があります。このトークンは以下のように取得します。

```js
const token = document.getElementsByName(
  "csrf-token"
)[0].content;
```

続いてこのトークンをAjaxリクエストのヘッダーで`X-CSRF-Token`として送信します。GETリクエストにCSRFを追加する必要はありません。CSRFが必要なのはGET以外のリクエストです。

CSRFについて詳しくは[セキュリティガイド](security.html#クロスサイトリクエストフォージェリ（csrf）)を参照してください。

その他の情報源
---------------

詳細な学習に役立つリンクをいくつか紹介します。

* [rails-ujs wiki](https://github.com/rails/rails/tree/main/actionview/app/assets/javascripts)
* [Railscasts: Unobtrusive JavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks)
