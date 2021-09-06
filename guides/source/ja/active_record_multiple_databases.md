Active Record で複数のデータベース利用
=====================================

このガイドでは、Active Recordでデータベースを複数利用する方法について説明します。

このガイドの内容:

* アプリケーションで複数のデータベースをセットアップする方法
* コネクションの自動切り替えの仕組み
* 複数のデータベースでの水平シャーディングの利用方法
* サポートされている機能と現在進行中の機能

--------------------------------------------------------------------------------


アプリケーションが人気を得て利用されるようになってくると、新しいユーザーやユーザーのデータをサポートするためにアプリケーションをスケールする必要が生じてきます。アプリケーションをスケールする方法のひとつが、データベースレベルでのスケールでしょう。Railsが複数のデータベースをサポートするようになりましたので（マルチプルデータベース）、すべてのデータを1箇所に保存する必要はありません。

現時点でサポートされている機能は以下のとおりです。

* 複数の「writer」データベースと、それぞれに対応する1つの「replica」
* モデルでのコネクション自動切り替え
* HTTP verbや直近の書き込みに応じたwriterとreplicaの自動スワップ
* マルチプルデータベースの作成、削除、マイグレーション、やりとりを行うRailsタスク

以下の機能は現時点では（まだ）サポートされていません。

* 水平シャーディングのための自動スワップ
* クラスタを越えるJOIN
* replicaのロードバランシング
* マルチプルデータベースのスキーマキャッシュのダンプ

## アプリケーションのセットアップ

アプリケーションでマルチプルデータベースを利用する場合、大半の機能についてはRailsが代わりに行いますが、一部手動で行う手順があります。

たとえば、writerデータベースがひとつあるアプリケーションに、新しいテーブルがいくつかあるデータベースを1つ追加するとします。新しいデータベースの名前は「animal」とします。

この場合のdatabase.ymlは以下のような感じになります。

```yaml
production:
  database: my_primary_database
  username: root
  password: <%= ENV['ROOT_PASSWORD'] %>
  adapter: mysql2
```

最初の設定に対するreplicaを追加し、さらにanimalという2つ目のデータベースとそれのreplicaも追加してみましょう。
これを行うには、database.ymlを以下のように2-tierから3-tier設定に変更する必要があります。

もしプライマリ設定が指定されている場合、これが「デフォルト」の設定として使用されます。
「primary」と名付けられた設定がない場合、Railsは環境での最初の設定を使用します。
デフォルトの設定ではデフォルトのRailsのファイル名が使用されます。
例えば、プライマリ設定では、スキーマファイルに`schema.rb`が使用される一方で、その他のエントリではファイル名に`[CONFIGURATION_NAMESPACE]_schema.rb`が使用されます。

```yaml
production:
  primary:
    database: my_primary_database
    username: root
    password: <%= ENV['ROOT_PASSWORD'] %>
    adapter: mysql2
  primary_replica:
    database: my_primary_database
    username: root_readonly
    password: <%= ENV['ROOT_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
  animals:
    database: my_animals_database
    username: animals_root
    password: <%= ENV['ANIMALS_ROOT_PASSWORD'] %>
    adapter: mysql2
    migrations_paths: db/animals_migrate
  animals_replica:
    database: my_animals_database
    username: animals_readonly
    password: <%= ENV['ANIMALS_READONLY_PASSWORD'] %>
    adapter: mysql2
    replica: true
```

マルチプルデータベースを用いる場合に重要な設定がいくつかあります。

第1に、`primary`と`primary_replica`のデータベース名は同じにすべきです。理由は、primaryとreplicaが同じデータを持つからです。
`animals`と`animals_replica`についても同様です。

第2に、writerとreplicaでは異なるユーザー名を使い、かつreplicaのパーミッションは（writeではなく）readにすべきです。

replicaデータベースを使う場合、`database.yml`のreplicaには`replica: true`というエントリを1つ追加する必要があります。このエントリがないと、どちらがreplicaでどちらがwriterかをRailsが区別できなくなるためです。

最後に、新しいwriterデータベースで利用するために、そのデータベースのマイグレーションを置くディレクトリを`migrations_paths`に設定する必要があります。`migrations_paths`については本ガイドで後述します。

新しいデータベースができたら、コネクションモデルをセットアップしましょう。新しいデータベースを使うには、抽象クラスを1つ作成してanimalsデータベースに接続する必要があります。

```ruby
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :animals, reading: :animals_replica }
end
```

