アセットパイプライン
==================

本ガイドでは、アセットパイプライン (asset pipeline) について解説します。

このガイドの内容:

* アセットパイプラインの概要と機能
* アプリケーションのアセットを正しく編成する方法
* アセットパイプラインのメリット
* アセットパイプラインにプリプロセッサを追加する
* アセットをgemパッケージにする

--------------------------------------------------------------------------------


アセットパイプラインについて
---------------------------

アセットパイプラインとは、JavaScriptやCSSのアセットを最小化 (minify: スペースや改行を詰めるなど) または圧縮して連結するためのフレームワークです。アセットパイプラインでは、CoffeeScriptやSass、ERBなど他の言語で記述されたアセットを作成する機能を追加することもできます。
アセットパイプラインはアプリケーションのアセットを自動的に他のgemのアセットと結合できます。たとえば、jquery-railsにはRailsでAJAXを使えるようにするjquery.jsが含まれています。

アセットパイプラインは[sprockets-rails](https://github.com/rails/sprockets-rails) gemによって実装され、デフォルトで有効になっています。アプリケーションの新規作成中にアセットパイプラインを無効にするには、`--skip-sprockets`オプションを渡します。

```bash
rails new appname --skip-sprockets
```

Railsでは`sass-rails` gemが自動的にGemfileに追加されます。Sprocketsはアセット圧縮の際にこのgemを利用します。

```ruby
gem 'sass-rails'
```

アセット圧縮方式を指定するには、`production.rb`の該当する設定オプションを設定します。`config.assets.css_compressor`はCSSの圧縮方式、`config.assets.js_compressor`はJavaScriptの圧縮方式をそれぞれ指定します。

```ruby
config.assets.css_compressor = :yui
config.assets.js_compressor = :terser
```

NOTE: `sass-rails` gemが`Gemfile`に含まれていれば自動的にCSS圧縮に利用されます。この場合`config.assets.css_compressor`オプションは設定されません。


### 主要な機能

アセットパイプラインの第1の機能はアセットを連結することです。これにより、ブラウザがWebページをレンダリングするためのリクエスト数を減らすことができます。Webブラウザが同時に処理できるリクエスト数には限りがあるため、同時リクエスト数を減らすことができればその分読み込みが高速になります。

SprocketsはすべてのJavaScriptファイルを1つのマスター`.js`ファイルに連結し、すべてのCSSファイルを1つのマスター`.css`ファイルに連結します。本ガイドで後述するように、アセットファイルをグループ化する方法は自由にカスタマイズできます。production環境では、アセットファイル名にSHA256フィンガープリントを挿入し、アセットファイルがWebブラウザでキャッシュされるようにしています。このフィンガープリントを変更することでブラウザでキャッシュされていた既存のアセットを無効にすることができます。フィンガープリントの変更は、アセットファイルの内容が変更された時に自動的に行われます。

アセットパイプラインの第2の機能はアセットの最小化（一種の圧縮）です。CSSファイルの最小化は、ホワイトスペースとコメントを削除することによって行われます。JavaScriptの最小化プロセスはもう少し複雑です。最小化方法はビルトインのオプションから選んだり、独自に指定したりすることができます。

アセットパイプラインの第3の機能は、より高級な言語を利用したコーディングのサポートです。これらの言語で記述されたコードはプリコンパイルされ、実際のアセットになります。デフォルトでサポートされている言語は、CSSに代わるSass、JavaScriptに代わるCoffeeScript、CSS/JavaScriptに代わるERBです。

### フィンガープリントと注意点

アセットファイル名で使われるフィンガープリントは、アセットファイルの内容に応じて変わります。アセットファイルの内容が少しでも変わると、アセットファイル名も必ずそれに応じて変わります（訳注: SHA256の性質により、異なるファイルからたまたま同じフィンガープリントが生成されることはほぼありません）。変更されていないファイルやめったに変更されないファイルがある場合、フィンガープリントも変化しないので、ファイルの内容が完全に同一であることが容易に確認できます。これはサーバーやデプロイ日が異なっていても有効です。

アセットファイル名は内容が変わると必ず変化するので、CDN、ISP、ネットワーク機器、Webブラウザなどあらゆる場面で有効なキャッシュをHTTPヘッダに設定できます。ファイルの内容が更新されると、フィンガープリントも更新されます。これにより、リモートクライアントは（訳注: 既存のキャッシュを使わずに）コンテンツの新しいコピーをサーバーにリクエストします。この手法を一般に「キャッシュ破棄（cache busting）」と呼びます。

Sprocketsがフィンガープリントを使う際には、ファイルの内容をハッシュ化したものをファイル名（通常は末尾）に追加します。たとえば、`global.css`というCSSファイル名は以下のようになります。

```
global-908e25f4bf641868d8683022a5b62f54.css
```

これはRailsのアセットパイプラインの戦略として採用されています。

以前のRailsでは、ビルトインのヘルパーにリンクされているすべてのアセットに日付ベースのクエリ文字列を追加するという戦略が使われていました。当時のソースで生成されたコードは以下のようになります。

```
/stylesheets/global.css?1309495796
```

このクエリ文字列ベースの戦略には多くの問題点があります。

**1. クエリパラメータ以外にファイル名に違いのないコンテンツは確実にキャッシュされないことがある**

  * [Steve Soudersのブログ記事](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)によると、「キャッシュされる可能性のあるリソースにクエリ文字列でアクセスするのは避けること」が推奨されています。Steveは、5%〜20%ものリクエストがキャッシュされていないことに気付きました。クエリ文字列は、キャッシュ無効化が発生する一部のCDNでは役に立ちません。

**2. マルチサーバー環境でファイル名が異なってしまうことがある**

  * Rails 2.xのデフォルトのクエリ文字列はファイルの更新日付に基いていました。このアセットをサーバークラスタにデプロイすると、サーバー間でファイルのタイムスタンプが同じになる保証がないため、リクエストを受けるサーバーが変わるたびに値が異なってしまいます。

**3. キャッシュの無効化が過剰に発生する**

  * コードリリース時のデプロイが行われると、アセットに変更があるかどうかにかかわらず「すべての」ファイルのmtime（最終更新時刻）が変更されてしまいます。このため、アセットに変更がなくてもWebブラウザを含むあらゆるリモートクライアントで強制的にアセットが再取得されてしまいます。

フィンガープリントが導入されたことによって上述のクエリ文字列による問題点が解決され、アセットの内容が同じであればファイル名も常に同じになるようになりました。

フィンガープリントはdevelopment環境とproduction環境の両方でデフォルトでオンになります。設定ファイルの`config.assets.digest`オプションを使うとフィンガープリントのオン/オフを制御できます。

詳しくは以下を参照してください。

* [キャッシュの最適化](https://developers.google.com/speed/docs/insights/LeverageBrowserCaching)
* [ファイル名の変更にクエリ文字列を使ってはいけない理由](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)


アセットパイプラインの利用方法
-----------------------------

以前のRailsでは、すべてのアセットは`public`ディレクトリの下の`images`、`javascripts`、`stylesheets`などのサブフォルダに置かれました。アセットパイプライン導入後は、`app/assets`ディレクトリがアセットの置き場所として推奨されています。このディレクトリに置かれたファイルはSprocketsミドルウェアによってサポートされます。

アセットは引き続き`public`ディレクトリ以下に置くことも可能です。`config.public_file_server.enabled`が`true`に設定されていると、`public`ディレクトリ以下に置かれているあらゆるアセットはアプリケーションまたはWebサーバーによって静的なファイルとして取り扱われます。プリプロセスが必要なファイルは`app/assets`ディレクトリの下に置く必要があります。

productionモードでは、Railsはプリコンパイルされたファイルを`public/assets`に置きます。プリコンパイルされたファイルは、Webサーバーによって静的なアセットとして扱われます。`app/assets`に置かれたファイルがそのままの形でproduction環境で利用されることは決してありません。

### コントローラ固有のアセット

Railsでscaffoldやコントローラを生成すると、そのコントローラ用のCSS（`sass-rails` gemが`Gemfile`で有効になっている場合はSCSS）も生成されます。scaffold生成時には、さらに`scaffolds.css` (`sass-rails` gemが`Gemfile`で有効になっている場合は`scaffolds.css.scss`) も生成されます。

たとえば`ProjectsController`を生成すると、`app/assets/stylesheets/projects.scss`ファイルが新しく作成されます。`require_tree`ディレクティブがあることで、これらのファイルを即座にアプリケーションから利用できます。`require_tree`について詳しくは[マニフェストファイルとディレクティブ](#マニフェストファイルとディレクティブ)を参照してください。

関連するコントローラに以下のコードを書くと、コントローラ固有のスタイルシートやJavaScriptファイルをそのコントローラだけで利用できます。

`<%= javascript_include_tag params[:controller] %>`または`<%= stylesheet_link_tag params[:controller] %>`

上のコードを使うときは、`require_tree`ディレクティブが使われていないことを必ず確認してください。上のコードを`require_tree`と併用すると、アセットが2回以上インクルードされてしまいます。

WARNING: アセットのプリコンパイルを利用する場合は、ページが読み込まれるたびにコントローラのアセットがプリコンパイルされるようにしておく必要があります。デフォルトでは、`.coffee`ファイルと`.scss`ファイルは自動ではプリコンパイルされません。プリコンパイルの動作について詳しくは、[アセットをプリコンパイルする](#アセットをプリコンパイルする)を参照してください。

NOTE: CoffeeScriptを利用するには、ExecJSがランタイムでサポートされている必要があります。macOSまたはWindowsを利用している場合は、OSにJavaScriptランタイムをインストールしてください。サポートされているすべてのJavaScriptランタイムに関するドキュメントは、[ExecJS](https://github.com/sstephenson/execjs#readme) で参照できます。

### アセットの編成

パイプラインのアセットは、アプリケーション内の`app/assets`、`lib/assets`、`vendor/assets`の3つのディレクトリのいずれかに置くことができます。

* `app/assets`は、カスタム画像ファイル、JavaScript、スタイルシートなど、アプリケーション自身が保有するアセットの置き場所です。

* `lib/assets`は、1つのアプリケーションの範疇に収まらないライブラリのコードや、複数のアプリケーションで共有されるライブラリのコードを置く場所です。

* `vendor/assets`は、JavaScriptプラグインやCSSフレームワークなど、外部の団体などによって所有されているアセットの置き場所です。

#### パスの検索

ファイルがマニフェストやヘルパーから参照される場合、Sprocketsはデフォルトのアセットの置き場所である3つのディレクトリからファイルを探します。

3つのディレクトリとは、`app/assets`の下にある`images`、`javascripts`、`stylesheets`ディレクトリです。ただしこれらのサブディレクトリは特殊なものではなく、実際には`assets/*`以下のすべてのパスが検索対象になります。

以下のファイルを例に説明します。

```
app/assets/javascripts/home.js
lib/assets/javascripts/moovinator.js
vendor/assets/javascripts/slider.js
vendor/assets/somepackage/phonebox.js
```

上のファイルはマニフェスト内で以下のように参照されます。

```js
//= require home
//= require moovinator
//= require slider
//= require phonebox
```

サブディレクトリ内のアセットにもアクセスできます。

```
app/assets/javascripts/sub/something.js
```

上のファイルは以下のように参照されます。

```js
//= require sub/something
```

検索パスを調べるには、Railsコンソールで`Rails.application.config.assets.paths`を調べます。

`config/initializers/assets.rb`に記述することで、標準の`assets/*`に加えて追加の（fully qualified: 完全修飾）パスをパイプラインに追加できます。以下の例で説明します。

```ruby
Rails.application.config.assets.paths << Rails.root.join("lib", "videoplayer", "flash")
```

パスの探索は、検索パスでの出現順で行われます。デフォルトでは`app/assets`の検索が優先されるので、対応するパスが`lib`や`vendor`にある場合はマスクされます。

ここで重要なのは、参照したいファイルがマニフェストの外にある場合は、それらをプリコンパイル配列に追加しなければならないという点です。追加しない場合、production環境で利用できなくなります。

#### indexファイルを使う

Sprocketsでは、`index`という名前のファイル（および関連する拡張子）を特殊な目的で利用します。

たとえば、たくさんのモジュールがあるjQueryライブラリを利用していて、それらが`lib/assets/javascripts/library_name`に保存されているとします。この`lib/assets/javascripts/library_name/index.js`ファイルはそのライブラリ内のすべてのファイルで利用できるマニフェストとして機能します。このファイルには必要なファイルをすべて順に記述するか、あるいは単に`require_tree`と記述します。

一般に、このライブラリはアプリケーションマニフェストに以下のように記述することでアクセスできるようになります。

```js
//= require library_name
```

このように記述することで、他でインクルードする前に関連するコードをグループ化できるようになり、記述が簡潔になりメンテナンスもやりやすくなります。

### アセットにリンクするコードを書く

Sprocketsはアセットにアクセスするためのメソッドを特に追加しません。従来同様`javascript_include_tag`と`stylesheet_link_tag`を使います。

```erb
<%= stylesheet_link_tag "application", media: "all" %>
<%= javascript_include_tag "application" %>
```

Railsに同梱されているturbolinks gemを利用している場合、`'data-turbo-track'`オプションが利用できます。これはアセットが更新されてページに読み込まれたかどうかをTurboがチェックします。

```erb
<%= stylesheet_link_tag "application", media: "all", "data-turbo-track" => "reload" %>
<%= javascript_include_tag "application", "data-turbo-track" => "reload" %>
```

通常のビューでは以下のような方法で`app/assets/images`ディレクトリの画像にアクセスできます。

```erb
<%= image_tag "rails.png" %>
```

パイプラインが有効でかつ現在の環境で無効になっていない場合、このファイルはSprocketsによって扱われます。ファイルが`public/assets/rails.png`に置かれている場合、Webサーバーによって扱われます。

`public/assets/rails-f90d8a84c707a8dc923fca1ca1895ae8ed0a09237f6992015fef1e11be77c023.png`など、ファイル名にSHA256ハッシュを含むファイルへのリクエストについても同様に扱われます。ハッシュの生成法については、本ガイドの[production環境の場合](#production環境の場合)で後述します。

Sprocketsは`config.assets.paths`で指定したパスも探索します。このパスには、標準的なアプリケーションパスと、Railsエンジンによって追加されるすべてのパスが含まれます。

必要であれば画像ファイルをサブディレクトリに置いて整理することもできます。この画像にアクセスするには、ディレクトリ名を含めて以下のようにタグで指定します。

```erb
<%= image_tag "icons/rails.png" %>
```

WARNING: アセットのプリコンパイルを行っている場合（[production環境の場合](#production環境の場合)を参照）、存在しないアセットへのリンクを含むページを呼び出すと例外が発生します。空文字へのリンクも同様に例外が発生します。ユーザーから提供されるデータに対して`image_tag`などのヘルパーを使う場合はご注意ください。

#### CSSとERB

アセットパイプラインは自動的にERBを評価します。たとえば、cssアセットファイルに`erb`という拡張子を追加すると（`application.css.erb`など）、CSSルール内で`asset_path`などのヘルパーが利用可能になります。

```css
.class { background-image: url(<%= asset_path 'image.png' %>) }
```

ここには、指定されたアセットへのパスを記述します。上の例では、アセット読み込みパスのいずれかにある画像ファイル（`app/assets/images/image.png`など） が指定されたと解釈されます。この画像が既にフィンガープリント付きで`public/assets`にあれば、このパスによる参照は有効になります。

[データURIスキーム](https://ja.wikipedia.org/wiki/Data_URI_scheme)（CSSファイルにデータを直接埋め込む手法）を使いたい場合は、`asset_data_uri`を使えます。

```css
#logo { background: url(<%= asset_data_uri 'logo.png' %>) }
```

上のコードは、CSSソースに正しくフォーマットされたdata URIを挿入します。

この場合、`-%>`でタグを閉じることはできませんのでご注意ください。

#### CSSとSass

アセットパイプラインを利用する場合は、最終的にアセットへのパスを変換する必要があります。このために、`sass-rails` gemは名前が`-url`や`-path`で終わる（Sass内ではハイフンですが、Rubyではアンダースコアで表します）各種ヘルパーを提供しています。ヘルパーがサポートするアセットクラスは、画像、フォント、ビデオ、音声、JavaScript、stylesheetです。

* `image-url("rails.png")`は`url(/assets/rails.png)`に変換される
* `image-path("rails.png")`は`"/assets/rails.png"`に変換される

以下のような、より一般的な記法も利用できます。

* `asset-url("rails.png")`は`url(/assets/rails.png)`に変換される
* `asset-path("rails.png")`は`"/assets/rails.png"`に変換される

#### JavaScript/CoffeeScriptとERB

JavaScriptアセットに`erb`拡張子を追加すると（`application.js.erb`など）、以下のようにJavaScriptコード内で`asset_path`ヘルパーを利用できるようになります。

```js
document.getElementById('logo').src = "<%= asset_path('logo.png') %>"
```

ここには、指定されたアセットへのパスを記述します。

### マニフェストファイルとディレクティブ

Sprocketsでは、どのアセットをインクルードしてサポートするかを指定するのにマニフェストファイルを利用します。マニフェストファイルには**ディレクティブ **（directive: 命令、指示）を記述します。必要なファイルをディレクティブで指定し、それに基いて最終的に単一のCSSやJavaScriptファイルがビルドされます。Sprocketsはディレクティブで指定されたファイルを読み込み、必要に応じて処理を行い、連結して単一のファイルを生成し、圧縮します（`Rails.application.config.assets.compress`がtrueの場合）。ファイルを連結してひとつにすることにより、ブラウザからサーバーへのリクエスト数を削減でき、ページの読み込み時間が大きく短縮されます。圧縮によってファイルサイズも小さくなり、ブラウザへの読み込み時間が短縮されます。

新規作成したRailsアプリケーションにはデフォルトで`app/assets/javascripts/application.js`ファイルに以下のような記述が含まれています。

```js
// ...
//= require rails-ujs
//= require turbolinks
//= require_tree .
```

JavaScriptのSprocketsディレクティブは`//=`で始まります。上の例では`require`と`require_tree`というディレクティブが使われています。`require`は、必要なファイルをSprocketsに指示するときに使います。ここでは`rails-ujs.js`と`turbolinks.js`を必要なファイルとして指定しています。これらのファイルはSprocketsの検索パスの中から読み込み可能になっています。このディレクティブでは拡張子を明示的に指定する必要はありません。ディレクティブが`.js`ファイルに書かれていれば、Sprocketsによって自動的に`.js`ファイルが`require`されているとみなされます。

`require_tree`ディレクティブは、指定されたディレクトリ以下の 「すべての」JavaScriptファイルを再帰的にインクルードし、出力に含めます。このパスは、マニフェストファイルからの相対パスとして指定する必要があります。`require_directory`ディレクティブを使うと、指定されたディレクトリの直下にあるすべてのJavaScriptファイルのみをインクルードします。この場合サブディレクトリは再帰的に探索されません。

ディレクティブは記載順に実行されますが、`require_tree`でインクルードされるファイルの読み込み順序は指定できません。従って、特定の読み込み順に依存しないようにする必要があります。どうしても特定のJavaScriptファイルを他のJavaScriptファイルよりも先に結合したい場合は、そのファイルへの`require`ディレクティブをマニフェストの冒頭に置きます。また、`require_directory`は、出力時に同じファイルを2回以上インクルードせずに、指定のディレクトリ内にあるすべてのJavaScriptのみをインクルードできます。

Railsは以下の行を含むデフォルトの`app/assets/stylesheets/application.css`ファイルも作成します。

```css
/* ...
*= require_self
*= require_tree .
*/
```

Railsは`app/assets/stylesheets/application.css`ファイルを作成します。これはRailsアプリケーション新規作成時に`--skip-sprockets`を指定するかどうかにかかわらず行われます。これにより、必要に応じて後からアセットパイプラインを追加することも可能です。

JavaScriptで使えるディレクティブはスタイルシートでも利用できます（なおJavaScriptと異なり、スタイルシートは明示的にインクルードされます）。CSSマニフェストにおける`require_tree`ディレクティブの動作はJavaScriptの場合と同様に、現在のディレクトリにあるすべてのスタイルシートを`require`します。

上の例では`require_self`が使われています。このディレクティブは、`require_self`呼び出しが行われた場所にそのファイルが持っているCSSを書き込みます。

NOTE: Sassファイルを複数利用している場合は、Sprocketsのディレクティブで読み込まずに[Sass `@import`ルール](http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#import)を利用する必要があります。このような場合にSprocketsディレクティブを使うと、Sassファイルが自分自身のスコープに置かれるため、その中で定義されている変数やミックスインが他のSassで利用できなくなってしまいます。

`@import "*"`や`@import "**/*"`などのようにワイルドカードマッチでツリー全体を指定することも可能です。これは`require_tree`と同様です。詳細および重要な警告については[sass-railsドキュメント](https://github.com/rails/sass-rails#features)を参照してください。

マニフェストファイルは必要に応じていくつでも使えます。たとえば、アプリケーションのadminセクションで使うJSファイルを`admin.js`マニフェストに記載し、CSSファイルを`admin.css`マニフェストに記載できます。

読み込み順についても前述のとおり反映されます。特に、個別に指定したファイルは、そのとおりの順序でコンパイルされます。たとえば、以下では3つのCSSファイルを結合しています。

```js
/* ...
*= require reset
*= require layout
*= require chrome
*/
```

### プリプロセス

適用されるプリプロセスの種類は、アセットファイルの拡張子によって決まります。コントローラやscaffoldをデフォルトのgemセットで生成した場合、通常のCSSファイルが置かれる場所にSCSSファイルが生成されます。上の例では、コントローラ名が"projects"の場合は`app/assets/stylesheets/projects.scss`ファイルが生成されます。

developmentモードの場合、あるいはアセットパイプラインが無効になっている場合は、これらのアセットへのリクエストは`sass` gemが提供するプロセッサによって処理され、通常のCSSとしてブラウザへのレスポンスを送信します。アセットパイプラインが有効になっている場合は、これらのアセットファイルはプリプロセスの対象となり、処理後のファイルが`public/assets`ディレクトリに置かれてRailsアプリケーションやWebサーバーによって配信されます。

アセットファイル名に別の拡張子を追加すると、プリプロセス時に別のレイヤを追加でリクエストできるようになります。アセットファイル名の拡張子は、「右から左」の順に処理されます。つまりアセットファイル名の拡張子は、これに沿って処理の必要な順序で与える必要があります。たとえば、`app/assets/stylesheets/projects.scss.erb`というスタイルシートでは、最初にERBとして処理され、続いてSCSS、最後にCSSとして処理されます。同様に、 `app/assets/javascripts/projects.coffee.erb` というJavaScriptファイルの場合は、ERB → CoffeeScript → JavaScript の順に処理されます。

このプリプロセス順序は非常に重要なので、ぜひ理解しておきましょう。たとえば、仮に`app/assets/javascripts/projects.erb.coffee`というファイルを呼び出すと、最初にCoffeeScriptインタプリタによって処理されますが、次のERBで処理できないので問題が発生することがあります。

development環境の場合
--------------

developmentモードの場合、アセットは個別のファイルとして、マニフェストファイルの記載順に読み込まれます。

`app/assets/javascripts/application.js`というマニフェストの内容が以下のようになっているとします。

```js
//= require core
//= require projects
//= require tickets
```

上によって以下のHTMLが生成されます。

```html
<script src="/assets/application-728742f3b9daa182fe7c831f6a3b8fa87609b4007fdc2f87c134a07b19ad93fb.js"></script>
```

### アセットが見つからない場合にエラーをraiseする

sprockets-rails 3.2.0移行を使っている場合は、アセットの探索時に何も見つからなかった場合の挙動を設定できます。以下のように`unknown_asset_fallback`を`false`にすると、アセットが見つからない場合にエラーをraiseします。

```ruby
config.assets.unknown_asset_fallback = false
```

`unknown_asset_fallback`を`true`にすると、エラーをraiseせずにパスを出力します。アセットのフォールバック動作はデフォルトで`true`です。

### ダイジェストをオフにする

`config/environments/development.rb`を更新して以下を記述すると、ダイジェストをオフにできます。

```ruby
config.assets.digest = false
```

このオプションが`true`の場合は、ダイジェストが生成されてアセットへのURLに含まれるようになります。

### ソースマップをオンにする

`config/environments/development.rb`に以下を記述すると、[ソースマップ](https://developer.mozilla.org/ja/docs/Tools/Debugger/How_to/Use_a_source_map)（Source Map）を有効にできます。

```ruby
config.assets.debug = true
```

デバッグモードを有効にすると、Sprocketsはアセットごとにソースマップを生成します。このソースマップによって、ブラウザの開発コンソールで個別のファイルをデバッグできるようになります。

アセットは、サーバー起動後の最初のリクエストを受けてコンパイルされ、キャッシュされます。Sprocketは、以後のリクエストでコンパイルのオーバーヘッドを減らすために、[Cache-Control](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Cache-Control) HTTPヘッダーにmust-revalidate`を設定します。ブラウザは、これらのリクエストで[HTTP 304（Not Modified）](https://developer.mozilla.org/ja/docs/Web/HTTP/Status/304)レスポンスを受け取ります。

リクエストとリクエストの間にマニフェスト内のファイルが変更されると、サーバーは新たにコンパイルしたファイルを用いてレスポンスを返します。

production環境の場合
-------------

Sprocketsは、production環境では上述のフィンガープリントによるスキームを利用します。デフォルトでは、Railsのアセットはプリコンパイル済みかつ静的なアセットとしてWebサーバーから提供されることが前提になっています。

コンパイルされるファイルの内容を元に、プリコンパイル中にSHA256ハッシュが生成され、ファイル名に挿入されてディスクに保存されます。フィンガープリントが追加されたファイル名は、Railsヘルパーによってマニフェストファイルの代わりに使われます。

以下の例で説明します。

```erb
<%= javascript_include_tag "application" %>
<%= stylesheet_link_tag "application" %>
```

上のコードによって以下のようなフィンガープリントが生成されます。

```html
<script src="/assets/application-908e25f4bf641868d8683022a5b62f54.js"></script>
<link href="/assets/application-4dd5b109ee3439da54f5bdfd78a80473.css" rel="stylesheet" />
```

NOTE: アセットパイプラインの`:cache`オプションと`:concat`オプションは廃止されました。これらのオプションは`javascript_include_tag`と`stylesheet_link_tag`から削除してください。

フィンガープリントの振る舞いについては`config.assets.digest`初期化オプションで制御できます。デフォルトでは`true`です。

NOTE: デフォルトの`config.assets.digest`オプションは、通常は変更しないでください。ファイル名にダイジェストが含まれていないと、遠い将来にヘッダが設定されたときに、ブラウザなどのリモートクライアントがファイルの内容変更を検出できなくなり、変更を再取得できなくなってしまいます。

### アセットをプリコンパイルする

Railsには、パイプラインにあるアセットマニフェストなどのファイルを手動でコンパイルするためのコマンドが1つバンドルされています。

コンパイルされたアセットは、`config.assets.prefix`で指定された場所に保存されます。この保存場所は、デフォルトでは`/assets`ディレクトリです。

デプロイ時にこのタスクをサーバー上で呼び出すと、コンパイル済みアセットをサーバー上で直接作成できます。ローカル環境でコンパイルする方法については次のセクションを参照してください。

以下がそのタスクです。

```bash
$ RAILS_ENV=production bin/rails assets:precompile
```

なお、Capistrano（v2.15.1以降）にはデプロイ中にこのタスクを扱うレシピが含まれています。`Capfile`に以下を追加します。

```ruby
load 'deploy/assets'
```

これにより、`config.assets.prefix`で指定されたフォルダが`shared/assets`にリンクされます。
既にこの共有フォルダを利用している場合は、独自のデプロイ用タスクを作成する必要があります。

ここで重要なのは、このフォルダが複数のデプロイによって共有されていることです。これは、サーバー以外の離れた場所でキャッシュされているページが古いコンパイル済みアセットを参照している場合でも、キャッシュ済みページの期限が切れて削除されるまではその古いページへの参照が有効になるようにするためです。

ファイルをコンパイルする際のデフォルトのマッチャによって、`app/assets`フォルダ以下の`application.js`、`application.css`、およびすべての非JS/CSSファイルがインクルードされます（画像ファイルもすべて自動的にインクルードされます）。`app/assets`フォルダにあるgemも含まれます。

```ruby
[ Proc.new { |filename, path| path =~ /app\/assets/ && !%w(.js .css).include?(File.extname(filename)) },
/application.(css|js)$/ ]
```

NOTE: このマッチャ（および後述するプリコンパイル配列の他のメンバ）が適用されるのは、コンパイル前やコンパイル中のファイル名ではなく、コンパイル後の最終的なファイル名である点にご注意ください。これは、コンパイルされてJavaScriptやCSSになるような中間ファイルは、（純粋なJavaScript/CSSと同様に）マッチャの対象からすべて除外されるということです。たとえば、`.coffee`と`.scss`ファイルはコンパイル後にそれぞれJavaScriptとCSSになるので、これらは自動的にはインクルードされません。

他のマニフェストや、個別のスタイルシート/JavaScriptファイルをインクルードしたい場合は、`config/initializers/assets.rb`の`precompile`という配列を使います。

```ruby
Rails.application.config.assets.precompile += %w( admin.js admin.css )
```

NOTE: プリコンパイル配列にSassやCoffeeScriptファイルなどを追加する場合にも、必ず`.js`や`.css`で終わるファイル名（つまりコンパイル後のファイル名として期待されるファイル名）も指定してください。

このタスクによって、すべてのアセットファイルのリストとそれに対応するフィンガープリントを含む`.sprockets-manifest-randomhex.json`ファイルも生成されます（`randomhex`は16バイトのランダムな16進文字列です）。これは、マッピングのリクエストがSprocketsに戻されるのを回避するためにRailsヘルパーメソッドで使われます。典型的なマニフェストファイルは以下のような感じになります。

```ruby
{"files":{"application-aee4be71f1288037ae78b997df388332edfd246471b533dcedaa8f9fe156442b.js":{"logical_path":"application.js","mtime":"2016-12-23T20:12:03-05:00","size":412383,
"digest":"aee4be71f1288037ae78b997df388332edfd246471b533dcedaa8f9fe156442b","integrity":"sha256-ruS+cfEogDeueLmX3ziDMu39JGRxtTPc7aqPn+FWRCs="},
"application-86a292b5070793c37e2c0e5f39f73bb387644eaeada7f96e6fc040a028b16c18.css":{"logical_path":"application.css","mtime":"2016-12-23T19:12:20-05:00","size":2994,
"digest":"86a292b5070793c37e2c0e5f39f73bb387644eaeada7f96e6fc040a028b16c18","integrity":"sha256-hqKStQcHk8N+LA5fOfc7s4dkTq6tp/lub8BAoCixbBg="},
"favicon-8d2387b8d4d32cecd93fa3900df0e9ff89d01aacd84f50e780c17c9f6b3d0eda.ico":{"logical_path":"favicon.ico","mtime":"2016-12-23T20:11:00-05:00","size":8629,
"digest":"8d2387b8d4d32cecd93fa3900df0e9ff89d01aacd84f50e780c17c9f6b3d0eda","integrity":"sha256-jSOHuNTTLOzZP6OQDfDp/4nQGqzYT1DngMF8n2s9Dto="},
"my_image-f4028156fd7eca03584d5f2fc0470df1e0dbc7369eaae638b2ff033f988ec493.png":{"logical_path":"my_image.png","mtime":"2016-12-23T20:10:54-05:00","size":23414,
"digest":"f4028156fd7eca03584d5f2fc0470df1e0dbc7369eaae638b2ff033f988ec493","integrity":"sha256-9AKBVv1+ygNYTV8vwEcN8eDbxzaequY4sv8DP5iOxJM="}},
"assets":{"application.js":"application-aee4be71f1288037ae78b997df388332edfd246471b533dcedaa8f9fe156442b.js",
"application.css":"application-86a292b5070793c37e2c0e5f39f73bb387644eaeada7f96e6fc040a028b16c18.css",
"favicon.ico":"favicon-8d2387b8d4d32cecd93fa3900df0e9ff89d01aacd84f50e780c17c9f6b3d0eda.ico",
"my_image.png":"my_image-f4028156fd7eca03584d5f2fc0470df1e0dbc7369eaae638b2ff033f988ec493.png"}}
```

マニフェストのデフォルトの置き場所は、`config.assets.prefix`で指定された場所のルートディレクトリ）です（デフォルトは'/assets'。

NOTE: productionモードで見つからないプリコンパイル済みファイルがあると、見つからないファイル名をエラーメッセージに含んだ`Sprockets::Helpers::RailsHelper::AssetPaths::AssetNotPrecompiledError`が発生します。

#### 遠い将来に期限が切れるヘッダー

プリコンパイル済みのアセットはファイルシステム上に置かれ、Webサーバーから直接クライアントに配信されます。これらプリコンパイル済みアセットには、いわゆる「遠い将来に期限が切れるヘッダ（far-future headers）」はデフォルトでは含まれません。したがって、フィンガープリントのメリットを得るためには、サーバーの設定を更新してこのヘッダを含める必要があります。

Apacheの設定:

```apache
# Expires* ディレクティブを使う場合はApacheの
# `mod_expires`モジュールを有効にする必要がある
<Location /assets/>
  # Last-Modifiedフィールドが存在する場合はETagの利用は推奨されない
  Header unset ETag
  FileETag None
  # RFCによるとキャッシュは最長1年まで
  ExpiresActive On
  ExpiresDefault "access plus 1 year"
</Location>
```

NGINXの場合:

```nginx
location ~ ^/assets/ {
  expires 1y;
  add_header Cache-Control public;

  add_header ETag "";
}
```

### ローカルでプリコンパイルする

場合によっては、productionサーバーでアセットをコンパイルしたくないことがあります。たとえば、producionファイルシステムへの書き込みアクセスが制限されている場合や、アセットを変更しないデプロイが頻繁に行われる場合などが考えられます。

そのような場合は、アセットをローカルでプリコンパイルできます。つまり、production向けの最終的なコンパイル済みアセットを、production環境にデプロイする前にソースコードリポジトリに追加するということです。この方法なら、productionサーバーにデプロイするたびにproductionで別途プリコンパイルを実行する必要はありません。

以下を実行すると、production向けにプリコンパイルできます。

```bash
$ RAILS_ENV=production rails assets:precompile
```

ただし以下の注意点があります。

*  プリコンパイル済みのアセットが配信可能な状態になっていると、元の（コンパイルされていない）アセットと一致していなくてもプリコンパイル済みのアセットが配信されてしまいます。**これはdevelopment環境でも同じことが起きます**。

    developmentサーバーが常にアセット変更のたびにオンザフライでコンパイルし、常に最新のコードが反映されるようにするには、development環境ではproductionと異なるディレクトリにプリコンパイル済みアセットを保存する設定が必要です。そうしないと、production用のプリコンパイル済みアセットがdevelopment環境でのブラウザ表示に影響を与えてしまいます（つまりアセットを変更してもブラウザに反映されなくなります）。

    この設定は、`config/environments/development.rb`ファイルに以下の行を追加することでできます。

    ```ruby
    config.assets.prefix = "/dev-assets"
    ```

* Capistranoなどの開発ツールで行われるアセットプリコンパイルを無効にしておく必要があります。
* アセットの圧縮や最小化に必要なツールをdevelopment環境のシステムで利用可能にしておく必要があります。

### 動的コンパイル

状況によっては動的コンパイル（live compilation）を使いたいこともあります。動的コンパイルモードでは、パイプラインのアセットへのリクエストは直接Sprocketsによって扱われます。

このオプションを有効にするには以下を設定します。

```ruby
config.assets.compile = true
```

最初のリクエストを受けると、アセットは上述のdevelopment環境のところで説明したとおりにコンパイルおよびキャッシュされ、ヘルパーで使われるマニフェスト名にSHA256ハッシュが含まれるようになります。

また、Sprocketsは[`Cache-Control` HTTPヘッダー](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Cache-Control)を`max-age=31536000`に変更します。このヘッダーは、サーバーとクライアントブラウザの間にあるすべてのキャッシュ（プロキシなど）に対して「サーバーが配信するこのコンテンツは1年間キャッシュに保存してよい」と通知します。これにより、そのサーバーのアセットに対するリクエスト数を削減でき、アセットをローカルブラウザのキャッシュやその他の中間キャッシュで代替するよい機会を得られます。

このモードはデフォルトよりもメモリ消費が多くパフォーマンスも落ちるため、通常はおすすめできません。

productionアプリケーションのデプロイ先のシステムに既存のJavaScriptランタイムがない場合は、以下をGemfileに記述します。

```ruby
group :production do
  gem 'mini_racer'
end
```

### CDN

[CDN（コンテンツデリバリーネットワーク）](https://ja.wikipedia.org/wiki/%E3%82%B3%E3%83%B3%E3%83%86%E3%83%B3%E3%83%84%E3%83%87%E3%83%AA%E3%83%90%E3%83%AA%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF)は、全世界を対象としてアセットをキャッシュすることを主な目的として設計されています。CDNを利用すると、ブラウザからアセットをリクエストしたときに、ネットワーク上で最も「近く」にあるキャッシュのコピーが使われます。production環境のRailsサーバーから（中間キャッシュを使わずに）直接アセットを配信しているのであれば、アプリケーションとブラウザの間でCDNを利用するのがベストプラクティスです。

CDNの典型的な利用法は、productionサーバーを "origin" サーバーとして設定することです。つまり、ブラウザがCDN上のアセットをリクエストしてキャッシュが見つからない場合は、オンデマンドでサーバーからアセットファイルを取得してキャッシュするということです。たとえば、Railsアプリケーションを`example.com`というドメインで運用しており、`mycdnsubdomain.fictional-cdn.com`というCDNが設定済みであるとします。ブラウザから`mycdnsubdomain.fictional-cdn.com/assets/smile.png`がリクエストされると、CDNはいったん元のサーバーの`example.com/assets/smile.png`にアクセスしてこのリクエストをキャッシュします。CDN上の同じURLに対して次のリクエストが発生すると、キャッシュされたコピーにヒットします。CDNがアセットを直接配信可能な場合は、ブラウザからのリクエストが直接Railsサーバーに到達することはありません。CDNが配信するアセットはネットワーク上でブラウザに「近い」位置にあるので、リクエストは高速化されます。また、サーバーはアセットの送信に使う時間を節約できるので、アプリケーション本来のコードをできるだけ高速で配信することに専念できます。

#### CDNで静的なアセットを提供する

CDNを設定するには、Railsアプリケーションがインターネット上でproductionモードで運用されており、`example.com`などのような一般公開されているURLでアクセス可能になっている必要があります。次に、クラウドホスティングプロバイダが提供するCDNサービスと契約を結ぶ必要もあります。その際、CDNの"origin"設定をRailsアプリケーションのWebサイト`example.com`にする必要もあります。originサーバーの設定方法のドキュメントについてはプロバイダーにお問い合わせください。

利用するCDNから、アプリケーションで使うカスタムサブドメイン（例: `mycdnsubdomain.fictional-cdn.com`）を交付してもらう必要もあります（メモ: fictional-cdn.comは説明用のドメインであり、少なくとも執筆時点では本当のCDNプロバイダーではありません）。CDNサーバーの設定が終わったら、今度はブラウザに対して、Railsサーバーに直接アクセスするのではなく、CDNからアセットを取得するように通知する必要があります。これを行なうには、従来の相対パスに代えてCDNをアセットのホストサーバーとするようRailsを設定します。Railsでアセットホストを設定するには、`config/environments/production.rb`の`config.asset_host`を以下のように設定します。

```ruby
config.asset_host = 'mycdnsubdomain.fictional-cdn.com'
```

NOTE: ここに記述するのは「ホスト名（サブドメインとルートドメインを合わせたもの）」だけです。`http://`や`https://`などのプロトコルスキームを記述する必要はありません。アセットへのリンクで使われるプロトコルスキームは、Webページヘのリクエスト発生時に、そのページへのデフォルトのアクセス方法に合わせて適切に生成されます。

この値は、以下のように[環境変数](https://ja.wikipedia.org/wiki/%E7%92%B0%E5%A2%83%E5%A4%89%E6%95%B0)でも設定できます。環境変数を使うと、stagingサーバー（訳注: 検証用に本番サーバーを模したサーバー）の実行が楽になります。

```ruby
config.asset_host = ENV['CDN_HOST']
```

NOTE: 上の設定が有効になるためには、サーバーの`CDN_HOST`環境変数に値（この場合は`mycdnsubdomain.fictional-cdn.com`）を設定しておく必要があります。

サーバーとCDNの設定完了後、以下のアセットを持つWebページにアクセスしたとします。

```erb
<%= asset_path('smile.png') %>
```

上の例では、`/assets/smile.png`のようなパスは返されません（読みやすくするためダイジェスト文字は省略してあります）。実際に生成されるCDNへのフルパスは以下のようになります。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

`smile.png`のコピーがCDNにあれば、CDNが代りにこのファイルをブラウザに送信します。元のサーバーはリクエストがあったことすら気づきません。ファイルのコピーがCDNにない場合は、CDNが「origin」（この場合は`example.com/assets/smile.png`）を探して今後のために保存しておきます。

一部のアセットだけをCDNで配信したい場合は、アセットヘルパーのカスタム`:host`オプションで`config.action_controller.asset_host`の値セットを上書きすることも可能です。

```erb
<%= asset_path 'image.png', host: 'mycdnsubdomain.fictional-cdn.com' %>
```

#### CDNのキャッシュの動作をカスタマイズする

CDNはコンテンツをキャッシュすることで動作します。CDNに保存されているコンテンツが古くなったり壊れていたりすると、メリットよりも害の方が大きくなります。本セクションでは、多くのCDNにおける一般的なキャッシュの動作について解説します。プロバイダによってはこの記述のとおりでないことがありますのでご注意ください。

##### CDNリクエストキャッシュ

これまでCDNがアセットをキャッシュするのに向いていると説明しましたが、実際にキャッシュされているのはアセット単体ではなくリクエスト全体です。リクエストにはアセット本体の他に各種ヘッダーも含まれています。ヘッダーの中でもっとも重要なのは`Cache-Control`です。これはCDN（およびWebブラウザ）にキャッシュの取り扱い方法を通知するためのものです。たとえば、誰かが実際には存在しないアセット`/assets/i-dont-exist.png`にリクエストを行い、Railsが404エラーを返したとします。このときに`Cache-Control`ヘッダーが有効になっていると、CDNがこの404エラーページをキャッシュする可能性があります。

##### CDNヘッダをデバッグする

このヘッダが正しくキャッシュされているかどうかを確認するひとつの方法は、[curl]( http://explainshell.com/explain?cmd=curl+-I+http%3A%2F%2Fwww.example.com)を使う方法です。curlを使ってサーバーとCDNにそれぞれリクエストを送信し、ヘッダーが同じであるかどうかを以下のように確認できます。

```bash
$ curl -I http://www.example/assets/application-
d0e099e021c95eb0de3615fd1d8c4d83.css
HTTP/1.1 200 OK
Server: Cowboy
Date: Sun, 24 Aug 2014 20:27:50 GMT
Connection: keep-alive
Last-Modified: Thu, 08 May 2014 01:24:14 GMT
Content-Type: text/css
Cache-Control: public, max-age=2592000
Content-Length: 126560
Via: 1.1 vegur
```

以下はCDNのコピーです。

```bash
$ curl -I http://mycdnsubdomain.fictional-cdn.com/application-
d0e099e021c95eb0de3615fd1d8c4d83.css
HTTP/1.1 200 OK Server: Cowboy Last-
Modified: Thu, 08 May 2014 01:24:14 GMT Content-Type: text/css
Cache-Control:
public, max-age=2592000
Via: 1.1 vegur
Content-Length: 126560
Accept-Ranges:
bytes
Date: Sun, 24 Aug 2014 20:28:45 GMT
Via: 1.1 varnish
Age: 885814
Connection: keep-alive
X-Served-By: cache-dfw1828-DFW
X-Cache: HIT
X-Cache-Hits:
68
X-Timer: S1408912125.211638212,VS0,VE0
```

CDNが提供する`X-Cache`などの機能やCDNが追加するヘッダなどの追加情報については、CDNのドキュメントを確認してください。

##### CDNとCache-Controlヘッダ

[`Cache-Control`ヘッダ](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9)は、リクエストがキャッシュされる方法を定めたW3Cの仕様です。CDNを使わない場合は、ブラウザはこのヘッダ情報に基づいてコンテンツをキャッシュします。このヘッダのおかげで、アセットで変更が発生していない場合にブラウザがCSSやJavaScriptをリクエストのたびに再度ダウンロードせずに済むので、非常に有用です。アセットの`Cache-Control`ヘッダは一般に "public" にしておくものであり、RailsサーバーはCDNやブラウザに対してそのことをこのヘッダで通知します。アセットが "public" であるということは、そのリクエストをどんなキャッシュに保存してもよいということを意味します。同様に`max-age` もこのヘッダでCDNやブラウザに通知されます。`max-age`は、オブジェクトをキャッシュに保存する期間を指定します。この期間を過ぎるとキャッシュは廃棄されます。`max-age`の値は秒単位で指定します。最大値は`31536000`であり、これは1年に相当します。Railsでは以下の設定でこの期間を指定できます。

```ruby
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}
```

production環境のアセットがアプリケーションから配信されると、キャッシュは1年間保存されます。多くのCDNはリクエストのキャッシュも保存しているので、この`Cache-Control`ヘッダーはアセットをリクエストするすべてのブラウザ（将来登場するブラウザも含む）に渡されます。ブラウザはこのヘッダを受け取ると、次回再度リクエストが必要になったときに備えてそのアセットを当分の間キャッシュに保存してよいことを認識します。

##### CDNにおけるURLベースのキャッシュ無効化について

多くのCDNでは、アセットのキャッシュを完全なURLに基いて行います。たとえば以下のアセットへのリクエストがあるとします。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile-123.png
```

上のリクエストのキャッシュは、下のアセットへのリクエストのキャッシュとは完全に異なるものとして扱われます。

```
http://mycdnsubdomain.fictional-cdn.com/assets/smile.png
```

`Cache-Control`の`max-age`を遠い将来に設定する場合は、アセットに変更が生じた時にこれらのキャッシュが確実に無効化されるようにしてください。たとえば、ニコニコマーク画像の色を黄色から青に変更したら、サイトを訪れた人には変更後の青いニコニコマークが見えるようにしたいはずです。RailsでCDNを併用している場合、Railsのアセットパイプライン`config.assets.digest`はデフォルトで`true`に設定されるので、アセットの内容が少しでも変更されれば必ずファイル名も変更されます。このとき、キャッシュ内の項目を手動で削除する必要はありません。アセットファイル名が内容に応じて常に一意になるので、ユーザーは常に最新のアセットを利用できます。

パイプラインをカスタマイズする
------------------------

### CSSを圧縮する

YUIはCSS圧縮方法のひとつです。[YUI CSS compressor](https://yui.github.io/yuicompressor/css.html)は最小化機能を提供します（訳注: この項では、圧縮 (compress) という語は最小化 (minify) や難読化 (uglify) と同じ意味で使われており、圧縮後のファイルはzipのようなバイナリではありません）。

YUI圧縮は以下の記述で有効にできます。これには`yui-compressor` gemが必要です。

```ruby
config.assets.css_compressor = :yui
```

sass-rails gemを使っている場合は、以下のように代替のCSS圧縮方法として指定できます。

```ruby
config.assets.css_compressor = :sass
```

### JavaScriptを圧縮する

JavaScriptの圧縮オプションには、`:terser`、`:closure`、`:uglifier`、`:yui`のいずれかを指定できます。それぞれ、`terser` gem、`closure-compiler` gem、`uglifier` gem、`yui-compressor` gemが必要です。

ここでは`terser` gemを例にします。Railsの`Gemfile`にはデフォルトで[terser](https://github.com/terser/terser)が含まれています（）。このgemは、NodeJS向けのコードをRubyでラップしたものです。terserによる圧縮は次のように行われます。ホワイトスペースとコメントを除去し、ローカル変数名を短くし、可能であれば`if`と`else`を三項演算子に置き換えるなどの細かな最適化を行います。

以下の設定により、JavaScriptの圧縮に`terser`が使われます。

```ruby
config.assets.js_compressor = :terser
```

NOTE: `terser`を利用するには[ExecJS](https://github.com/sstephenson/execjs#readme)をサポートするJavaScriptランタイムが必要です。macOSやWindowsを利用している場合は、OSにJavaScriptランタイムをインストールしてください。

### gzip圧縮されたアセットを提供する

デフォルトで、非圧縮版のアセットの他にgzip圧縮されたコンパイル済みアセットも生成されます。gzipアセットはデータ転送の削減に役立ちます。これを指定するには`gzip`フラグを設定します。

```ruby
config.assets.gzip = false # gzipアセットの生成を無効にする場合
```

gzip形式のアセットの配信方法については、利用しているWebサーバーのドキュメントを参照してください。

### 独自の圧縮機能を使う

CSSやJavaScriptの圧縮設定にはあらゆるオブジェクトを設定できます。設定に与えるオブジェクトには`compress`メソッドが実装されている必要があります。このメソッドは文字列のみを引数として受け取り、圧縮結果を文字列で返す必要があります。

```ruby
class Transformer
  def compress(string)
    do_something_returning_a_string(string)
  end
end
```

上のコードを有効にするには、`application.rb`の設定オプションに新しいオブジェクトを渡します。

```ruby
config.assets.css_compressor = Transformer.new
```


### アセットのパスを変更する

Sprocketsが利用するデフォルトのパブリックなパスは`/assets`です。

このパスは以下のように変更可能です。

```ruby
config.assets.prefix = "/他のパス"
```

このオプションは、アセットパイプラインを利用していない既存のプロジェクトがあり、そのプロジェクトの既存のパスを指定したり、別途新しいリソース用のパスを指定したりする場合に便利です。

### X-Sendfileヘッダー

`X-Sendfile`ヘッダーはWebサーバーに対するディレクティブであり、アプリケーションからのレスポンスをブラウザに送信せずに破棄し、代りに別のファイルをディスクから読みだしてブラウザに送信します。このオプションはデフォルトでは無効です。サーバーがこのヘッダーをサポートしていればオンにできます。このオプションをオンにすると、それらのファイル送信がWebサーバーに一任され、それによって高速化されます。この機能の利用方法については[`send_file`](http://api.rubyonrails.org/classes/ActionController/DataStreaming.html#method-i-send_file) APIドキュメントを参照してください。

ApacheとNGINXではこのオプションがサポートされており、以下のように`config/environments/production.rb`で有効にできます。

```ruby
# config.action_dispatch.x_sendfile_header = "X-Sendfile" # Apache用
# config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # NGINX用
```

WARNING: 既存のRailsアプリケーションをアップグレードする際にこの機能の利用を検討している場合は、このオプションの貼り付け先に十分ご注意ください。このオプションを貼り付けてよいのは`production.rb`と、production環境として振る舞わせたい他の環境ファイルだけです。`application.rb`ではありません。

TIP: 詳しくは、production環境で利用するWebサーバーのドキュメントを参照してください。
- [Apache](https://tn123.org/mod_xsendfile/)
- [NGINX](http://wiki.nginx.org/XSendfile)

アセットのキャッシュストア
------------------

デフォルトのSprocketsは、development環境とproduction環境で`tmp/cache/assets`にアセットをキャッシュします。これは以下のように変更できます。

```ruby
config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:memory_store,
                                                { size: 32.megabytes })
end
```

アセットキャッシュストアを無効にするには以下のようにします。

```ruby
config.assets.configure do |env|
  env.cache = ActiveSupport::Cache.lookup_store(:null_store)
end
```

アセットをGemに追加する
--------------------------

アセットはgemの形式で外部から持ち込むこともできます。

そのよい例は`jquery-rails` gemです。これは標準のJavaScriptライブラリをgemとしてRailsに提供します。このgemには`Rails::Engine`から継承したエンジンクラスが1つ含まれています。このgemを導入することにより、Railsはこのgem用のディレクトリにアセットを配置可能であることを認識し、`app/assets`、`lib/assets`、`vendor/assets`ディレクトリがSprocketsの検索パスに追加されます。

ライブラリやGemをプリプロセッサ化する
------------------------------------------

Sprocketsでは機能を拡張するのにProcessors、Transformers、Compressors、Exportersを使います。詳しくはSprocketsのREADME「[Extending Sprockets](https://github.com/rails/sprockets/blob/master/guides/extending_sprockets.md)」を参照してください。以下ではtext/css (`.css`)ファイルの末尾にコメントを追加するプリプロセッサを登録しています。

```ruby
module AddComment
  def self.call(input)
    { data: input[:data] + "/* Hello From my sprockets extension */" }
  end
end
```

これで入力データを変更するモジュールができたので、続いてMIMEタイプのプリプロセッサとして登録します。

```ruby
Sprockets.register_preprocessor 'text/css', AddComment
```
