
Railsジェネレータとテンプレート入門
=====================================================

Railsの各種ジェネレータは、ワークフローを改善するために欠かせないツールです。本ガイドは、Railsジェネレータの作成方法および既存のジェネレータのカスタマイズ方法について解説します。

このガイドの内容:

* アプリケーションで利用できるジェネレータを確認する方法
* テンプレートを使用してジェネレータを作成する方法
* Railsがジェネレータの起動前に探索するときの方法
* RailsがテンプレートからRailsコードを内部的に生成する方法
* ジェネレータを自作することでscaffoldをカスタマイズする方法
* ジェネレータのテンプレートを変更することでscaffoldをカスタマイズする方法
* 多数のジェネレータをうっかり上書きしないためのフォールバック使用法
* アプリケーションテンプレートの作成方法

--------------------------------------------------------------------------------

ジェネレータとの最初の出会い
-------------

`rails`コマンドでRailsアプリケーションを作成すると、実はRailsのジェネレータを利用したことになります。続いて、単に`rails generate`と入力して実行すると、その時点でアプリケーションから利用可能なすべてのジェネレータのリストが表示されます。

```bash
$ rails new myapp
$ cd myapp
$ bin/rails generate
```

Railsで利用可能なすべてのジェネレータのリストが表示されます。たとえばヘルパージェネレータの詳細な説明が知りたい場合は以下のように入力します。

```bash
$ bin/rails generate helper --help
```

初めてジェネレータを作成する
-----------------------------

