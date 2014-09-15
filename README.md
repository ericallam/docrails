## Rails の世界へようこそ!

Rails is a web-application framework that includes everything needed to
create database-backed web applications according to the
[Model-View-Controller (MVC)](http://en.wikipedia.org/wiki/Model-view-controller)
pattern.

Understanding the MVC pattern is key to understanding Rails. MVC divides your
application into three layers, each with a specific responsibility.

The _Model layer_ represents your domain model (such as Account, Product,
Person, Post, etc.) and encapsulates the business logic that is specific to
your application. In Rails, database-backed model classes are derived from
`ActiveRecord::Base`. Active Record allows you to present the data from
database rows as objects and embellish these data objects with business logic
methods. Although most Rails models are backed by a database, models can also
be ordinary Ruby classes, or Ruby classes that implement a set of interfaces
as provided by the Active Model module. You can read more about Active Record
in its [README](activerecord/README.rdoc).

The _Controller layer_ is responsible for handling incoming HTTP requests and
providing a suitable response. Usually this means returning HTML, but Rails controllers
can also generate XML, JSON, PDFs, mobile-specific views, and more. Controllers load and
manipulate models, and render view templates in order to generate the appropriate HTTP response.
In Rails, incoming requests are routed by Action Dispatch to an appropriate controller, and
controller classes are derived from `ActionController::Base`. Action Dispatch and Action Controller
are bundled together in Action Pack. You can read more about Action Pack in its
[README](actionpack/README.rdoc).

The _View layer_ is composed of "templates" that are responsible for providing
appropriate representations of your application's resources. Templates can
come in a variety of formats, but most view templates are HTML with embedded
Ruby code (ERB files). Views are typically rendered to generate a controller response,
or to generate the body of an email. In Rails, View generation is handled by Action View.
You can read more about Action View in its [README](actionview/README.rdoc).

Active Record, Action Pack, and Action View can each be used independently outside Rails.
In addition to them, Rails also comes with Action Mailer ([README](actionmailer/README.rdoc)), a library
to generate and send emails; and Active Support ([README](activesupport/README.rdoc)), a collection of
utility classes and standard library extensions that are useful for Rails, and may also be used
independently outside Rails.

## Railsをはじめよう

1. Install Rails at the command prompt if you haven't yet:

        gem install rails

2. At the command prompt, create a new Rails application:

        rails new myapp

   where "myapp" is the application name.

3. Change directory to `myapp` and start the web server:

        cd myapp
        rails server

   Run with `--help` or `-h` for options.

4. Using a browser, go to `http://localhost:3000` and you'll see:
"Welcome aboard: You're riding Ruby on Rails!"

5. Follow the guidelines to start developing your application. You may find
   the following resources handy:
    * [Getting Started with Rails](http://guides.rubyonrails.org/getting_started.html)
    * [Ruby on Rails Guides](http://guides.rubyonrails.org)
    * [The API Documentation](http://api.rubyonrails.org)
    * [Ruby on Rails チュートリアル](http://railstutorial.jp)

***

## 日本語訳について 

本リポジトリは[Ruby on Rails Guides](http://guides.rubyonrails.org/)を日本語に訳したものです。

Railsガイド
http://railsguide.jp/

Ruby on Rails Tutorialの日本語訳「Railsチュートリアル」も無料で公開されているので，    
こちらも是非合わせて読んでみてください :)

Railsチュートリアル   
http://railstutorial.jp/


## 翻訳の流れ

![翻訳の流れ](https://raw.githubusercontent.com/yasslab/railsguides.jp/japanese/images/flow-of-translation.jpg)
参考: [[翻訳]Ruby on Rails 4.1リリース前にアップグレードガイドを先行翻訳した & 同じ翻訳を2回しないで済むようにした](http://techracho.bpsinc.jp/hachi8833/2014_03_28/16037)

### ① 原著との差分更新の方法

- cf. [Syncing a fork, GitHub Help](https://help.github.com/articles/syncing-a-fork)

### ② GTTに最新のドキュメントをアップロードする

- Google Translator Toolkit: https://translate.google.com/toolkit/
- Markdownは対応してないので、必要に応じてファイル名を `hogehoge.md.txt` などに変更する。
- ※必ずRailsガイド用の翻訳メモリに結びつけること. (shared TM は使わない)
- cf. [翻訳メモリの使用 - Translate ヘルプ - Google Help](https://support.google.com/translate/toolkit/answer/147863?hl=ja)

#### GTT は共有が面倒なので，ターミナルなどで編集して Pull Request して頂いても大丈夫です :+1: その際は，@yasulab などが別途 GTT 上の翻訳メモリに翻訳文を格納します．
(↑ このステップをもうちょっとスマートにできるようにしたい...)

### ③ GTT上で英語→日本語に翻訳する (訳文は翻訳メモリに格納)

- 詳細: [Google Translator Toolkitと翻訳メモリ(ノーカット版) : RubyWorld Conference 2013より](http://techracho.bpsinc.jp/hachi8833/2013_12_16/14889)

### ④ 日本語語のHTMLファイルの生成方法

0. `/guides` フォルダに移動する
1. Google Translator Toolkit から訳文のファイルをダウンロードする (要: ダウンロード権限)
2. `./main.rb` を実行して、訳文のファイルを適切な名前に変更し、`/source` 以下に配置。
3. `bundle exec rake guides:generate:html`を実行して、`/output`以下にHTMLを生成。

### ⑤ Herokuにデプロイ

- @yasulab が対応.
- 手伝ってくれる方がいれば @yasulab まで. collaborator に追加します.

## Railsガイド協力者

- [@hachi8833](https://github.com/hachi8833)
- [@yasulab](https://github.com/yasulab)

and supported by [ヤスラボ](http://yasslab.jp/ja/).

## 相談部屋 (チャットルーム)

- [idobata.io](https://idobata.io) の [yasslab/railsguides.jp](https://idobata.io/organizations/yasslab/rooms/railsguides/join_request/c89d1d3b-d6d1-4baa-9271-145fbd0c4734) 部屋にて，Rails ガイドに関するアレコレを情報交換しています．

## ライセンス

This work is licensed under a [Creative Commons Attribution-Share Alike 3.0](http://creativecommons.org/licenses/by-sa/3.0/) License

"Rails", "Ruby on Rails", and the Rails logo are trademarks of David Heinemeier Hansson. All rights reserved.

[Ruby on Rails](http://rubyonrails.org/) is released under the [MIT License](http://www.opensource.org/licenses/MIT).
