Rails コア開発環境の構築方法
================================

本ガイドでは、Ruby on Rails自体の開発環境を構築する方法について解説します。

このガイドの内容:

* 自分のPCをRails開発用にセットアップする方法
* Railsのテストスイートの中から特定のグループを実行する方法
* RailsテストスイートのうちActive Recordに関する部分の動作

--------------------------------------------------------------------------------

環境を構築する他の方法について
------------

ローカルマシンでRailsを開発用にセットアップしたくない場合は、Codespaces、VS Code Remote Plugin、またはrails-dev-boxを利用できます。これらのオプションについて詳しくは[こちら][setup]を参照してください。

[setup]: contributing_to_ruby_on_rails.html#development環境を構築する

ローカル開発環境のセットアップ
------------

Ruby on Railsを自分のコンピュータ上で開発したい場合は、以下の手順を参照してください。

### Gitをインストールする

Ruby on Railsではソースコード管理にGitを使っています。インストール方法については[Gitホームページ][git-scm]に記載されています。Gitを学べる資料はインターネット上に多数あります。

[git-scm]: https://git-scm.com/

### Ruby on Railsリポジトリをクローンする

Ruby on Railsのソースコードを置きたいディレクトリ（ここに独自`rails`サブディレクトリが作成されます）で以下を実行します。

```bash
$ git clone https://github.com/rails/rails.git
$ cd rails
```

### 追加のツールやサービスをインストールする

Railsのテストの中には追加のツールに依存しているものもあります。そうしたテストを実行するには、これらのツールを手動でインストールしておく必要があります。

以下のリストは、Railsのgemごとに必要な追加の依存関係です。

* Action Cable: Redisに依存
* Active Record: SQLite3、MySQL、PostgreSQLに依存
* Active Storage: Yarn（Yarnはさらに[Node.js][]に依存）、ImageMagick、libvips、FFmpeg、muPDFに依存
  macOSではXQuartzにも依存
* Active Support: memcached、Redisに依存
* Railties: JavaScriptランタイム環境（[Node.js][]など）に依存

機能を変更したいgemを正しくテストするには、そのgemが依存するサービスをすべてインストールする必要があります。macOS、Ubuntu、Fedora/CentOS、Arch Linux、FreeBSDの各サービスのインストール方法について詳しくは後述します。

NOTE: Redisのドキュメントでは、パッケージマネージャによるRedisインストールは推奨されていません（パッケージマネージャーが古いため）。Redisをソースからインストールしてサーバーを立ち上げる方法については、[Redisドキュメント][Redis install]に詳しく記載されています。

NOTE: Active Recordのテストは、少なくともMySQLとPostgreSQLとSQLite3で**必ず**パスしなければなりません。 単一のアダプタでしかテストされていないパッチは却下されます（変更とテストの内容が特定のアダプタに限定されない場合を除く）。

以下は、OSごとの追加ツールのインストール方法です。

[Node.js]: https://nodejs.org/
[Redis install]: https://redis.io/download#installation

#### macOS

macOSの場合は、必要な追加ツールを[Homebrew][]ですべてインストールできます。

ツールをすべてインストールするには、クローンしたRailsディレクトリで以下を実行します。

```bash
$ brew bundle
```

インストールしたサービスを起動する必要もあります。サービスをすべて起動するには以下を実行します。

```bash
$ brew services list
```

サービスを個別に起動するには、以下のように実行します。

```bash
$ brew services start mysql
```

上のコマンドの`mysql`は、起動したいサービス名に置き換えます。

[Homebrew]: https://brew.sh/

##### 潜在的な問題

このセクションでは、macOSのネイティブ拡張機能、特にローカル開発で`mysql2` gemをバンドルする場合に遭遇する可能性のある問題について詳しく説明します。AppleがRailsの開発者環境に変更を加えたため、このドキュメントは今後変更される可能性や正確でない可能性があります。

macOSで`mysql2` gemをコンパイルするためには、以下が必要です。

1. `openssl@1.1`がインストール済みであること（`openssl@3`ではない）
2. Rubyが`openssl@1.1`でコンパイルされていること
3. `mysql2`用のbundle config内でコンパイラフラグが設定されていること

`openssl@1.1`と`openssl@3`の両方がインストールされている場合は、Railsが `mysql2`をバンドルするために、Rubyに`openssl@1.1`を利用するように指示する必要があります。

`.bash_profile`で、以下のように`PATH`と`RUBY_CONFIGURE_OPTS`が`openssl@1.1`を指すように設定します。

```bash
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
```

`~/.bundle/config`で`mysql2`を次のように設定します。このとき、`BUNDLE_BUILD__MYSQL2`の他のエントリは必ず削除してください。

```bash
BUNDLE_BUILD__MYSQL2: "--with-ldflags=-L/usr/local/opt/openssl@1.1/lib --with-cppflags=-L/usr/local/opt/openssl@1.1/include"
```

これらのフラグをRubyのインストールやRailsのバンドル前に設定しておくことで、ローカルのmacOS開発環境が動作するようになるはずです。

#### Ubuntu

以下を実行すると、すべての依存関係をインストールできます。

