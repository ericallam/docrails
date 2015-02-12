


Railsのアプリケーションテンプレート
===========================

Railsのアプリケーションテンプレートは単純なRubyファイルであり、新規または既存のRailsプロジェクトにgemやイニシャライザを追加するためのDSL (ドメイン固有言語) を含んでいます。

このガイドの内容:

* テンプレートを使用してRailsアプリケーションの生成/カスタマイズを行う方法
* RailsテンプレートAPIを使用して再利用可能なアプリケーションテンプレートを開発する方法

--------------------------------------------------------------------------------

### 使用法
-----

アプリケーションテンプレートを適用するためには、-mオプションを使用してテンプレートの場所を指定する必要があります。ファイルパスまたはURLのどちらでも使用できます。

```bash
$ rails new blog -m ~/template.rb
$ rails new blog -m http://example.com/template.rb
```

rakeタスク`rails:template`を使用して、既存のRailsアプリケーションにテンプレートを適用することもできます。テンプレートの場所はLOCATION環境変数を使用して渡す必要があります。ここでも、ファイルパスまたはURLのどちらを使用してもかまいません。

```bash
$ bin/rake rails:template LOCATION=~/template.rb
$ bin/rake rails:template LOCATION=http://example.com/template.rb
```

テンプレートAPI
------------

RailsのテンプレートAPIはわかりやすく設計されています。以下は代表的なRailsアプリケーションテンプレートです。

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

以下のセクションで、APIで提供される主なメソッドの概要を解説します。

### gem(*args)

生成された`Gemfile`ファイルに、指定された`gem`のエントリを追加します。

たとえば、Railsアプリケーションが`bj`と`nokogiri` gemに依存しているとします。

```ruby
gem "bj"
gem "nokogiri"
```

Gemfileでgemを指定しただけではインストールされないのでご注意ください。指定したgemをインストールするためには`bundle install`を実行する必要があります。

```bash
bundle install
```

### gem_group(*names, &block)

gemのエントリを指定のグループに含めます。

たとえば、`rspec-rails` gemを`development`グループと`test`グループだけで読み込みたい場合は以下のようにします。

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### add_source(source, options = {})

生成された`Gemfile`ファイルに、指定されたソースを追加します。

たとえば、`"http://code.whytheluckystiff.net"`にあるgemをソースとして使用したい場合は以下のようにします。

```ruby
add_source "http://code.whytheluckystiff.net"
```

### environment/application(data=nil, options={}, &block)

`config/application.rb`ファイルの`Application`クラスの内側に指定の行を追加します。

`options[:env]`が指定されている場合は、`config/environments`ディレクトリに置かれている同等のファイルに追加します。

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'production'
```

`data`引数の代わりにブロックをひとつ渡すこともできます。

### vendor/lib/file/initializer(filename, data = nil, &block)

生成されたRailsアプリケーションの`config/initializers`ディレクトリにイニシャライザをひとつ追加します。

たとえば、`Object#not_nil?`と`Object#not_blank?`というメソッドを使用したい場合は以下のようにします。

```ruby
initializer 'bloatlol.rb', <<-CODE
  class Object
    def not_nil?
      !nil?
    end

    def not_blank?
      !blank?
    end
  end
CODE
```

同様に、`lib()`は`lib/`ディレクトリに、`vendor()`は`vendor/`ディレクトリにそれぞれファイルをひとつ作成します。

`file()`メソッドを使用すれば、`Rails.root`からの相対パスを渡してディレクトリやファイルを自在に作成することもできます。

```ruby
file 'app/components/foo.rb', <<-CODE
  class Foo
  end
CODE
```

上のコードは`app/components`ディレクトリを作成し、その中に`foo.rb`ファイルを置きます。

### rakefile(filename, data = nil, &block)

指定されたタスクを含むrakeファイルを`lib/tasks`の下に作成します。

```ruby
rakefile("bootstrap.rake") do
  <<-TASK
    namespace :boot do
      task :strap do
        puts "i like boots!"
      end
    end
  TASK
end
```

上のコードは`lib/tasks/bootstrap.rake`ファイルを作成し、その中に`boot:strap` rakeタスクを置きます。

### generate(what, *args)

引数を渡してRailsジェネレータを実行します。

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### run(command)

任意のコマンドを実行します。いわゆるバッククォートと同等です。たとえば`README.rdoc`ファイルを削除する場合は以下のようにします。

```ruby
run "rm README.rdoc"
```

### rake(command, options = {})

Railsアプリケーション内にあるtakeタスクを指定して実行します。たとえばデータベースのマイグレーションを行うには以下のように書きます。

```ruby
rake "db:migrate"
```

Railsの環境を指定してrakeタスクを実行することもできます。

```ruby
rake "db:migrate", env: 'production'
```

### route(routing_code)

Adds a routing entry to the `config/routes.rb` file. In the steps above, we generated a person scaffold and also removed `README.rdoc`. Now, to make `PeopleController#index` the default page for the application:

```ruby
route "root to: 'person#index'"
``` 

### inside(dir)

Enables you to run a command from the given directory. For example, if you have a copy of edge rails that you wish to symlink from your new apps, you can do this:

```ruby
inside('vendor') do
  run "ln -s ~/commit-rails/rails rails"
  end
``` 

### ask(question)

`ask()` gives you a chance to get some feedback from the user and use it in your templates. Let's say you want your user to name the new shiny library you're adding:

```ruby
lib_name = ask("What do you want to call the shiny library ?")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
``` 

### yes?(question) or no?(question)

These methods let you ask questions from templates and decide the flow based on the user's answer. Let's say you want to freeze rails only if the user wants to:

```ruby
rake("rails:freeze:gems") if yes?("Freeze rails gems?")
# no?(question) acts just the opposite.
``` 

### git(:command)

Rails templates let you run any git command:

```ruby
  git :init
  git add: "."
git commit: "-a -m 'Initial commit'"
``` 

### after_bundle(&block)

Registers a callback to be executed after the gems are bundled and binstubs are generated. Useful for all generated files to version control:

```ruby
after_bundle do
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"
  end
``` 

The callbacks gets executed even if `--skip-bundle` and/or `--skip-spring` has been passed.

Advanced Usage
--------------

The application template is evaluated in the context of a `Rails::Generators::AppGenerator` instance. It uses the `apply` action provided by [Thor](https://github.com/erikhuda/thor/blob/master/lib/thor/actions.rb#L207).
This means you can extend and change the instance to match your needs.

For example by overwriting the `source_paths` method to contain the location of your template. Now methods like `copy_file` will accept relative paths to your template's location.

```ruby
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
  end
```