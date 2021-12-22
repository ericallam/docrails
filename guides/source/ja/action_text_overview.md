**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Action Text の概要
====================

本ガイドでは、リッチテキストコンテンツの扱いを始めるのに必要なものをすべて提供します。

このガイドの内容:

* Action Textの設定方法
* リッチテキストコンテンツの扱い方
* リッチテキストコンテンツにスタイルを付ける方法

--------------------------------------------------------------------------------


はじめに
------------

Action Textを使って、Railsにリッチテキストコンテンツと編集機能を導入できます。Action Textに含まれている[Trixエディタ](https://trix-editor.org)は、書式設定/リンク/引用/リスト/画像埋め込み/ギャラリーなどあらゆるものを扱えます。
Trixエディタが生成するリッチテキストコンテンツは独自のRichTextモデルに保存され、このモデルはアプリケーションの既存のあらゆるActive Recordモデルと関連付けられます。
あらゆる埋め込み画像（およびその他の添付ファイル）は自動的にActive Storageに保存され、`include`されたRichTextモデルに関連付けられます。

## Trixと他のリッチテキストエディタを比較する

ほとんどのWYSIWYGエディタは、HTMLの`contenteditable`や`execCommand` APIのラッパーです。これはマイクロソフトがInternet Explorer 5.5のライブエディット機能をサポートするために設計したもので、最終的に[リバースエンジニアリング](https://blog.whatwg.org/the-road-to-html-5-contenteditable#history)されて他のブラウザに普及しました。

これらのAPIの仕様やドキュメントは永遠に未完成のままであり、かつWYSIWYG HTMLエディタが扱う範囲が広大なため、ブラウザの実装ごとに独自のバグやおかしな動作が発生しています。ブラウザ間の動作のぶれの解決はJavaScript開発者たちに任せきりの状態です。

Trixでは`contenteditable`をI/Oデバイスとして扱うことで、こうしたブラウザ間の動作のぶれを回避しました。エディタに独自の方法で入力されると、Trixはその入力を内部のドキュメントモデル上での編集操作に変換してから、ドキュメントをエディタ上で再レンダリングします。これにより、Trixはあらゆるキーストロークで発生するものを完全に制御し、`execCommand`を使う必要性をすべて回避しています。

## インストール

`rails action_text:install`を実行すると、Yarnパッケージが追加され、必要なマイグレーションがコピーされます。また、埋め込み画像や他の添付ファイルを扱うためにActive Storageのセットアップも必要です。詳しくは[Active Storageの概要](active_storage_overview.html)ガイドを参照してください。

NOTE: Action Textでは、`action_text_rich_texts`テーブルとのポリモーフィックなリレーションシップを利用して、リッチテキスト属性を持つあらゆるモデルで共有できるようになっています。Action Textコンテンツを持つモデルがUUID値をidに使っている場合、Action Text属性を使うすべてのモデルで固有のidにUUID値を使う必要が生じます。また、Action Text用に生成されるマイグレーションでは、`:record`の`references`行に`type: :uuid`を指定する形に更新する必要もあります。

インストールが完了すると、Railsアプリは以下のように変更されるはずです。

1. JavaScriptのエントリポイントに`trix`と`@rails/actiontext`の両方を含める必要があります。

    ```js
    // application.js
    import "trix"
    import "@rails/actiontext"
    ```

2. `trix`スタイルシートは、自分の`application.css`ファイルでAction Textスタイルとともにインクルードされます。

## リッチテキストコンテンツを作成する

既存のモデルにリッチテキストのフィールドを追加するには次のようにします。

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  has_rich_text :content
end
```

または、新しいモデルを生成するときに以下のようにリッチテキストフィールドを追加します。

```bash
bin/rails generate model Message content:rich_text
```

NOTE: 自分の`messages`テーブルに`content`フィールドを追加する必要はありません。

次に、フォーム内でモデルのこのフィールドを[`rich_text_area`]を用いて参照します。

```erb
<%# app/views/messages/_form.html.erb %>
<%= form_with model: message do |form| %>
  <div class="field">
    <%= form.label :content %>
    <%= form.rich_text_area :content %>
  </div>
<% end %>
```

最後に、サニタイズ済みのリッチテキストをページ上に表示します。

```erb
<%= @message.content %>
```

リッチテキストコンテンツをコントローラで受け取れるようにするには、参照される属性を許可するだけで済みます。

```ruby
class MessagesController < ApplicationController
  def create
    message = Message.create! params.require(:message).permit(:title, :content)
    redirect_to message
  end
end
```

[`rich_text_area`]: https://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-rich_text_area

## リッチテキストコンテンツをレンダリングする

Action Textは、リッチテキストコンテンツのサニタイズやレンダリングを自動で行います。

デフォルトでは、Action TextエディタとコンテンツにはTrixのデフォルトのスタイルが与えられます。

このデフォルトを変更するには、`application.scss`の`// require "actiontext.scss"`行を削除して[trix.css](https://raw.githubusercontent.com/basecamp/trix/master/dist/trix.css)が読み込まれないようにします。

デフォルトでは、Action Textは`.trix-content` CSSクラスを宣言した要素内でリッチテキストコンテンツをレンダリングします。

```html+erb
<%# app/views/layouts/action_text/contents/_content.html.erb %>
<div class="trix-content">
  <%= yield %>
</div>
```

リッチテキストを囲むHTMLを独自のレイアウトで変更するには、独自の`app/views/layouts/action_text/contents/_content.html.erb`テンプレートを宣言してコンテンツ内で`yield`を呼び出します。

画像やその他の添付ファイル（いわゆるblob: binary large object）の埋め込みに使うHTMLにもスタイルを指定できます。Action Textをインストールすると、`app/views/active_storage/blobs/_blob.html.erb`というパーシャルが配置されるので、ここでスタイルをカスタマイズできます。

### 添付ファイルのレンダリング

Action Textでは、Active Storage経由でアップロードした添付ファイルを埋め込むことも、[署名済みグローバルID](https://github.com/rails/globalid#signed-global-ids)で解決可能な任意のデータを埋め込むこともできます。

Action Textは、`sgid`属性を解決してインスタンス化することで埋め込み`<action-text-attachment>`をレンダリングします。解決が成功すると、そのインスタンスが[`render`](https://edgeapi.rubyonrails.org/classes/ActionView/Helpers/RenderingHelper.html#method-i-render)に渡されます。
生成されるHTMLは、`<action-text-attachment>`要素の子孫として埋め込まれます。

たとえば`User`モデルを例に考えてみましょう。

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar
end

user = User.find(1)
user.to_global_id.to_s #=> gid://MyRailsApp/User/1
user.to_signed_global_id.to_s #=> BAh7CEkiCG…
```

次に、 `User`インスタンスにある署名済みグローバルIDを参照する`<action-text-attachment>`要素が埋め込まれたリッチテキストを考えてみましょう。

```html
<p>Hello, <action-text-attachment sgid="BAh7CEkiCG…"></action-text-attachment>.</p>
```

Action Textは、この"BAh7CEkiCG…"というStringを用いて`User`インスタンスを解決します。

次に、アプリケーションの`users/user`パーシャルを考えてみましょう。

```html+erb
<%# app/views/users/_user.html.erb %>
<span><%= image_tag user.avatar %> <%= user.name %></span>
```

Action TextでレンダリングされるHTMLは以下のようになります。

```html
<p>Hello, <action-text-attachment sgid="BAh7CEkiCG…"><span><img src="..."> Jane Doe</span></action-text-attachment>.</p>
```

別のパーシャルをレンダリングするには、以下のように`User#to_attachable_partial_path`を定義します。

```ruby
class User < ApplicationRecord
  def to_attachable_partial_path
    "users/attachable"
  end
end
```

次にそのパーシャルを宣言します。`User`インスタンスは、パーシャル内の`user`ローカル変数でアクセスできます。

```html+erb
<%# app/views/users/_attachable.html.erb %>
<span><%= image_tag user.avatar %> <%= user.name %></span>
```

Action Textの`<action-text-attachment>`要素レンダリングと統合するには、クラスが以下の条件を満たさなければなりません。

* `ActionText::Attachable`モジュールを`include`する
* `#to_sgid(**options)`を実装する（[`GlobalID::Identification` concern][global-id])経由で利用可能）
* （オプション）`#to_attachable_partial_path`を宣言する

デフォルトでは、`ActiveRecord::Base`のすべての子孫は[`GlobalID::Identification` concern][global-id]をミックスインするので、`ActionText::Attachable`と互換性があります。

[global-id]: https://github.com/rails/globalid#usage

## N+1クエリを回避する

依存する`ActionText::RichText`をプリロードしたい場合は、以下のように名前付きスコープを利用できます（リッチテキストフィールド名が`content`という前提）。

```ruby
Message.all.with_rich_text_content # 添付ファイルなしで本文をプリロードする
Message.all.with_rich_text_content_and_embeds # 本文と添付ファイルを両方プリロードする
```

## APIとバックエンドの開発

1. たとえばJSONを使うバックエンドAPIで、ファイルアップロード用に別のエンドポイントが必要だとします。このエンドポイントは`ActiveStorage::Blob`を作成してその`attachable_sgid`を返します。

    ```json
    {
      "attachable_sgid": "BAh7CEkiCG…"
    }
    ```

2. その`attachable_sgid`を受け取ったら、`<action-text-attachment>`タグのあるリッチテキストコンテンツに挿入するようフロントエンド側に依頼します。

    ```html
    <action-text-attachment sgid="BAh7CEkiCG…"></action-text-attachment>
    ```

これはBasecampをベースにしているので、詳しい情報については[Basecampのドキュメント](https://github.com/basecamp/bc3-api/blob/master/sections/rich_text.md)を参照してください。

