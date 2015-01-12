
Railsの初期化プロセス
================================

本章は、Rails 4におけるRails初期化プロセスの内部について解説します。上級Rails開発者向けに推奨される、きわめて高度な内容を扱っています。

このガイドの内容:

* `rails server`の使用法
* Rails初期化シーケンスのタイムライン
* ブートシーケンスで通常と異なるファイルが必要となる箇所
* Rails::Serverインターフェイスの定義方法と使用法

--------------------------------------------------------------------------------

本章では、デフォルトのRails 4アプリケーション向けにRuby on Railsスタックの起動時に必要となるすべてのメソッド呼び出しについて、詳細な解説を行います。具体的には、`rails server`を実行してアプリケーションを起動したときにどのようなことが行われているかに注目して解説します。

NOTE: 文中に記載されるRuby on Railsアプリケーションへのパスは、特に記載のない限り相対パスを使用します。

TIP: Railsの[ソースコード](https://github.com/rails/rails)を参照しながら読み進めるのであれば、Githubページ上で`t`キーバインドを使用してfile finderを起動し、ファイルを素早く見つけることをお勧めします。

起動!
-------

それではアプリケーションを起動して初期化を開始しましょう。Railsアプリケーションの起動は`rails console`または`rails server`を実行して行うのが普通です。

### `railties/bin/rails`

`rails server`のうち、`rails`コマンドの部分はRubyで記述された実行ファイルであり、読み込みパス上に置かれています。この実行ファイルには以下の行が含まれています。

```ruby
version = ">= 0"
load Gem.bin_path('railties', 'rails', version)
```

このコマンドをRailsコンソールで実行すると、`railties/bin/rails`が読み込まれるのがわかります。`railties/bin/rails.rb`ファイルには以下のコードが含まれています。

```ruby
require "rails/cli"
```

今度は`railties/lib/rails/cli`ファイルが`Rails::AppRailsLoader.exec_app_rails`を呼び出します。

### `railties/lib/rails/app_rails_loader.rb`

`exec_app_rails`の主要な目的な、Railsアプリケーションにある`bin/rails`を実行することです。カレントディレクトリに`bin/rails`がない場合、`bin/rails`が見つかるまでディレクトリを上に向って探索します。これにより、Railsアプリケーション内のどのディレクトリからでも`rails`コマンドを実行できるようになります。

`rails server`については、以下の同等のコマンドが実行されます。

```bash
$ exec ruby bin/rails server
```

### `bin/rails`

このファイルの内容は次のとおりです。

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application', __FILE__)
require_relative '../config/boot'
require 'rails/commands'
```

`APP_PATH`定数は後で`rails/commands`で使用されます。この行で参照されている`config/boot`ファイルは、Railsアプリケーションの`config/boot.rb`ファイルであり、Bundlerの読み込みと設定を担当します。

### `config/boot.rb`

`config/boot.rb`には以下の行が含まれています。

```ruby
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
```

標準的なRailsアプリケーションにはGemfileというファイルがあり、アプリケーション内のすべての依存関係がそのファイル内で宣言されています。`config/boot.rb`はGemfileの位置を`ENV['BUNDLE_GEMFILE']`に設定します。Gemfileが存在する場合、`bundler/setup`をrequireします。このrequireは、Gemfileの依存ファイルが置かれている読み込みパスをBundlerで設定する際に使用されます。

標準的なRailsアプリケーションは多くのgemに依存しますが、特に以下のgemに依存しています。

* actionmailer
* actionpack
* actionview
* activemodel
* activerecord
* activesupport
* arel
* builder
* bundler
* erubis
* i18n
* mail
* mime-types
* rack
* rack-cache
* rack-mount
* rack-test
* rails
* railties
rake
* sqlite3
* thor
* tzinfo

### `rails/commands.rb`

`config/boot.rb`の設定が完了すると、次にrequireするのはコマンドの別名を拡張する`rails/commands`です。この状況で`ARGV`配列には`server`だけが含まれており、以下のように受け渡しされます。

```ruby
ARGV << '--help' if ARGV.empty?

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console"
  "s"  => "server",
  "db" => "dbconsole"
  "r"  => "runner"
}

command = ARGV.shift
command = aliases[command] || command

require 'rails/commands/commands_tasks'