```bash
$ sudo apt-get update
$ sudo apt-get install sqlite3 libsqlite3-dev mysql-server libmysqlclient-dev postgresql postgresql-client postgresql-contrib libpq-dev redis-server memcached imagemagick ffmpeg mupdf mupdf-tools libxml2-dev libvips42 poppler-utils

# Yarnをインストールする
# Node.jsがインストールされない場合は以下のコマンドを使う
$ curl --fail --silent --show-error --location https://deb.nodesource.com/setup_18.x | sudo -E bash -
$ sudo apt-get install -y nodejs
# Node.jsをインストール済みの場合は以下のコマンドでyarn npmパッケージをインストールする
$ sudo npm install --global yarn
```

#### FedoraまたはCentOS

以下を実行すると、すべての依存関係をインストールできます。

```bash
$ sudo dnf install sqlite-devel sqlite-libs mysql-server mysql-devel postgresql-server postgresql-devel redis memcached imagemagick ffmpeg mupdf libxml2-devel vips poppler-utils

# Yarnをインストールする
# Node.jsをインストールしていない場合はこのコマンドを使う
$ curl --silent --location https://rpm.nodesource.com/setup_18.x | sudo bash -
$ sudo dnf install -y nodejs
# Node.jsをインストール済みの場合は以下のコマンドでyarn npmパッケージをインストールする
$ sudo npm install --global yarn
```

#### Arch Linux

以下を実行すると、すべての依存関係をインストールできます。

```bash
$ sudo pacman -S sqlite mariadb libmariadbclient mariadb-clients postgresql postgresql-libs redis memcached imagemagick ffmpeg mupdf mupdf-tools poppler yarn libxml2 libvips poppler
$ sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
$ sudo systemctl start redis mariadb memcached
```

NOTE: MySQLはArch Linuxではサポートされなくなったので、代わりにMariaDBをインストールする必要があります（[Arch Linuxのお知らせ][announcement]を参照）。

[announcement]: https://www.archlinux.org/news/mariadb-replaces-mysql-in-repositories/

#### FreeBSD

以下を実行すると、すべての依存関係をインストールできます。

```bash
$ sudo pkg install sqlite3 mysql80-client mysql80-server postgresql11-client postgresql11-server memcached imagemagick6 ffmpeg mupdf yarn libxml2 vips poppler-utils
# portmaster databases/redis
```

`ports`ですべてのツールをインストールすることも可能です（パッケージは`databases`フォルダに保存されます）。

NOTE: MySQLのインストールで発生する問題については、[MySQLドキュメント][MySQL doc]を参照してください。

[MySQL doc]: https://dev.mysql.com/doc/refman/8.0/ja/freebsd-installation.html

#### Debian

以下を実行すると、すべての依存関係をインストールできます。

```bash
$ sudo apt-get install sqlite3 libsqlite3-dev default-mysql-server default-libmysqlclient-dev postgresql postgresql-client postgresql-contrib libpq-dev redis-server memcached imagemagick ffmpeg mupdf mupdf-tools libxml2-dev libvips42 poppler-utils
```

NOTE: DebianのデフォルトのMySQLサーバーはMariaDBなので、何らかの違いが生じる可能性にご注意ください。

### データベースを設定する

Active Recordのテストを実行するのに必要なデータベースエンジンごとに、追加の設定手順がいくつか必要になります。

PostgreSQLの認証方法は異なります。LinuxまたはBSDで、開発用アカウントをdevelopment環境にセットアップするには、以下を実行するだけで済みます。

```bash
$ sudo -u postgres createuser --superuser $USER
```

macOSの場合は以下です。

```bash
$ createuser --superuser $USER
```

NOTE: MySQLはデータベースの作成時点でユーザーを作成します。このタスクでは、ユーザがパスワードなしの`root`であると仮定しています。

続いて、MySQLとPostgreSQLそれぞれについて以下を実行し、testデータベースを追加する必要があります。

```bash
$ cd activerecord
$ bundle exec rake db:create
```

以下を実行すると、データベースエンジンごとにtestデータベースを作成できます。

```bash
$ cd activerecord
$ bundle exec rake db:mysql:build
$ bundle exec rake db:postgresql:build
```

データベースを削除するには以下を実行します。

```bash
$ cd activerecord
$ bundle exec rake db:drop
```

NOTE: 上のrakeタスクでtestデータベースを作成すると、文字セットとコレーション（照合順序）が正しく設定されます。

他のデータベースを使っている場合は、`activerecord/test/config.yml`または`activerecord/test/config.example.yml`でデフォルトの接続情報があるかどうかをチェックしてください。別のcredential（認証情報）が必要な場合はローカルコンピュータで`activerecord/test/config.yml`を変更することでできますが、この変更はRailsの更新に含めてはいけません。

### JavaScriptの依存関係をインストールする

Yarnをインストールした場合は、以下を実行してJavaScriptの依存関係をインストールする必要があります。

```bash
$ yarn install
```

### 依存するgemをインストールする

gemは、Rubyにデフォルトで同梱されている[Bundler][]でインストールします。

RailsのGemfileに記載されているgemをインストールするには、以下を実行します。

```bash
$ bundle install
```

または、Active Recordのテストを実行する必要がない場合は、以下を実行します。

```bash
$ bundle install --without db
```

[Bundler]: https://bundler.io/

### Railsに貢献する

設定がすべて完了したら、ガイドの[Ruby on Rails に貢献する][]をお読みください。

[Ruby on Rails に貢献する]: contributing_to_ruby_on_rails.html#ローカルブランチでアプリケーションを実行する
