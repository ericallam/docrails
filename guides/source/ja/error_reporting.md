Rails アプリケーションのエラー通知機能
========================

このガイドは、Ruby on Railsアプリケーションで発生する例外の管理方法を解説します。

本ガイドの内容:

* Railsの`ErrorReporter`でエラーをキャプチャして通知する方法
* エラー通知サービス用のカスタムサブスクライバの作成方法

--------------------------------------------------------------------------------

エラー通知機能
------------------------

Railsの[`ErrorReporter`][]は、アプリケーションで発生した例外を収集して、好みのサービスや場所に通知する標準的な方法を提供します。

このエラーレポーターの目的は、以下のような定型的なエラー処理コードを置き換えることです。

```ruby
begin
  do_something
rescue SomethingIsBroken => error
  MyErrorReportingService.notify(error)
end
```

上の定形コードを、以下のようなインターフェイスで統一できます。

```ruby
Rails.error.handle(SomethingIsBroken) do
  do_something
end
```

Railsはすべての実行（HTTPリクエスト、ジョブ、`rails runner`の起動など）を`ErrorReporter`にラップするので、アプリで発生した未処理のエラーは、そのサブスクライバを介してエラーレポートサービスに自動的に通知されます。

これにより、サードパーティのエラー通知ライブラリは、Rackミドルウェアを挿入したり、未処理の例外をキャプチャするパッチを適用したりする必要がなくなります。また、Active Supportを使うライブラリがこの機能を利用して、従来ログに出力されなかった警告を、コードに手を加えずに通知できるようになります。