Rails::CommandsTasks.new(ARGV).run_command!(command)
```

TIP: 実際にやってみるとわかるとおり、空のARGVリストが渡されると、使用法のスニペットが表示されます。

`server`の代わりに`s`が渡されると、ここで定義されている`aliases`の中からマッチするコマンドを探します。

### `rails/commands/command_tasks.rb`

`run_command`は、間違ったRailsコマンドが入力された時にエラーメッセージを表示する役割も担います。正しいコマンドの場合は同じ名前のメソッドが呼び出されます。

```ruby
COMMAND_WHITELIST = %(plugin generate destroy console server dbconsole application runner new version help)

def run_command!(command)
  command = parse_command(command)
  if COMMAND_WHITELIST.include?(command)
    send(command)
  else
    write_error_message(command)
  end
end
```

`server`コマンドが指定されると、Railsはさらに以下のコードを実行します。

```ruby
def set_application_directory!
  Dir.chdir(File.expand_path('../../', APP_PATH)) unless File.exist?(File.expand_path("config.ru"))
end

def server
  set_application_directory!
  require_command!("server")

  Rails::Server.new.tap do |server|
    # サーバーが環境を設定してからアプリケーションをrequireする必要がある
    # そうしないとサーバーに与えられた環境オプションを展開できない
    require APP_PATH
    Dir.chdir(Rails.application.root)
    server.start
  end
end

def require_command!(command)
  require "rails/commands/#{command}"
end
```

上のファイルは、`config.ru`ファイルが見つからない場合に限り、Railsのルートディレクトリ (`config/application.rb`を指す`APP_PATH`から2階層上のディレクトリ) に置かれます。このコードは続いて`rails/commands/server`を実行します。これは`Rails::Server`クラスを設定するものです。

```ruby
require 'fileutils'
require 'optparse'
require 'action_dispatch'
require 'rails'

module Rails
  class Server < ::Rack::Server
```

`fileutils`および`optparse`は標準のRubyライブラリであり、それぞれファイル操作や解析オプションを使用できるヘルパー関数を提供します。

### `actionpack/lib/action_dispatch.rb`

Action DispatchはRailsフレームワークのルーティングを司るコンポーネントです。ルーティング、セッションおよび共通のミドルウェアなどの機能を提供します。

### `rails/commands/server.rb`

`Rails::Server`クラスはこのファイル内で定義されており、`Rack::Server`を継承しています。`Rails::Server.new`を呼び出すと、`rails/commands/server.rb`の`initialize`メソッドが呼び出されます。

```ruby
def initialize(*)
  super
  set_environment
end
```

最初に`super`が呼び出され、そこから`Rack::Server`の`initialize`メソッドを呼び出します。●

### Rack: `lib/rack/server.rb`

`Rack::Server`は、あらゆるRackベースのアプリケーション (Railsもその中に含まれます) のための共通のサーバーインターフェイスを提供する役割を担います。

`Rack::Server`の`initialize`は、いくつかの変数を設定しているだけの簡単なメソッドです。

```ruby
def initialize(options = nil)
  @options = options
  @app = options[:app] if options && options[:app]
end
```

この場合`options`の値は`nil`になるので、このメソッドでは何も実行されません。

`super`が`Rack::Server`の中で完了すると、`rails/commands/server.rb`に制御が戻ります。この時点で、`set_environment`が`Rails::Server`オブジェクトのコンテキスト内で呼び出されますが、一見したところ大した処理を行なっていないように見えます。

```ruby
def set_environment
  ENV["RAILS_ENV"] ||= options[:environment]
end
```

In fact, the `options` method here does quite a lot. This method is defined in `Rack::Server` like this:

  ```ruby
def options
  @options ||= parse_options(ARGV)
      end 
```

Then `parse_options` is defined like this:

  ```ruby
def parse_options(args)
  options = default_options

  # Don't evaluate CGI ISINDEX parameters.
  # http://www.meb.uni-bonn.de/docs/cgi/cl.html
  args.clear if ENV.include?("REQUEST_METHOD")

  options.merge! opt_parser.parse!(args)
  options[:config] = ::File.expand_path(options[:config])
  ENV["RACK_ENV"] = options[:environment]
いくつかあります。 
      end 
```

With the `default_options` set to this:

  ```ruby
def default_options
  environment  = ENV['RACK_ENV'] || 'development'
  default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

  {
    :environment => environment,
    :pid         => nil,
    :Port        => 9292,
    :Host        => default_host,
    :AccessLog   => [],
    :config      => "config.ru"
  }
      end 
```

There is no `REQUEST_METHOD` key in `ENV` so we can skip over that line. The next line merges in the options from `opt_parser` which is defined plainly in `Rack::Server`:

  ```ruby
def opt_parser
  Options.new
      end 
```

The class **is** defined in `Rack::Server`, but is overwritten in `Rails::Server` to take different arguments. Its `parse!` method begins like this:

  ```ruby