続いて`ApplicationRecord`を更新し、新しいreplicaを認識させる必要があります。

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :primary_replica }
end
```

primary/primary_replicaと接続しているクラスは、通常のRailsアプリケーションと同様に`ApplicationRecord`を継承できます。

```ruby
class Person < ApplicationRecord
end
```

Railsはデフォルトで、primaryのデータベースロールは`writing`、replicaのデータベースロールは`reading`であることを期待します。レガシーなシステムでは、既に設定されているロールを変更したくないこともあるでしょう。その場合はアプリケーションで以下のように新しいロール名を設定できます。

```ruby
config.active_record.writing_role = :default
config.active_record.reading_role = :readonly
```

ここで重要なのは、データベースへの接続を「単一のモデル内」で行うことと、そのモデルを継承してテーブルを利用することです（複数のモデルから同じデータベースに接続するのではなく）。データベースクライアントにはコネクションをオープンできる数に上限があります。Railsはコネクションを指定する名前としてモデル名を用いるので、複数のモデルから同じデータベースに接続するとコネクション数が増加します。

database.ymlと新しいモデルをセットアップできたので、いよいよデータベースを作成しましょう。Rails 6.0にはマルチプルデータベースを使うのに必要なrailsタスクがすべて揃っています。

`bin/rails -T`を実行すると、利用可能なコマンド一覧がすべて表示されます。出力は以下のようになります。

```bash
$ bin/rails -T
rails db:create                          # Creates the database from DATABASE_URL or config/database.yml for the ...
rails db:create:animals                  # Create animals database for current environment
rails db:create:primary                  # Create primary database for current environment
rails db:drop                            # Drops the database from DATABASE_URL or config/database.yml for the cu...
rails db:drop:animals                    # Drop animals database for current environment
rails db:drop:primary                    # Drop primary database for current environment
rails db:migrate                         # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)
rails db:migrate:animals                 # Migrate animals database for current environment
rails db:migrate:primary                 # Migrate primary database for current environment
rails db:migrate:status                  # Display status of migrations
rails db:migrate:status:animals          # Display status of migrations for animals database
rails db:migrate:status:primary          # Display status of migrations for primary database
rails db:rollback                        # Rolls the schema back to the previous version (specify steps w/ STEP=n)
rails db:rollback:animals                # Rollback animals database for current environment (specify steps w/ STEP=n)
rails db:rollback:primary                # Rollback primary database for current environment (specify steps w/ STEP=n)
rails db:schema:dump                     # Creates a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:dump:animals             # Creates a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:dump:primary             # Creates a db/schema.rb file that is portable against any DB supported  ...
rails db:schema:load                     # Loads a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:load:animals             # Loads a database schema file (either db/schema.rb or db/structure.sql  ...
rails db:schema:load:primary             # Loads a database schema file (either db/schema.rb or db/structure.sql  ...
```

`bin/rails db:create`などのコマンドを実行すると、primaryとanimalsデータベースの両方が作成されます。ただし（データベースの）ユーザーを作成するコマンドはないので、replicaでreadonlyをサポートするには手動で行う必要があります。animalデータベースだけを作成するには、`bin/rails db:create:animals`を実行します。

## ジェネレータとマイグレーション

マルチプルデータベースでのマイグレーションは、設定ファイルにあるデータベースキー名を冒頭に付けた個別のフォルダに配置すべきです。

データベース設定の`migrations_paths`を設定し、マイグレーションファイルを探索する場所をRailsに認識させる必要もあります。

たとえば、`animals`データベースはマイグレーション用に`db/animals_migrate`ディレクトリに配置、`primary`は`db/migrate`ディレクトリに配置、という具合になります。Railsのジェネレータは、ファイルを正しいディレクトリで生成するための`--database`オプションを受け取るようになりました。このコマンドは次のような感じで実行します。

```bash
$ bin/rails generate migration CreateDogs name:string --database animals
```

もし、ジェネレータを使っている場合は、scaffoldとモデルジェネレータが抽象クラスを作成しますので、コマンドラインにデータベースのキーを渡してください。

```bash
$ bin/rails generate scaffold Dog name:string --database animals
```

データベース名のクラスと`Record`が作成されます。
この例では、データベースが`Animals`なので、`AnimalsRecord`が作成されます。

```ruby
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: { writing: :animals }
end
```

生成されたモデルは自動で`AnimalsRecord`クラスを継承します。

```ruby
class Dog < AnimalsRecord
end
```

メモ：Railsはどのデータベースがレプリカなのか知らないので、完了したらこれを抽象クラスに追加する必要があります。

Railsは新しいクラスを一度だけ生成します。新しいscaffoldsによって上書きされることはなく、scaffoldが削除されたときには削除されます。

`AnimalsRecord`と異なる既存の抽象クラスがある場合、`--parent`オプションを利用して別の抽象クラスを指定することができます。

```bash
$ bin/rails generate scaffold Dog name:string --database animals --parent Animals::Record
```

このような場合、別の親クラスを利用することを指定しているため、`AnimalsRecord`の生成をスキップします。

## コネクションの自動切り替えを有効にする

最後に、アプリケーションでread-onlyのレプリカを利用するために、自動切り替え用のミドルウェアを有効にする必要があります。

自動切り替え機能によって、アプリケーションはHTTP verbや直近の書き込みの有無に応じてwriterからreplica、またはreplicaからwriterへと切り替えます。

アプリケーションがPOST、PUT、DELETE、PATCHのいずれかのリクエストを受け取ると、自動的にwriterデータベースに書き込みます。書き込み後に指定の時間が経過するまでは、アプリケーションはwriterから読み出します。アプリケーションがGETリクエストやHEADリクエストを受け取ると、直近の書き込みがなければreplicaから読み出します。

コネクション自動切り替えのミドルウェアを有効にするには、アプリケーション設定に以下の行を追加するか、コメントを解除します。

```ruby
config.active_record.database_selector = { delay: 2.seconds }
config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
```

Railsは「自分が書き込んだものを読み取る」ことを保証するので、`delay`ウィンドウの期間内であればGETリクエストやHEADリクエストをwriterに送信します。この`delay`は、デフォルトで2秒に設定されます。この値の変更は、利用するデータベースのインフラストラクチャに基づいて行うべきです。Railsは、`delay`ウィンドウの期間内で他のユーザーが「最近書き込んだものを読み取る」ことについては保証しないので、最近書き込まれたものでなければGETリクエストやHEADリクエストをreplicaに送信します。

Railsのコネクション自動切り替えは、どちらかというと原始的であり、多機能とは言えません。この機能は、アプリケーションの開発者でも十分カスタマイズ可能な柔軟性を備えたコネクション自動切り替えシステムをデモンストレーションするためのものです。

Railsでのコネクション自動切り替え方法や、切り替えに使うパラメータはセットアップで簡単に変更できます。たとえば、コネクションをスワップするかどうかを、セッションではなくcookieで行いたいのであれば、以下のように独自のクラスを作成できます。

```ruby
class MyCookieResolver
  # cookieクラスで使うコードをここに書く