Railsのジェネレータは、Rails 3.0以降は[Thor](https://github.com/erikhuda/thor)の上に構築されています。Thorは強力な解析オプションと優れたファイル操作APIを提供しています。具体例として、`config/initializers`ディレクトリの下に`initializer.rb`という名前のイニシャライザファイルを1つ作成するジェネレータを構成してみましょう。

最初の手順として、以下の内容を持つ`lib/generators/initializer_generator.rb`というファイルを1つ作成します。

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

NOTE: `create_file`メソッドは`Thor::Actions`によって提供されています。`create_file`およびその他のThorのメソッドのドキュメントについては[Thorドキュメント](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)を参照してください。

今作成した新しいジェネレータはきわめてシンプルです。`Rails::Generators::Base`を継承しており、メソッド定義はひとつだけです。ジェネレータが起動されると、ジェネレータ内で定義されているパブリックメソッドが定義順に実行されます。最終的に`create_file`メソッドが呼び出され、指定の内容を持つファイルが指定のディレクトリに1つ作成されます。RailsのアプリケーションテンプレートAPIを使い慣れている開発者であれば、すぐにも新しいジェネレータAPIに熟達できることでしょう。

以下を実行するだけで、この新しいジェネレータを呼び出すことができます。

```bash
$ bin/rails generate initializer
```

次に進む前に、今作成したばかりのジェネレータの説明を表示してみましょう。

```bash
$ bin/rails generate initializer --help
```

Railsでは、ジェネレータが`ActiveRecord::Generators::ModelGenerator`のように名前空間化されていれば実用的な説明文を生成できますが、この場合は残念ながらそのようになっていません。この問題は2とおりの方法で解決することができます。1つ目の方法は、ジェネレータ内で`desc`メソッドを呼び出すというものです。

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "このジェネレータはconfig/initializersにイニシャライザファイルを作成する"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# イニシャライザの内容をここに記述"
  end
end
```

これで、`--help`を付けて新しいジェネレータを呼び出すと新しい説明文が表示されるようになりました。説明文を追加する2番目の方法は、ジェネレータと同じディレクトリに`USAGE`という名前のファイルを作成することです。次に、この方法で実際に説明文を追加してみましょう。

ジェネレータを使用してジェネレータを生成する
-----------------------------------

Railsには、ジェネレータを生成するためのジェネレータもあります。

```bash
$ bin/rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

上で作成したジェネレータの内容は以下のとおりです。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

上のジェネレータを見て最初に気付く点は、`Rails::Generators::Base`ではなく`Rails::Generators::NamedBase`を継承していることでしょう。これは、このジェネレータを生成するためには少なくとも1つの引数が必要であることを意味します。この引数はイニシャライザの名前であり、コードではこのイニシャライザ名を`name`という変数で参照できます。

新しいジェネレータを呼び出せば説明文が表示されます。なお、古いジェネレータファイルは必ず削除しておいてください。

```bash
$ bin/rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

新しいジェネレータには`source_root`という名前のクラスメソッドも含まれています。このメソッドは、ジェネレータのテンプレートの置き場所を指定する場合に使用します。デフォルトでは、作成された`lib/generators/initializer/templates`ディレクトリを指します。

ジェネレータのテンプレートの機能を理解するために、`lib/generators/initializer/templates/initializer.rb`を作成して以下の内容を追加してみましょう。

```ruby
# 初期化内容をここに追記する
```

続いてジェネレータを変更し、呼び出されたときにこのテンプレートをコピーするようにします。

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

それではこのジェネレータを実行してみましょう。

```bash
$ bin/rails generate initializer core_extensions
```

`config/initializers/core_extensions.rb`にcore_extensionsという名前のイニシャライザが作成され、そこにさっきのテンプレートが反映されていることが確認できます。`copy_file`メソッドはコピー元のルートディレクトリから、指定のパスにファイルをひとつコピーしています。`file_name`メソッドは`Rails::Generators::NamedBase`を継承したことで自動的に作成されます。

ジェネレータ関連で利用できるメソッドについては、本章の[最終セクション](#generator-methods)で扱っています。

ジェネレータが参照するファイル
-----------------

`rails generate initializer core_extensions`を実行するとき、Railsは以下のファイルを上から順に見つかるまでrequireします。

```bash
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

どのファイルも見つからない場合はエラーメッセージが表示されます。

INFO: 上の例ではアプリケーションの`lib`ディレクトリの下にファイルを置いていますが、これらのディレクトリは`$LOAD_PATH`に属していることがその理由です。

ワークフローをカスタマイズする
-------------------------

Rails自身が持つジェネレータはscaffoldを柔軟にカスタマイズできます。設定は`config/application.rb`で行います。デフォルトのコードを以下にいくつか示します。

```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

ワークフローをカスタマイズする前のscaffoldは以下のように動作します。

```bash
$ bin/rails generate scaffold User name:string
      invoke  active_record
      create    db/migrate/20130924151154_create_users.rb
      create    app/models/user.rb
      invoke  test_unit
      create      test/models/user_test.rb
      create      test/fixtures/users.yml
      invoke  resource_route
       route    resources :users
      invoke  scaffold_controller
      create    app/controllers/users_controller.rb
      invoke    erb 
      create      app/views/users
      create      app/views/users/index.html.erb
      create      app/views/users/edit.html.erb
      create      app/views/users/show.html.erb
      create      app/views/users/new.html.erb
      create      app/views/users/_form.html.erb
      invoke  test_unit
      create      test/controllers/users_controller_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/users.js.coffee
      invoke    scss
      create      app/assets/stylesheets/users.css.scss
      invoke  scss
      create    app/assets/stylesheets/scaffolds.css.scss
```

この出力結果から、Rails 3.0以降のジェネレータの動作を容易に理解できます。実はscaffoldジェネレータ自身は何も生成していません。生成に必要なメソッドを順に呼び出しているだけです。このような仕組みになっているので、呼び出しを自由に追加/置換/削除できます。たとえば、scaffoldジェネレータはscaffold_controllerというジェネレータを呼び出しています。これはerbのジェネレータ、test_unitのジェネレータ、そしてヘルパーのジェネレータを呼び出します。ジェネレータごとに役割がひとつずつ割り当てられているので、コードを再利用しやすく、コードの重複も防げます。

最初のカスタマイズとして、ワークフローでスタイルシートとJavaScriptとテストフィクスチャファイルをscaffoldで生成しないようにしてみましょう。これは、以下のように設定を変更することで行うことができます。

```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

scaffoldジェネレータでふたたびリソースを生成してみると、今度はスタイルシートとJavaScriptファイルとフィクスチャが生成されなくなります。If you want to customize it further, for example to use DataMapper and RSpec instead of Active Record and TestUnit, it's just a matter of adding their gems to your application and configuring your generators.

To demonstrate this, we are going to create a new helper generator that simply adds some instance variable readers. First, we create a generator within the rails namespace, as this is where rails searches for generators used as hooks:

```bash
$ bin/rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
```

After that, we can delete both the `templates` directory and the `source_root` class method call from our new generator, because we are not going to need them. Add the method below, so our generator looks like the following:

  ```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
      end 
FILE 
      end 
      end 
```

We can try out our new generator by creating a helper for products:

```bash
$ bin/rails generate my_helper products
      create  app/helpers/products_helper.rb
```

And it will generate the following helper file in `app/helpers`:

  ```ruby
module ProductsHelper
  attr_reader :products, :product
      end 
```

Which is what we expected. We can now tell scaffold to use our new helper generator by editing `config/application.rb` once again:

  ```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
  g.helper          :my_helper
      end 
```

and see it in action when invoking the generator:

```bash
$ bin/rails generate scaffold Article body:text
      [...]
      invoke    my_helper
      create      app/helpers/articles_helper.rb
```

We can notice on the output that our new helper was invoked instead of the Rails default. However one thing is missing, which is tests for our new generator and to do that, we are going to reuse old helpers test generators.

Since Rails 3.0, this is easy to do due to the hooks concept. Our new helper does not need to be focused in one specific test framework, it can simply provide a hook and a test framework just needs to implement this hook in order to be compatible.

To do that, we can change the generator this way:

  ```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
      end 
FILE 
      end 

  hook_for :test_framework
      end 
```

Now, when the helper generator is invoked and TestUnit is configured as the test framework, it will try to invoke both `Rails::TestUnitGenerator` and `TestUnit::MyHelperGenerator`. Since none of those are defined, we can tell our generator to invoke `TestUnit::Generators::HelperGenerator` instead, which is defined since it's a Rails generator. To do that, we just need to add:

  ```ruby
# Search for :helper instead of :my_helper
hook_for :test_framework, as: :helper
```

And now you can re-run scaffold for another resource and see it generating tests as well!

Customizing Your Workflow by Changing Generators Templates
----------------------------------------------------------

In the step above we simply wanted to add a line to the generated helper, without adding any extra functionality. There is a simpler way to do that, and it's by replacing the templates of already existing generators, in that case `Rails::Generators::HelperGenerator`.

In Rails 3.0 and above, generators don't just look in the source root for templates, they also search for templates in other paths. And one of them is `lib/templates`. Since we want to customize `Rails::Generators::HelperGenerator`, we can do that by simply making a template copy inside `lib/templates/rails/helper` with the name `helper.rb`. So let's create that file with the following content:

```erb
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
      end 
```

and revert the last change in `config/application.rb`:

  ```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
      end 
```

If you generate another resource, you can see that we get exactly the same result! This is useful if you want to customize your scaffold templates and/or layout by just creating `edit.html.erb`, `index.html.erb` and so on inside `lib/templates/erb/scaffold`.

Scaffold templates in Rails frequently use ERB tags; these tags need to be escaped so that the generated output is valid ERB code.

For example, the following escaped ERB tag would be needed in the template (note the extra `%`)...

  ```ruby
<%%= stylesheet_include_tag :application %>
```

...to generate the following output:

  ```ruby
<%= stylesheet_include_tag :application %>
```

Adding Generators Fallbacks
---------------------------

One last feature about generators which is quite useful for plugin generators is fallbacks. For example, imagine that you want to add a feature on top of TestUnit like [shoulda](https://github.com/thoughtbot/shoulda) does. Since TestUnit already implements all generators required by Rails and shoulda just wants to overwrite part of it, there is no need for shoulda to reimplement some generators again, it can simply tell Rails to use a `TestUnit` generator if none was found under the `Shoulda` namespace.

We can easily simulate this behavior by changing our `config/application.rb` once again:

  ```ruby
config.generators do |g|
  g.orm :active_record
  g.template_engine :erb
  g.test_framework  :shoulda, fixture: false
  g.stylesheets     false
  g.javascripts     false

  # Add a fallback!
  g.fallbacks[:shoulda] = :test_unit
      end 
```

Now, if you create a Comment scaffold, you will see that the shoulda generators are being invoked, and at the end, they are just falling back to TestUnit generators:

```bash
$ bin/rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20130924143118_create_comments.rb
      create    app/models/comment.rb
      invoke    shoulda
      create      test/models/comment_test.rb
      create      test/fixtures/comments.yml
      invoke  resource_route
       route    resources :comments
      invoke  scaffold_controller
      create    app/controllers/comments_controller.rb
      invoke    erb 
      create      app/views/comments
      create      app/views/comments/index.html.erb
      create      app/views/comments/edit.html.erb
      create      app/views/comments/show.html.erb
      create      app/views/comments/new.html.erb
      create      app/views/comments/_form.html.erb
      invoke    shoulda
      create      test/controllers/comments_controller_test.rb
      invoke    my_helper
      create      app/helpers/comments_helper.rb
      invoke    jbuilder
      create      app/views/comments/index.json.jbuilder
      create      app/views/comments/show.json.jbuilder
invoke  assets
invoke    coffee
      create      app/assets/javascripts/comments.js.coffee
invoke    scss
```

Fallbacks allow your generators to have a single responsibility, increasing code reuse and reducing the amount of duplication.

Application Templates
---------------------

Now that you've seen how generators can be used _inside_ an application, did you know they can also be used to _generate_ applications too? This kind of generator is referred as a "template". This is a brief overview of the Templates API. For detailed documentation see the [Rails Application Templates guide](rails_application_templates.html).

  ```ruby
gem "rspec-rails", group: "test"
gem "cucumber-rails", group: "test"

if yes?("Would you like to install Devise?")
  gem "devise"
  generate "devise:install"
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
      end 
```

In the above template we specify that the application relies on the `rspec-rails` and `cucumber-rails` gem so these two will be added to the `test` group in the `Gemfile`. Then we pose a question to the user about whether or not they would like to install Devise. If the user replies "y" or "yes" to this question, then the template will add Devise to the `Gemfile` outside of any group and then runs the `devise:install` generator. This template then takes the users input and runs the `devise` generator, with the user's answer from the last question being passed to this generator.

Imagine that this template was in a file called `template.rb`. We can use it to modify the outcome of the `rails new` command by using the `-m` option and passing in the filename:

```bash
$ rails new thud -m template.rb
```

This command will generate the `Thud` application, and then apply the template to the generated output.

Templates don't have to be stored on the local system, the `-m` option also supports online templates:

```bash
$ rails new thud -m https://gist.github.com/radar/722911/raw/
```

Whilst the final section of this guide doesn't cover how to generate the most awesome template known to man, it will take you through the methods available at your disposal so that you can develop it yourself. These same methods are also available for generators.

Generator methods
-----------------

The following are methods available for both generators and templates for Rails.

NOTE: Methods provided by Thor are not covered this guide and can be found in [Thor's documentation](http://rdoc.info/github/erikhuda/thor/master/Thor/Actions.html)

### `gem`

Specifies a gem dependency of the application.

  ```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

Available options are:

* `:group` - The group in the `Gemfile` where this gem should go.
* `:version` - The version string of the gem you want to use. Can also be specified as the second argument to the method.
* `:git` - The URL to the git repository for this gem.

Any additional options passed to this method are put on the end of the line:

  ```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

The above code will put the following line into `Gemfile`:

  ```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

### `gem_group`

Wraps gem entries inside a group:

  ```ruby
gem_group :development, :test do
  gem "rspec-rails"
      end 
```

### `add_source`

Adds a specified source to `Gemfile`:

  ```ruby
add_source "http://gems.github.com"
```

### `inject_into_file`

Injects a block of code into a defined position in your file.

  ```ruby
inject_into_file 'name_of_file.rb', after: "#The code goes below this line. Don't forget the Line break at the end\n" do <<-'RUBY'
  puts "Hello World"
RUBY
      end 
```

### `gsub_file`

Replaces text inside a file.

  ```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

Regular Expressions can be used to make this method more precise. You can also use `append_file` and `prepend_file` in the same way to place code at the beginning and end of a file respectively.

### `application`

Adds a line to `config/application.rb` directly after the application class definition.

  ```ruby
application "config.asset_host = 'http://example.com'"
```

This method can also take a block:

  ```ruby
application do
  "config.asset_host = 'http://example.com'"
      end 
```

Available options are:

* `:env` - Specify an environment for this configuration option. If you wish to use this option with the block syntax the recommended syntax is as follows:

  ```ruby
application(nil, env: "development") do
  "config.asset_host = 'http://localhost:3000'"
      end 
```

### `git`

Runs the specified git command:

  ```ruby
git :init
git add: "."
git commit: "-m First commit!"
git add: "onefile.rb", rm: "badfile.cxx"
```

The values of the hash here being the arguments or options passed to the specific git command. As per the final example shown here, multiple git commands can be specified at a time, but the order of their running is not guaranteed to be the same as the order that they were specified in.

### `vendor`

Places a file into `vendor` which contains the specified code.

  ```ruby
vendor "sekrit.rb", '#top secret stuff'
```

This method also takes a block:

  ```ruby
vendor "seeds.rb" do
  "puts 'in your app, seeding your database'"
      end 
```

### `lib`

Places a file into `lib` which contains the specified code.

  ```ruby
lib "special.rb", "p Rails.root"
```

This method also takes a block:

  ```ruby
lib "super_special.rb" do
  puts "Super special!"
      end 
```

### `rakefile`

Creates a Rake file in the `lib/tasks` directory of the application.

  ```ruby
rakefile "test.rake", "hello there"
```

This method also takes a block:

  ```ruby
rakefile "test.rake" do
  %Q{
    task rock: :environment do
      puts "Rockin'"
      end 
  }
      end 
```

### `initializer`

Creates an initializer in the `config/initializers` directory of the application:

  ```ruby
initializer "begin.rb", "puts 'this is the beginning'"
```

This method also takes a block, expected to return a string:

  ```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
      end 
```

### `generate`

Runs the specified generator where the first argument is the generator name and the remaining arguments are passed directly to the generator.

  ```ruby
generate "scaffold", "forums title:string description:text"
```


### `rake`

Runs the specified Rake task.

  ```ruby
rake "db:migrate"
```

Available options are:

* `:env` - Specifies the environment in which to run this rake task.
* `:sudo` - Whether or not to run this task using `sudo`. デフォルトは`false`です。

### `capify!`

Runs the `capify` command from Capistrano at the root of the application which generates Capistrano configuration.

  ```ruby
capify!
```

### `route`

Adds text to the `config/routes.rb` file:

  ```ruby
route "resources :people"
```

### `readme`

Output the contents of a file in the template's `source_path`, usually a README.

  ```ruby
readme "README"
```