def parse!(args)
  args, options = args.dup, {}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: rails server [mongrel, thin, etc] [options]"
    opts.on("-p", "--port=port", Integer,
            "Runs Rails on the specified port.", "Default: 3000") { |v| options[:Port] = v }
  ...
```

This method will set up keys for the `options` which Rails will then be able to use to determine how its server should run. After `initialize` has finished, we jump back into `rails/server` where `APP_PATH` (which was set earlier) is required.

### `config/application`

When `require APP_PATH` is executed, `config/application.rb` is loaded (recall that `APP_PATH` is defined in `bin/rails`). This file exists in your application and it's free for you to change based on your needs.

### `Rails::Server#start`

After `config/application` is loaded, `server.start` is called. This method is defined like this:

  ```ruby
def start
  print_boot_information
  trap(:INT) { exit }
  create_tmp_directories
  log_to_stdout if options[:log_stdout]

          super
  ...
      end 

  private

  def print_boot_information
    ...
    puts "=> Run `rails server -h` for more startup options"
    ...
    puts "=> Ctrl-C to shutdown server" unless options[:daemonize]
      end 

  def create_tmp_directories
    %w(cache pids sessions sockets).each do |dir_to_make|
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', dir_to_make))
      end 
      end 

  def log_to_stdout
    wrapped_app # touch the app so the logger is set up

    console = ActiveSupport::Logger.new($stdout)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
      end 
```

This is where the first output of the Rails initialization happens. This method creates a trap for `INT` signals, so if you `CTRL-C` the server, it will exit the process. As we can see from the code here, it will create the `tmp/cache`, `tmp/pids`, `tmp/sessions` and `tmp/sockets` directories. It then calls `wrapped_app` which is responsible for creating the Rack app, before creating and assigning an instance of `ActiveSupport::Logger`.

The `super` method will call `Rack::Server.start` which begins its definition like this:

  ```ruby
def start &blk
  if options[:warn]
    $-w = true
      end 

  if includes = options[:include]
    $LOAD_PATH.unshift(*includes)
      end 

  if library = options[:require]
    require library
      end 

  if options[:debug]
    $DEBUG = true
    require 'pp'
    p options[:server]
    pp wrapped_app
    pp app
      end 

  check_pid! if options[:pid]

  # Touch the wrapped app, so that the config.ru is loaded before
  # daemonization (i.e. before chdir, etc).
  wrapped_app

  daemonize_app if options[:daemonize]

  write_pid if options[:pid]

  trap(:INT) do
    if server.respond_to?(:shutdown)
      server.shutdown
  else
出口
      end 
      end 

  server.run wrapped_app, options, &blk
      end 
```

The interesting part for a Rails app is the last line, `server.run`. Here we encounter the `wrapped_app` method again, which this time we're going to explore more (even though it was executed before, and thus memoized by now).

  ```ruby
@wrapped_app ||= build_app app
```

The `app` method here is defined like so:

  ```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
      end 
...
  private
  def build_app_and_options_from_config
    if !::File.exist? options[:config]
      abort "configuration #{options[:config]} not found"
      end 

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! いくつかあります。 
app
      end 

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
      end 
```

The `options[:config]` value defaults to `config.ru` which contains this:

  ```ruby
# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run <%= app_const %>
```


The `Rack::Builder.parse_file` method here takes the content from this `config.ru` file and parses it using this code:

  ```ruby
app = new_from_string cfgfile, config

...

def self.new_from_string(builder_script, file="(rackup)")
  eval "Rack::Builder.new {\n" + builder_script + "\n}.to_app",
    TOPLEVEL_BINDING, file, 0
      end 
```

The `initialize` method of `Rack::Builder` will take the block here and execute it within an instance of `Rack::Builder`. This is where the majority of the initialization process of Rails happens. The `require` line for `config/environment.rb` in `config.ru` is the first to run:

  ```ruby
require ::File.expand_path('../config/environment', __FILE__)
```

### `config/environment.rb`

This file is the common file required by `config.ru` (`rails server`) and Passenger. This is where these two ways to run the server meet; everything before this point has been Rack and Rails setup.

This file begins with requiring `config/application.rb`:

  ```ruby
require File.expand_path('../application', __FILE__)
```

### `config/application.rb`

This file requires `config/boot.rb`:

  ```ruby
require File.expand_path('../boot', __FILE__)
```

But only if it hasn't been required before, which would be the case in `rails server` but **wouldn't** be the case with Passenger.

Then the fun begins!

Loading Rails
-------------