end
```

続いて、これをミドルウェアに渡します。

```ruby
config.active_record.database_selector = { delay: 2.seconds }
config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
config.active_record.database_resolver_context = MyCookieResolver
```

## コネクションを手動で切り替える

アプリケーションでprimaryやreplicaに接続するときに、コネクションの自動切り替えが適切ではないことがあります。たとえば、特定のリクエストについては、たとえPOSTリクエストパスにいる場合であっても常にreplicaに送信したいとします。

Railsはこのような場合のために、必要なコネクションに切り替える`connected_to`メソッドを提供しています。


```ruby
ActiveRecord::Base.connected_to(role: :reading) do
  # このブロック内のコードはすべてreadingロールで接続される
end
```


`connected_to`呼び出しの「ロール」では、そのコネクションハンドラ（またはロール）で接続されたコネクションを探索します。`reading`コネクションハンドラは、`reading`というロール名を持つ`connects_to`を介して接続されたすべてのコネクションを維持します。

ここで注意したいのは、ロールを設定した`connected_to`では、既存のコネクションの探索や切り替えにそのコネクションのspecification名が用いられることです。つまり、`connected_to(role: :nonexistent)`のように不明なロールを渡すと、`ActiveRecord::ConnectionNotEstablished (No connection pool with 'AnimalsBase' found
for the 'nonexistent' role.)`エラーが発生します。


## 注意点

### シャーディング

最初に申し上げておきたいのは、現時点のRailsではシャーディング（sharding）はまだサポートされていないという点です。私たちはRails 6.0でマルチプルデータベースをサポートするために膨大な作業をこなさなければなりませんでした。シャーディングのサポートを忘れていたわけではありませんが、そのために必要な追加作業は6.0では間に合いませんでした。さしあたってシャーディングが必要なのであれば、シャーディングをサポートするさまざまなgemのどれかを引き続き利用するのがおすすめと言えるかもしれません。

### replicaのロードバランシング

replicaのロードバランシングはインフラストラクチャに強く依存するため、これもRailsではサポート対象外です。今後、基本的かつ原始的なreplicaロードバランシング機能が実装されるかもしれませんが、アプリケーションをスケールさせるためにもRailsの外部でアプリケーションを扱えるものにすべきです。

### データベースをまたがるJOIN

アプリケーションは複数のデータベースにまたがるJOINを行えません。Rails 6.1では、JOINの代わりに`has_many`リレーションシップを用いて2つのクエリを作成することをサポートする予定ですが、Rails 6.0ではJOINを手動で2つのSELECT文に分ける必要があります。

### スキーマキャッシュ

スキーマキャッシュとマルチプルデータベースを利用する場合、アプリのスキーマキャッシュを読み込むためのイニシャライザを自分で書く必要があります。Rails 6.0には間に合いませんでしたが、いずれ今後のバージョンで解決できればと思います。
