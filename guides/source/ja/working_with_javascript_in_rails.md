Rails で JavaScript を利用する
================================

本ガイドでは、JavaScript機能をRailsアプリケーションに統合する方法について解説します。外部のJavaScriptパッケージを利用する場合に使えるオプションや、RailsでTurboを使う方法についても解説します。

このガイドの内容:

* Node.jsやYarnやJavaScriptのバンドラーを使わずにRailsを利用する方法
* JavaScriptをimport maps・esbuild・rollup・webpackでバンドルする新規Railsアプリケーションを作成する方法
* Turboの概要と利用法
* Railsが提供するTurbo HTMLヘルパーの利用法

--------------------------------------------------------------------------------

Import Maps
-----------

[import maps](https://github.com/rails/importmap-rails)は、バージョン付けされたファイルに対応する論理名を用いてJavaScriptモジュールをブラウザで直接importできます。import mapsはRails 7からデフォルトになっており、トランスパイルやバンドルの必要なしにほとんどのNPMパッケージを用いて誰でもモダンなJavaScriptアプリケーションを構築できるようになります。

import mapsを利用するアプリケーションは、[Node.js](https://nodejs.org/en/)や[Yarn](https://yarnpkg.com/)なしで機能します。RailsのJavaScript依存関係を`importmap-rails`で管理する予定であれば、Node.jsやYarnをインストールする必要はありません。

import mapsを利用する場合、別途ビルドプロセスを実行する必要はなく、`bin/rails server`コマンドでサーバーを起動するだけでOKです。

### importmap-railsをインストールする

Rails 7以降の新規アプリケーションでは、自動的にimportmap-railsが使われます。以下のように既存のアプリケーションに手動インストールすることも可能です。

```bash
$ bin/bundle add importmap-rails
```

以下のインストールタスクを実行します。

```bash
$ bin/rails importmap:install
```

### NPMパッケージをimportmap-railsで追加する

import mapを利用するアプリケーションに新しいパッケージを追加するには、ターミナルで以下のように`bin/importmap pin`コマンドを実行します。

```bash
$ bin/importmap pin react react-dom
```

続いて、従来と同様に`application.js`ファイルでパッケージを`import`します。


```javascript
import React from "react"
import ReactDOM from "react-dom"
```

NPMパッケージをJavaScriptバンドラーで追加する
--------

import mapsは新規Railsアプリケーションのデフォルトですが、従来のJavaScriptバンドラーを使いたい場合は、新規Railsアプリケーション作成時に[esbuild](https://esbuild.github.io/)、[webpack](https://webpack.js.org/)、[rollup.js](https://rollupjs.org/guide/en/)のいずれかを選択できます。

import mapsではなくJavaScriptバンドラーを新規Railsアプリケーションで利用するには、以下のように`rails new`コマンドに`—javascript`または`-j`オプションを渡します。

```bash
$ rails new my_new_app --javascript=webpack
OR
$ rails new my_new_app -j webpack
```

どのバンドルオプションにも、シンプルな設定と、[jsbundling-rails](https://github.com/rails/jsbundling-rails) gemによるアセットパイプラインとの統合が用意されています。

バンドルオプションを利用する場合は、development環境でのRailsサーバー起動とJavaScriptのビルドに`bin/dev`コマンドをお使いください。

### Node.jsとYarnをインストールする

RailsアプリケーションでJavaScriptバンドラーを使う場合は、Node.jsとYarnをインストールしなければなりません。

Node.jsのインストール方法については[Node.js Webサイト](https://nodejs.org/ja/download/)を参照してください。また、以下のコマンドで正しくインストールされたかどうかを確認してください。

```bash
$ node --version
```

Node.jsランタイムのバージョンが出力されるはずです。必ず`8.16.0`より大きいバージョンをお使いください。

Yarnのインストール方法については[Yarn Webサイト](https://classic.yarnpkg.com/en/docs/install)の手順に沿ってください。インストール後、以下のコマンドを実行するとYarnのバージョンが出力されるはずです。

```bash
$ yarn --version
```

`1.22.0`のように表示されれば、Yarnは正しくインストールされています。

import mapsとJavaScriptバンドラーのどちらを選ぶか
-----------------------------------------------------

Railsアプリケーションを新規作成する場合、import mapsとJavaScriptバンドラーのどちらかのソリューションを選ぶ必要があります。アプリケーションごとに要件は異なるので、JavaScriptのオプションを決める際には十分注意してください。特に大規模で複雑なアプリケーションほど、後から別のオプションに乗り換えようとすると時間がかかる可能性があります。

Railsチームは、import mapsが複雑さを削減して開発者のエクスペリエンスやパフォーマンスを向上させる能力を持っていると信じているので、import mapsがデフォルトのオプションとして選ばれています。

多くのアプリケーション、特にJavaScriptのニーズを[Hotwire](https://hotwired.dev/)スタックに依存しているアプリケーションにおいては、import mapが長期的に正しい選択肢となるでしょう。Rails 7でimport mapsがデフォルトのオプションになった背景については[こちら](https://world.hey.com/dhh/rails-7-will-have-three-great-answers-to-javascript-in-2021-8d68191b)の記事を参照してください。

それ以外のアプリケーションでは、引き続き従来のJavaScriptバンドラーが必要になることもあるでしょう。従来のJavaScriptバンドラーを選択すべきであることを示唆する要件は以下のとおりです。

* コードでトランスパイルが必須である場合（JSXやTypeScriptなどを使う場合）
* CSSをインクルードするJavaScriptライブラリや、[Webpack loaders](https://webpack.js.org/loaders/)に依存する必要がある場合
* [tree-shaking](https://webpack.js.org/guides/tree-shaking/)がどうしても必要な場合
* [cssbundling-rails gem](https://github.com/rails/cssbundling-rails)経由でBootstrap、Bulma、PostCSS、Dart CSSをインストールする場合。なお、`rails new`で特に別のオプションを指定しなかった場合は、cssbundling-rails gemが自動的に`esbuild`をインストールします（Tailwindを選んだ場合を除く）。

Turbo
-----

Whether you choose import maps or a traditional bundler, Rails ships with
[Turbo](https://turbo.hotwired.dev/) to speed up your application while dramatically reducing the
amount of JavaScript that you will need to write.

Turbo lets your server deliver HTML directly as an alternative to the prevailing front-end
frameworks that reduce the server-side of your Rails application to little more than a JSON API.

### Turbo Drive

[Turbo Drive](https://turbo.hotwired.dev/handbook/drive) speeds up page loads by avoiding full-page
teardowns and rebuilds on every navigation request. Turbo Drive is an improvement on and
replacement for Turbolinks.

### Turbo Frames

[Turbo Frames](https://turbo.hotwired.dev/handbook/frames) allow predefined parts of a page to be
updated on request, without impacting the rest of the page’s content.

You can use Turbo Frames to build in-place editing without any custom JavaScript, lazy load
content, and create server-rendered, tabbed interfaces with ease.

Rails provides HTML helpers to simplify the use of Turbo Frames through the
[turbo-rails](https://github.com/hotwired/turbo-rails) gem.

Using this gem, you can add a Turbo Frame to your application with the `turbo_frame_tag` helper
like this:

```erb
<%= turbo_frame_tag dom_id(post) do %>
  <div>
     <%= link_to post.title, post_path(path) %>
  </div>
<% end %>
```

### Turbo Streams

[Turbo Streams](https://turbo.hotwired.dev/handbook/streams) deliver page changes as fragments of
HTML wrapped in self-executing `<turbo-stream>` elements. Turbo Streams allow you to broadcast
changes made by other users over WebSockets and update pieces of a page after a form submission
without requiring a full page load.

Rails provides HTML and server-side helpers to simplify the use of Turbo Streams through the
[turbo-rails](https://github.com/hotwired/turbo-rails) gem.

Using this gem, you can render Turbo Streams from a controller action:

```ruby
def create
  @post = Post.new(post_params)
  respond_to do |format|
    if @post.save
      format.turbo_stream
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

Rails will automatically look for a `.turbo_stream.erb` view file and render that view when found.

Turbo Stream responses can also be rendered inline in the controller action:

```ruby
def create
  @post = Post.new(post_params)
  respond_to do |format|
    if @post.save
      format.turbo_stream { render turbo_stream: turbo_stream.prepend('posts', partial: 'post') }
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

Finally, Turbo Streams can be initiated from a model or a background job using built-in helpers.
These broadcasts can be used to update content via a WebSocket connection to all users, keeping
page content fresh and bringing your application to life.

To broadcast a Turbo Stream from a model combine a model callback like this:

```ruby
class Post < ApplicationRecord
  after_create_commit { broadcast_append_to('posts') }
end
```

With a WebSocket connection set up on the page that should receive the updates like this:

```erb
<%= turbo_stream_from "posts" %>
```

Replacements for Rails/UJS Functionality
----------------------------------------

Rails 6 shipped with a tool called UJS that allows developers to override the method of `<a>` tags
to perform non-GET requests after a hyperlink click and to add confirmation dialogs before
executing an action. This was the default before Rails 7, but it is now recommended to use Turbo
instead.

### Method

Clicking links always results in an HTTP GET request. If your application is
[RESTful](https://en.wikipedia.org/wiki/Representational_State_Transfer), some links are in fact