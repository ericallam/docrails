Rails エンジン入門
============================

本ガイドでは、Railsの「エンジン」について解説します。Railsエンジンのきわめて簡潔で使いやすいインターフェイスを用いて、ホストとなるRailsアプリケーションに機能を追加する方法についても解説します。

このガイドの内容:

* エンジンの役割
* エンジンの生成方法
* エンジンのビルド方法
* エンジンをアプリケーションにフックする
* エンジン機能をアプリケーションで上書きする
* 読み込み/設定フックでRailsフレームワークが読み込まれないようにする方法

--------------------------------------------------------------------------------


Railsにおけるエンジンの役割
-----------------

エンジン (engine) は、ホストとなるRailsアプリケーションに機能を提供するミニチュア版Railsアプリケーションとみなせます。この場合、ホストとなるRailsアプリケーションは、実際にはエンジンに「ターボをかけた」ようなものにすぎず、`Rails::Application`クラスは`Rails::Engine`から多くの振る舞いを継承します。

すなわち、エンジンとアプリケーションは、細かな違いを除けばほぼ同じであると考えられます。本ガイドでもこの点をたびたび確認します。エンジンとアプリケーションは、同じ構造を共有しています。

エンジンはプラグインとも密接に関連します。エンジンやプラグインは、どちらも共通の`lib`ディレクトリ構造を共有し、どちらも`rails plugin new`ジェネレータを用いて生成されます。両者の違いは、Railsはエンジンを一種の「完全なプラグイン」とみなしている点です。これは、エンジンを生成する際にジェネレータコマンドで`--full`を与えることからもわかります。このガイドでは、実際には`--mountable`オプションを使います。このオプションは、`--full`のオプション以外にもいくつかの機能を追加します。
以後本ガイドでは「完全なプラグイン (full plugin)」を単に「エンジン」と呼びます。エンジンがプラグインになることも、プラグインがエンジンになることもできます。

本ガイドでの説明用に作成するエンジンには「blorgh」(blogのもじり) という名前を付けます。このエンジンはホストアプリケーションにブログ機能を追加し、記事とコメントを作成できます。本ガイドでは、最初にこのエンジンを単体で動作するようにし、次にこのエンジンをアプリケーションにフックします。

エンジンはホストアプリケーションから分離しておくこともできます。「分離」とは、あるアプリケーションが`articles_path`のようなルーティングヘルパーによってパスを提供できるとすると、そのアプリケーションのエンジンも同じく`articles_path`というヘルパーによってパスを提供でき、しかも両者が衝突しないということです。エンジンを分離すると、コントローラ名、モデル名、テーブル名はすべて名前空間化されます。これについては本ガイドで後述します。

ここで、ぜひ理解しておくべき重要な点があります。アプリケーションは **いかなる場合も** エンジンよりも優先されます。ある環境において、最終的な決定権を持つのはアプリケーション自身です。エンジンはアプリケーションの動作を大幅に変更するものではなく、アプリケーションを単に拡張するものです。