The next line in `config/application.rb` is:

  ```ruby
require 'rails/all'
```

### `railties/lib/rails/all.rb`

This file is responsible for requiring all the individual frameworks of Rails:

  ```ruby
require "rails"

%w(
  active_record
  action_controller
  action_view
  action_mailer
  rails/test_unit
  sprockets
).each do |framework|
      begin
    require "#{framework}/railtie"
    rescue LoadError
      end 
      end 
```

This is where all the Rails frameworks are loaded and thus made available to the application. We won't go into detail of what happens inside each of those frameworks, but you're encouraged to try and explore them on your own.

For now, just keep in mind that common functionality like Rails engines, I18n and Rails configuration are all being defined here.

### Back to `config/environment.rb`

The rest of `config/application.rb` defines the configuration for the `Rails::Application` which will be used once the application is fully initialized. When `config/application.rb` has finished loading Rails and defined the application namespace, we go back to `config/environment.rb`, where the application is initialized. For example, if the application was called `Blog`, here we would find `Rails.application.initialize!`, which is defined in `rails/application.rb`.

### `railties/lib/rails/application.rb`

The `initialize!` method looks like this:

  ```ruby
def initialize!(group=:default) #:nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
self
      end 
```

As you can see, you can only initialize an app once. The initializers are run through the `run_initializers` method which is defined in `railties/lib/rails/initializable.rb`:

  ```ruby
def run_initializers(group=:default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
      end 
  @ran = true
      end 
```

The `run_initializers` code itself is tricky. What Rails is doing here is traversing all the class ancestors looking for those that respond to an `initializers` method. It then sorts the ancestors by name, and runs them. For example, the `Engine` class will make all the engines available by providing an `initializers` method on them.

The `Rails::Application` class, as defined in `railties/lib/rails/application.rb` defines `bootstrap`, `railtie`, and `finisher` initializers. The `bootstrap` initializers prepare the application (like initializing the logger) while the `finisher` initializers (like building the middleware stack) are run last. The `railtie` initializers are the initializers which have been defined on the `Rails::Application` itself and are run between the `bootstrap` and `finishers`.

After this is done we go back to `Rack::Server`.

### Rack: lib/rack/server.rb

Last time we left when the `app` method was being defined:

  ```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
      end 
...
  private
  def build_app_and_options_from_config
    if !::File.exist? options[:config]
      abort "configuration #{options[:config]} not found"
      end 

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! いくつかあります。 
app
      end 

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
      end 
```

At this point `app` is the Rails app itself (a middleware), and what
happens next is Rack will call all the provided middlewares:

  ```ruby
def build_app(app)
  middleware[options[:environment]].reverse_each do |middleware|
    middleware = middleware.call(self) if middleware.respond_to?(:call)
    next unless middleware
    klass = middleware.shift
    app = klass.new(app, *middleware)
      end 
app
      end 
```

Remember, `build_app` was called (by `wrapped_app`) in the last line of `Server#start`. Here's how it looked like when we left:

  ```ruby
server.run wrapped_app, options, &blk
```

At this point, the implementation of `server.run` will depend on the server you're using. For example, if you were using Puma, here's what the `run` method would look like:

  ```ruby
...
DEFAULT_OPTIONS = {
  :Host => '0.0.0.0',
  :Port => 8080,
  :Threads => '0:16',
  :Verbose => false
}

def self.run(app, options = {})
  options  = DEFAULT_OPTIONS.merge(options)

  if options[:Verbose]
    app = Rack::CommonLogger.new(app, STDOUT)
      end 

  if options[:environment]
    ENV['RACK_ENV'] = options[:environment].to_s
      end 

  server   = ::Puma::Server.new(app)
  min, max = options[:Threads].split(':', 2)

  puts "Puma #{::Puma::Const::PUMA_VERSION} starting..."
  puts "* Min threads: #{min}, max threads: #{max}"
  puts "* Environment: #{ENV['RACK_ENV']}"
  puts "* Listening on tcp://#{options[:Host]}:#{options[:Port]}"

  server.add_tcp_listener options[:Host], options[:Port]
  server.min_threads = min
  server.max_threads = max
  yield server if block_given?

      begin
    server.run.join
  rescue Interrupt
    puts "* Gracefully stopping, waiting for requests to finish"
    server.stop(true)
    puts "* Goodbye!"
      end 

      end 
```

We won't dig into the server configuration itself, but this is the last piece of our journey in the Rails initialization process.

This high level overview will help you understand when your code is executed and how, and overall become a better Rails developer. If you still want to know more, the Rails source code itself is probably the best place to go next.