[`ErrorReporter`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html

このエラーレポーターの利用は必須ではありません。エラーをキャプチャする他の手法はすべて引き続き利用できます。

### エラーレポーターにサブスクライブする

エラーレポーターを利用するには**サブスクライバ**（subscriber）が必要です。サブスクライバは、`report`メソッドを持つ任意のオブジェクトのことです。アプリケーションでエラーが発生したり、手動で通知されたりすると、Railsのエラーレポーターはエラーオブジェクトといくつかのオプションを使ってこのメソッドを呼び出します。

[Sentry][]や[Honeybadger][]などのように、自動的にサブスクライバを登録してくれるエラー通知ライブラリもあります。詳しくはプロバイダのドキュメントを参照してください。

また、以下のようにカスタムサブスクライバを作成することも可能です。

```ruby
# config/initializers/error_subscriber.rb
class ErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    MyErrorReportingService.report_error(error, context: context, handled: handled, level: severity)
  end
end
```

Subscriberクラスを定義したら、[`Rails.error.subscribe`][]メソッドを呼び出して登録します。

```ruby
Rails.error.subscribe(ErrorSubscriber.new)
```

サブスクライバはいくつでも登録できます。Railsはサブスクライバを登録順に呼び出します。

NOTE: Railsのエラーレポーターは、どの環境でも常に登録されたサブスクライバーを呼び出します。しかし多くのエラー通知サービスは、デフォルトではproduction環境でのみエラーを通知します。必要に応じて、複数の環境で設定を行ってテストする必要があります。

[Sentry]: https://github.com/getsentry/sentry-ruby/blob/e18ce4b6dcce2ebd37778c1e96164684a1e9ebfc/sentry-rails/lib/sentry/rails/error_subscriber.rb
[Honeybadger]: https://docs.honeybadger.io/lib/ruby/integration-guides/rails-exception-tracking/
[`Rails.error.subscribe`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-subscribe

### エラーレポーターを利用する

エラーレポーターの使い方は3種類あります。

#### エラーを通知して握りつぶす

[`Rails.error.handle`][] は、ブロック内で発生したエラーを通知してから、そのエラーを**握りつぶします**。ブロックの外の残りのコードは通常通り続行されます。

```ruby
result = Rails.error.handle do
  1 + '1' # TypeErrorが発生
end
result # => nil
1 + 1 # ここは実行される
```

ブロック内でエラーが発生しなかった場合、`Rails.error.handle`はブロックの結果を返し、エラーが発生した場合は`nil`を返します。

以下のように`fallback`を指定することで、この振る舞いをオーバーライドできます。

```ruby
user = Rails.error.handle(fallback: -> { User.anonymous }) do
  User.find_by(params[:id])
end
```

[`Rails.error.handle`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-handle

#### エラーを通知して再度raiseする

[`Rails.error.record`][] はすべての登録済みレポーターにエラーを通知し、その後エラーを再度raiseします。残りのコードは実行されません。

```ruby
Rails.error.record do
1 + '1' # TypeErrorが発生
end
1 + 1 # ここは実行されない
```

ブロック内でエラーが発生しなかった場合、`Rails.error.record`はそのブロックの結果を返します。

[`Rails.error.record`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-record

#### エラーを手動で通知する

[`Rails.error.report`][]を呼び出して手動でエラーを通知することも可能です。

```ruby
begin
  # code
rescue StandardError => e
  Rails.error.report(e)
end
```

渡したオプションは、すべてエラーサブスクライバに渡されます。

[`Rails.error.report`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-report

### エラー通知機能のオプション

3つのレポートAPI（`#handle`、`#record`、`#report`）はすべて以下のオプションをサポートしています。これらのオプションは、すべての登録済みサブスクライバに渡されます。

- `handled`: エラーが処理されたかどうかを示す`Boolean`。
  デフォルトは`true`です（ただし`#record`のデフォルトは`false`です）。

- `severity`: エラーの重大性を表す`Symbol`。
  期待される値は`:error`、`:warning`、`:info`のいずれか。
  `#handle`では`:warning`に設定されます。
  `#record`では`:error`に設定されます。

- `context`: リクエストやユーザーの詳細など、エラーに関する詳細なコンテキストを提供する`Hash`。

- `source`: エラーの発生源に関する`String`。
  デフォルトのソースは`"application"`です。
  内部ライブラリから通知されたエラーは他のソースを設定する可能性があります（例: Redis キャッシュライブラリは`"redis_cache_store.active_support"`を設定する可能性があります）。
  サブスクライバは、ソースを利用することで興味のないエラーを無視できます。

```ruby
Rails.error.handle(context: { user_id: user.id }, severity: :info) do
  # ...
end
```

### エラークラスでフィルタリングする

`Rails.error.handle`や`Rails.error.record`では、以下のように特定のクラスのエラーだけを通知できます。

```ruby
Rails.error.handle(IOError) do
  1 + '1' # TypeErrorが発生
end
1 + 1 # TypeErrorsはIOErrorsではないので、ここは「実行されない」
```

上の`TypeError`はRailsのエラー通知レポーターにキャプチャされません。通知されるのは `IOError`およびその子孫インスタンスだけです。その他のエラーは通常どおりraiseします。

### コンテキストをグローバルに設定する

コンテキストは、`context`オプションで設定することも、以下のように[`#set_context`][]APIで設定することもできます。

```ruby
Rails.error.set_context(section: "checkout", user_id: @user.id)
```

この方法で設定されたコンテキストは、`context`オプションとマージされます。

```ruby
Rails.error.set_context(a: 1)
Rails.error.handle(context: { b: 2 }) { raise }
# 通知されるコンテキスト: {:a=>1, :b=>2}
Rails.error.handle(context: { b: 3 }) { raise }
# 通知されるコンテキスト: {:a=>1, :b=>3}
```

[`#set_context`]: https://api.rubyonrails.org/classes/ActiveSupport/ErrorReporter.html#method-i-set_context

### ライブラリで利用する

エラー通知ライブラリは、以下のように`Railtie`でライブラリのサブスクライバを登録できます。

```ruby
module MySdk
  class Railtie < ::Rails::Railtie
    initializer "my_sdk.error_subscribe" do
      Rails.error.subscribe(MyErrorSubscriber.new)
    end
  end
end
```

エラーサブスクライバを登録すると、Rackミドルウェアのような他のエラー機構がある場合、エラーが何度も通知される可能性があります。他のエラー機構を削除するか、レポーターの機能を調整して、通知済みの例外を通知しないようにする必要があります。