その他のエンジンに関するドキュメントについては、[Devise](https://github.com/plataformatec/devise) (親アプリケーションに認証機能を提供するエンジン) や [Thredded](https://github.com/thredded/thredded) (フォーラム機能を提供するエンジン) を参照してください。この他に、[Spree](https://github.com/spree/spree) (eコマースプラットフォーム) や[Refinery CMS](https://github.com/refinery/refinerycms) (CMSエンジン) などもあります。

最後に、エンジン機能はJames Adam、Piotr Sarnacki、Railsコアチーム、そして多くの人々の助けなしでは実現できなかったでしょう。彼らに会うことがあったら、ぜひ感謝の気持ちをお伝えください。

エンジンを生成する
--------------------

エンジンを生成するには、プラグインジェネレータを実行し、必要に応じてオプションをジェネレータに渡します。blorghの場合は「マウンタブル」エンジン（マウント可能なエンジン）として生成するので、ターミナルで以下のコマンドを実行します。

```bash
$ bin/rails plugin new blorgh --mountable
```

プラグインジェネレータで利用できるオプションの一覧をすべて表示するには、以下を入力します。

```bash
$ bin/rails plugin --help
```

`--mountable`オプションは、名前空間（namespace）で分離されたマウンタブルエンジンを生成する場合に使います。このジェネレータで生成したプラグインのスケルトン構造は、`--full`オプションを使った場合と同じです。`--full`オプションは、以下を提供するスケルトン構造を含むエンジンを作成します。

  * `app`ディレクトリツリー
  * `config/routes.rb`ファイル

    ```ruby
    Rails.application.routes.draw do
    end
    ```

  * `lib/blorgh/engine.rb`ファイルは、Railsアプリケーションが標準で持つ`config/application.rb`ファイルと同一の機能を持ちます。

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
      end
    end
    ```

`--mountable`オプションを使うと、`--full`オプションに以下も追加されます。

  * アセットマニフェストファイル（`application.js`および`application.css`）
  * 名前空間化された`ApplicationController`スタブ
  * 名前空間化された`ApplicationHelper`スタブ
  * エンジンで使うレイアウトビューテンプレート
  * `config/routes.rb`での名前空間分離

    ```ruby
    Blorgh::Engine.routes.draw do
    end
    ```

  * `lib/blorgh/engine.rb`での名前空間分離

    ```ruby
    module Blorgh
      class Engine < ::Rails::Engine
        isolate_namespace Blorgh
      end
    end
    ```

さらに、`--mountable`オプションはダミーのテスト用アプリケーションを`test/dummy`に配置するようジェネレータに指示します。これを行うには、以下のダミーアプリケーションのルーティングファイルを`test/dummy/config/routes.rb`に追加します。

```ruby
mount Blorgh::Engine => "/blorgh"
```

### エンジンの内部

#### 重要なファイル

新しく作成したエンジンのルートディレクトリには、`blorgh.gemspec`というファイルが置かれます。アプリケーションにこのエンジンを後からインクルードするには、`Gemfile`に以下の行を追加します。

```ruby
gem 'blorgh', path: 'engines/blorgh'
```

Gemfileを更新したら、いつものように`bundle install`を実行するのを忘れないこと。エンジンを通常のgemと同様に`Gemfile`に記述すると、Bundlerはgemと同様にエンジンを読み込み、`blorgh.gemspec`ファイルを解析し、`lib`以下に置かれているファイル（この場合`lib/blorgh.rb`）をrequireします。このファイルは、(`lib/blorgh/engine.rb`に置かれている) `blorgh/engine.rb`ファイルをrequireし、`Blorgh`という基本モジュールを定義します。

```ruby
require "blorgh/engine"

module Blorgh
end
```

TIP: エンジンによっては、このファイルをエンジン全体で使うグローバル設定オプションとして配置したいこともあるでしょう。これは比較的よいアイデアです。設定オプションを提供したい場合は、エンジンの`module`が定義されているファイルが、まさにこれを行なうのにふさわしい場所と言えます。そのモジュールの中にメソッドを配置すれば準備が完了します。

エンジンの基本クラスは`lib/blorgh/engine.rb`の中にあります。

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    isolate_namespace Blorgh
  end
end
```

`Rails::Engine`クラスを継承すると、指定されたパスにエンジンがあることがgemからRailsに通知され、アプリケーションの内部でエンジンが正しくマウントされます。そして、エンジンの`app`ディレクトリをモデル/メーラー/コントローラ/ビューの読み込みパスに追加します。

ただし、`isolate_namespace`メソッドについては特別な注意が必要です。このメソッドの呼び出しは、エンジンのコントローラ/モデル/ルーティングなどが持つ固有の名前空間を、アプリケーション内部のコンポーネントが持つ類似の名前空間から分離する役目を担います。この呼び出しが行われないと、エンジンのコンポーネントがアプリケーション側に「漏れ出す」リスクが生じ、思わぬ動作が発生したり、エンジンの重要なコンポーネントが同じような名前のアプリケーション側コンポーネントによって上書きされてしまったりする可能性があります。名前の衝突の例として、ヘルパーを取り上げましょう。`isolate_namespace`が呼び出されないと、エンジンのヘルパーがアプリケーションのコントローラにインクルードされてしまいます。

NOTE: `Engine`クラスの定義に含まれる`isolate_namespace`の行を変更・削除しないことを**強く**推奨します。この行が変更されると、生成されたエンジン内のクラスがアプリケーションと衝突する**可能性があります**。

名前空間を分離するということは、`bin/rails g model`の実行によって生成されたモデル（ここでは `bin/rails g model article`を実行したとします）は`Article`にならず、名前空間化されて`Blorgh::Article`になるということです。さらにモデルのテーブルも名前空間化され、単なる`articles`ではなく`blorgh_articles`になります。コントローラもモデルと同様に名前空間化されます。`ArticlesController`というコントローラは`Blorgh::ArticlesController`になり、このコントローラのビューは`app/views/articles`ではなく`app/views/blorgh/articles`に置かれます。メーラーも同様に名前空間化されます。

最後に、ルーティングもエンジン内で分離されます。これは名前空間化の最も重要な部分の1つであり、これについては本ガイドの[ルーティング](#ルーティング)セクションで後述します。

#### `app`ディレクトリ

エンジンの`app`ディレクトリの中には、通常のアプリケーションでおなじみの標準的な`assets`、`controllers`、`helpers`、`mailers`、`models`、`views`ディレクトリが置かれます。モデルについては、エンジンの作成について解説するセクションで後述します。

エンジンの`app/assets`ディレクトリの下にも、通常のアプリケーションと同様に`images`や`stylesheets`ディレクトリがそれぞれあります。通常のアプリケーションと異なる点は、これらのディレクトリの下に、さらにエンジン名を持つサブディレクトリがあることです。これは、エンジンが名前空間化されるのと同様、エンジンのアセットも同様に名前空間化される必要があるからです。

`app/controllers`ディレクトリの下には`blorgh`ディレクトリが置かれます。この中には`application_controller.rb`というファイルが1つ置かれます。このファイルはエンジンのコントローラ共通の機能を提供するためのものです。この`blorgh`ディレクトリには、エンジンで使うその他のコントローラを置きます。これらのファイルを名前空間化されたディレクトリに配置することで、他のエンジンやアプリケーションに同じ名前のコントローラがある場合に、名前の衝突を避けられます。

NOTE: あるエンジンに含まれる`ApplicationController`というクラス名は、アプリケーションそのものが持つクラスと同じ名前です。その理由は、アプリケーションをエンジンに変換しやすくするためです。

 `app/controllers`と同様に、`app/helpers`、`app/jobs`、`app/mailers`、`app/models`ディレクトリの下にもそれぞれ`blorgh`というディレクトリがあり、その中に`application_helper.rb`というファイルがあります。このファイルは、エンジンのヘルパーで使うあらゆる共通機能を提供します。自分のファイルをこの名前空間化されたディレクトリの中に配置することで、他のエンジンに含まれる名前が完全に同一なルーティングヘルパーと衝突することも、アプリケーション内にあるヘルパーと衝突することも防止できます。

最後に、`app/views`ディレクトリの下には`layouts`フォルダがあります。ここには`blorgh/application.html.erb`というファイルが置かれます。このファイルは、エンジンで使うレイアウトを指定するためのものです。エンジンが単体のエンジンとして使われていれば、このファイルでレイアウトをいくらでもカスタマイズできます。レイアウト変更のためにアプリケーション自身の`app/views/layouts/application.html.erb`ファイルを変更する必要はありません。

エンジンのレイアウトをユーザーに強制したくない場合は、このファイルを削除することで、エンジンのコントローラでは別のレイアウトを参照するように変更できます。

#### `bin`ディレクトリ

このディレクトリには`bin/rails`というファイルが1つだけ置かれます。これはアプリケーション内で使っているのと似た`rails`サブコマンドであり、ジェネレータです。このような構成になっていることで、このエンジンで利用するための独自のコントローラやモデルを以下のようにコマンドで簡単に生成できます。

```bash
$ bin/rails generate model
```

もちろん、`Engine`クラスに`isolate_namespace`を持つエンジンでは、このコマンドで生成したものがすべて名前空間化されることを理解しておきましょう。

#### `test`ディレクトリ

`test`ディレクトリは、エンジンがテストを行なうための場所です。エンジンをテストするために、`test/dummy`ディレクトリに埋め込まれた縮小版のRailsアプリケーションが用意されます。このアプリケーションはエンジンを`test/dummy/config/routes.rb`ファイル内で以下のようにマウントします。

```ruby
Rails.application.routes.draw do
  mount Blorgh::Engine => "/blorgh"
end
```

上の行によって、`/blorgh`パスにあるエンジンがマウントされ、アプリケーションのこのパスを通じてのみアクセス可能になります。

testディレクトリの下には`test/integration`ディレクトリがあります。ここにはエンジンの結合テストが置かれます。`test`ディレクトリに他のディレクトリを作成することもできます。たとえば、モデルのテスト用に`test/models`ディレクトリを作成しても構いません。

エンジンの機能を提供する
------------------------------

本ガイドで説明用に作成するエンジンの機能は、記事の送信とコメントの送信です。基本的には[Railsをはじめよう](getting_started.html)と大して変わらない流れですが、多少の新味も加えられています。

NOTE: 本節のコマンドは、必ず`blorgh`エンジンのルートディレクトリで実行してください。

### Articleリソースを生成する

ブログエンジンで最初に生成すべきは、`Article`モデルとそれに関連するコントローラです。これらを手軽に生成するために、Railsのscaffoldジェネレータを使います。

```bash
$ bin/rails generate scaffold article title:string text:text
```

上のコマンドを実行すると以下の情報が出力されます。

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_articles.rb
create    app/models/blorgh/article.rb
invoke    test_unit
create      test/models/blorgh/article_test.rb
create      test/fixtures/blorgh/articles.yml
invoke  resource_route
 route    resources :articles
invoke  scaffold_controller
create    app/controllers/blorgh/articles_controller.rb
invoke    erb
create      app/views/blorgh/articles
create      app/views/blorgh/articles/index.html.erb
create      app/views/blorgh/articles/edit.html.erb
create      app/views/blorgh/articles/show.html.erb
create      app/views/blorgh/articles/new.html.erb
create      app/views/blorgh/articles/_form.html.erb
create      app/views/blorgh/articles/_article.html.erb
invoke    resource_route
invoke    test_unit
create      test/controllers/blorgh/articles_controller_test.rb
create      test/system/blorgh/articles_test.rb
invoke    helper
create      app/helpers/blorgh/articles_helper.rb
invoke      test_unit
```

scaffoldジェネレータが最初に行なうのは、`active_record`ジェネレータの呼び出しです。これはマイグレーションの生成とそのリソースのモデルを生成します。ここでご注目いただきたいのは、マイグレーションは通常の`create_articles`ではなく`create_blorgh_articles`という名前で呼ばれるという点です。これは`Blorgh::Engine`クラスの定義で呼び出される`isolate_namespace`メソッドによるものです。このモデルも名前空間化されるので、`Engine`クラス内の`isolate_namespace`呼び出しによって、`app/models/article.rb`ではなく`app/models/blorgh/article.rb`に置かれます。

続いて、そのモデルに対応する`test_unit`ジェネレータが呼び出され、（`test/models/article_test.rb`ではなく）`test/models/blorgh/article_test.rb` にモデルのテストが置かれます。フィクスチャも同様に（`test/fixtures/articles.yml`ではなく）`test/fixtures/blorgh/articles.yml`に置かれます。

その後、そのリソースに対応する行が`config/routes.rb`ファイルに挿入され、エンジンで使われます。ここで挿入される行は単に`resources :articles`となっています。これにより、そのエンジンで使われる`config/routes.rb`ファイルが以下のように変更されます。

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

このルーティングは、`YourApp::Application`クラスではなく`Blorgh::Engine`オブジェクトに基づいていることにご注目ください。これにより、エンジンのルーティングがエンジン自身に制限され、[testディレクトリ](#testディレクトリ)セクションで説明したように特定の位置にマウントできるようになります。ここでは、エンジンのルーティングがアプリケーション内のルーティングから分離されていることにもご注目ください。詳細については本ガイドの[ルーティング](#ルーティング)セクションで解説します。

続いて`scaffold_controller`ジェネレータが呼ばれ、`Blorgh::ArticlesController`という名前のコントローラを生成します (生成場所は`app/controllers/blorgh/articles_controller.rb`です)。このコントローラに関連するビューは`app/views/blorgh/articles`となります。このジェネレータは、コントローラ用のテスト (`test/controllers/blorgh/articles_controller_test.rb`) とヘルパー (`app/helpers/blorgh/articles_helper.rb`) も同時に生成します。

このジェネレータによって生成されるものはすべて正しく名前空間化されます。このコントローラのクラスは、以下のように`Blorgh`モジュール内で定義されます。

```ruby
module Blorgh
  class ArticlesController < ApplicationController
    ...
  end
end
```

NOTE: この`ArticlesController`クラスが継承するのは、アプリケーションの`ApplicationController`ではなく、`Blorgh::ApplicationController`です。

`app/helpers/blorgh/articles_helper.rb`のヘルパーも同様に名前空間化されます。

```ruby
module Blorgh
  module ArticlesHelper
    ...
  end
end
```

これにより、たとえ他のエンジンやアプリケーションにarticleリソースがあっても衝突を回避できます。

エンジンのルートディレクトリで`bin/rails db:migrate`を実行すると、scaffoldジェネレータによって生成されたマイグレーションが実行されます。続いて`test/dummy`ディレクトリで`rails server`を実行してみましょう。`http://localhost:3000/blorgh/articles`をブラウザで表示すると、生成されたデフォルトのscaffoldが表示されます。表示されたものをいろいろクリックしてみてください。これで、最初の機能を備えたエンジンの生成に成功しました。

コンソールで遊んでみたいのであれば、`rails console`でRailsアプリケーションをコンソールで動かせます。`Article`モデルは前述のとおり名前空間化されているので、このモデルを参照するには`Blorgh::Article`と指定する必要があります。

```irb
>> Blorgh::Article.find(1)
=> #<Blorgh::Article id: 1 ...>
```

最後の作業です。このエンジンの`articles`リソースはエンジンのルート（root）パスに置くべきです。これは、エンジンのマウントされているルートパスをユーザーがブラウザで表示したときに、記事の一覧が表示されるべきだからです。これを行うには、エンジンの`config/routes.rb`ファイルに以下の記述を追加します。

```ruby
root to: "articles#index"
```

これで、ユーザーが (`/articles`ではなく) エンジンのルートパスをブラウザで表示すると記事の一覧が表示されるようになりました。つまり、わざわざ`http://localhost:3000/blorgh/articles`と指定しなくても`http://localhost:3000/blorgh`と指定すれば済むようになります。

### commentsリソースを生成する

エンジンで記事を新規作成できるようになったので、今度は記事にコメントを追加する機能も付けてみましょう。これを行なうには、commentモデルとcommentsコントローラを生成し、articles scaffoldを変更してコメントを表示できるようにし、それから新規コメントを作成できるようにします。

エンジンのルートディレクトリで、モデルのジェネレータを実行します。このとき、`Comment`モデルを生成すること、integer型の`article_id`カラムとtext型の`text`カラムを持つテーブルと関連付けるよう指定します。

```bash
$ bin/rails generate model Comment article_id:integer text:text
```

上によって以下が出力されます。

```
invoke  active_record
create    db/migrate/[timestamp]_create_blorgh_comments.rb
create    app/models/blorgh/comment.rb
invoke    test_unit
create      test/models/blorgh/comment_test.rb
create      test/fixtures/blorgh/comments.yml
```

このジェネレータ呼び出しでは必要なモデルファイルだけが生成されます。さらに`blorgh`ディレクトリの下で名前空間化され、`Blorgh::Comment`というモデルクラスも作成されます。それではマイグレーションを実行してblorgh_commentsテーブルを生成してみましょう。

```bash
$ bin/rails db:migrate
```

記事のコメントが表示されるよう、`app/views/blorgh/articles/show.html.erb`を編集して、以下の行を「Edit」リンクの直前に追加します。

```html+erb
<h3>Comments</h3>
<%= render @article.comments %>
```

上の行では、`Blorgh::Article`モデルとコメントが`has_many`関連付けとして定義されている必要がありますが、現時点ではまだありません。この定義を行なうために、`app/models/blorgh/article.rb`を開いてモデルに以下の行を追加します。

```ruby
has_many :comments
```

これにより、モデルは以下のようになります。

```ruby
module Blorgh
  class Article < ApplicationRecord
    has_many :comments
  end
end
```

NOTE: この`has_many`は`Blorgh`モジュールの中にあるクラスの中で定義されています。これだけで、これらのオブジェクトに対して`Blorgh::Comment`モデルを使いたいという意図がRailsに自動的に認識されます。つまり、ここでは`:class_name`オプションでクラス名を指定する必要はありません。

続いて、記事を作成するためのフォームを作成する必要があります。フォームを追加するには、`app/views/blorgh/articles/show.html.erb`の`render @article.comments`呼び出しの直後に以下の行を追加します。

```erb
<%= render "blorgh/comments/form" %>
```

続いて、この行を出力に含めるためのパーシャル (部分テンプレート) も必要です。`app/views/blorgh/comments`にディレクトリを作成し、`_form.html.erb`というファイルを作成します。このファイルの中に以下のパーシャルを記述します。

```html+erb
<h3>New comment</h3>
<%= form_with(model: [@article, @article.comments.build], local: true) do |form| %>
  <p>
    <%= form.label :text %><br>
    <%= form.text_area :text %>
  </p>
  <%= form.submit %>
<% end %>
```

このフォームが送信されると、エンジン内の`/articles/:article_id/comments`というルーティングに対して`POST`リクエストを送信しようとします。このルーティングはまだ存在していないので、`config/routes.rb`の`resources :articles`行を以下のように変更します。

```ruby
resources :articles do
  resources :comments
end
```

これでcomments用のネストしたルーティングが作成されました。これが上のフォームで必要となります。

ルーティングはできましたが、ルーティング先のコントローラがまだありません。これを作成するには、アプリケーションのルートディレクトリで以下のコマンドを実行します。

```bash
$ bin/rails g controller comments
```

上によって以下が生成されます。

```
create  app/controllers/blorgh/comments_controller.rb
invoke  erb
 exist    app/views/blorgh/comments
invoke  test_unit
create    test/controllers/blorgh/comments_controller_test.rb
invoke  helper
create    app/helpers/blorgh/comments_helper.rb
invoke    test_unit
```

このフォームは`POST`リクエストを`/articles/:article_id/comments`に送信します。これに対応するのは`Blorgh::CommentsController`の`create`アクションです。このアクションを作成する必要があります。`app/controllers/blorgh/comments_controller.rb`のクラス定義の中に以下の行を追加します。

```ruby
def create
  @article = Article.find(params[:article_id])
  @comment = @article.comments.create(comment_params)
  flash[:notice] = "Comment has been created!"
  redirect_to articles_path
end

private
  def comment_params
    params.require(:comment).permit(:text)
  end
```

いよいよ、コメントフォームが動作するのに必要な最後の手順です。コメントはまだ正常に表示できません。この時点でコメントを作成しようとすると、以下のようなエラーが生じるでしょう。

```
Missing partial blorgh/comments/_comment with {:handlers=>[:erb, :builder],
:formats=>[:html], :locale=>[:en, :en]}. Searched in:   *
"/Users/ryan/Sites/side_projects/blorgh/test/dummy/app/views"   *
"/Users/ryan/Sites/side_projects/blorgh/app/views"
```

このエラーは、コメントの表示に必要なパーシャルをエンジンが見つけられないためです。Railsはアプリケーションの (`test/dummy`) `app/views`を最初に検索し、続いてエンジンの`app/views`ディレクトリを検索します。見つからない場合はエラーになります。エンジン自身は`blorgh/comments/comment`を検索すべきであることを認識しています。これは、エンジンが受け取るモデルオブジェクトが`Blorgh::Comment`クラスに属しているためです。

さしあたって、コメントテキストを出力する役目をこのパーシャルに担ってもらわなければなりません。`app/views/blorgh/comments/_comment.html.erb`ファイルを作成し、以下の記述を追加します。

```erb
<%= comment_counter + 1 %>. <%= comment.text %>
```

`<%= render @article.comments %>`呼び出しによって`comment_counter`ローカル変数が返されます。この変数は自動的に定義され、コメントをiterateするたびにカウントアップします。この例では、作成されたコメントの横に小さな数字を表示するのに使っています。

これでブログエンジンのコメント機能ができました。今度はこの機能をアプリケーションの中で使ってみましょう。

アプリケーションにフックする
---------------------------

エンジンをアプリケーションで利用するのはきわめて簡単です。本セクションでは、エンジンをアプリケーションにマウントして必要な初期設定を行い、アプリケーションが提供する`User`クラスにエンジンをリンクして、エンジン内の記事とコメントに所有者権限を与えるところまでをカバーします。

### エンジンをマウントする

最初に、利用するエンジンをアプリケーションの`Gemfile`に記述する必要があります。テストに使える手頃なアプリケーションが見当たらない場合は、エンジンのディレクトリの外で以下の`rails new`コマンドを実行してアプリケーションを作成してください。

```bash
$ rails new unicorn
```

エンジンを`Gemfile`で指定する方法は、他のgemを指定する方法と普通は同じです。

```ruby
gem 'devise'
```

ただし、この`blorgh`エンジンはローカルPCで開発中であり、gemリポジトリには存在しないので、`Gemfile`ファイル内でエンジンgemへのパスを`:path`オプションで指定する必要があります。

```ruby
gem 'blorgh', path: 'engines/blorgh'
```

続いて`bundle`コマンドを実行し、gemをインストールします。

前述したように、`Gemfile`に記述したgemはRailsの読み込み時に読み込まれます。このgemは最初にエンジンの`lib/blorgh.rb`をrequireし、続いて`lib/blorgh/engine.rb`をrequireします。後者はこのエンジンの機能を担う主要な部品が定義されている場所です。

アプリケーションからエンジンの機能にアクセスできるようにするには、エンジンをアプリケーションの`config/routes.rb`ファイルでマウントする必要があります。

```ruby
mount Blorgh::Engine, at: "/blog"
```

この行を記述することで、エンジンがアプリケーションの`/blog`パスにマウントされます。`rails server`を実行してRailsを起動すると、`http://localhost:3000/blog`にアクセスできるようになります。

NOTE: Deviseなどの他のエンジンでは、この点が若干異なり、ルーティングで（`devise_for`などの）カスタムヘルパーを指定するものがあります。これらのヘルパーの動作は完全に同じであり、事前に定義されたカスタマイズ可能なパスにエンジンの機能の一部をマウントします。

### エンジンの設定

作成したエンジンには、`blorgh_articles`テーブルと`blorgh_comments`テーブル用のマイグレーションが含まれます。アプリケーションのデータベースでこれらのテーブルを作成し、エンジンのモデルからこれらのテーブルにアクセスできるようにする必要があります。これらのマイグレーションをアプリケーションにコピーするには、ホストとなるRailsエンジンの`test/dummy`ディレクトリで以下のコマンドを実行します。

```bash
$ bin/rails blorgh:install:migrations
```

マイグレーションをコピーする必要のあるエンジンが複数ある場合は、代わりに`railties:install:migrations`を使います。

```bash
$ bin/rails railties:install:migrations
```

マイグレーションで`MIGRATIONS_PATH`を指定することで、ソースのエンジンのカスタムパスを指定できます。

```bash
$ bin/rails railties:install:migrations MIGRATIONS_PATH=db_blourgh
```

マルチプルデータベースを利用している場合は、`DATABASE`を指定することでターゲットのデータベースを指定できます。

```bash
$ bin/rails railties:install:migrations DATABASE=animals
```

このコマンドは、初回実行時にエンジンからすべてのマイグレーションをコピーします。次回以降の実行時には、コピーされていないマイグレーションのみがコピーされます。このコマンドの初回実行時の出力結果は以下のようになります。

```bash
Copied migration [timestamp_1]_create_blorgh_articles.blorgh.rb from blorgh
Copied migration [timestamp_2]_create_blorgh_comments.blorgh.rb from blorgh
```

最初のタイムスタンプ (`[timestamp_1]`) は現在時刻、次のタイムスタンプ (`[timestamp_2]`) は現在時刻に1秒追加した値になります。タイムスタンプがこのようになっている理由は、アプリケーションの既存のマイグレーションがすべて完了した後でエンジンのマイグレーションを実行する必要があるためです。

アプリケーションのコンテキストでマイグレーションを実行するには、単に`bin/rails db:migrate`を実行します。`http://localhost:3000/blog`でエンジンにアクセスすると、記事は空の状態です。これは、アプリケーションの内部で作成されたテーブルはエンジンの内部で作成されたテーブルとは異なるためです。新しくマウントしたエンジンでもっといろいろやってみましょう。アプリケーションの動作は、エンジンを単体で動かしているときと同じであることがわかります。

エンジンを1つだけマイグレーションしたい場合、以下のように`SCOPE`を指定します。

```bash
$ bin/rails db:migrate SCOPE=blorgh
```

このオプションは、エンジンを削除する前にマイグレーションを元に戻したい場合などに便利です。blorghエンジンによるすべてのマイグレーションを元に戻したい場合は、以下のようなコマンドを実行します。

```bash
$ bin/rails db:migrate SCOPE=blorgh VERSION=0
```

### アプリケーションのクラスをエンジンで使う

#### アプリケーションのモデルをエンジンで使う

エンジンを1つ作成すると、やがてエンジンの部品とアプリケーションの部品を連携させるために、アプリケーションの特定のクラスをエンジンから利用したくなるでしょう。この`blorgh`エンジンであれば、記事とコメントの作者の情報がある方がずっとわかりやすくなります。

通常のアプリケーションであれば、記事やコメントの作者を表す何らかの`User`クラスが備わっているかもしれません。しかしそのクラス名が`User`とは限らず、アプリケーションによっては`Person`というクラスかもしれません。このような状況に対応するために、このエンジンでは`User`クラスとの関連付けをハードコードしないようにすべきです。

ここでは話を簡単にするため、アプリケーションがユーザーを表すために持つクラスは`User`であるとします (この後でもっとカスタマイズしやすくします)。このクラスは、アプリケーションで以下のコマンドを実行して生成できます。

```bash
$ bin/rails generate model user name:string
```

今後`users`テーブルをアプリケーションで使えるようにするために、ここで`bin/rails db:migrate`を実行する必要があります。

話を簡単にするため、記事のフォームのテキストフィールド名も`author_name`という名前であるとします。記事を書くユーザーはここに自分の名前を入力できます。エンジンはこの名前を用いて`User`オブジェクトを新規作成するか、その名前が既にあるかどうかを調べます。続いて、エンジンは作成または見つけた`User`オブジェクトを記事と関連付けます。

最初に、`author_name`テキストフィールドをエンジンのパーシャル`app/views/blorgh/articles/_form.html.erb`に追加する必要があります。そこで、以下のコードを`title`フィールドのすぐ上に追加します。

```html+erb
<div class="field">
  <%= form.label :author_name %><br>
  <%= form.text_field :author_name %>
</div>
```

続いて、エンジンの`Blorgh::ArticleController#article_params`メソッドを更新して、新しいフォームパラメータを受け付けるようにする必要もあります。

```ruby
def article_params
  params.require(:article).permit(:title, :text, :author_name)
end
```

次に、`Blorgh::Article`モデルにも`author_name`フィールドを実際の`User`オブジェクトに変換し、`User`オブジェクトを記事の`author`と関連付けてから記事を保存するコードが必要です。このフィールド用の`attr_accessor`も設定する必要があります。これにより、このフィールド用のゲッターメソッドとセッターメソッドが定義されます。

これらをすべて行なうには、`author_name`用の`attr_accessor`、authorとの関連付け、および`before_validation`呼び出しを`app/models/blorgh/article.rb`に追加する必要があります。`author`関連付けは、この時点ではあえて`User`クラスとハードコードしておきます。

```ruby
attr_accessor :author_name
belongs_to :author, class_name: "User"

before_validation :set_author

private
  def set_author
    self.author = User.find_or_create_by(name: author_name)
  end
```

`author`オブジェクトと`User`クラスの関連付けを指定すると、エンジンとアプリケーションの間にリンクが確立されます。`blorgh_articles`テーブルのレコードと、`users`テーブルのレコードを関連付けるための方法が必要です。この関連付けは`author`という名前なので、`blorgh_articles`テーブルには`author_id`というカラムが追加される必要があります。

この新しいカラムを追加するには、エンジンのディレクトリで以下のコマンドを実行する必要があります。

```bash
$ bin/rails generate migration add_author_id_to_blorgh_articles author_id:integer
```

NOTE: 上のようにコマンドオプションでマイグレーション名とカラムの仕様を指定することで、特定のテーブルに追加しようとしているカラムがRailsによって自動的に認識され、そのためのマイグレーションが作成されます。この他にオプションを指定する必要はありません。

このマイグレーションはアプリケーションに対して実行する必要があります。これを行なうには、最初に以下のコマンドを実行してマイグレーションをエンジンからコピーする必要があります。

```bash
$ bin/rails blorgh:install:migrations
```

上のコマンドでコピーされるマイグレーションは「1つ」だけである点にご注意ください。これは、最初の2つのマイグレーションはこのコマンドが初めて実行されたときにコピー済みであるためです。

```
NOTE Migration [timestamp]_create_blorgh_articles.blorgh.rb from blorgh has been skipped. Migration with the same name already exists.
NOTE Migration [timestamp]_create_blorgh_comments.blorgh.rb from blorgh has been skipped. Migration with the same name already exists.
Copied migration [timestamp]_add_author_id_to_blorgh_articles.blorgh.rb from blorgh
```

このマイグレーションを実行するコマンドは以下のとおりです。

```bash
$ bin/rails db:migrate
```

これですべての部品が定位置に置かれ、ある記事 (article) を、`users`テーブルのレコードで表される作者 (author) に関連付けるアクションが実行されるようになりました。この記事は`blorgh_articles`テーブルで表されます。

最後に、作者名を記事のページに表示しましょう。以下のコードを`app/views/blorgh/articles/_article.html.erb`の"Title"出力の上に追加します。

```html+erb
<p>
  <strong>Author:</strong>
  <%= article.author.name %>
</p>
```

#### アプリケーションのコントローラをエンジンで使う

Railsのコントローラでは、認証やセッション変数へのアクセスに関するコードをアプリケーション全体で共有するのが一般的なので、このようなコードはデフォルトで`ApplicationController`から継承します。
しかし、Railsのエンジンは基本的にメインとなるアプリケーションから独立しているので、エンジンが利用できる`ApplicationController`はスコープで制限されています。名前空間が導入されていることでコードの衝突は回避されますが、エンジンのコントローラからメインアプリケーションの`ApplicationController`のメソッドにアクセスする必要も頻繁に発生します。エンジンのコントローラからメインアプリケーションの`ApplicationController`へのアクセスを提供するには、エンジンが所有するスコープ付きの`ApplicationController`に変更を加え、メインアプリケーションの`ApplicationController`を継承するのが簡単な方法です。Blorghエンジンの場合、`app/controllers/blorgh/application_controller.rb`を以下のように変更します。

```ruby
module Blorgh
  class ApplicationController < ::ApplicationController
  end
end
```

エンジンのコントローラはデフォルトで`Blorgh::ApplicationController`を継承します。上の変更を行なうことで、あたかもエンジンがアプリケーションの一部であるかのように、エンジンのコントローラで`ApplicationController`にアクセスできるようになります。

この変更を行なうには、エンジンをホストするRailsアプリケーションに`ApplicationController`という名前のコントローラが存在する必要があります。

### エンジンを設定する

このセクションでは、`User`クラスをカスタマイズ可能にする方法と、エンジンの一般的な設定方法について解説します。

#### アプリケーション側からエンジンを設定する

次は、アプリケーションで`User`を表すクラスをエンジンからカスタマイズ可能にする方法について説明します。カスタマイズしたいクラスは、前述の`User`のようなクラスばかりとは限りません。このクラスの設定をカスタマイズ可能にするには、エンジン内部に`author_class`という名前の設定が必要です。この設定は、親アプリケーション内部でユーザーを表すクラスがどれであるかを指定するためのものです。

この設定を定義するには、エンジンで使う`Blorgh`モジュール内部に`mattr_accessor`というアクセサを置く必要があります。エンジンにある`lib/blorgh.rb`に以下の行を追加します。

```ruby
mattr_accessor :author_class
```

`mattr_accessor`メソッドの動作は`attr_accessor`や`cattr_accessor`などの姉妹メソッドと似ていますが、指定されたモジュールにゲッターメソッドとセッターメソッドを提供します（訳注: `cattr_accessor`は`mattr_accessor`のエイリアスです）。これらを利用する場合は`Blorgh.author_class`という名前で参照する必要があります。

続いて、`Blorgh::Article`モデルの設定をこの新しい設定に切り替えます。`app/models/blorgh/article.rb`モデル内の`belongs_to`関連付けを以下のように変更します。

```ruby
belongs_to :author, class_name: Blorgh.author_class
```

`Blorgh::Article`モデルの`set_author`メソッドもこのクラスを使う必要があります。

```ruby
self.author = Blorgh.author_class.constantize.find_or_create_by(name: author_name)
```

`author_class`での保存時に`constantize`が必ず呼び出されるようにしたい場合は、`lib/blorgh.rb`の`Blorgh`モジュール内部の`author_class`ゲッターメソッドをオーバーライドするだけでできます。これにより、値の保存時に必ず`constantize`を呼び出してから結果が返されます。

```ruby
def self.author_class
  @@author_class.constantize
end
```

これにより、`set_author`用の上のコードは以下のようになります。

```ruby
self.author = Blorgh.author_class.find_or_create_by(name: author_name)
```

これにより記述がやや簡潔になりますが、その分動作も若干暗黙的になります。この`author_class`メソッドは常に`Class`オブジェクトを返す必要があります。

`author_class`メソッドが`String`ではなく`Class`を返すように変更を加えたので、`Blorgh::Article`の`belongs_to`定義もそれに合わせて変更する必要があります。

```ruby
belongs_to :author, class_name: Blorgh.author_class.to_s
```

この設定をアプリケーション内で行なうには、イニシャライザを使う必要があります。イニシャライザを使えば、アプリケーションが起動してエンジンのモデルを呼び出すまでにアプリケーションの設定が完了します。この動作は、既存のこの設定に依存する場合があります。

`blorgh`がインストールされているアプリケーションの`config/initializers/blorgh.rb`にイニシャライザを作成して、以下の記述を追加します。

```ruby
Blorgh.author_class = "User"
```

WARNING: この設定では、このクラス名をクラスそのものではなく`String`で（=引用符で囲んだ文字列リテラルとして）記述することがきわめて重要です。クラス自身を書くと、Railsはそのクラスを読み込んで関連するテーブルを参照しようとしますが、参照先のテーブルが存在しない場合に問題が発生する可能性があります。このため、クラス名は`String`で表し、後でエンジンが`constantize`でクラスに変換する必要があります。

次は、新しい記事を1つ作成してみましょう。記事の作成はこれまでとまったく同様に行えます。1つだけ異なるのは、このクラスの動作を学ぶために`config/initializers/blorgh.rb`の設定をエンジンで使う点です。

ここでは、クラスで使うAPIがどんなものでなければならないかだけが重要です（どんなクラスであるかについては厳密な依存はありません）。エンジンで使うクラスで必須となるメソッドは`find_or_create_by`のみです。このメソッドはそのクラスのオブジェクトを1つ返します。もちろん、このオブジェクトは何らかの形で参照可能な識別子 (id) を持つ必要があります。

#### 一般的なエンジンの設定

エンジンの中で、イニシャライザや国際化などの機能オプションも使いたいことがあります。うれしいことに、Railsエンジンの機能の大半はRailsアプリケーションと共通しているので、これらは完全に実現可能です。実際、Railsアプリケーションの機能は、エンジンが持つ機能のスーパーセットです。

たとえばイニシャライザ（エンジンが読み込まれる前に実行されるコード）を使いたい場合は、そのための場所である`config/initializers`フォルダに置きます。このディレクトリの機能について詳しくは『Rails アプリケーションを設定する』ガイドの[イニシャライザファイルを使う](configuring.html#イニシャライザ)を参照してください。エンジンのイニシャライザの動作は、アプリケーションの`config/initializers`ディレクトリに置かれているイニシャライザと完全に同じです。標準のイニシャライザを使いたい場合も同様です。

ロケールファイルも、アプリケーションの場合と同様`config/locales`ディレクトリに置くだけで利用できます。

エンジンをテストする
-----------------

エンジンが生成されると、`test/dummy`ディレクトリの下に小規模なダミーアプリケーションが自動的に配置されます。このダミーアプリケーションはエンジンのマウント場所として使われるので、エンジンのテストがきわめてシンプルになります。このディレクトリ内でコントローラやモデルやビューを生成してアプリケーションを拡張すれば、それらを用いてエンジンをテストできます。

`test`ディレクトリは、通常のRailsにおけるtesting環境と同様に扱う必要があります。Railsのtesting環境では単体テスト、機能テスト、結合テストを行なえます。

### 機能テスト

ここで1つ注意事項があります。作成した機能テストは、エンジンではなく、`test/dummy`に置かれるダミーアプリケーション上で実行されます。理由は、testing環境がそのように設定されているためです。エンジンの主要な機能、特にコントローラをテストするには、エンジンをホストする親アプリケーションが必要です。仮に、コントローラの機能テストの中で、以下のような一般的な`GET`をテストするとしましょう。

```ruby
module Blorgh
  class FooControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def test_index
      get foos_url
      # ...
    end
  end
end
```

しかしこれは正常に機能しないでしょう。アプリケーションは、このようなリクエストをエンジンにルーティングする**方法**を知らないので、明示的にエンジンにルーティングする必要があります。これを行なうには、設定コードの中で`@routes`インスタンス変数にエンジンのルーティングセットを設定する必要があります。

```ruby
module Blorgh
  class FooControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @routes = Engine.routes
    end

    def test_index
      get foos_url
      # ...
    end
  end
end
```

これで、このコントローラの`index`アクションに対して`GET`リクエストを送信しようとしていることがアプリケーションによって認識され、かつアプリケーションのルーティングではなく、エンジンのルーティングが使われるようになります。

これでエンジン用のURLヘルパーもテストで期待どおりに動作します。

エンジンの機能を改良する
------------------------------

このセクションでは、エンジンのMVC機能をメインのRailsアプリケーションに追加またはオーバーライドする方法について解説します。

### モデルやコントローラをオーバーライドする

エンジンのモデルやコントローラは、メインのRailsアプリケーション側でそれらのクラスを再オープン（再定義）することで拡張できます。

オーバーライドは専用の`app/overrides`ディレクトリに配置できます。これはオートローダーで無視され、 `to_prepare`コールバックでプリロードされます。

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # ...

    overrides = "#{Rails.root}/app/overrides"
    Rails.autoloaders.main.ignore(overrides)

    config.to_prepare do
      Dir.glob("#{overrides}/**/*_override.rb").sort.each do |override|
        load override
      end
    end
  end
end
```

#### 既存のクラスを`class_eval`で再オープンする

たとえば以下のエンジンモデルをオーバライドするとします。

```ruby
# Blorgh/app/models/blorgh/article.rb
module Blorgh
  class Article < ApplicationRecord
    # ...
  end
end
```

これは、以下のようにクラスを「再オープン」するファイルを作成するだけでできます。

```ruby
# MyApp/app/overrides/models/blorgh/article_override.rb
Blorgh::Article.class_eval do
  # ...
end
```

このオーバーライドが、そのクラスやモジュールを「再オープン」することがきわめて重要です。定義がエンジン内にあるので、クラスやモジュールがメモリ上にない状態でそれらを`class`や`module`キーワードで定義すると、正しいものでなくなる可能性があります。上のように`class_eval`を使うことで、確実に再オープンできるようになります。

#### 既存のクラスを`ActiveSupport::Concern`で再オープンする

`Class#class_eval`は単純な調整には大変便利ですが、クラスの変更が複雑な場合は[`ActiveSupport::Concern`](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)を検討しましょう。`ActiveSupport::Concern`は、相互にリンクしている依存モジュールおよび依存クラスが実行時に読み込まれるときの順序を管理するので、コードのモジュール化を大きく促進できるようになります。

`Article#time_since_created`を**追加**して`Article#summary`を**オーバーライド**する場合

```ruby
# MyApp/app/models/blorgh/article.rb

class Blorgh::Article < ApplicationRecord
  include Blorgh::Concerns::Models::Article

  def time_since_created
    Time.current - created_at
  end

  def summary
    "#{title} - #{truncate(text)}"
  end
end
```

```ruby
# Blorgh/app/models/blorgh/article.rb
module Blorgh
  class Article < ApplicationRecord
    include Blorgh::Concerns::Models::Article
  end
end
```

```ruby
# Blorgh/lib/concerns/models/article.rb

module Blorgh::Concerns::Models::Article
  extend ActiveSupport::Concern

  # `included do`は、インクルードされたコードを
  # それがインクルードされているコンテキスト（つまりBlorgh::Article）で評価し、
  # そのモジュールが実行されるコンテキストでは評価しない。
  included do
    attr_accessor :author_name
    belongs_to :author, class_name: "User"

    before_validation :set_author

    private
      def set_author
        self.author = User.find_or_create_by(name: author_name)
      end
  end

  def summary
    "#{title}"
  end

  module ClassMethods
    def some_class_method
      'some class method string'
    end
  end
end
```

### 自動読み込みとエンジン

自動読み込みとエンジンの詳細については、「Railsの自動読み込みと再読み込み」ガイドの[自動読み込みとRailsエンジン](autoloading_and_reloading_constants.html#自動読み込みとrailsエンジン)を参照してください。

### ビューをオーバーライドする

Railsは、出力すべきビューを探索する際に、最初にアプリケーションの`app/views`ディレクトリを探索します。探しているビューがそこにない場合、続いてそのディレクトリを持つすべてのエンジンで、`app/views`ディレクトリを探索します。

たとえば、アプリケーションが`Blorgh::ArticlesController`のindexアクションの結果を出力するためのビューを探索するときは、最初にアプリケーション自身の`app/views/blorgh/articles/index.html.erb`を探索し、ない場合は引き続きエンジンの中を探索します。

`app/views/blorgh/articles/index.html.erb`というファイルを作成するだけで、このビューをオーバーライドできます。これを利用して、通常のビューでの出力結果を完全に変更できます。

`app/views/blorgh/articles/index.html.erb`というファイルを作成して以下のコードを追加すれば、この動作をすぐにも試せます。

```html+erb
<h1>Articles</h1>
<%= link_to "New Article", new_article_path %>
<% @articles.each do |article| %>
  <h2><%= article.title %></h2>
  <small>By <%= article.author %></small>
  <%= simple_format(article.text) %>
  <hr>
<% end %>
```

### ルーティング

デフォルトでは、エンジン内部のルーティングはアプリケーションのルーティングから分離されています。これは、`Engine`クラス内の`isolate_namespace`呼び出しによって実現されます。これは本質的に、アプリケーションとエンジンが完全に同一の名前のルーティングを持つことが可能で、しかも衝突しないということを意味します。

エンジン内部のルーティングは、以下のように`config/routes.rb`の`Engine`クラスによって構成されます。

```ruby
Blorgh::Engine.routes.draw do
  resources :articles
end
```

このようにエンジンとアプリケーションのルーティングが分離されているので、アプリケーションの特定の部分をエンジンの特定の部分にリンクしたい場合は、エンジンのルーティングプロキシメソッドを使う必要があります。`articles_path`のような通常のルーティングメソッドの呼び出しは、アプリケーションとエンジンの両方でそのようなヘルパーが定義されている場合には期待と異なる場所にリンクされる可能性があります。

たとえば以下のコード例では、そのテンプレートがアプリケーションでレンダリングされる場合の行き先はアプリケーションの`articles_path`になり、エンジンでレンダリングされる場合の行き先はエンジンの`articles_path`になります。

```erb
<%= link_to "Blog articles", articles_path %>
```

このルーティングを常にエンジンの`articles_path`ルーティングヘルパーメソッドで取り扱いたい場合、以下のようにエンジンと同じ名前を共有するルーティングプロキシメソッドを呼び出す必要があります。

```erb
<%= link_to "Blog articles", blorgh.articles_path %>
```

逆にエンジン内部からアプリケーションを参照する場合は、同じ要領で`main_app`を使います。

```erb
<%= link_to "Home", main_app.root_path %>
```

上のコードをエンジン内で使うと、行き先は**常に**アプリケーションのルートになります。この`main_app`ルーティングプロキシメソッドを呼び出しを省略すると、行き先は呼び出された場所によってアプリケーションまたはエンジンのいずれかとなって確定しません。

ルーティングプロキシメソッド呼び出しを省略したアプリケーション側のルーティングヘルパーメソッドを、エンジン内でレンダリングされるテンプレートから呼び出そうとすると、未定義メソッド呼び出しエラーが発生することがあります。このような問題が発生した場合は、アプリケーション側のルーティングメソッドをエンジンから呼びだすときに、`main_app`というプレフィックスを付け忘れていないかどうかを確認してください。

### アセット

エンジンの中にあるアセットは、通常のアプリケーションで使われるアセットとまったく同じように振る舞います。エンジンのクラスは`Rails::Engine`を継承しているので、アプリケーションはエンジンの`app/assets`ディレクトリと`lib/assets`ディレクトリを探索対象として認識します。

エンジン内の他のコンポーネントと同様、アセットも名前空間化される必要があります。たとえば、`style.css`というアセットは、`app/assets/stylesheets/style.css`ではなく`app/assets/stylesheets/エンジン名/style.css`に置かれる必要があります。アセットが名前空間化されていないと、ホスト側のアプリケーションにまったく同じ名前のアセットが存在する場合に、エンジンのアセットではなくアプリケーションのアセットが使われてしまう可能性があります。

`app/assets/stylesheets/blorgh/style.css`というアセットを例に説明します。このアセットをアプリケーションに含めるには、単に`stylesheet_link_tag`を使うだけで済みます。これにより、このアセットはあたかもエンジン内部にあるかのように参照されます。

```erb
<%= stylesheet_link_tag "blorgh/style.css" %>
```

処理されるファイルでアセットパイプラインの`*= require`ステートメントを使えば、アセットを他のアセットの依存関係として指定することも可能です。

```css
/*
 *= require blorgh/style
 */
```

INFO: SassやCoffeeScriptなどの言語を使う場合は、必要なライブラリを`.gemspec`に追加する必要があります。

### アセットとプリコンパイルを分離する

エンジン内のアセットが、ホスト側のアプリケーションで必須ではない場合があります。
たとえば、エンジンでしか使わない管理機能を作成したとしましょう。この場合、これらのアセットはgemのadminレイアウトでしか使われないため、ホストアプリケーションでは`admin.css`や`admin.js`は不要です。それらのアセットを必要とするのは、そのgemのadminレイアウトだけなので、ホストアプリケーションから見れば、自分が持つスタイルシートに`"blorgh/admin.css"`を追加する意味はありません。
このような場合、これらのアセットを明示的にプリコンパイルする必要があります。これによって、`bin/rails assets:precompile`が実行されたときにエンジンのアセットを追加するようSprocketsに指示されます。

プリコンパイルの対象となるアセットは`engine.rb`で定義できます。

```ruby
initializer "blorgh.assets.precompile" do |app|
  app.config.assets.precompile += %w( admin.js admin.css )
end
```

詳しくは[アセットパイプライン](asset_pipeline.html)ガイドを参照してください。

### 他のgemとの依存関係

エンジンはgemとしてインストールされる可能性があるので、エンジン内のGemの依存関係は、エンジンのルートにある`.gemspec`ファイル内で指定する必要があります。依存関係を`Gemfile`で指定すると、従来のgemインストールでは認識されなくなって必要なgemがインストールされず、エンジンが誤動作する原因になります。

通常の`gem install`コマンド実行時に同時にインストールされる必要のあるgemを指定するには、以下のようにエンジンの`.gemspec`ファイルで、`Gem::Specification`ブロックの内側に記述します。

```ruby
s.add_dependency "moo"
```

アプリケーションの開発時にのみ必要なgemのインストールを指定するには、以下のように記述します。

```ruby
s.add_development_dependency "moo"
```

どちらの依存gemも、アプリケーションで`bundle install`を実行するときにインストールされます。gemの開発用依存関係は、エンジンをdevelopment環境またはtest環境で実行する場合にのみ使われます。

エンジンが`require`されたタイミングで依存gemもすぐに`require`したい場合は、以下のようにエンジンが初期化されるより前にrequireする必要があるので注意が必要です。

```ruby
require "other_engine/engine"
require "yet_another_engine/engine"

module MyEngine
  class Engine < ::Rails::Engine
  end
end
```

フックの読み込みと設定
----------------------------

Railsのコードは、アプリケーション読み込みの段階で頻繁に参照されます。Railsはこれらのフレームワークの読み込み順序について責任を持つため、途中で`ActiveRecord::Base`などのフレームワークを読み込んでしまうと、Railsがアプリケーションに期待する暗黙の規約に違反してしまう可能性があります。さらに、`ActiveRecord::Base`のコードをアプリケーション起動時に読み込んでしまうと、そうしたフレームワーク全体が再読み込みされるため、起動に時間がかかったり読み込み順序で競合が発生したりする可能性もあります。

読み込みフックと設定フックは、Railsの読み込み規約に違反せずにこの初期化プロセスにフックできるAPIです。また、起動パフォーマンス低下も緩和され、コンフリクトも回避されます。

### Railsフレームワークの読み込みを回避する

Rubyは動的言語であるため、一部のコードで別のRailsフレームワークが読み込まれることがあります。次のコードをご覧ください

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

上のスニペットの動作は次のようになります。Rubyがこのファイルを読み込んで`ActiveRecord::Base`まで進むと、それをきっかけに定数の定義を探索して`require`します。このようにして、Active Recordフレームワーク全体が起動時に読み込まれます。

`ActiveSupport.on_load`は、あるコードの読み込みを、実際に必要になる時点まで遅延できるメカニズムです。上のスニペットは次のように書き換えられます。

```ruby
ActiveSupport.on_load(:active_record) do
  include MyActiveRecordHelper
end
```

新しいスニペットは、`ActiveRecord::Base`の読み込み時に`MyActiveRecordHelper`だけを`include`するようになります。

### フックが呼び出されるタイミング

Railsフレームワークにおけるこれらのフックは、特定のライブラリの読み込み時に呼び出されます。
たとえば、`ActionController::Base`が読み込まれると`:action_controller_base`フックが呼び出されます。これは、`:action_controller_base`フックによるすべての`ActiveSupport.on_load`呼び出しが`ActionController::Base`のコンテキストで呼び出される（ここでは`self`が`ActionController::Base`として評価される）ということです。

### 読み込みフックでコードを変更する

一般に、（フックによる）コードの変更方法は単純です。たとえば、`ActiveRecord::Base`などのRailsフレームワークを参照するコードは、読み込みフックでラップできます。

**`include`呼び出しを変更する場合**

```ruby
ActiveRecord::Base.include(MyActiveRecordHelper)
```

上のコードは以下のように書けます。

```ruby
ActiveSupport.on_load(:active_record) do
  # selfがActiveRecord::Baseを指すので
  # includeを呼び出せる
  include MyActiveRecordHelper
end
```

**`prepend`呼び出しを変更する場合**

```ruby
ActionController::Base.prepend(MyActionControllerHelper)
```

上のコードは以下のように書けます。

```ruby
ActiveSupport.on_load(:action_controller_base) do
  # selfがActiveRecord::Baseを指すので
  # includeを呼び出せる
  prepend MyActionControllerHelper
end
```

**クラスメソッド呼び出しを変更する場合**

```ruby
ActiveRecord::Base.include_root_in_json = true
```

上のコードは以下のように書けます。

```ruby
ActiveSupport.on_load(:active_record) do
  # ここではselfがActiveRecord::Baseを指す
  self.include_root_in_json = true
end
```

## 利用可能なフック

これらの読み込みフックは、自分のコードで利用できます。以下のクラスの初期化プロセスにフックするには、利用可能なフックを使います。

| クラス                             | 対応するフック                      |
| --------------------------------- | ------------------------------------ |
| `ActionCable`                        | `action_cable`                       |
| `ActionCable::Channel::Base`         | `action_cable_channel`               |
| `ActionCable::Connection::Base`      | `action_cable_connection`            |
| `ActionCable::Connection::TestCase`  | `action_cable_connection_test_case`  |
| `ActionController::API`              | `action_controller_api`              |
| `ActionController::API`              | `action_controller`                  |
| `ActionController::Base`             | `action_controller_base`             |
| `ActionController::Base`             | `action_controller`                  |
| `ActionController::TestCase`         | `action_controller_test_case`        |
| `ActionDispatch::IntegrationTest`    | `action_dispatch_integration_test`   |
| `ActionDispatch::Response`           | `action_dispatch_response`           |
| `ActionDispatch::Request`            | `action_dispatch_request`            |
| `ActionDispatch::SystemTestCase`     | `action_dispatch_system_test_case`   |
| `ActionMailbox::Base`                | `action_mailbox`                     |
| `ActionMailbox::InboundEmail`        | `action_mailbox_inbound_email`       |
| `ActionMailbox::Record`              | `action_mailbox_record`              |
| `ActionMailbox::TestCase`            | `action_mailbox_test_case`           |
| `ActionMailer::Base`                 | `action_mailer`                      |
| `ActionMailer::TestCase`             | `action_mailer_test_case`            |
| `ActionText::Content`                | `action_text_content`                |
| `ActionText::Record`                 | `action_text_record`                 |
| `ActionText::RichText`               | `action_text_rich_text`              |
| `ActionText::EncryptedRichText`      | `action_text_encrypted_rich_text`    |
| `ActionView::Base`                   | `action_view`                        |
| `ActionView::TestCase`               | `action_view_test_case`              |
| `ActiveJob::Base`                    | `active_job`                         |
| `ActiveJob::TestCase`                | `active_job_test_case`               |
| `ActiveRecord::Base`                 | `active_record`                      |
| `ActiveRecord::TestFixtures`         | `active_record_fixtures`             |
| `ActiveRecord::ConnectionAdapters::PostgreSQLAdapter`    | `active_record_postgresqladapter`    |
| `ActiveRecord::ConnectionAdapters::Mysql2Adapter`        | `active_record_mysql2adapter`        |
| `ActiveRecord::ConnectionAdapters::TrilogyAdapter`       | `active_record_trilogyadapter`       |
| `ActiveRecord::ConnectionAdapters::SQLite3Adapter`       | `active_record_sqlite3adapter`       |
| `ActiveStorage::Attachment`          | `active_storage_attachment`          |
| `ActiveStorage::VariantRecord`       | `active_storage_variant_record`      |
| `ActiveStorage::Blob`                | `active_storage_blob`                |
| `ActiveStorage::Record`              | `active_storage_record`              |
| `ActiveSupport::TestCase`            | `active_support_test_case`           |
| `i18n`                               | `i18n`                               |


## 設定用フック

設定用フックは特定のフレームワークにはフックせず、アプリケーション全体のコンテキストで実行されます。

| フック                  | ユースケース                                         |
| ---------------------- | -------------------------------------------------- |
| `before_configuration` | 最初に実行される設定フックです。あらゆる初期化より先に呼びされます。|
| `before_initialize` | 次に実行される設定フックです。フレームワークの初期化の直前で呼び出されます。|
| `before_eager_load` | 初期化後に実行される設定フックです。[`config.eager_load`][]がfalseの場合は実行されません。|
| `after_initialize` | 最後に実行される設定フックです。フレームワークの初期化後に呼び出しされます。|

設定フックは、Engineクラス内で呼び出されます。

```ruby
module Blorgh
  class Engine < ::Rails::Engine
    config.before_configuration do
      puts 'I am called before any initializers'
    end
  end
end
```

[`config.eager_load`]: configuring.html#config-eager-load
