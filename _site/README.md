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


## 日本語のHTMLファイルの生成方法

0. `/guides` フォルダに移動する
1. Google Translator Toolkit から訳文のファイルをダウンロードする (要: ダウンロード権限)
2. `./main.rb` を実行して、訳文のファイルを適切な名前に変更し、`/source` 以下に配置。
3. `bundle exec rake guides:generate:html`を実行して、`/output`以下にHTMLを生成。


## 原著との差分更新の方法

- [Syncing a fork, GitHub Help](https://help.github.com/articles/syncing-a-fork)

## Railsガイド協力者

- [@hachi8833](https://github.com/hachi8833)
- [@yasulab](https://github.com/yasulab)

and supported by [ヤスラボ](http://yasslab.jp/ja/).

## 原著(英語)への貢献方法

We encourage you to contribute to Ruby on Rails! Please check out the
[Contributing to Ruby on Rails guide](http://edgeguides.rubyonrails.org/contributing_to_ruby_on_rails.html) for guidelines about how to proceed. [Join us!](http://contributors.rubyonrails.org)

# ライセンス

This work is licensed under a [Creative Commons Attribution-Share Alike 3.0](http://creativecommons.org/licenses/by-sa/3.0/) License

"Rails", "Ruby on Rails", and the Rails logo are trademarks of David Heinemeier Hansson. All rights reserved.

[Ruby on Rails](http://rubyonrails.org/) is released under the [MIT License](http://www.opensource.org/licenses/MIT).
