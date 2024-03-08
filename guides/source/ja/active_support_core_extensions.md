Active Support コア拡張機能
==============================

Active SupportはRuby on Railsのコンポーネントであり、Ruby言語の拡張やユーティリティを提供します。

Active Supportは言語レベルで基本部分を底上げして豊かなものにし、Railsアプリケーションの開発とRuby on Railsそれ自体の開発に役立てるべく作られています。

このガイドの内容:

* コア拡張機能（Core Extensions）について
* すべての拡張機能を読み込む方法
* 必要な拡張機能だけを利用する方法
* Active Supportが提供する拡張機能一覧

--------------------------------------------------------------------------------


コア拡張機能を読み込む方法
---------------------------

### 単体のActive Support

フットプリントを最小限にするため、Active Supportはデフォルトでは最小限の依存関係を読み込みます。Active Supportは細かく分割され、必要な拡張機能だけが読み込まれるようになっています。また、関連する拡張機能（場合によってはすべての拡張機能）も同時に読み込むのに便利なエントリポイントもあります。

したがって、以下のような`require`文を実行すると、Active Supportによって`require`される拡張機能だけが読み込まれます。

```ruby
require 'active_support'
```

#### 必要な定義だけを選ぶ

この例では、[`Hash#with_indifferent_access`][Hash#with_indifferent_access]の読み込み方を説明します。この拡張機能は、`Hash`を[`ActiveSupport::HashWithIndifferentAccess`][ActiveSupport::HashWithIndifferentAccess]に変換して、以下のように文字列とシンボルのどちらをキーに指定してもアクセスできるようにします。

```ruby
{ a: 1 }.with_indifferent_access["a"] # => 1
```

本ガイドでは、コア拡張機能として定義されているすべてのメソッドについて、その定義ファイルの置き場所も示してあります。たとえば`with_indifferent_access` の場合、以下のようなメモを追加してあります。

NOTE: 定義は[`active_support/core_ext/hash/indifferent_access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/hash_with_indifferent_access.rb)にあります。

つまり、以下のようにピンポイントで`require`を実行できます。

```ruby
require "active_support"
require "active_support/core_ext/hash/indifferent_access"
```

Active Supportの改訂は注意深く行われていますので、あるファイルを選んだ場合、本当に必要な依存ファイルだけが同時に読み込まれます（依存関係がある場合）。

#### コア拡張機能をグループ化して読み込む

次の段階として、`Hash`に対するすべての拡張機能を単に読み込んでみましょう。経験則として、`SomeClass`というクラスがあれば、`active_support/core_ext/some_class`というパスを指定することで一度に読み込めます。

従って、（`with_indifferent_access`を含む）`Hash`のすべての拡張機能を読み込む場合には以下のようにします。

```ruby
require 'active_support'
require "active_support/core_ext/hash"
```

#### すべてのコア拡張機能を読み込む

すべてのコア拡張機能を単に読み込みたい場合は、以下のように`require`します。

```ruby
require 'active_support'
require 'active_support/core_ext'
```

#### すべてのActive Supportを読み込む

最後に、利用可能なActive Supportをすべて読み込みたい場合は以下のようにします。

```ruby
require 'active_support/all'
```

ただし、これを実行してもActive Support全体がメモリに読み込まれるわけではないことにご注意ください。一部は`autoload`として設定されており、実際に使うときだけ読み込まれます。

### Ruby on RailsアプリケーションにおけるActive Support

Ruby on Railsアプリケーションでは、基本的にすべてのActive Supportを読み込みます。例外は[`config.active_support.bare`][]を`true`に設定した場合です。このオプションを`true`にすると、フレームワーク自体が必要とするまでアプリケーションは拡張機能を読み込みません。また上で解説したように、読み込まれる拡張機能はあらゆる粒度で選択されます。

[`config.active_support.bare`]: configuring.html#config-active-support-bare

すべてのオブジェクトで使える拡張機能
-------------------------

### `blank?`と`present?`

Railsアプリケーションでは以下の値を空白（blank）とみなします。

* `nil`と`false`

* ホワイトスペース（whitespace）だけで構成された文字列（以下の注釈を参照）

* 空配列と空ハッシュ

* その他、`empty?`メソッドに応答してtrueを返すオブジェクトはすべて空（empty）として扱われます。

INFO: 文字列を判定する述語メソッドでは、Unicode対応した文字クラスである`[:space:]`が使われています。そのため、たとえばU+2029（段落区切り文字）はホワイトスペースと判断されます。

WARNING: 数字については空白であるかどうかは判断されません。特に0および0.0は**空白ではありません**のでご注意ください。

たとえば、`ActionController::HttpAuthentication::Token::ControllerMethods`にある以下のメソッドではトークンが存在しているかどうかを[`blank?`][Object#blank?]でチェックしています。

```ruby
def authenticate(controller, &login_procedure)
  token, options = token_and_options(controller.request)
  unless token.blank?
    login_procedure.call(token, options)
  end
end
```

[`present?`][Object#present?]メソッドは`!blank?`メソッドと同等です。以下の例は`ActionDispatch::Http::Cache::Response`から引用しました。

```ruby
def set_conditional_cache_control!
  return if self["Cache-Control"].present?
  ...
end
```

NOTE: 定義は[`active_support/core_ext/object/blank.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/blank.rb)にあります。

[Object#blank?]: https://api.rubyonrails.org/classes/Object.html#method-i-blank-3F
[Object#present?]: https://api.rubyonrails.org/classes/Object.html#method-i-present-3F

### `presence`

[`presence`][Object#presence]メソッドは、`present?`が`true`の場合は自身のレシーバを返し、falseの場合は`nil`を返します。このメソッドは以下のような便利な定番の用法があります。

```ruby
host = config[:host].presence || 'localhost'
```

NOTE: 定義は[`active_support/core_ext/object/blank.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/blank.rb)にあります。

[Object#presence]: https://api.rubyonrails.org/classes/Object.html#method-i-presence

### `duplicable?`

Ruby 2.5以降は、ほとんどのオブジェクトを`dup`や`clone`で複製できます。

```ruby
"foo".dup           # => "foo"
"".dup              # => ""
Rational(1).dup     # => (1/1)
Complex(0).dup      # => (0+0i)
1.method(:+).dup    # => TypeError (allocator undefined for Method)
```

Active Supportでは、複製可能かどうかをオブジェクトに問い合わせる[`duplicable?`][Object#duplicable?]が提供されています。

```ruby
"foo".duplicable?           # => true
"".duplicable?              # => true
Rational(1).duplicable?     # => true
Complex(1).duplicable?      # => true
1.method(:+).duplicable?    # => false
```

WARNING: どんなクラスでも、`dup`メソッドと`clone`メソッドを除去することでこれらのメソッドを無効にできます。このとき、これらのメソッドが実行されると例外が発生します。このような状態では、どんなオブジェクトについてもそれが複製可能かどうかを確認するには`rescue`を使う以外に方法はありません。`duplicable?`メソッドは、上のハードコードされたリストに依存しますが、その代わり`rescue`よりずっと高速です。実際のユースケースでハードコードされたリストで十分であることがわかっている場合にのみ、`duplicable?`をお使いください。

NOTE: 定義は[`active_support/core_ext/object/duplicable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/duplicable.rb)にあります。

[Object#duplicable?]: https://api.rubyonrails.org/classes/Object.html#method-i-duplicable-3F

### `deep_dup`

[`deep_dup`][Object#deep_dup]メソッドは、与えられたオブジェクトの「ディープコピー」を返します。Rubyは通常の場合、他のオブジェクトを含むオブジェクトを`dup`しても、含まれている他のオブジェクトを複製しません。このようなコピーは「浅いコピー（shallow copy）」と呼ばれます。たとえば、以下のように文字列を含む配列があるとします。

```ruby
array     = ['string']
duplicate = array.dup

duplicate.push 'another-string'

# このオブジェクトは複製されたので、複製された方にだけ要素が追加された
array     # => ['string']
duplicate # => ['string', 'another-string']

duplicate.first.gsub!('string', 'foo')

# 1つ目の要素は複製されていないので、一方を変更するとどちらの配列も変更される
array     # => ['foo']
duplicate # => ['foo', 'another-string']
```

上で見たとおり、`Array`のインスタンスを複製して別のオブジェクトができたことにより、一方を変更しても他方は変更されないようになりました。ただし、配列は複製されましたが、配列の要素はそうではありません。`dup`メソッドはディープコピーを行わないので、配列の中にある文字列は複製後も同一オブジェクトのままです。

オブジェクトをディープコピーする必要がある場合は次のように`deep_dup`をお使いください。

```ruby
array     = ['string']
duplicate = array.deep_dup

duplicate.first.gsub!('string', 'foo')

array     # => ['string']
duplicate # => ['foo']
```

オブジェクトが複製可能でない場合、`deep_dup`は単にそのオブジェクトを返します。

```ruby
number = 1
duplicate = number.deep_dup
number.object_id == duplicate.object_id   # => true
```

NOTE: 定義は[`active_support/core_ext/object/deep_dup.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/deep_dup.rb)にあります。

[Object#deep_dup]: https://api.rubyonrails.org/classes/Object.html#method-i-deep_dup

### `try`

`nil`でない場合にのみオブジェクトのメソッドを呼び出したい場合、最も単純な方法は条件文を追加することですが、どこか冗長になってしまいます。そこで[`try`][Object#try]メソッドを使うという手があります。`try`は`Object#public_send`と似ていますが、`nil`に送信された場合には`nil`を返す点が異なります。

例:

```ruby
# tryメソッドを使わない場合
unless @number.nil?
  @number.next
end

# tryメソッドを使った場合
@number.try(:next)
```

`ActiveRecord::ConnectionAdapters::AbstractAdapter`から別の例として以下をご紹介します。ここでは`@logger`が`nil`になることがあります。このコードでは`try`を使ったことで余分なチェックを行わずに済んでいます。

```ruby
def log_info(sql, name, ms)
  if @logger.try(:debug?)
    name = '%s (%.1fms)' % [name || 'SQL', ms]
    @logger.debug(format_log_entry(name, sql.squeeze(' ')))
  end
end
```

`try`メソッドは引数の代わりにブロックを与えて呼び出すこともできます。この場合オブジェクトが`nil`でない場合にのみブロックが実行されます。

```ruby
@person.try { |p| "#{p.first_name} #{p.last_name}" }
```

`try`メソッドは、`NoMethodError`を握りつぶして代わりに`nil`を返す点に注意が必要です。メソッド名の誤りを防ぎたい場合は[`try!`][Object#try!]を使います。

```ruby
@number.try(:nest)  # => nil
@number.try!(:nest) # NoMethodError: undefined method `nest' for 1:Integer
```

NOTE: 定義は[`active_support/core_ext/object/try.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/try.rb)にあります。

[Object#try]: https://api.rubyonrails.org/classes/Object.html#method-i-try
[Object#try!]: https://api.rubyonrails.org/classes/Object.html#method-i-try-21

### `class_eval(*args, &block)`

[`class_eval`][Kernel#class_eval]メソッドを使うと、任意のオブジェクトのsingletonクラスのコンテキストでコードを評価できます。

```ruby
class Proc
  def bind(object)
    block, time = self, Time.current
    object.class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end
end
```

NOTE: 定義は[`active_support/core_ext/kernel/singleton_class.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/kernel/singleton_class.rb)にあります。

[Kernel#class_eval]: https://api.rubyonrails.org/classes/Kernel.html#method-i-class_eval

### `acts_like?(duck)`

[`acts_like?`][Object#acts_like?]メソッドは、一部のクラスがその他のクラスと同様に振る舞うかどうかを、シンプルな規約に沿ってチェックします。`String`クラスと同じインターフェイスを提供するクラスがあり、その中で以下のメソッドを定義しておくとします。

```ruby
def acts_like_string?
end
```

このメソッドは単なる目印であり、メソッドの本体と戻り値の間に関連はありません。これにより、クライアントコードで以下のようなダックタイピングチェックを行えます。

```ruby
some_klass.acts_like?(:string)
```

Railsには`Date`クラスや`Time`クラスと同様に振る舞うクラスがいくつかあり、この手法を使えます。

NOTE: 定義は[`active_support/core_ext/object/acts_like.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/acts_like.rb)にあります。

[Object#acts_like?]: https://api.rubyonrails.org/classes/Object.html#method-i-acts_like-3F

### `to_param`

Railsのあらゆるオブジェクトは[`to_param`][Object#to_param]メソッドに応答します。これは、オブジェクトを値として表現するものを返すということです。返された値はクエリ文字列やURLの一部で利用できます。

デフォルトでは、`to_param`メソッドは単に`to_s`メソッドを呼び出します。

```ruby
7.to_param # => "7"
```

`to_param`によって返された値を **エスケープしてはいけません**。

```ruby
"Tom & Jerry".to_param # => "Tom & Jerry"
```

このメソッドは、Railsの多くのクラスで上書きされています。

たとえば、`nil`、`true`、`false`の場合は自分自身を返します。[`Array#to_param`][Array#to_param]を実行すると、`to_param`が配列内の各要素に対して実行され、結果が「/」でjoinされます。

```ruby
[0, true, String].to_param # => "0/true/String"
```

特に、Railsのルーティングシステムはモデルに対して`to_param`メソッドを実行することで、`:id`プレースホルダの値を取得しています。`ActiveRecord::Base#to_param`はモデルの`id`を返しますが、このメソッドをモデル内で再定義することもできます。以下のコード例があるとします。

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

上のコードから以下の結果を得られます。

```ruby
user_path(@user) # => "/users/357-john-smith"
```

WARNING: コントローラ側では、`to_param`メソッドがモデル側で再定義されている可能性があることに常に注意しておく必要があります。上のようなリクエストを受信した場合、`params[:id]`の値が「357-john-smith」になるからです。

NOTE: 定義は[`active_support/core_ext/object/to_param.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/to_param.rb)にあります。

[Array#to_param]: https://api.rubyonrails.org/classes/Array.html#method-i-to_param
[Object#to_param]: https://api.rubyonrails.org/classes/Object.html#method-i-to_param

### `to_query`

[`to_query`][Object#to_query]メソッドは、エスケープされていない`key`を受け取ると、そのキーを`to_param`が返す値に対応させるクエリ文字列の一部を生成します。以下のコード例があるとします。

```ruby
class User
  def to_param
    "#{id}-#{name.parameterize}"
  end
end
```

上のコードから以下の結果を得られます。

```ruby
current_user.to_query('user') # => "user=357-john-smith"
```

このメソッドは、キーと値のいずれについても、必要な箇所をすべてエスケープします。

```ruby
account.to_query('company[name]')
# => "company%5Bname%5D=Johnson+%26+Johnson"
```

これにより、この結果をそのままクエリ文字列として利用できます。

配列に`to_query`メソッドを適用した場合、`to_query`を配列の各要素に適用して`key[]`をキーとして追加し、それらを「&」で連結したものを返します。

```ruby
[3.4, -45.6].to_query('sample')
# => "sample%5B%5D=3.4&sample%5B%5D=-45.6"
```

ハッシュも`to_query`に応答しますが、使われるシグネチャが異なります。メソッドに引数が渡されない場合、このメソッド呼び出しは、一連のキーバリューペアをソート済みの形で生成し、それぞれの値に対して`to_query(key)`を呼び出し、結果を「&」で連結します。

```ruby
{ c: 3, b: 2, a: 1 }.to_query # => "a=1&b=2&c=3"
```

[`Hash#to_query`][Hash#to_query]メソッドは、それらのキーに対して名前空間をオプションで与えることもできます。

```ruby
{ id: 89, name: "John Smith" }.to_query('user')
# => "user%5Bid%5D=89&user%5Bname%5D=John+Smith"
```

NOTE: 定義は[`active_support/core_ext/object/to_query.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/to_query.rb)にあります。

[Hash#to_query]: https://api.rubyonrails.org/classes/Hash.html#method-i-to_query
[Object#to_query]: https://api.rubyonrails.org/classes/Object.html#method-i-to_query

### `with_options`

[`with_options`][Object#with_options]メソッドは、連続した複数のメソッド呼び出しに対して共通して与えられるオプションを解釈するための手段を提供します。

デフォルトのオプションがハッシュで与えられると、`with_options`はブロックに対するプロキシオブジェクトを生成します。そのブロック内では、プロキシに対して呼び出されたメソッドにオプションを追加したうえで、そのメソッドをレシーバに転送します。たとえば、以下のように同じオプションを繰り返さないで済むようになります。

```ruby
class Account < ApplicationRecord
  has_many :customers, dependent: :destroy
  has_many :products,  dependent: :destroy
  has_many :invoices,  dependent: :destroy
  has_many :expenses,  dependent: :destroy
end
```

上のコードを以下のように書けます。

```ruby
class Account < ApplicationRecord
  with_options dependent: :destroy do |assoc|
    assoc.has_many :customers
    assoc.has_many :products
    assoc.has_many :invoices
    assoc.has_many :expenses
  end
end
```

この手法を使って、たとえばニュースレターの読者を言語ごとに「グループ化」できます。読者が話す言語に応じて異なるニュースレターを送信したいとします。メール送信用のコードのどこかで、以下のような感じでロケール依存ビットをグループ化できます。

```ruby
I18n.with_options locale: user.locale, scope: "newsletter" do |i18n|
  subject i18n.t :subject
  body    i18n.t :body, user_name: user.name
end
```

TIP: `with_options`はメソッドをレシーバに転送しているので、呼び出しをネストすることもできます。各ネスティングレベルでは、自身の呼び出しに、継承したデフォルト呼び出しをマージします。

NOTE: 定義は[`active_support/core_ext/object/with_options.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/with_options.rb)にあります。

[Object#with_options]: https://api.rubyonrails.org/classes/Object.html#method-i-with_options

### JSONのサポート

Active Supportが提供する`to_json`メソッドの実装は、通常`json` gemがRubyオブジェクトに対して提供している`to_json`よりも優れています。その理由は、`Hash`や`OrderedHash`、`Process::Status`などのクラスでは、正しいJSON表現を提供するために特別な処理が必要になるためです。

NOTE: 定義は[`active_support/core_ext/object/json.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/json.rb)にあります。

### インスタンス変数

Active Supportは、インスタンス変数に簡単にアクセスするためのメソッドを多数提供しています。

#### `instance_values`

[`instance_values`][Object#instance_values]メソッドはハッシュを返します。インスタンス変数名から「@」を除いたものがハッシュのキーに、インスタンス変数の値がハッシュの値にマップされます。キーは文字列です。

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_values # => {"x" => 0, "y" => 1}
```

NOTE: 定義は[`active_support/core_ext/object/instance_variables.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/instance_variables.rb)にあります。

[Object#instance_values]: https://api.rubyonrails.org/classes/Object.html#method-i-instance_values

#### `instance_variable_names`

[`instance_variable_names`][Object#instance_variable_names]メソッドは配列を返します。配列のインスタンス名には「@」記号が含まれます。

```ruby
class C
  def initialize(x, y)
    @x, @y = x, y
  end
end

C.new(0, 1).instance_variable_names # => ["@x", "@y"]
```

NOTE: 定義は[`active_support/core_ext/object/instance_variables.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/instance_variables.rb)にあります。

[Object#instance_variable_names]: https://api.rubyonrails.org/classes/Object.html#method-i-instance_variable_names

### 警告や例外の抑制

[`silence_warnings`][Kernel#silence_warnings]メソッドと[`enable_warnings`][Kernel#enable_warnings]メソッドは、ブロックが継続する間`$VERBOSE`の値を変更し、その後リセットします。

```ruby
silence_warnings { Object.const_set "RAILS_DEFAULT_LOGGER", logger }
```

[`suppress`][Kernel#suppress]メソッドを使って例外の発生を止めることもできます。このメソッドは、例外クラスを表す任意の数値を受け取ります。`suppress`は、あるブロックの実行時に例外が発生し、その例外が（`kind_of?`による判定で）いずれかの引数に一致する場合、それをキャプチャして例外を発生せずに戻ります。一致しない場合、例外はキャプチャされません。

```ruby
# ユーザーがロックされていればインクリメントは失われるが、重要ではない
suppress(ActiveRecord::StaleObjectError) do
  current_user.increment! :visits
end
```

NOTE: 定義は[`active_support/core_ext/kernel/reporting.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/kernel/reporting.rb)にあります。

[Kernel#enable_warnings]: https://api.rubyonrails.org/classes/Kernel.html#method-i-enable_warnings
[Kernel#silence_warnings]: https://api.rubyonrails.org/classes/Kernel.html#method-i-silence_warnings
[Kernel#suppress]: https://api.rubyonrails.org/classes/Kernel.html#method-i-suppress

### `in?`

述語[`in?`][Object#in?]は、あるオブジェクトが他のオブジェクトに含まれているかどうかをテストします。渡された引数が`include?`に応答しない場合は`ArgumentError`例外が発生します。

`in?`の例を示します。

```ruby
1.in?([1, 2])        # => true
"lo".in?("hello")    # => true
25.in?(30..50)       # => false
1.in?(1)             # => ArgumentError
```

NOTE: 定義は[`active_support/core_ext/object/inclusion.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/inclusion.rb)にあります。

[Object#in?]: https://api.rubyonrails.org/classes/Object.html#method-i-in-3F

`Module`の拡張
----------------------

### 属性

#### `alias_attribute`

モデルの属性には、リーダー (reader)、ライター (writer)、述語 (predicate) があります。[`alias_attribute`][Module#alias_attribute]を使うと、これらに対応する3つのメソッドを持つ、モデルの属性のエイリアス (alias) を一度に作成できます。他のエイリアス作成メソッドと同様、1つ目の引数には新しい名前、2つ目の引数には元の名前を指定します (変数に代入するときと同じ順序、と覚えておく手もあります)。

```ruby
class User < ApplicationRecord
  # emailカラムを"login"という名前でも参照したい
  # そうすることで認証のコードがわかりやすくなる
  alias_attribute :login, :email
end
```

NOTE: 定義は[`active_support/core_ext/module/aliasing.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/aliasing.rb)にあります。

[Module#alias_attribute]: https://api.rubyonrails.org/classes/Module.html#method-i-alias_attribute

#### 内部属性

あるクラスで属性を定義すると、後でそのクラスのサブクラスが作成されるときに名前が衝突するリスクが生じます。これはライブラリにおいては特に重要な問題です。

Active Supportでは、[`attr_internal_reader`][Module#attr_internal_reader]、[`attr_internal_writer`][Module#attr_internal_writer]、[`attr_internal_accessor`][Module#attr_internal_accessor]というマクロが定義されています。これらのマクロは、Rubyにビルトインされている`attr_*`と同様に振る舞いますが、内部のインスタンス変数名が衝突しにくいように配慮される点が異なります。

[`attr_internal`][Module#attr_internal]マクロは`attr_internal_accessor`と同義です。

```ruby
# ライブラリ
class ThirdPartyLibrary::Crawler
  attr_internal :log_level
end

# クライアントコード
class MyCrawler < ThirdPartyLibrary::Crawler
  attr_accessor :log_level
end
```

先の例では、`:log_level`はライブラリのパブリックインターフェイスに属さず、開発中以外は使われません。クライアント側のコードでは衝突の可能性について考慮せずに独自に`:log_level`をサブクラスで定義しています。ライブラリ側で`attr_internal`を使っているおかげで衝突が生じずに済んでいます。

このとき、内部インスタンス変数の名前にはデフォルトで冒頭にアンダースコアが追加されます。上の例であれば`@_log_level`となります。この動作は`Module.attr_internal_naming_format`で変更することもできます。`sprintf`と同様のフォーマット文字列を与え、冒頭に`@`を置き、それ以外の名前を置きたい場所に`%s`を置きます。デフォルト値は`"@_%s"`です。

Railsではこの内部属性を他の場所でも若干使っています。たとえばビューでは以下のように使われています。

```ruby
module ActionView
  class Base
    attr_internal :captures
    attr_internal :request, :layout
    attr_internal :controller, :template
  end
end
```

NOTE: 定義は[`active_support/core_ext/module/attr_internal.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/attr_internal.rb)にあります。

[Module#attr_internal]: https://api.rubyonrails.org/classes/Module.html#method-i-attr_internal
[Module#attr_internal_accessor]: https://api.rubyonrails.org/classes/Module.html#method-i-attr_internal_accessor
[Module#attr_internal_reader]: https://api.rubyonrails.org/classes/Module.html#method-i-attr_internal_reader
[Module#attr_internal_writer]: https://api.rubyonrails.org/classes/Module.html#method-i-attr_internal_writer

#### モジュール属性

[`mattr_reader`][Module#mattr_reader]、[`mattr_writer`][Module#mattr_writer]、[`mattr_accessor`][Module#mattr_accessor]という3つのマクロは、クラス用に定義される`cattr_*`マクロと同じです。実際、`cattr_*`マクロは単なる`mattr_*`マクロのエイリアスです。[クラス属性](#class属性)も参照してください。

たとえば、これらのマクロは以下のDependenciesモジュールで使われています。

```ruby
module ActiveStorage
  mattr_accessor :logger
end
```

NOTE: 定義は[`active_support/core_ext/module/attribute_accessors.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/attribute_accessors.rb)にあります。

[Module#mattr_accessor]: https://api.rubyonrails.org/classes/Module.html#method-i-mattr_accessor
[Module#mattr_reader]: https://api.rubyonrails.org/classes/Module.html#method-i-mattr_reader
[Module#mattr_writer]: https://api.rubyonrails.org/classes/Module.html#method-i-mattr_writer

### 親

#### `module_parent`

[`module_parent`][Module#module_parent]メソッドは、名前がネストしたモジュールに対して実行でき、対応する定数を持つモジュールを返します。

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parent # => X::Y
M.module_parent       # => X::Y
```

モジュールが無名またはトップレベルの場合、`module_parent`は`Object`を返します。

WARNING: `module_parent_name`はこの場合に`nil`を返します。

NOTE: 定義は[`active_support/core_ext/module/introspection.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/introspection.rb)にあります。

[Module#module_parent]: https://api.rubyonrails.org/classes/Module.html#method-i-module_parent

#### `module_parent_name`

名前がネストしたモジュールに対して[`module_parent_name`][Module#module_parent_name]メソッドを実行すると、対応する定数を持つモジュールの完全修飾名を返します。

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parent_name # => "X::Y"
M.module_parent_name       # => "X::Y"
```

モジュールが無名またはトップレベルの場合、`module_parent_name`は`nil`を返します。

WARNING: `module_parent`はこの場合`Object`を返します。

NOTE: 定義は[`active_support/core_ext/module/introspection.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/introspection.rb)にあります。

[Module#module_parent_name]: https://api.rubyonrails.org/classes/Module.html#method-i-module_parent_name

#### `module_parents`

[`module_parents`][Module#module_parents]メソッドは、レシーバで`module_parent`を呼び出し、`Object`に到達するまでパスをさかのぼります。連鎖したモジュールは、階層の下から上の順に配列として返されます。

```ruby
module X
  module Y
    module Z
    end
  end
end
M = X::Y::Z

X::Y::Z.module_parents # => [X::Y, X, Object]
M.module_parents       # => [X::Y, X, Object]
```

NOTE: 定義は[`active_support/core_ext/module/introspection.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/introspection.rb)にあります。

[Module#module_parents]: https://api.rubyonrails.org/classes/Module.html#method-i-module_parents

### 無名モジュール

モジュールには名前がある場合とない場合があります。

```ruby
module M
end
M.name # => "M"

N = Module.new
N.name # => "N"

Module.new.name # => nil
```

モジュールに名前があるかどうかを述語メソッド[`anonymous?`][Module#anonymous?]でチェックできます。

```ruby
module M
end
M.anonymous? # => false

Module.new.anonymous? # => true
```

到達不能な（unreachable）モジュールが必ずしも無名（anonymous）とは限りません。

```ruby
module M
end

m = Object.send(:remove_const, :M)

m.anonymous? # => false
```

逆に無名モジュールは、定義上必ず到達不能になります。

NOTE: 定義は[`active_support/core_ext/module/anonymous.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/anonymous.rb)にあります。

[Module#anonymous?]: https://api.rubyonrails.org/classes/Module.html#method-i-anonymous-3F

### メソッドの委譲

#### `delegate`

[`delegate`][Module#delegate]マクロを使って、メソッドを簡単に委譲できます。

あるアプリケーションの`User`モデルにログイン情報があり、それに関連する名前などの情報は`Profile`モデルにあるとします。

```ruby
class User < ApplicationRecord
  has_one :profile
end
```

この構成では、`user.profile.name`のようにプロファイル越しにユーザー名を取得することになります。以下のようにこれらの属性に直接アクセスできたらもっと便利になるでしょう。

```ruby
class User < ApplicationRecord
  has_one :profile

  def name
    profile.name
  end
end
```

これは`delegate`でできます。

```ruby
class User < ApplicationRecord
  has_one :profile

  delegate :name, to: :profile
end
```

この方法なら記述が短くて済み、意味も明快です。

委譲するメソッドは対象クラス内でpublicでなければなりません。

`delegate`マクロには複数のメソッドを指定できます。

```ruby
delegate :name, :age, :address, :twitter, to: :profile
```

`:to`オプションが文字列に変換されると、メソッドの委譲先となるオブジェクトに評価される式になります。通常は文字列またはシンボルになります。そのような式は、レシーバのコンテキストで評価されます。

```ruby
# Rails定数を委譲する
delegate :logger, to: :Rails

# レシーバのクラスに委譲する
delegate :table_name, to: :class
```

WARNING: `:prefix`オプションが`true`の場合、一般性が低下します (以下を参照)。

委譲時に`NoMethodError`が発生して対象が`nil`の場合、`NoMethodError`が伝搬します。`:allow_nil`オプションを使うと、例外の代わりに`nil`を返すようにできます。

```ruby
delegate :name, to: :profile, allow_nil: true
```

`:allow_nil`を指定すると、ユーザーのプロファイルがない場合に`user.name`呼び出しは`nil`を返します。

`:prefix`オプションを`true`にすると、生成されたメソッドの名前にプレフィックスを追加します。これは、たとえばよりよい名前を取得したい場合に便利です。

```ruby
delegate :street, to: :address, prefix: true
```

上の例では、`street`ではなく`address_street`が生成されます。

WARNING: この場合、生成されるメソッドの名前では、対象となるオブジェクト名とメソッド名が使われます。`:to`オプションで指定するのはメソッド名でなければなりません。

プレフィックスをカスタマイズすることもできます。

```ruby
delegate :size, to: :attachment, prefix: :avatar
```

上の例では、マクロによって`size`の代わりに`avatar_size`が生成されます。

`:private`オプションはメソッドのスコープを変更します。

```ruby
delegate :date_of_birth, to: :profile, private: true
```

委譲されたメソッドはデフォルトでpublicになりますが、`private: true`を渡すことで変更できます。

NOTE: 定義は[`active_support/core_ext/module/delegation.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/delegation.rb)にあります。

[Module#delegate]: https://api.rubyonrails.org/classes/Module.html#method-i-delegate

#### `delegate_missing_to`

`User`オブジェクトにないものを`Profile`にあるものにすべて委譲したいとしましょう。[`delegate_missing_to`][Module#delegate_missing_to]マクロを使えばこれを簡単に実装できます。

```ruby
class User < ApplicationRecord
  has_one :profile

  delegate_missing_to :profile
end
```

オブジェクト内にある呼び出し可能なもの（インスタンス変数、メソッド、定数など）なら何でも対象にできます。対象のうち、publicなメソッドだけが委譲されます。

NOTE: 定義は[`active_support/core_ext/module/delegation.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/delegation.rb)にあります。

[Module#delegate_missing_to]: https://api.rubyonrails.org/classes/Module.html#method-i-delegate_missing_to

### メソッドの再定義

メソッドを`define_method`で再定義する必要があるが、その名前が既にあるかどうかがわからないことがあります。有効な名前が既にあれば警告が表示されます。警告が表示されても大したことはありませんが、邪魔に思えることもあります。

[`redefine_method`][Module#redefine_method]メソッドを使うと、必要に応じて既存のメソッドが削除されるので、このような警告表示を抑制できます。

（`delegate`を使っているなどの理由で）メソッド自身の置き換えを定義する必要がある場合は、[`silence_redefinition_of_method`][Module#silence_redefinition_of_method]を使うこともできます。

NOTE: 定義は[`active_support/core_ext/module/redefine_method.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/module/redefine_method.rb)にあります。

[Module#redefine_method]: https://api.rubyonrails.org/classes/Module.html#method-i-redefine_method
[Module#silence_redefinition_of_method]: https://api.rubyonrails.org/classes/Module.html#method-i-silence_redefinition_of_method

`Class`の拡張
---------------------

### Class属性

#### `class_attribute`

[`class_attribute`][Class#class_attribute]メソッドは、1つ以上の継承可能なクラスの属性を宣言します。そのクラス属性は、その下のどの階層でも上書き可能です。

```ruby
class A
  class_attribute :x
end

class B < A; end

class C < B; end

A.x = :a
B.x # => :a
C.x # => :a

B.x = :b
A.x # => :a
C.x # => :b

C.x = :c
A.x # => :a
B.x # => :b
```

たとえば、`ActionMailer::Base`に以下の定義があるとします。

```ruby
class_attribute :default_params
self.default_params = {
  mime_version: "1.0",
  charset: "UTF-8",
  content_type: "text/plain",
  parts_order: [ "text/plain", "text/enriched", "text/html" ]
}.freeze
```

これらの属性はインスタンスのレベルでアクセスまたはオーバーライドできます。

```ruby
A.x = 1

a1 = A.new
a2 = A.new
a2.x = 2

a1.x # => 1 (Aが使われる)
a2.x # => 2 (a2でオーバーライドされる)
```

`:instance_writer`を`false`に設定すれば、writerインスタンスメソッドは生成されません。

```ruby
module ActiveRecord
  class Base
    class_attribute :table_name_prefix, instance_writer: false, default: "my"
  end
end
```

上のオプションは、モデルの属性設定時にマスアサインメントを防止するのに便利です。

`:instance_reader`を`false`に設定すれば、インスタンスのreaderメソッドは生成されません。

```ruby
class A
  class_attribute :x, instance_reader: false
end

A.new.x = 1
A.new.x # NoMethodError
```

利便性のために、`class_attribute`は、インスタンスのreaderが返すものを「二重否定」するインスタンス述語メソッドも定義します。上の例の場合、`x?`となります。

`:instance_reader`が`false`の場合、インスタンス述語はreaderメソッドと同様に`NoMethodError`を返します。

インスタンス述語が不要な場合、`instance_predicate: false`を指定すれば定義されなくなります。

NOTE: 定義は[`active_support/core_ext/class/attribute.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/class/attribute.rb)にあります。

[Class#class_attribute]: https://api.rubyonrails.org/classes/Class.html#method-i-class_attribute

#### `cattr_reader`、`cattr_writer`、`cattr_accessor`

[`cattr_reader`][Module#cattr_reader]、[`cattr_writer`][Module#cattr_writer]、[`cattr_accessor`][Module#cattr_accessor]マクロは、`attr_*`と似ていますが、クラス用である点が異なります。これらのメソッドは、クラス変数を`nil`に設定し (クラス変数が既にある場合を除く)、対応するクラスメソッドを生成してアクセスできるようにします。

```ruby
class MysqlAdapter < AbstractAdapter
  # @@emulate_booleansにアクセスできるクラスメソッドを生成する
  cattr_accessor :emulate_booleans
end
```

同様に、`cattr_*`にブロックを渡して属性にデフォルト値を設定することもできます。

```ruby
class MysqlAdapter < AbstractAdapter
  # @@emulate_booleansにアクセスしてデフォルト値をtrueにするクラスメソッドを生成する
  cattr_accessor :emulate_booleans, default: true
end
```

利便性のため、このときインスタンスメソッドも生成されますが、これらは実際にはクラス属性の単なるプロキシです。このため、インスタンスがクラス属性を変更することは可能ですが、`class_attribute`が行なうのと同じように上書きすることはできません(上記参照)。たとえば以下の場合、

```ruby
module ActionView
  class Base
    cattr_accessor :field_error_proc, default: Proc.new {
      # ...
    }
  end
end
```

ビューで`field_error_proc`にアクセスできます。

`:instance_reader`オプションを`false`に設定することで、readerインスタンスメソッドが生成されないようにできます。同様に、`:instance_writer`オプションを`false`に設定することで、writerインスタンスメソッドが生成されないようにできます。`:instance_accessor`オプションを`false`に設定すれば、どちらのインスタンスメソッドも生成されません。いずれの場合も、指定できる値は`false`のみです。'nil'など他のfalse値は指定できません。

```ruby
module A
  class B
    # first_nameインスタンスreaderは生成されない
    cattr_accessor :first_name, instance_reader: false
    # last_name= インスタンスwriterは生成されない
    cattr_accessor :last_name, instance_writer: false
    # surnameインスタンスreaderもsurname= インスタンスwriterも生成されない
    cattr_accessor :surname, instance_accessor: false
  end
end
```

`:instance_accessor`を`false`に設定すると、モデルの属性設定時にマスアサインメントを防止するのに便利です。

NOTE: 定義は[`active_support/core_ext/module/attribute_accessors.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/class/attribute_accessors.rb)にあります。

[Module#cattr_accessor]: https://api.rubyonrails.org/classes/Module.html#method-i-cattr_accessor
[Module#cattr_reader]: https://api.rubyonrails.org/classes/Module.html#method-i-cattr_reader
[Module#cattr_writer]: https://api.rubyonrails.org/classes/Module.html#method-i-cattr_writer

### サブクラスと子孫

#### `subclasses`

[`subclasses`][Class#subclasses]メソッドはレシーバのサブクラスを返します。

```ruby
class C; end
C.subclasses # => []

class B < C; end
C.subclasses # => [B]

class A < B; end
C.subclasses # => [B]

class D < C; end
C.subclasses # => [B, D]
```

返されるクラスの順序は一定ではありません。

NOTE: 定義は[`active_support/core_ext/class/subclasses.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/class/subclasses.rb)にあります。

[Class#subclasses]: https://api.rubyonrails.org/classes/Class.html#method-i-subclasses

#### `descendants`

[`descendants`][Class#descendants]メソッドは、そのレシーバより下位にあるすべてのクラスを返します。

```ruby
class C; end
C.descendants # => []

class B < C; end
C.descendants # => [B]

class A < B; end
C.descendants # => [B, A]

class D < C; end
C.descendants # => [B, A, D]
```

返されるクラスの順序は一定ではありません。

NOTE: 定義は[`active_support/core_ext/class/subclasses.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/class/subclasses.rb)にあります。

[Class#descendants]: https://api.rubyonrails.org/classes/Class.html#method-i-descendants

`String`の拡張
----------------------

### 安全な出力

#### 開発の動機

HTMLテンプレートにデータを挿入する方法は、きわめて慎重に設計する必要があります。たとえば、`@review.title`を何の工夫もなくそのままHTMLに式展開するようなことは絶対にすべきではありません。もしこのレビューのタイトルが仮に「Flanagan & Matz rules!」だとしたら、出力はwell-formedになりません。well-formedにするには、`&`->`&amp;`のようにエスケープしなければなりません。さらに、ユーザーがレビューのタイトルに細工をして、悪意のあるHTMLをタイトルに含めれば、巨大なセキュリティホールになる可能性すらあります。このリスクの詳細については、[セキュリティガイド](security.html#クロスサイトスクリプティング（xss）)のクロスサイトスクリプティングの節を参照してください。

#### 安全な文字列

Active Supportには「**(html的に) 安全な文字列**」という概念があります。安全な文字列とは、HTMLにそのまま挿入しても問題がないというマークが付けられている文字列です。マーキングさえされていれば、「実際にエスケープされているかどうかにかかわらず」その文字列は信頼されます。

文字列はデフォルトでは「unsafe」とマークされます。

```ruby
"".html_safe? # => false
```

与えられた文字列に[`html_safe`][String#html_safe]メソッドを適用することで、安全な文字列を得られます。

```ruby
s = "".html_safe
s.html_safe? # => true
```

ここで注意しなければならないのは、`html_safe`メソッドそれ自体は何らエスケープを行なっていないということです。安全であるとマーキングしているに過ぎません。

```ruby
s = "<script>...</script>".html_safe
s.html_safe? # => true
s            # => "<script>...</script>"
```

すなわち、特定の文字列に対して`html_safe`メソッドを呼び出す際には、その文字列が本当に安全であることを確認する義務があります。

安全であると宣言された文字列に対し、安全でない文字列を`concat`/`<<`や`+`で破壊的に追加すると、結果は安全な文字列になります。安全でない引数は追加時にエスケープされます。

```ruby
"".html_safe + "<" # => "&lt;"
```

安全な引数であれば、(エスケープなしで)直接追加されます。

```ruby
"".html_safe + "<".html_safe # => "<"
```

基本的にこれらのメソッドは、通常のビューでは使わないでください。現在のRailsのビューでは、安全でない値は自動的にエスケープされるためです。

```erb
<%= @review.title %> <%# 必要に応じてエスケープされるので問題なし %>
```

何らかの理由で、エスケープされていない文字列をそのままの形で挿入したい場合は、`html_safe`を呼ぶのではなく、[`raw`][]ヘルパーをお使いください。

```erb
<%= raw @cms.current_template %> <%# @cms.current_templateをそのまま挿入 %>
```

あるいは、`raw`と同等の`<%==`を使います。

```erb
<%== @cms.current_template %> <%# @cms.current_templateをそのまま挿入 %>
```

`raw`ヘルパーは、内部で`html_safe`を呼び出します。

```ruby
def raw(stringish)
  stringish.to_s.html_safe
end
```

NOTE: 定義は[`active_support/core_ext/string/output_safety.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/output_safety.rb)にあります。

[`raw`]: https://api.rubyonrails.org/classes/ActionView/Helpers/OutputSafetyHelper.html#method-i-raw
[String#html_safe]: https://api.rubyonrails.org/classes/String.html#method-i-html_safe

#### 各種変換

経験上、上で説明したような連結 (concatenation) 操作を除き、どんなメソッドでも潜在的には文字列を安全でないものに変換してしまう可能性があることに常に注意を払う必要があります。`downcase`、`gsub`、`strip`、`chomp`、`underscore`などの変換メソッドがこれに該当します。

`gsub!`のような破壊的な変換を行なうメソッドを使うと、レシーバ自体が安全でなくなってしまいます。

INFO: こうしたメソッドを実行すると、実際に変換が行われたかどうかにかかわらず、安全を表すビットは常にオフになります。

#### 変換と強制

安全な文字列に対して`to_s`を実行した場合は、安全な文字列を返します。しかし、`to_str`による強制変換を実行した場合には安全でない文字列を返します。

#### コピー

安全な文字列に対して`dup`または`clone`を実行した場合は、安全な文字列が生成されます。

### `remove`

[`remove`][String#remove]メソッドを実行すると、すべての該当パターンが削除されます。

```ruby
"Hello World".remove(/Hello /) # => "World"
```

このメソッドには破壊的なバージョンの`String#remove!`もあります。

NOTE: 定義は[`active_support/core_ext/string/filters.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/filters.rb)にあります。

[String#remove]: https://api.rubyonrails.org/classes/String.html#method-i-remove

### `squish`

[`squish`][String#squish]メソッドは、冒頭と末尾のホワイトスペースを除去し、連続したホワイトスペースを1つに減らします。

```ruby
" \n  foo\n\r \t bar \n".squish # => "foo bar"
```

このメソッドには破壊的なバージョンの`String#squish!`もあります。

このメソッドでは、ASCIIとUnicodeのホワイトスペースを扱えます。

NOTE: 定義は[`active_support/core_ext/string/filters.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/filters.rb)にあります。

[String#squish]: https://api.rubyonrails.org/classes/String.html#method-i-squish

### `truncate`

[`truncate`][String#truncate]メソッドは、指定された`length`にまで長さを切り詰めたレシーバのコピーを返します。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20)
# => "Oh dear! Oh dear!..."
```

`:omission`オプションを指定することで、省略文字 (...) をカスタマイズすることもできます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(20, omission: '&hellip;')
# => "Oh dear! Oh &hellip;"
```

特に、省略文字列の長さも含めた長さに切り詰められることにご注意ください。

`:separator`を指定することで、自然な区切り位置で切り詰めできます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18)
# => "Oh dear! Oh dea..."
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: ' ')
# => "Oh dear! Oh..."
```

`:separator`オプションでは正規表現も使えます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate(18, separator: /\s/)
# => "Oh dear! Oh..."
```

上の例では、"dear"という単語の途中で切り落とされそうになるところを、`:separator`によって防いでいます。

NOTE: 定義は[`active_support/core_ext/string/filters.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/filters.rb)にあります。

[String#truncate]: https://api.rubyonrails.org/classes/String.html#method-i-truncate

### `truncate_bytes`

[`truncate_bytes`][String#truncate_bytes]メソッドは、最大で`bytesize`バイトに切り詰められたレシーバーのコピーを返します。


```ruby
"👍👍👍👍".truncate_bytes(15)
# => "👍👍👍…"
```

`:omission`オプションを指定することで、省略文字 (...) をカスタマイズすることもできます。

```ruby
"👍👍👍👍".truncate_bytes(15, omission: "🖖")
# => "👍👍🖖"
```

NOTE: 定義は[`active_support/core_ext/string/filters.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/filters.rb)にあります。

[String#truncate_bytes]: https://api.rubyonrails.org/classes/String.html#method-i-truncate_bytes

### `truncate_words`

[`truncate_words`][String#truncate_words]メソッドは、指定されたワード数から後ろを切り落としたレシーバのコピーを返します。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4)
# => "Oh dear! Oh dear!..."
```

`:omission`オプションを指定することで、省略文字 (...) をカスタマイズすることもできます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, omission: '&hellip;')
# => "Oh dear! Oh dear!&hellip;"
```

`:separator`を指定することで、自然な区切り位置で切り詰めできます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(3, separator: '!')
# => "Oh dear! Oh dear! I shall be late..."
```

`:separator`オプションでは正規表現も使えます。

```ruby
"Oh dear! Oh dear! I shall be late!".truncate_words(4, separator: /\s/)
# => "Oh dear! Oh dear!..."
```

NOTE: 定義は[`active_support/core_ext/string/filters.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/filters.rb)にあります。

[String#truncate_words]: https://api.rubyonrails.org/classes/String.html#method-i-truncate_word

### `inquiry`

[`inquiry`][String#inquiry]は、文字列を`StringInquirer`オブジェクトに変換します。このオブジェクトを使うと、等しいかどうかをよりスマートにチェックできます。

```ruby
"production".inquiry.production? # => true
"active".inquiry.inactive?       # => false
```

NOTE: 定義は[`active_support/core_ext/string/inquiry.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inquiry.rb)にあります。

[String#inquiry]: https://api.rubyonrails.org/classes/String.html#method-i-inquiry

### `starts_with?`と`ends_with?`

Active Supportでは、`String#start_with?`と`String#end_with?`を英語的に自然な三人称（starts、ends）にしたエイリアスも定義されています。

```ruby
"foo".starts_with?("f") # => true
"foo".ends_with?("o")   # => true
```

NOTE: 定義は[`active_support/core_ext/string/starts_ends_with.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/starts_ends_with.rb)にあります。

### `strip_heredoc`

[`strip_heredoc`][String#strip_heredoc]メソッドは、ヒアドキュメントのインデントを除去します。

以下に例を示します。

```ruby
if options[:usage]
  puts <<-USAGE.strip_heredoc
    This command does such and such.

    Supported options are:
      -h         This message
      ...
  USAGE
end
```

このUSAGEメッセージは左寄せで表示されます。

技術的には、インデントが最も浅い行を探して、そのインデント分だけ行頭のホワイトスペースを全体から削除するという操作を行っています。

NOTE: 定義は[`active_support/core_ext/string/strip.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/strip.rb)にあります。

[String#strip_heredoc]: https://api.rubyonrails.org/classes/String.html#method-i-strip_heredoc

### `indent`

[`indent`][String#indent]メソッドは、レシーバの行にインデントを追加します。

```ruby
<<EOS.indent(2)
def some_method
  some_code
end
EOS
# =>
  def some_method
    some_code
  end
```

2つめの引数`indent_string`は、インデントに使う文字列を指定します。デフォルトは`nil`であり、この場合最初にインデントされている行のインデント文字を参照してそこからインデント文字を推測します。インデントがまったくない場合はスペース1つを使います。

```ruby
"  foo".indent(2)        # => "    foo"
"foo\n\t\tbar".indent(2) # => "\t\tfoo\n\t\t\t\tbar"
"foo".indent(2, "\t")    # => "\t\tfoo"
```

`indent_string`には1文字のスペースまたはタブを使うのが普通ですが、どんな文字列でも使えます。

3つ目の引数`indent_empty_lines`は、空行もインデントするかどうかを指定するフラグです。デフォルトは`false`です。

```ruby
"foo\n\nbar".indent(2)            # => "  foo\n\n  bar"
"foo\n\nbar".indent(2, nil, true) # => "  foo\n  \n  bar"
```

[`indent!`][String#indent!]メソッドはインデントをその場で (破壊的に) 行います。

NOTE: 定義は[`active_support/core_ext/string/indent.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/indent.rb)にあります。

[String#indent!]: https://api.rubyonrails.org/classes/String.html#method-i-indent-21
[String#indent]: https://api.rubyonrails.org/classes/String.html#method-i-indent

### アクセス

#### `at(position)`

[`at`][String#at]メソッドは、対象となる文字列のうち、`position`で指定された位置にある文字を返します。

```ruby
"hello".at(0)  # => "h"
"hello".at(4)  # => "o"
"hello".at(-1) # => "o"
"hello".at(10) # => nil
```

NOTE: 定義は[`active_support/core_ext/string/access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/access.rb)にあります。

[String#at]: https://api.rubyonrails.org/classes/String.html#method-i-at

#### `from(position)`

[`from`][String#from]メソッドは、文字列のうち、`position`で指定された位置から始まる部分文字列を返します。

```ruby
"hello".from(0)  # => "hello"
"hello".from(2)  # => "llo"
"hello".from(-2) # => "lo"
"hello".from(10) # => nil
```

NOTE: 定義は[`active_support/core_ext/string/access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/access.rb)にあります。

[String#from]: https://api.rubyonrails.org/classes/String.html#method-i-from

#### `to(position)`

[`to`][String#to]メソッドは、文字列のうち、`position`で指定された位置を終端とする部分文字列を返します。

```ruby
"hello".to(0)  # => "h"
"hello".to(2)  # => "hel"
"hello".to(-2) # => "hell"
"hello".to(10) # => "hello"
```

NOTE: 定義は[`active_support/core_ext/string/access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/access.rb)にあります。

[String#to]: https://api.rubyonrails.org/classes/String.html#method-i-to

#### `first(limit = 1)`

[`first`][String#first]メソッドは、文字列冒頭から`limit`文字分の部分文字列を返します。

`str.first(n)`という呼び出しは、`n` > 0の場合は`str.to(n-1)`と等価です。`n` == 0の場合は空文字列を返します。

NOTE: 定義は[`active_support/core_ext/string/access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/access.rb)にあります。

[String#first]: https://api.rubyonrails.org/classes/String.html#method-i-first

#### `last(limit = 1)`

[`last`][String#last]メソッドは、文字列末尾から`limit`文字分の部分文字列を返します。

`str.last(n)` という呼び出しは、`n` > 0の場合は`str.from(-n)`と等価です。`n` == 0の場合は空文字列を返します。

NOTE: 定義は[`active_support/core_ext/string/access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/access.rb)にあります。

[String#last]: https://api.rubyonrails.org/classes/String.html#method-i-last

### 活用形

#### `pluralize`

[`pluralize`][String#pluralize]メソッドは、レシーバを「複数形」にしたものを返します。

```ruby
"table".pluralize     # => "tables"
"ruby".pluralize      # => "rubies"
"equipment".pluralize # => "equipment"
```

上の例でも示したように、Active Supportは不規則な複数形や非可算名詞をある程度扱えます。`config/initializers/inflections.rb`にあるビルトインのルールは拡張可能です。このファイルは`rails new`コマンド実行時にデフォルトで生成され、ファイルのコメントに説明が示されています。

`pluralize`メソッドではオプションで`count`パラメータを使えます。`count == 1`を指定すると単数形を返します。`count`がそれ以外の値の場合は複数形を返します（訳注: 英語では個数がゼロや小数や負の数の場合は複数形で表されます）。

```ruby
"dude".pluralize(0) # => "dudes"
"dude".pluralize(1) # => "dude"
"dude".pluralize(2) # => "dudes"
```

Active Recordでは、モデル名に対応するデフォルトのテーブル名を求めるときにこのメソッドを使います。

```ruby
# active_record/model_schema.rb
def undecorated_table_name(model_name)
  table_name = model_name.to_s.demodulize.underscore
  pluralize_table_names ? table_name.pluralize : table_name
end
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#pluralize]: https://api.rubyonrails.org/classes/String.html#method-i-pluralize

#### `singularize`

[`singularize`][String#singularize]メソッドの動作は`pluralize`と逆で、レシーバを「単数形」にしたものを返します。

```ruby
"tables".singularize    # => "table"
"rubies".singularize    # => "ruby"
"equipment".singularize # => "equipment"
```

Railsの関連付け (association) では、関連付けられたクラスにデフォルトで対応する名前を求める時にこのメソッドを使います。

```ruby
# active_record/reflection.rb
def derive_class_name
  class_name = name.to_s.camelize
  class_name = class_name.singularize if collection?
  class_name
end
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#singularize]: https://api.rubyonrails.org/classes/String.html#method-i-singularize

#### `camelize`

[`camelize`][String#camelize]メソッドは、レシーバをキャメルケース (冒頭を大文字にした単語をスペースなしで連結した語) にしたものを返します。

```ruby
"product".camelize    # => "Product"
"admin_user".camelize # => "AdminUser"
```

このメソッドは、パスをRubyのクラスに変換するときにもよく使われます。スラッシュで区切られているパスは「::」で区切られます。

```ruby
"backoffice/session".camelize # => "Backoffice::Session"
```

たとえばAction Packでは、特定のセッションストアを提供するクラスを読み込むのにこのメソッドを使います。

```ruby
# action_controller/metal/session_management.rb
def session_store=(store)
  @@session_store = store.is_a?(Symbol) ?
    ActionDispatch::Session.const_get(store.to_s.camelize) :
    store
end
```

`camelize`メソッドはオプションの引数を受け付けます。`:upper`（デフォルト）または`:lower`を指定できます。後者を指定すると、冒頭が小文字になります。

```ruby
"visual_effect".camelize(:lower) # => "visualEffect"
```

このメソッドは、そのような命名規約に沿う言語（JavaScriptなど）で使う名前を求めるのに便利です。

INFO: `camelize`メソッドの動作は、`underscore`メソッドと逆の動作と考えるとわかりやすいでしょう。ただし完全に逆の動作ではありません。たとえば、`"SSLError".underscore.camelize`を実行した結果は`"SslError"`になり、元に戻りません。このような場合をサポートするために、Active Supportでは`config/initializers/inflections.rb`の頭字語（acronym）を次のように指定できます。

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'SSL'
end

"SSLError".underscore.camelize # => "SSLError"
```

[`camelcase`][String#camelcase]は`camelize`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#camelcase]: https://api.rubyonrails.org/classes/String.html#method-i-camelcase
[String#camelize]: https://api.rubyonrails.org/classes/String.html#method-i-camelize

#### `underscore`

[`underscore`][String#underscore]メソッドは上と逆に、キャメルケースをパスに変換します。

```ruby
"Product".underscore   # => "product"
"AdminUser".underscore # => "admin_user"
```

"::"も"/"に逆変換されます。

```ruby
"Backoffice::Session".underscore # => "backoffice/session"
```

小文字で始まる文字列も扱えます。

```ruby
"visualEffect".underscore # => "visual_effect"
```

ただし`underscore`は引数を取りません。

Railsでは、コントローラのクラス名を小文字化するのに`underscore`を使っています。


```ruby
# actionpack/lib/abstract_controller/base.rb
def controller_path
  @controller_path ||= name.delete_suffix("Controller").underscore
end
```

たとえば、上の値は`params[:controller]`で取得できます。

INFO: `underscore`メソッドの動作は、`camelize`メソッドと逆の動作と考えるとわかりやすいでしょう。ただし完全に逆の動作ではありません。たとえば、`"SSLError".underscore.camelize`を実行した結果は`"SslError"`になり、元に戻りません。

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#underscore]: https://api.rubyonrails.org/classes/String.html#method-i-underscore

#### `titleize`

[`titleize`][String#titleize]メソッドは、レシーバの語の1文字目を大文字にします。

```ruby
"alice in wonderland".titleize # => "Alice In Wonderland"
"fermat's enigma".titleize     # => "Fermat's Enigma"
```

[`titlecase`][String#titlecase]メソッドは`titleize`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#titlecase]: https://api.rubyonrails.org/classes/String.html#method-i-titlecase
[String#titleize]: https://api.rubyonrails.org/classes/String.html#method-i-titleize

#### `dasherize`

[`dasherize`][String#dasherize]メソッドは、レシーバのアンダースコア文字をダッシュに置き換えます（訳注: ここで言うダッシュは実際には「ハイフンマイナス文字」(U+002D)です）。

```ruby
"name".dasherize         # => "name"
"contact_data".dasherize # => "contact-data"
```

モデルのXMLシリアライザではノード名をこのメソッドでダッシュ化しています。

```ruby
# active_model/serializers/xml.rb
def reformat_name(name)
  name = name.camelize if camelize?
  dasherize? ? name.dasherize : name
end
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#dasherize]: https://api.rubyonrails.org/classes/String.html#method-i-dasherize

#### `demodulize`

[`demodulize`][String#demodulize]メソッドは、フルパスの (qualified) 定数名を与えられると、パス部分を取り除いて右側の定数名だけにしたものを返します。

```ruby
"Product".demodulize                        # => "Product"
"Backoffice::UsersController".demodulize    # => "UsersController"
"Admin::Hotel::ReservationUtils".demodulize # => "ReservationUtils"
"::Inflections".demodulize                  # => "Inflections"
"".demodulize                               # => ""

```

以下のActive Recordの例では、`counter_cache_column`の名前をこのメソッドで求めています。

```ruby
# active_record/reflection.rb
def counter_cache_column
  if options[:counter_cache] == true
    "#{active_record.name.demodulize.underscore.pluralize}_count"
  elsif options[:counter_cache]
    options[:counter_cache]
  end
end
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#demodulize]: https://api.rubyonrails.org/classes/String.html#method-i-demodulize

#### `deconstantize`

[`deconstantize`][String#deconstantize]メソッドは、フルパスの定数を表す参照表現を与えられると、一番右の部分 (通常は定数名) を取り除きます。

```ruby
"Product".deconstantize                        # => ""
"Backoffice::UsersController".deconstantize    # => "Backoffice"
"Admin::Hotel::ReservationUtils".deconstantize # => "Admin::Hotel"
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#deconstantize]: https://api.rubyonrails.org/classes/String.html#method-i-deconstantize

#### `parameterize`

[`parameterize`][String#parameterize]メソッドは、レシーバをURLで利用可能な形式に正規化します。

```ruby
"John Smith".parameterize # => "john-smith"
"Kurt Gödel".parameterize # => "kurt-godel"
```

文字列の大文字小文字が変わらないようにするには、`preserve_case`引数に`true`を指定します。`preserve_case`はデフォルトでは`false`です。

```ruby
"John Smith".parameterize(preserve_case: true) # => "John-Smith"
"Kurt Gödel".parameterize(preserve_case: true) # => "Kurt-Godel"
```

独自のセパレータ（区切り文字）を使うには、`separator`引数をオーバーライドします。

```ruby
"John Smith".parameterize(separator: "_") # => "john_smith"
"Kurt Gödel".parameterize(separator: "_") # => "kurt_godel"
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#parameterize]: https://api.rubyonrails.org/classes/String.html#method-i-parameterize

#### `tableize`

[`tableize`][String#tableize]メソッドは、`underscore`に続けて`pluralize`を実行したものです。

```ruby
"Person".tableize      # => "people"
"Invoice".tableize     # => "invoices"
"InvoiceLine".tableize # => "invoice_lines"
```

単純な場合であれば、モデル名に`tableize`を使うとモデルのテーブル名を得られます。実際のActive Recordの実装は、単に`tableize`を実行する場合よりも複雑です。Active Recordではクラス名に対して`demodulize`も行っており、返される文字列に影響する可能性のあるオプションもいくつかチェックしています。

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#tableize]: https://api.rubyonrails.org/classes/String.html#method-i-tableize

#### `classify`

[`classify`][String#classify]メソッドは`tableize`と逆の動作で、与えられたテーブル名に対応するクラス名を返します。

```ruby
"people".classify        # => "Person"
"invoices".classify      # => "Invoice"
"invoice_lines".classify # => "InvoiceLine"
```

このメソッドは、フルパスの (qualified) テーブル名も扱えます。

```ruby
"highrise_production.companies".classify # => "Company"
```

`classify`が返すクラス名は文字列であることにご注意ください。得られた文字列に対して`constantize` (後述) を実行することで実際のクラスオブジェクトを得られます。

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#classify]: https://api.rubyonrails.org/classes/String.html#method-i-classify

#### `constantize`

[`constantize`][String#constantize]メソッドは、レシーバの定数参照表現を解決し、実際のオブジェクトを返します。

```ruby
"Fixnum".constantize # => Fixnum

module M
  X = 1
end
"M::X".constantize # => 1
```

与えられた文字列を`constantize`メソッドで評価しても既知の定数とマッチしない、または指定された定数名が無効な場合は`NameError`が発生します。

`constantize`メソッドによる定数名解決は、常にトップレベルの`Object`から開始されます。これは冒頭に「::」がない場合でも同じです。

```ruby
X = :in_Object
module M
  X = :in_M

  X                 # => :in_M
  "::X".constantize # => :in_Object
  "X".constantize   # => :in_Object (!)
end
```

このため、このメソッドは、同じ場所でRubyが定数を評価したときの値と必ずしも等価ではありません。

メーラー (mailer) のテストケースでは、テストするクラスの名前からテスト対象のメーラーを取得するのに`constantize`メソッドを使います。

```ruby
# action_mailer/test_case.rb
def determine_default_mailer(name)
  name.sub(/Test$/, '').constantize
rescue NameError => e
  raise NonInferrableMailerError.new(name)
end
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#constantize]: https://api.rubyonrails.org/classes/String.html#method-i-constantize

#### `humanize`

[`humanize`][String#humanize]メソッドは、属性名を (英語的に) 読みやすい表記に変換します。

具体的には以下の変換を行います。

  * 引数に (英語の) 活用ルールを適用する（inflection）。
  * 冒頭にアンダースコアがある場合は削除する。
  * 末尾に「_id」がある場合は削除する。
  * アンダースコアが他にもある場合はスペースに置き換える。
  * 略語を除いてすべての単語を小文字にする（downcase）。
  * 最初の単語だけ冒頭の文字を大文字にする（capitalize）。

`:capitalize`オプションをfalseにすると、冒頭の文字は大文字にされません（デフォルトは`true`）。

```ruby
"name".humanize                         # => "Name"
"author_id".humanize                    # => "Author"
"author_id".humanize(capitalize: false) # => "author"
"comments_count".humanize               # => "Comments count"
"_id".humanize                          # => "Id"
```

"SSL"が頭字語と定義されている場合は以下のようになります。

```ruby
'ssl_error'.humanize # => "SSL error"
```

ヘルパーメソッド`full_messages`では、属性名をメッセージに含めるときに`humanize`を使います。


```ruby
def full_messages
  map { |attribute, message| full_message(attribute, message) }
end

def full_message
  ...
  attr_name = attribute.to_s.tr('.', '_').humanize
  attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
  ...
end
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#humanize]: https://api.rubyonrails.org/classes/String.html#method-i-humanize

#### `foreign_key`

[`foreign_key`][String#foreign_key]メソッドは、クラス名から外部キーカラム名を求めるのに用いられます。具体的には、`demodulize`、`underscore`を実行し、末尾に「_id」を追加します。

```ruby
"User".foreign_key           # => "user_id"
"InvoiceLine".foreign_key    # => "invoice_line_id"
"Admin::Session".foreign_key # => "session_id"
```

末尾の「_id」のアンダースコアが不要な場合は、引数に`false`を指定します。

```ruby
"User".foreign_key(false) # => "userid"
```

関連付け (association) では、外部キー名を推測するときにこのメソッドを使います。たとえば`has_one`と`has_many`では以下を行っています。

```ruby
# active_record/associations.rb
foreign_key = options[:foreign_key] || reflection.active_record.name.foreign_key
```

NOTE: 定義は[`active_support/core_ext/string/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/inflections.rb)にあります。

[String#foreign_key]: https://api.rubyonrails.org/classes/String.html#method-i-foreign_key

#### `upcase_first`

[`upcase_first`][String#upcase_first]メソッドはレシーバの冒頭の文字を大文字にします。

```ruby
"employee salary".upcase_first # => "Employee salary"
"".upcase_first                # => ""
```

NOTE: 定義は`active_support/core_ext/string/inflections.rb`にあります。

[String#upcase_first]: https://api.rubyonrails.org/classes/String.html#method-i-upcase_first

#### `downcase_first`

The method [`downcase_first`][String#downcase_first] converts the first letter of the receiver to lowercase:

```ruby
"If I had read Alice in Wonderland".downcase_first # => "if I had read Alice in Wonderland"
"".downcase_first                                  # => ""
```

NOTE: Defined in `active_support/core_ext/string/inflections.rb`.

[String#downcase_first]: https://api.rubyonrails.org/classes/String.html#method-i-downcase_first

### 各種変換

#### `to_date`、`to_time`、`to_datetime`

[`to_date`][String#to_date]、[`to_time`][String#to_time]、[`to_datetime`][String#to_datetime]メソッドは、`Date._parse`をラップして使いやすくします。

```ruby
"2010-07-27".to_date              # => Tue, 27 Jul 2010
"2010-07-27 23:37:00".to_time     # => 2010-07-27 23:37:00 +0200
"2010-07-27 23:37:00".to_datetime # => Tue, 27 Jul 2010 23:37:00 +0000
```

`to_time`はオプションで`:utc`や`:local`を引数に取り、タイムゾーンを指定できます。

```ruby
"2010-07-27 23:42:00".to_time(:utc)   # => 2010-07-27 23:42:00 UTC
"2010-07-27 23:42:00".to_time(:local) # => 2010-07-27 23:42:00 +0200
```

デフォルトは`:local`です。

詳しくは`Date._parse`のドキュメントを参照してください。

INFO: 3つのメソッドはいずれも、レシーバが空の場合は`nil`を返します。

NOTE: 定義は[`active_support/core_ext/string/conversions.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/string/conversions.rb)にあります。

[String#to_date]: https://api.rubyonrails.org/classes/String.html#method-i-to_date
[String#to_datetime]: https://api.rubyonrails.org/classes/String.html#method-i-to_datetime
[String#to_time]: https://api.rubyonrails.org/classes/String.html#method-i-to_time

`Numeric`の拡張
-----------------------

### バイト

すべての数値は、以下のメソッドに応答します。

* [`bytes`][Numeric#bytes]
* [`kilobytes`][Numeric#kilobytes]
* [`megabytes`][Numeric#megabytes]
* [`gigabytes`][Numeric#gigabytes]
* [`terabytes`][Numeric#terabytes]
* [`petabytes`][Numeric#petabytes]
* [`exabytes`][Numeric#exabytes]
* [`zettabytes`][Numeric#zettabytes]

これらのメソッドは、対応するバイト数を返すときに1024の倍数を使います。

```ruby
2.kilobytes   # => 2048
3.megabytes   # => 3145728
3.5.gigabytes # => 3758096384.0
-4.exabytes   # => -4611686018427387904
```

これらのメソッドには単数形のエイリアスもあります。

```ruby
1.megabyte # => 1048576
```

NOTE: 定義は[`active_support/core_ext/numeric/bytes.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/numeric/bytes.rb)にあります。

[Numeric#bytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-bytes
[Numeric#exabytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-exabytes
[Numeric#gigabytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-gigabytes
[Numeric#kilobytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-kilobytes
[Numeric#megabytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-megabytes
[Numeric#petabytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-petabytes
[Numeric#terabytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-terabytes
[Numeric#zettabytes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-zettabytes


### Time

以下のメソッドがあります。

* [`seconds`][Numeric#seconds]
* [`minutes`][Numeric#minutes]
* [`hours`][Numeric#hours]
* [`days`][Numeric#days]
* [`weeks`][Numeric#weeks]
* [`fortnights`][Numeric#fortnights]

たとえば`45.minutes + 2.hours + 4.weeks`のように時間の計算や宣言を行なえます。これらの戻り値は、Timeオブジェクトに加算することも、Timeオブジェクトから減算することもできます。

これらのメソッドを[`from_now`][Duration#from_now]や[`ago`][Duration#ago]などと組み合わせることで、以下のように精密に日付を計算できます。

```ruby
# Time.current.advance(months: 1) と等価
1.month.from_now

# Time.current.advance(weeks: 2) と等価
2.weeks.from_now

# Time.current.advance(months: 4, weeks: 5) と等価
(4.months + 5.weeks).from_now
```

WARNING: 上記以外の期間については、`Integer`の`Time`拡張を参照してください。

NOTE: 定義は[`active_support/core_ext/numeric/time.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/numeric/time.rb)にあります。

[Duration#ago]: https://api.rubyonrails.org/classes/ActiveSupport/Duration.html#method-i-ago
[Duration#from_now]: https://api.rubyonrails.org/classes/ActiveSupport/Duration.html#method-i-from_now
[Numeric#days]: https://api.rubyonrails.org/classes/Numeric.html#method-i-days
[Numeric#fortnights]: https://api.rubyonrails.org/classes/Numeric.html#method-i-fortnights
[Numeric#hours]: https://api.rubyonrails.org/classes/Numeric.html#method-i-hours
[Numeric#minutes]: https://api.rubyonrails.org/classes/Numeric.html#method-i-minutes
[Numeric#seconds]: https://api.rubyonrails.org/classes/Numeric.html#method-i-seconds
[Numeric#weeks]: https://api.rubyonrails.org/classes/Numeric.html#method-i-weeks


### 書式設定

数値はさまざまな方法でフォーマットできます。

以下のように、数値を電話番号形式の文字列に変換できます。

```ruby
5551234.to_fs(:phone)
# => 555-1234
1235551234.to_fs(:phone)
# => 123-555-1234
1235551234.to_fs(:phone, area_code: true)
# => (123) 555-1234
1235551234.to_fs(:phone, delimiter: " ")
# => 123 555 1234
1235551234.to_fs(:phone, area_code: true, extension: 555)
# => (123) 555-1234 x 555
1235551234.to_fs(:phone, country_code: 1)
# => +1-123-555-1234
```

以下のように、数値を通貨形式の文字列に変換できます。

```ruby
1234567890.50.to_fs(:currency)                 # => $1,234,567,890.50
1234567890.506.to_fs(:currency)                # => $1,234,567,890.51
1234567890.506.to_fs(:currency, precision: 3)  # => $1,234,567,890.506
```

以下のように、数値をパーセント形式の文字列に変換できます。

```ruby
100.to_fs(:percentage)
# => 100.000%
100.to_fs(:percentage, precision: 0)
# => 100%
1000.to_fs(:percentage, delimiter: '.', separator: ',')
# => 1.000,000%
302.24398923423.to_fs(:percentage, precision: 5)
# => 302.24399%
```

以下のように、数値の桁区切りを追加して文字列形式にできます。

```ruby
12345678.to_fs(:delimited)                     # => 12,345,678
12345678.05.to_fs(:delimited)                  # => 12,345,678.05
12345678.to_fs(:delimited, delimiter: ".")     # => 12.345.678
12345678.to_fs(:delimited, delimiter: ",")     # => 12,345,678
12345678.05.to_fs(:delimited, separator: " ")  # => 12,345,678 05
```

以下のように、数字を特定の精度に丸めて文字列形式にできます。

```ruby
111.2345.to_fs(:rounded)                     # => 111.235
111.2345.to_fs(:rounded, precision: 2)       # => 111.23
13.to_fs(:rounded, precision: 5)             # => 13.00000
389.32314.to_fs(:rounded, precision: 0)      # => 389
111.2345.to_fs(:rounded, significant: true)  # => 111
```

以下のように、数値を人間が読みやすいバイト数形式の文字列に変換できます。

```ruby
123.to_fs(:human_size)                  # => 123 Bytes
1234.to_fs(:human_size)                 # => 1.21 KB
12345.to_fs(:human_size)                # => 12.1 KB
1234567.to_fs(:human_size)              # => 1.18 MB
1234567890.to_fs(:human_size)           # => 1.15 GB
1234567890123.to_fs(:human_size)        # => 1.12 TB
1234567890123456.to_fs(:human_size)     # => 1.1 PB
1234567890123456789.to_fs(:human_size)  # => 1.07 EB
```

以下のように、数値を人間が読みやすいバイト数形式で数詞を単位とする文字列に変換できます。

```ruby
123.to_fs(:human)               # => "123"
1234.to_fs(:human)              # => "1.23 Thousand"
12345.to_fs(:human)             # => "12.3 Thousand"
1234567.to_fs(:human)           # => "1.23 Million"
1234567890.to_fs(:human)        # => "1.23 Billion"
1234567890123.to_fs(:human)     # => "1.23 Trillion"
1234567890123456.to_fs(:human)  # => "1.23 Quadrillion"
```

NOTE: 定義は[`active_support/core_ext/numeric/conversions.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/numeric/conversions.rb)にあります。

`Integer`の拡張
-----------------------

### `multiple_of?`

[`multiple_of?`][Integer#multiple_of?]メソッドは、レシーバの整数が引数の倍数であるかどうかをテストします。

```ruby
2.multiple_of?(1) # => true
1.multiple_of?(2) # => false
```

NOTE: 定義は[`active_support/core_ext/integer/multiple.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/integer/multiple.rb)にあります。

[Integer#multiple_of?]: https://api.rubyonrails.org/classes/Integer.html#method-i-multiple_of-3F

### `ordinal`

[`ordinal`][Integer#ordinal]メソッドは、レシーバの整数に対応する序数のサフィックス文字列を返します。

```ruby
1.ordinal    # => "st"
2.ordinal    # => "nd"
53.ordinal   # => "rd"
2009.ordinal # => "th"
-21.ordinal  # => "st"
-134.ordinal # => "th"
```

NOTE: 定義は[`active_support/core_ext/integer/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/integer/inflections.rb)にあります。

[Integer#ordinal]: https://api.rubyonrails.org/classes/Integer.html#method-i-ordinal

### `ordinalize`

`ordinalize`メソッドは、レシーバの整数に、対応する序数文字列を追加したものをかえします。上の`ordinal`メソッドは、序数文字列**だけ**を返す点が異なることにご注意ください。

```ruby
1.ordinalize    # => "1st"
2.ordinalize    # => "2nd"
53.ordinalize   # => "53rd"
2009.ordinalize # => "2009th"
-21.ordinalize  # => "-21st"
-134.ordinalize # => "-134th"
```

NOTE: 定義は[`active_support/core_ext/integer/inflections.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/integer/inflections.rb)にあります。

[Integer#ordinalize]: https://api.rubyonrails.org/classes/Integer.html#method-i-ordinalize

### Time

以下のメソッドがあります。

* [`months`][Integer#months]
* [`years`][Integer#years]

`4.months + 5.years`のような形式での時間の計算や宣言を行えるようにします。これらの戻り値をTimeオブジェクトに足したりTimeオブジェクトから引いたりすることも可能です。

これらのメソッドを[`from_now`][Duration#from_now]や[`ago`][Duration#ago]などと組み合わせることで、以下のように精密に日付を計算できます。

```ruby
# Time.current.advance(months: 1)と同等
1.month.from_now

# Time.current.advance(years: 2)と同等
2.years.from_now

# Time.current.advance(months: 4, years: 5)と同等
(4.months + 5.years).from_now
```

WARNING: 上記以外の期間については、`Numeric`の`Time`拡張を参照してください。

NOTE: 定義は[`active_support/core_ext/integer/time.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/integer/time.rb)にあります。

[Integer#months]: https://api.rubyonrails.org/classes/Integer.html#method-i-months
[Integer#years]: https://api.rubyonrails.org/classes/Integer.html#method-i-years

`BigDecimal`の拡張
--------------------------

### `to_s`

`to_s`メソッドは「F」のデフォルトの記法を提供します。これは、`to_s`を単に呼び出すと、エンジニアリング記法ではなく浮動小数点を得られるということです。

```ruby
BigDecimal(5.00, 6).to_s       # => "5.0"
```

エンジニアリング記法も従来通りサポートされます。

```ruby
BigDecimal(5.00, 6).to_s("e")  # => "0.5E1"
```

`Enumerable`の拡張
--------------------------

### `index_by`

[`index_by`][Enumerable#index_by]メソッドは、何らかのキーによってインデックス化されたenumerableの要素を持つハッシュを生成します。

このメソッドはコレクションを列挙し、各要素をブロックに渡します。この要素は、ブロックから返された値によってインデックス化されます。

```ruby
invoices.index_by(&:number)
# => {'2009-032' => <Invoice ...>, '2009-008' => <Invoice ...>, ...}
```

WARNING: キーは通常は一意でなければなりません。異なる要素から同じ値が返されると、そのキーのコレクションは作成されません。返された項目のうち、最後の項目だけが使われます。

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。

[Enumerable#index_by]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-index_by

### `index_with`

[`index_with`][Enumerable#index_with]メソッドは、enumerableの要素をキーとして持つハッシュを生成します。値は渡されたデフォルト値か、ブロックで返されます。

```ruby
post = Post.new(title: "hey there", body: "what's up?")

%i( title body ).index_with { |attr_name| post.public_send(attr_name) }
# => { title: "hey there", body: "what's up?" }

WEEKDAYS.index_with(Interval.all_day)
# => { monday: [ 0, 1440 ], … }
```

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。


[Enumerable#index_with]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-index_with

### `many?`

[`many?`][Enumerable#many?]メソッドは、`collection.size > 1`の短縮形です。

```erb
<% if pages.many? %>
  <%= pagination_links %>
<% end %>
```

`many?`は、ブロックがオプションとして与えられると、`true`を返す要素だけを扱います。

```ruby
@see_more = videos.many? { |video| video.category == params[:category] }
```

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。

[Enumerable#many?]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-many-3F

### `exclude?`

`exclude?`述語メソッドは、与えられたオブジェクトがそのコレクションに属して**いない**かどうかをテストします。`include?`の逆の動作です。

```ruby
to_visit << node if visited.exclude?(node)
```

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。

[Enumerable#exclude?]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-exclude-3F

### `including`

[`including`][Enumerable#including]メソッドは、渡された要素を含む新しいenumerableを返します。


```ruby
[ 1, 2, 3 ].including(4, 5)                    # => [ 1, 2, 3, 4, 5 ]
["David", "Rafael"].including %w[ Aaron Todd ] # => ["David", "Rafael", "Aaron", "Todd"]
```

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。

[Enumerable#including]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-including

### `excluding`

[`excluding`][Enumerable#excluding]メソッドは、渡された要素を除いた新しいenumerableのコピーを返します。


```ruby
["David", "Rafael", "Aaron", "Todd"].excluding("Aaron", "Todd") # => ["David", "Rafael"]
```

[`without`][Enumerable#without]は`excluding`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。

[Enumerable#excluding]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-excluding
[Enumerable#without]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-without

### `pluck`

[`pluck`][Enumerable#pluck]メソッドは、指定されたキーに基づく配列を返します。

```ruby
[{ name: "David" }, { name: "Rafael" }, { name: "Aaron" }].pluck(:name) # => ["David", "Rafael", "Aaron"]
```

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。

[Enumerable#pluck]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-pluck

### `pick`

[`pick`][Enumerable#pick]メソッドは、最初の要素から指定のキーで値を取り出します。

```ruby
[{ name: "David" }, { name: "Rafael" }, { name: "Aaron" }].pick(:name) # => "David"
[{ id: 1, name: "David" }, { id: 2, name: "Rafael" }].pick(:id, :name) # => [1, "David"]
```

NOTE: 定義は[`active_support/core_ext/enumerable.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/enumerable.rb)にあります。

[Enumerable#pick]: https://api.rubyonrails.org/classes/Enumerable.html#method-i-pick

`Array`の拡張
---------------------

### 配列へのアクセス

Active Supportには配列のAPIが多数追加されており、配列に容易にアクセスできるようになっています。たとえば[`to`][Array#to]メソッドは、配列の冒頭から、渡されたインデックスが示す箇所までの範囲を返します。

```ruby
%w(a b c d).to(2) # => ["a", "b", "c"]
[].to(7)          # => []
```

同様に[`from`][Array#from]メソッドは、配列のうち、インデックスが指す箇所から末尾までの要素を返します。インデックスが配列のサイズより大きい場合は、空の配列を返します。

```ruby
%w(a b c d).from(2)  # => ["c", "d"]
%w(a b c d).from(10) # => []
[].from(0)           # => []
```

[`including`][Array#including]メソッドは、渡された要素を含む新しい配列を返します。

```ruby
[ 1, 2, 3 ].including(4, 5)          # => [ 1, 2, 3, 4, 5 ]
[ [ 0, 1 ] ].including([ [ 1, 0 ] ]) # => [ [ 0, 1 ], [ 1, 0 ] ]
```

[`excluding`][Array#excluding]メソッドは、渡された要素を除外した新しい配列のコピーを返します。
これは、パフォーマンス上の理由で`Array#reject`の代わりに`Array#-`を用いた`Enumerable#excluding`の最適化です。

```ruby
["David", "Rafael", "Aaron", "Todd"].excluding("Aaron", "Todd") # => ["David", "Rafael"]
[ [ 0, 1 ], [ 1, 0 ] ].excluding([ [ 1, 0 ] ])                  # => [ [ 0, 1 ] ]
```

[`second`][Array#second]、[`third`][Array#third]、[`fourth`][Array#fourth]、[`fifth`][Array#fifth]は、[`second_to_last`][Array#second_to_last]や[`third_to_last`][Array#third_to_last]と同様に、対応する位置の要素を返します (`first`と`last`は元からビルトインされています)。社会の智慧と建設的な姿勢のおかげで、今では[`forty_two`][Array#forty_two]も使えます (訳注: [Rails 2.2 以降](https://github.com/rails/rails/commit/9d8cc60ec3845fa3e6f9292a65b119fe4f619f7e)で使えます。「42」については、Wikipediaの[生命、宇宙、そして万物についての究極の疑問の答え](http://ja.wikipedia.org/wiki/%E7%94%9F%E5%91%BD%E3%80%81%E5%AE%87%E5%AE%99%E3%80%81%E3%81%9D%E3%81%97%E3%81%A6%E4%B8%87%E7%89%A9%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6%E3%81%AE%E7%A9%B6%E6%A5%B5%E3%81%AE%E7%96%91%E5%95%8F%E3%81%AE%E7%AD%94%E3%81%88)を参照してください)。

```ruby
%w(a b c d).third # => "c"
%w(a b c d).fifth # => nil
```

NOTE: 定義は[`active_support/core_ext/array/access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/access.rb)にあります。

[Array#excluding]: https://api.rubyonrails.org/classes/Array.html#method-i-excluding
[Array#fifth]: https://api.rubyonrails.org/classes/Array.html#method-i-fifth
[Array#forty_two]: https://api.rubyonrails.org/classes/Array.html#method-i-forty_two
[Array#fourth]: https://api.rubyonrails.org/classes/Array.html#method-i-fourth
[Array#from]: https://api.rubyonrails.org/classes/Array.html#method-i-from
[Array#including]: https://api.rubyonrails.org/classes/Array.html#method-i-including
[Array#second]: https://api.rubyonrails.org/classes/Array.html#method-i-second
[Array#second_to_last]: https://api.rubyonrails.org/classes/Array.html#method-i-second_to_last
[Array#third]: https://api.rubyonrails.org/classes/Array.html#method-i-third
[Array#third_to_last]: https://api.rubyonrails.org/classes/Array.html#method-i-third_to_last
[Array#to]: https://api.rubyonrails.org/classes/Array.html#method-i-to

### 展開

[`extract!`][Array#extract!]メソッドは、ブロックの返す値が`true`になる要素をレシーバーから削除して、削除した要素を返します。ブロックが渡されない場合はEnumeratorを返します。

```ruby
numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
odd_numbers = numbers.extract! { |number| number.odd? } # => [1, 3, 5, 7, 9]
numbers # => [0, 2, 4, 6, 8]
```

NOTE: 定義は[`active_support/core_ext/array/extract.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/extract.rb)にあります。

[Array#extract!]: https://api.rubyonrails.org/classes/Array.html#method-i-extract-21

### オプションの展開

Rubyでは、メソッドに与えられた最後の引数がハッシュの場合、ハッシュの波かっこ`{}`を省略できます（引数が`&block`引数である場合を除く）。

```ruby
User.exists?(email: params[:email])
```

このようなシンタックスシュガーは、多数の引数が順序に依存することを避け、名前付きパラメータをエミュレートするインターフェイスを提供するためにRailsで多用されています。特に、末尾にオプションのハッシュを置くのは定番中の定番です。

しかし、あるメソッドが受け取る引数の数が固定されておらず、メソッド宣言で`*`が使われていると、そのような波かっこなしのオプションハッシュは引数の配列の末尾要素になってしまい、ハッシュとして認識されなくなってしまいます。

このような場合、[`extract_options!`][Array#extract_options!]メソッドを使うと、配列の末尾項目の型をチェックできます。それがハッシュの場合、そのハッシュを取り出して返し、それ以外の場合は空のハッシュを返します。

`caches_action`コントローラマクロでの定義を例にとって見てみましょう。

```ruby
def caches_action(*actions)
  return unless cache_configured?
  options = actions.extract_options!
  # ...
end
```

このメソッドは、任意の数のアクション名を引数に取ることができ、引数の末尾項目でオプションハッシュを使えます。`extract_options!`メソッドを使うと、このオプションハッシュの取得と`actions`からの除去を簡単かつ明示的に行えます。

NOTE: 定義は[`active_support/core_ext/array/extract_options.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/extract_options.rb)にあります。

[Array#extract_options!]: https://api.rubyonrails.org/classes/Array.html#method-i-extract_options-21

### 各種変換

#### `to_sentence`

[`to_sentence`][Array#to_sentence]メソッドは、配列を変換して、要素を列挙する英文にします。

```ruby
%w().to_sentence                # => ""
%w(Earth).to_sentence           # => "Earth"
%w(Earth Wind).to_sentence      # => "Earth and Wind"
%w(Earth Wind Fire).to_sentence # => "Earth, Wind, and Fire"
```

このメソッドは3つのオプションを受け付けます。

* `:two_words_connector`: 項目数が2つの場合の接続詞を指定します。デフォルトはスペースを含む「` and `」です。
* `:words_connector`: 3つ以上の要素を接続する場合、最後の2つの間以外で使われる接続詞を指定します。デフォルトはスペースを含む「`, `」です。
* `:last_word_connector`: 3つ以上の要素を接続する場合、最後の2つの要素で使われる接続詞を指定します。デフォルトはスペースを含む「`, and `」です。

これらのオプションは標準の方法でローカライズできます。使えるキーは以下のとおりです。

| オプション             | I18n キー                           |
| ---------------------- | ----------------------------------- |
| `:two_words_connector` | `support.array.two_words_connector` |
| `:words_connector`     | `support.array.words_connector`     |
| `:last_word_connector` | `support.array.last_word_connector` |

NOTE: 定義は[`active_support/core_ext/array/conversions.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/conversions.rb)にあります。

[Array#to_sentence]: https://api.rubyonrails.org/classes/Array.html#method-i-to_sentence

#### `to_fs`

[`to_fs`][Array#to_fs]メソッドは、デフォルトでは`to_s`と同様に振る舞います。

ただし、配列の中に`id`に応答する項目がある場合は、`:db`というシンボルを引数として渡すことで対応できる点が異なります。この手法は、Active Recordオブジェクトのコレクションに対してよく使われます。返される文字列は以下のとおりです。

```ruby
[].to_fs(:db)            # => "null"
[user].to_fs(:db)        # => "8456"
invoice.lines.to_fs(:db) # => "23,567,556,12"
```

上の例の整数は、`id`への呼び出しによって取り出されたものとみなされます。

NOTE: 定義は[`active_support/core_ext/array/conversions.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/conversions.rb)にあります。

[Array#to_fs]: https://api.rubyonrails.org/classes/Array.html#method-i-to_fs

#### `to_xml`

[`to_xml`][Array#to_xml]メソッドは、レシーバをXML表現に変換したものを含む文字列を返します。

```ruby
Contributor.limit(2).order(:rank).to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors type="array">
#   <contributor>
#     <id type="integer">4356</id>
#     <name>Jeremy Kemper</name>
#     <rank type="integer">1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id type="integer">4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank type="integer">2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

実際には、`to_xml`をすべての要素に送信し、結果をrootノードの下に集めます。すべての要素が`to_xml`に応答する必要があります。そうでない場合は例外が発生します。

デフォルトでは、root要素の名前は最初の要素のクラス名を複数形にしてアンダースコア化（underscored）とダッシュ化（dasherized）したものになります。残りの要素も最初の要素と同じ型 (`is_a?`でチェックされます) に属し、ハッシュでないことが前提となっています。上の例で言うと「contributors」です。

最初の要素と同じ型に属さない要素が1つでもある場合、rootノードには`objects`が使われます。

```ruby
[Contributor.first, Commit.first].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <id type="integer">4583</id>
#     <name>Aaron Batalion</name>
#     <rank type="integer">53</rank>
#     <url-id>aaron-batalion</url-id>
#   </object>
#   <object>
#     <author>Joshua Peek</author>
#     <authored-timestamp type="datetime">2009-09-02T16:44:36Z</authored-timestamp>
#     <branch>origin/master</branch>
#     <committed-timestamp type="datetime">2009-09-02T16:44:36Z</committed-timestamp>
#     <committer>Joshua Peek</committer>
#     <git-show nil="true"></git-show>
#     <id type="integer">190316</id>
#     <imported-from-svn type="boolean">false</imported-from-svn>
#     <message>Kill AMo observing wrap_with_notifications since ARes was only using it</message>
#     <sha1>723a47bfb3708f968821bc969a9a3fc873a3ed58</sha1>
#   </object>
# </objects>
```

レシーバがハッシュの配列である場合、root要素はデフォルトで`objects`になります。

```ruby
[{ a: 1, b: 2 }, { c: 3 }].to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <objects type="array">
#   <object>
#     <b type="integer">2</b>
#     <a type="integer">1</a>
#   </object>
#   <object>
#     <c type="integer">3</c>
#   </object>
# </objects>
```

WARNING: コレクションが空の場合、root要素はデフォルトで「nilクラス」になります。ここからわかるように、たとえば上の例でのcontributorsのリストのroot要素は、コレクションが空の場合は「contributors」ではなく「nilクラス」になってしまうということです。`:root`オプションを使って、root要素を統一することもできます。

子ノードの名前は、デフォルトではrootノードを単数形にしたものが使われます。上の例で言うと「contributor」や「object」です。`:children`オプションを使うと、これらをノード名として設定できます。

デフォルトのXMLビルダは、`Builder::XmlMarkup`から直接生成されたインスタンスです。`:builder`オブションを使って独自のビルダを構成できます。このメソッドでは`:dasherize`やその同族と同様のオプションが利用でき、指定したオプションはビルダに転送されます。

```ruby
Contributor.limit(2).order(:rank).to_xml(skip_types: true)
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <contributors>
#   <contributor>
#     <id>4356</id>
#     <name>Jeremy Kemper</name>
#     <rank>1</rank>
#     <url-id>jeremy-kemper</url-id>
#   </contributor>
#   <contributor>
#     <id>4404</id>
#     <name>David Heinemeier Hansson</name>
#     <rank>2</rank>
#     <url-id>david-heinemeier-hansson</url-id>
#   </contributor>
# </contributors>
```

NOTE: 定義は[`active_support/core_ext/array/conversions.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/conversions.rb)にあります。

[Array#to_xml]: https://api.rubyonrails.org/classes/Array.html#method-i-to_xml

### ラッピング

[`Array.wrap`][Array.wrap]メソッドは、配列の中にある引数が配列 (または配列的なもの) になっていない場合に、それらを配列の中にラップします。

特徴:

* 引数が`nil`の場合、空の配列を返します。
* 上記以外の場合で、引数が`to_ary`に応答する場合は`to_ary`が呼び出され、`to_ary`の値が`nil`でない場合はその値を返します。
* 上記以外の場合、引数を内側に含んだ配列 (要素が1つだけの配列) を返します。

```ruby
Array.wrap(nil)       # => []
Array.wrap([1, 2, 3]) # => [1, 2, 3]
Array.wrap(0)         # => [0]
```

このメソッドの目的は`Kernel#Array`と似ていますが、いくつかの相違点があります。

* 引数が`to_ary`に応答する場合、このメソッドが呼び出されます。`nil`が返された場合、`Kernel#Array`は`to_a`を適用しようと動作を続けますが、`Array.wrap`はその場で、引数を単一の要素として持つ配列を返します。
* `to_ary`から返された値が`nil`でも`Array`オブジェクトでもない場合、`Kernel#Array`は例外を発生しますが、`Array.wrap`は例外を発生せずに単にその値を返します。
* このメソッドは引数に対して`to_a`を呼び出しませんが、この引数が `to_ary` に応答しない場合、引数を単一の要素として持つ配列を返します。

特に最後の点については、いくつかの列挙型で比較する価値があります。

```ruby
Array.wrap(foo: :bar) # => [{:foo=>:bar}]
Array(foo: :bar)      # => [[:foo, :bar]]
```

この動作は、スプラット演算子（`*`）を用いる手法にも関連します。

```ruby
[*object]
```

NOTE: 定義は[`active_support/core_ext/array/wrap.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/wrap.rb)にあります。

[Array.wrap]: https://api.rubyonrails.org/classes/Array.html#method-c-wrap

### 複製

[`Array#deep_dup`][Array#deep_dup]メソッドは、自分自身を複製すると同時に、その中のすべてのオブジェクトをActive Supportの`Object#deep_dup`メソッドによって再帰的に複製します。この動作は、`Array#map`を用いて`deep_dup`メソッドを内部の各オブジェクトに適用するのと似ています。

```ruby
array = [1, [2, 3]]
dup = array.deep_dup
dup[1][2] = 4
array[1][2] == nil   # => true
```

NOTE: 定義は[`active_support/core_ext/object/deep_dup.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/deep_dup.rb)にあります。

[Array#deep_dup]: https://api.rubyonrails.org/classes/Array.html#method-i-deep_dup

### グループ化

#### `in_groups_of(number, fill_with = nil)`

[`in_groups_of`][Array#in_groups_of]メソッドは、指定のサイズで配列を連続したグループに分割し、分割されたグループを含む配列を1つ返します。

```ruby
[1, 2, 3].in_groups_of(2) # => [[1, 2], [3, nil]]
```

ブロックが渡された場合は`yield`します。

```html+erb
<% sample.in_groups_of(3) do |a, b, c| %>
  <tr>
    <td><%= a %></td>
    <td><%= b %></td>
    <td><%= c %></td>
  </tr>
<% end %>
```

最初の例では、`in_groups_of`メソッドは最後のグループをなるべく`nil`要素で埋め、指定のサイズを満たすようにしています。空きを埋める値はオプションの第2引数で指定できます。

```ruby
[1, 2, 3].in_groups_of(2, 0) # => [[1, 2], [3, 0]]
```

第2引数に`false`を渡すと、最後のグループの空きは詰められます。

```ruby
[1, 2, 3].in_groups_of(2, false) # => [[1, 2], [3]]
```

このため、`false`は空きを埋める値としては利用できません。

NOTE: 定義は[`active_support/core_ext/array/grouping.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/grouping.rb)にあります。

[Array#in_groups_of]: https://api.rubyonrails.org/classes/Array.html#method-i-in_groups_of

#### `in_groups(number, fill_with = nil)`

[`in_groups`][Array#in_groups]は、配列を指定の個数のグループに分割し、分割されたグループを含む配列を1つ返します。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3)
# => [["1", "2", "3"], ["4", "5", nil], ["6", "7", nil]]
```

ブロックが渡された場合は`yield`します。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3) { |group| p group }
["1", "2", "3"]
["4", "5", nil]
["6", "7", nil]
```

この例では、`in_groups`メソッドは一部のグループの後ろを必要に応じて`nil`要素で埋めているのがわかります。1つのグループには、このような余分な要素がグループの一番右側に必要に応じて最大で1つ置かれる可能性があります。また、そのような値を持つグループは、常に全体の中で最後のグループになります。

空きを埋める値はオプションの第2引数で指定できます。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, "0")
# => [["1", "2", "3"], ["4", "5", "0"], ["6", "7", "0"]]
```

第2引数に`false`を渡すと、要素の個数の少ないグループの空きは詰められます。

```ruby
%w(1 2 3 4 5 6 7).in_groups(3, false)
# => [["1", "2", "3"], ["4", "5"], ["6", "7"]]
```

このため、`false`は空きを埋める値としては利用できません。

NOTE: 定義は[`active_support/core_ext/array/grouping.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/grouping.rb)にあります。

[Array#in_groups]: https://api.rubyonrails.org/classes/Array.html#method-i-in_groups

#### `split(value = nil)`

[`split`][Array#split]メソッドは、指定のセパレータで配列を分割し、分割されたチャンクを返します。

ブロックを渡した場合、配列の要素のうち「ブロックが`true`を返す要素」がセパレータとして使われます。

```ruby
(-5..5).to_a.split { |i| i.multiple_of?(4) }
# => [[-5], [-3, -2, -1], [1, 2, 3], [5]]
```

ブロックを渡さない場合、引数として受け取った値がセパレータとして使われます。デフォルトのセパレータは`nil`です。

```ruby
[0, 1, -5, 1, 1, "foo", "bar"].split(1)
# => [[0], [-5], [], ["foo", "bar"]]
```

TIP: 上の例からもわかるように、セパレータが連続すると空の配列になります。

NOTE: 定義は[`active_support/core_ext/array/grouping.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/array/grouping.rb)にあります。

[Array#split]: https://api.rubyonrails.org/classes/Array.html#method-i-split

`Hash`の拡張
--------------------

### 各種変換

#### `to_xml`

[`to_xml`][Hash#to_xml]メソッドは、レシーバをXML表現に変換したものを含む文字列を返します。

```ruby
{ foo: 1, bar: 2 }.to_xml
# =>
# <?xml version="1.0" encoding="UTF-8"?>
# <hash>
#   <foo type="integer">1</foo>
#   <bar type="integer">2</bar>
# </hash>
```

具体的には、このメソッドは与えられたペアから**値**に応じてノードを作成します。`key`と`value`のペアが与えられたとき、以下のように動作します。

* `value`がハッシュの場合、`key`を`:root`として再帰的な呼び出しを行います。

* `value`が配列の場合、`key`を`:root`として、`key`を単数形化（singularize）したものを`:children`として再帰的な呼び出しを行います。

* 値が呼び出し可能な（callable）オブジェクトの場合、引数が1つまたは2つ必要です。引数の数に応じて (`arity`メソッドで確認)、呼び出し可能オブジェクトを呼び出します。第1引数には`key`を`:root`として指定したもの、第2引数には`key`を単数形化したものが使われます。戻り値は新しいノードです。

* `value`が`to_xml`メソッドに応答する場合、`key`を`:root`としてメソッドを呼び出します。

* その他の場合、`key`を持つノードがタグとして作成されます。そのノードには`value`を文字列形式にしたものがテキストノードとして追加されます。`value`が`nil`の場合、"nil"属性が"true"に設定されたものが追加されます。`:skip_types`オプションが`true`でない (または`:skip_types`オプションがない) 場合、「type」属性も以下のマッピングで追加されます。

```ruby
XML_TYPE_NAMES = {
  "Symbol"     => "symbol",
  "Integer"    => "integer",
  "BigDecimal" => "decimal",
  "Float"      => "float",
  "TrueClass"  => "boolean",
  "FalseClass" => "boolean",
  "Date"       => "date",
  "DateTime"   => "datetime",
  "Time"       => "datetime"
}
```

rootノードはデフォルトでは「hash」ですが、`:root`オプションでカスタマイズできます。

デフォルトのXMLビルダは、`Builder::XmlMarkup`から直接生成されたインスタンスです。`:builder`オブションで独自のビルダを構成できます。このメソッドでは`:dasherize`とその同族と同様のオプションが利用でき、指定したオプションはビルダに転送されます。

NOTE: 定義は[`active_support/core_ext/hash/conversions.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/conversions.rb)にあります。

[Hash#to_xml]: https://api.rubyonrails.org/classes/Hash.html#method-i-to_xml

### マージ

Rubyには、2つのハッシュをマージする組み込みの`Hash#merge`メソッドがあります。

```ruby
{ a: 1, b: 1 }.merge(a: 0, c: 2)
# => {:a=>0, :b=>1, :c=>2}
```

Active Supportでは、この他にも便利なハッシュのマージをいくつか提供しています。

#### `reverse_merge`と`reverse_merge!`

`merge`でキーが衝突した場合、引数のハッシュのキーが優先されます。以下のような定形の手法を利用すれば、デフォルト値付きオプションハッシュを簡潔に書けます。

```ruby
options = { length: 30, omission: "..." }.merge(options)
```

Active Supportでは、別の記法を使いたい場合のために[`reverse_merge`][Hash#reverse_merge]も定義されています。

```ruby
options = options.reverse_merge(length: 30, omission: "...")
```

マージを対象内で行なう破壊的なバージョンの[`reverse_merge!`][Hash#reverse_merge!]もあります。

```ruby
options.reverse_merge!(length: 30, omission: "...")
```

WARNING: `reverse_merge!`は呼び出し元のハッシュを変更する可能性があることにご注意ください。それが意図した副作用であるかそうでないかにかかわらず、注意が必要です。

NOTE: 定義は[`active_support/core_ext/hash/reverse_merge.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/reverse_merge.rb)にあります。

[Hash#reverse_merge!]: https://api.rubyonrails.org/classes/Hash.html#method-i-reverse_merge-21
[Hash#reverse_merge]: https://api.rubyonrails.org/classes/Hash.html#method-i-reverse_merge

#### `reverse_update`

[`reverse_update`][Hash#reverse_update]メソッドは、上で説明した`reverse_merge!`のエイリアスです。

WARNING: `reverse_update`には`!`のついたバージョンはありません。

NOTE: 定義は[`active_support/core_ext/hash/reverse_merge.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/reverse_merge.rb)にあります。

[Hash#reverse_update]: https://api.rubyonrails.org/classes/Hash.html#method-i-reverse_update

#### `deep_merge`と`deep_merge!`

先の例で説明したとおり、キーがレシーバと引数で重複している場合、引数の側の値が優先されます。

Active Supportでは[`Hash#deep_merge`][Hash#deep_merge]が定義されています。ディープマージでは、レシーバと引数の両方に同じキーが出現し、さらにどちらも値がハッシュである場合に、その下位のハッシュを**マージ**したものが、最終的なハッシュの値として使われます。

```ruby
{ a: { b: 1 } }.deep_merge(a: { c: 2 })
# => {:a=>{:b=>1, :c=>2}}
```

[`deep_merge!`][Hash#deep_merge!]メソッドはディープマージを破壊的に実行します。

NOTE: 定義は[`active_support/core_ext/hash/deep_merge.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/deep_merge.rb)にあります。

[Hash#deep_merge!]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_merge-21
[Hash#deep_merge]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_merge

### ディープ複製

[`Hash#deep_dup`][Hash#deep_dup]メソッドは、自分自身の複製に加えて、その中のすべてのキーと値を再帰的に複製します。複製にはActive Supportの`Object#deep_dup`メソッドが使われます。この動作は、`Enumerator#each_with_object`を用いて`deep_dup`を内部の各キーバリューペアに送信するのと似ています。

```ruby
hash = { a: 1, b: { c: 2, d: [3, 4] } }

dup = hash.deep_dup
dup[:b][:e] = 5
dup[:b][:d] << 5

hash[:b][:e] == nil      # => true
hash[:b][:d] == [3, 4]   # => true
```

NOTE: 定義は[`active_support/core_ext/object/deep_dup.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/object/deep_dup.rb)にあります。

[Hash#deep_dup]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_dup

### ハッシュキーの操作

#### `except`と`except!`

[`except`][Hash#except]メソッドは、引数で指定されたキーがあればレシーバのハッシュから取り除きます。

```ruby
{ a: 1, b: 2 }.except(:a) # => {:b=>2}
```

レシーバが`convert_key`に応答する場合、このメソッドはすべての引数に対して呼び出されます。そのおかげで、たとえばハッシュの`with_indifferent_access`で`except`メソッドが期待どおりに動作します。

```ruby
{ a: 1 }.with_indifferent_access.except(:a)  # => {}
{ a: 1 }.with_indifferent_access.except("a") # => {}
```

レシーバーからキーを取り除く破壊的な[`except!`][Hash#except!]もあります。

NOTE: 定義は[`active_support/core_ext/hash/except.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/except.rb)にあります。

[Hash#except!]: https://api.rubyonrails.org/classes/Hash.html#method-i-except-21
[Hash#except]: https://api.rubyonrails.org/classes/Hash.html#method-i-except

#### `stringify_keys`と`stringify_keys!`

[`stringify_keys`][Hash#stringify_keys]メソッドは、レシーバのハッシュキーを文字列に変換したハッシュを返します。具体的には、レシーバのハッシュキーに対して`to_s`を送信しています。

```ruby
{ nil => nil, 1 => 1, a: :a }.stringify_keys
# => {"" => nil, "1" => 1, "a" => :a}
```

キーが重複している場合、ハッシュに最も新しく挿入された値が使われます。

```ruby
{ "a" => 1, a: 2 }.stringify_keys
# 値は以下になる
# => {"a"=>2}
```

このメソッドは、シンボルと文字列が両方含まれているハッシュをオプションとして受け取る場合に便利なことがあります。たとえば、`ActionView::Helpers::FormHelper`では以下のように定義されています。

```ruby
def to_check_box_tag(options = {}, checked_value = "1", unchecked_value = "0")
  options = options.stringify_keys
  options["type"] = "checkbox"
  ...
end
```

`stringify_keys`メソッドのおかげで、2行目で「type」キーに安全にアクセスできます。`:type`のようなシンボルでも「"type"」のような文字列でも指定できます。

レシーバーのキーを直接文字列化する破壊的な[`stringify_keys!`][Hash#stringify_keys!]もあります。

また、[`deep_stringify_keys`][Hash#deep_stringify_keys]や[`deep_stringify_keys!`][Hash#deep_stringify_keys!]を使うと、与えられたハッシュのすべてのキーを文字列化し、その中にネストされているすべてのハッシュのキーを文字列化することもできます。以下に例を示します。

```ruby
{ nil => nil, 1 => 1, nested: { a: 3, 5 => 5 } }.deep_stringify_keys
# => {""=>nil, "1"=>1, "nested"=>{"a"=>3, "5"=>5}}
```

NOTE: 定義は[`active_support/core_ext/hash/keys.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/keys.rb)にあります。

[Hash#deep_stringify_keys!]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_stringify_keys-21
[Hash#deep_stringify_keys]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_stringify_keys
[Hash#stringify_keys!]: https://api.rubyonrails.org/classes/Hash.html#method-i-stringify_keys-21
[Hash#stringify_keys]: https://api.rubyonrails.org/classes/Hash.html#method-i-stringify_keys

#### `symbolize_keys`と`symbolize_keys!`

[`symbolize_keys`][Hash#symbolize_keys]メソッドは、レシーバのハッシュキーをシンボルに変換したハッシュを返します。具体的には、レシーバのハッシュキーに対して`to_sym`を送信しています。

```ruby
{ nil => nil, 1 => 1, "a" => "a" }.symbolize_keys
# => {nil=>nil, 1=>1, :a=>"a"}
```

WARNING: 上の例では、3つのキーのうち最後の1つしかシンボルに変換されていないことにご注意ください。数字や`nil`はシンボルに変換されません。

キーが重複している場合、ハッシュに最も新しく挿入された値が使われます。

```ruby
{ "a" => 1, a: 2 }.symbolize_keys
# => {:a=>2}
```

このメソッドは、シンボルと文字列が両方含まれているハッシュをオプションとして受け取る場合に便利なことがあります。たとえば、`ActionText::TagHelper`では以下のように定義されています。

```ruby
def rich_text_area_tag(name, value = nil, options = {})
  options = options.symbolize_keys

  options[:input] ||= "trix_input_#{ActionText::TagHelper.id += 1}"
  # ...
end
```

`symbolize_keys`メソッドのおかげで、3行目で`:input`キーに安全にアクセスできています。`:input`のようなシンボルでも「"input"」のような文字列でも指定できます。

レシーバーのキーを直接シンボルに変換する破壊的な[`symbolize_keys!`][Hash#symbolize_keys!]もあります。

また、[`deep_symbolize_keys`][Hash#deep_symbolize_keys]や[`deep_symbolize_keys!`][Hash#deep_symbolize_keys!]を使うと、与えられたハッシュのすべてのキーと、その中にネストされているすべてのハッシュのキーをシンボルに変換することもできます。以下に例を示します。

```ruby
{ nil => nil, 1 => 1, "nested" => { "a" => 3, 5 => 5 } }.deep_symbolize_keys
# => {nil=>nil, 1=>1, nested:{a:3, 5=>5}}
```

NOTE: 定義は[`active_support/core_ext/hash/keys.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/keys.rb)にあります。

[Hash#deep_symbolize_keys!]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_symbolize_keys-21
[Hash#deep_symbolize_keys]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_symbolize_keys
[Hash#symbolize_keys!]: https://api.rubyonrails.org/classes/Hash.html#method-i-symbolize_keys-21
[Hash#symbolize_keys]: https://api.rubyonrails.org/classes/Hash.html#method-i-symbolize_keys

#### `to_options`と`to_options!`

[`to_options`][Hash#to_options]と[`to_options!`][Hash#to_options!]メソッドは、それぞれ`symbolize_keys`メソッドと`symbolize_keys!`メソッドのエイリアスです。

NOTE: 定義は[`active_support/core_ext/hash/keys.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/keys.rb)にあります。

[Hash#to_options!]: https://api.rubyonrails.org/classes/Hash.html#method-i-to_options-21
[Hash#to_options]: https://api.rubyonrails.org/classes/Hash.html#method-i-to_options

#### `assert_valid_keys`

[`assert_valid_keys`][Hash#assert_valid_keys]メソッドは任意の個数の引数を受け取ることが可能で、許可リストに含まれていないキーがレシーバにあるかどうかをチェックします。そのようなキーが見つかった場合、`ArgumentError`が発生します。

```ruby
{ a: 1 }.assert_valid_keys(:a)  # パスする
{ a: 1 }.assert_valid_keys("a") # ArgumentError
```

たとえばActive Recordは、関連付けをビルドするときに未知のオプションを受け付けません。Active Recordは`assert_valid_keys`による制御を実装しています。

NOTE: 定義は[`active_support/core_ext/hash/keys.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/keys.rb)にあります。

[Hash#assert_valid_keys]: https://api.rubyonrails.org/classes/Hash.html#method-i-assert_valid_keys

### 値を扱う

#### `deep_transform_values` and `deep_transform_values!`

[`deep_transform_values`][Hash#deep_transform_values]メソッドは、ブロック操作で変換されたすべての値を持つ新しいハッシュを返します。その中には、rootハッシュと、ネストしたハッシュや配列のすべての値も含まれます。

```ruby
hash = { person: { name: 'Rob', age: '28' } }

hash.deep_transform_values { |value| value.to_s.upcase }
# => {person: {name: "ROB", age: "28"}}
```

ブロック操作を用いてすべての値を破壊的に変更する[`deep_transform_values!`][Hash#deep_transform_values!]もあります。

NOTE: 定義は[`active_support/core_ext/hash/deep_transform_values.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/deep_transform_values.rb)にあります。

[Hash#deep_transform_values!]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_transform_values-21
[Hash#deep_transform_values]: https://api.rubyonrails.org/classes/Hash.html#method-i-deep_transform_values

### スライス

破壊的なスライス操作を行なう`slice!`メソッドは、指定のキーのみを置き換え、削除されたキーバリューペアを含むハッシュを1つ返します。

```ruby
hash = { a: 1, b: 2 }
rest = hash.slice!(:a) # => {:b=>2}
hash                   # => {:a=>1}
```

NOTE: 定義は[`active_support/core_ext/hash/slice.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/slice.rb)にあります。

[Hash#slice!]: https://api.rubyonrails.org/classes/Hash.html#method-i-slice-21

### 抽出

[`extract!`][Hash#extract!]メソッドは、与えられたキーにマッチするキーバリューペアを取り除き、取り除いたペアを返します。

```ruby
hash = { a: 1, b: 2 }
rest = hash.extract!(:a) # => {:a=>1}
hash                     # => {:b=>2}
```

`extract!`メソッドは、レシーバのハッシュのサブクラスと同じサブクラスを返します。

```ruby
hash = { a: 1, b: 2 }.with_indifferent_access
rest = hash.extract!(:a).class
# => ActiveSupport::HashWithIndifferentAccess
```

NOTE: 定義は[`active_support/core_ext/hash/slice.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/slice.rb)にあります。

[Hash#extract!]: https://api.rubyonrails.org/classes/Hash.html#method-i-extract-21

### ハッシュキーのシンボルと文字列を同様に扱う（indifferent access）

[`with_indifferent_access`][Hash#with_indifferent_access]メソッドは、レシーバから得た[`ActiveSupport::HashWithIndifferentAccess`][ActiveSupport::HashWithIndifferentAccess]を返します。

```ruby
{a: 1}.with_indifferent_access["a"] # => 1
```

NOTE: 定義は[`active_support/core_ext/hash/indifferent_access.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/hash/indifferent_access.rb)にあります。

[ActiveSupport::HashWithIndifferentAccess]: https://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html
[Hash#with_indifferent_access]: https://api.rubyonrails.org/classes/Hash.html#method-i-with_indifferent_access

`Regexp`の拡張
----------------------

### `multiline?`

[`multiline?`][Regexp#multiline?]メソッドは、正規表現に`/m`フラグが設定されているかどうかをチェックします。このフラグが設定されていると、ドット（`.`）が改行にマッチし、複数行を扱えるようになります。

```ruby
%r{.}.multiline?  # => false
%r{.}m.multiline? # => true

Regexp.new('.').multiline?                    # => false
Regexp.new('.', Regexp::MULTILINE).multiline? # => true
```

Railsはこのメソッドをルーティングコードでも1箇所だけ利用しています。ルーティングでは正規表現で複数行を扱うことを許していないので、このフラグで制限を加えています。

```ruby
def verify_regexp_requirements(requirements)
  ...
  if requirement.multiline?
    raise ArgumentError, "Regexp multiline option is not allowed in routing requirements: #{requirement.inspect}"
  end
  ...
end
```

NOTE: 定義は[`active_support/core_ext/regexp.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/regexp.rb)にあります。

[Regexp#multiline?]: https://api.rubyonrails.org/classes/Regexp.html#method-i-multiline-3F

`Range`の拡張
---------------------

### `to_fs`

Active Supportでは、オプションのフォーマット引数を理解する`to_s`の代替として`Range#to_fs`を定義しています。執筆時点では、デフォルトでないフォーマットとしてサポートされているのは`:db`のみです。

```ruby
(Date.today..Date.tomorrow).to_fs
# => "2009-10-25..2009-10-26"

(Date.today..Date.tomorrow).to_fs(:db)
# => "BETWEEN '2009-10-25' AND '2009-10-26'"
```

上の例でもわかるように、フォーマットに`:db`を指定するとSQLの`BETWEEN`句が生成されます。このフォーマットは、Active Recordで条件の値の範囲をサポートするときに使われます。

NOTE: 定義は[`active_support/core_ext/range/conversions.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/range/conversions.rb)にあります。

### `===`、`include?`

`Range#===`メソッドと`Range#include?`メソッドは、与えられたインスタンスの範囲内に値が収まっているかどうかをチェックします。

```ruby
(2..3).include?(Math::E) # => true
```

Active Supportではこれらのメソッドを拡張して、他の範囲指定を引数で指定できるようにしています。この場合、引数の範囲がレシーバの範囲の中に収まっているかどうかがチェックされています。

```ruby
(1..10) === (3..7)  # => true
(1..10) === (0..7)  # => false
(1..10) === (3..11) # => false
(1...9) === (3..9)  # => false

(1..10).include?(3..7)  # => true
(1..10).include?(0..7)  # => false
(1..10).include?(3..11) # => false
(1...9).include?(3..9)  # => false
```

NOTE: 定義は[`active_support/core_ext/range/compare_range.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/range/compare_range.rb)にあります。

### `overlap?`

[`Range#overlap?`][Range#overlap?]メソッドは、与えられた2つの範囲に（空白でない）重なりがあるかどうかをチェックします。

```ruby
(1..10).overlap?(7..11)  # => true
(1..10).overlap?(0..7)   # => true
(1..10).overlap?(11..27) # => false
```

NOTE: 定義は[`active_support/core_ext/range/overlap.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/range/overlap.rb)にあります。

[Range#overlap?]: https://api.rubyonrails.org/classes/Range.html#method-i-overlap-3F

`Date`の拡張
--------------------

### 計算

INFO: 以下の計算方法の一部では1582年10月をエッジケースとして用いています。この月にユリウス暦からグレゴリオ暦への切り替えが行われたため、10月5日から10月14日までが存在しません。本ガイドはこの「特殊な月」について詳しく解説することはしませんが、メソッドがこの月でも期待どおりに動作することについては説明しておきたいと思います。具体的には、たとえば`Date.new(1582, 10, 4).tomorrow`を実行すると`Date.new(1582, 10, 15)`と同じ結果を返します。期待どおりに動作することは、Active Supportの`test/core_ext/date_ext_test.rb`用のテストスイートで確認できます。

#### `Date.current`

Active Supportでは、[`Date.current`][Date.current]を定義して現在のタイムゾーンにおける「今日」を定めています。このメソッドは`Date.today`と似ていますが、ユーザー定義のタイムゾーンがある場合にそれを考慮する点が異なります。Active Supportでは[`Date.yesterday`][Date.yesterday]メソッドと[`Date.tomorrow`][Date.tomorrow]も定義しています。インスタンスでは[`past?`][DateAndTime::Calculations#past?]、[`today?`][DateAndTime::Calculations#today?]、[`tomorrow?`][DateAndTime::Calculations#tomorrow?]、[`next_day?`][DateAndTime::Calculations#next_day?]、[`yesterday?`][DateAndTime::Calculations#yesterday?]、[`prev_day?`][DateAndTime::Calculations#prev_day?]、[`future?`][DateAndTime::Calculations#future?]、[`on_weekday?`][DateAndTime::Calculations#on_weekday?]、[`on_weekend?`][DateAndTime::Calculations#on_weekend?]を利用でき、これらはすべて`Date.current`を起点として導かれます。

ユーザー定義のタイムゾーンを考慮するメソッドを用いて日付を比較したい場合、`Date.today`ではなく必ず`Date.current`を使ってください。ユーザー定義のタイムゾーンは、システムのタイムゾーンより未来になる可能性があります（`Date.today`はデフォルトでシステムのタイムゾーンを使います）。つまり、`Date.today`が`Date.yesterday`と等しくなる可能性があるということです。

NOTE: 定義は[`active_support/core_ext/date/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date/calculations.rb)にあります。

[Date.current]: https://api.rubyonrails.org/classes/Date.html#method-c-current
[Date.tomorrow]: https://api.rubyonrails.org/classes/Date.html#method-c-tomorrow
[Date.yesterday]: https://api.rubyonrails.org/classes/Date.html#method-c-yesterday
[DateAndTime::Calculations#future?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-future-3F
[DateAndTime::Calculations#on_weekday?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-on_weekday-3F
[DateAndTime::Calculations#on_weekend?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-on_weekend-3F
[DateAndTime::Calculations#past?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-past-3F

#### 名前付き日付

##### `beginning_of_week`、`end_of_week`

[`beginning_of_week`][DateAndTime::Calculations#beginning_of_week]メソッドと[`end_of_week`][DateAndTime::Calculations#end_of_week]メソッドは、それぞれ週の最初の日付と週の最後の日付を返します。週の始まりはデフォルトでは月曜日ですが、引数を渡して変更できます。そのときにスレッドローカルの`Date.beginning_of_week`または[`config.beginning_of_week`][]を設定します。

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.beginning_of_week          # => Mon, 03 May 2010
d.beginning_of_week(:sunday) # => Sun, 02 May 2010
d.end_of_week                # => Sun, 09 May 2010
d.end_of_week(:sunday)       # => Sat, 08 May 2010
```

[`at_beginning_of_week`][DateAndTime::Calculations#at_beginning_of_week]は`beginning_of_week`のエイリアス、[`at_end_of_week`][DateAndTime::Calculations#at_end_of_week]は`end_of_week`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[`config.beginning_of_week`]: configuring.html#config-beginning-of-week
[DateAndTime::Calculations#at_beginning_of_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_beginning_of_week
[DateAndTime::Calculations#at_end_of_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_end_of_week
[DateAndTime::Calculations#beginning_of_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-beginning_of_week
[DateAndTime::Calculations#end_of_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-end_of_week

##### `monday`、`sunday`

[`monday`][DateAndTime::Calculations#monday]メソッドはその日から見た「前の月曜（の日付）」を、[`sunday`][DateAndTime::Calculations#sunday]メソッドはその日から見た「次の日曜（の日付）」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 8)     # => Sat, 08 May 2010
d.monday                     # => Mon, 03 May 2010
d.sunday                     # => Sun, 09 May 2010

d = Date.new(2012, 9, 10)    # => Mon, 10 Sep 2012
d.monday                     # => Mon, 10 Sep 2012

d = Date.new(2012, 9, 16)    # => Sun, 16 Sep 2012
d.sunday                     # => Sun, 16 Sep 2012
```

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#monday]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-monday
[DateAndTime::Calculations#sunday]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-sunday

##### `prev_week`、`next_week`

[`next_week`][DateAndTime::Calculations#next_week]メソッドは、英語の曜日名のシンボル（デフォルトではスレッドローカルの[`Date.beginning_of_week`][Date.beginning_of_week]または[`config.beginning_of_week`][]または`:monday`）を受け取り、それに対応する翌週の曜日の日付を返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.next_week              # => Mon, 10 May 2010
d.next_week(:saturday)   # => Sat, 15 May 2010
```

[`prev_week`][DateAndTime::Calculations#prev_week]も同様に、前の週の曜日の日付を返します。

```ruby
d.prev_week              # => Mon, 26 Apr 2010
d.prev_week(:saturday)   # => Sat, 01 May 2010
d.prev_week(:friday)     # => Fri, 30 Apr 2010
```

[`last_week`][DateAndTime::Calculations#last_week]は`prev_week`のエイリアスです。

`Date.beginning_of_week`または`config.beginning_of_week`が設定されていれば、`next_week`と`prev_week`はどちらも正常に動作します。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[Date.beginning_of_week]: https://api.rubyonrails.org/classes/Date.html#method-c-beginning_of_week
[DateAndTime::Calculations#last_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-last_week
[DateAndTime::Calculations#next_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-next_week
[DateAndTime::Calculations#prev_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-prev_week

##### `beginning_of_month`、`end_of_month`

[`beginning_of_month`][DateAndTime::Calculations#beginning_of_month]メソッドはその月の「最初の日」、[`end_of_month`][DateAndTime::Calculations#end_of_month]メソッドはその月の「最後の日」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_month     # => Sat, 01 May 2010
d.end_of_month           # => Mon, 31 May 2010
```

[`at_beginning_of_month`][DateAndTime::Calculations#at_beginning_of_month]は`beginning_of_month`のエイリアス、[`at_end_of_month`][DateAndTime::Calculations#at_end_of_month]は`end_of_month`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#at_beginning_of_month]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_beginning_of_month
[DateAndTime::Calculations#at_end_of_month]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_end_of_month
[DateAndTime::Calculations#beginning_of_month]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-beginning_of_month
[DateAndTime::Calculations#end_of_month]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-end_of_month

##### `quarter`, `beginning_of_quarter`, `end_of_quarter`

[`quarter`][DateAndTime::Calculations#quarter]は、レシーバのカレンダー年における四半期を返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.quarter                # => 2
```

[`beginning_of_quarter`][DateAndTime::Calculations#beginning_of_quarter]メソッドと[`end_of_quarter`][DateAndTime::Calculations#end_of_quarter]メソッドは、レシーバのカレンダー年における四半期「最初の日」と「最後の日」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_quarter   # => Thu, 01 Apr 2010
d.end_of_quarter         # => Wed, 30 Jun 2010
```

[`at_beginning_of_quarter`][DateAndTime::Calculations#at_beginning_of_quarter]は`beginning_of_quarter`のエイリアス、[`at_end_of_quarter`][DateAndTime::Calculations#at_end_of_quarter]は`end_of_quarter`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-quarter
[DateAndTime::Calculations#at_beginning_of_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_beginning_of_quarter
[DateAndTime::Calculations#at_end_of_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_end_of_quarter
[DateAndTime::Calculations#beginning_of_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-beginning_of_quarter
[DateAndTime::Calculations#end_of_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-end_of_quarter

##### `beginning_of_year`、`end_of_year`

[`beginning_of_year`][DateAndTime::Calculations#beginning_of_year]メソッドと[`end_of_year`][DateAndTime::Calculations#end_of_year]メソッドは、その年の「最初の日」と「最後の日」をそれぞれ返します。

```ruby
d = Date.new(2010, 5, 9) # => Sun, 09 May 2010
d.beginning_of_year      # => Fri, 01 Jan 2010
d.end_of_year            # => Fri, 31 Dec 2010
```

[`at_beginning_of_year`][DateAndTime::Calculations#at_beginning_of_year]は`beginning_of_year`のエイリアス、[`at_end_of_year`][DateAndTime::Calculations#at_end_of_year]は`end_of_year`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#at_beginning_of_year]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_beginning_of_year
[DateAndTime::Calculations#at_end_of_year]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-at_end_of_year
[DateAndTime::Calculations#beginning_of_year]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-beginning_of_year
[DateAndTime::Calculations#end_of_year]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-end_of_year

#### その他の日付計算メソッド

##### `years_ago`、`years_since`

[`years_ago`][DateAndTime::Calculations#years_ago]メソッドは、年数を受け取り、その年数前の同じ日付を返します。

```ruby
date = Date.new(2010, 6, 7)
date.years_ago(10) # => Wed, 07 Jun 2000
```

[`years_since`][DateAndTime::Calculations#years_since]も同じ要領で、指定の年数後の同じ日付を返します。

```ruby
date = Date.new(2010, 6, 7)
date.years_since(10) # => Sun, 07 Jun 2020
```

同じ日が行き先の月にない場合、その月の最後の日を返します。

```ruby
Date.new(2012, 2, 29).years_ago(3)     # => Sat, 28 Feb 2009
Date.new(2012, 2, 29).years_since(3)   # => Sat, 28 Feb 2015
```

[`last_year`][DateAndTime::Calculations#last_year]は`#years_ago(1)`のショートハンドです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#last_year]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-last_year
[DateAndTime::Calculations#years_ago]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-years_ago
[DateAndTime::Calculations#years_since]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-years_since

##### `months_ago`、`months_since`

[`months_ago`][DateAndTime::Calculations#months_ago]メソッドと[`months_since`][DateAndTime::Calculations#months_since]メソッドは、上と同じ要領で月に対して行います。

```ruby
Date.new(2010, 4, 30).months_ago(2)   # => Sun, 28 Feb 2010
Date.new(2010, 4, 30).months_since(2) # => Wed, 30 Jun 2010
```

対象の月に同じ日がない場合は、その月の最後の日を返します。

```ruby
Date.new(2010, 4, 30).months_ago(2)    # => Sun, 28 Feb 2010
Date.new(2009, 12, 31).months_since(2) # => Sun, 28 Feb 2010
```

[`last_month`][DateAndTime::Calculations#last_month]は`#months_ago(1)`のショートハンドです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#last_month]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-last_month
[DateAndTime::Calculations#months_ago]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-months_ago
[DateAndTime::Calculations#months_since]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-months_since

##### `weeks_ago`

[`weeks_ago`][DateAndTime::Calculations#weeks_ago]メソッドは、同じ要領で週に対して行います。

```ruby
Date.new(2010, 5, 24).weeks_ago(1)    # => Mon, 17 May 2010
Date.new(2010, 5, 24).weeks_ago(2)    # => Mon, 10 May 2010
```

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#weeks_ago]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-weeks_ago

##### `advance`

[`advance`][Date#advance]メソッドは、日付を移動する最も一般的な方法です。このメソッドは`:years`、`:months`、`:weeks`、`:days`をキーに持つハッシュを受け取り、日付をできるだけ詳細な形式で、現在のキーで示されるとおりに返します。

```ruby
date = Date.new(2010, 6, 6)
date.advance(years: 1, weeks: 2)  # => Mon, 20 Jun 2011
date.advance(months: 2, days: -2) # => Wed, 04 Aug 2010
```

上の例にも示されているように、増分値には負の数も指定できます。

NOTE: 定義は[`active_support/core_ext/date/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date/calculations.rb)にあります。

[Date#advance]: https://api.rubyonrails.org/classes/Date.html#method-i-advance

#### 要素の変更

[`change`][Date#change]メソッドは、指定の年/月/日に応じてレシーバの日付を変更し、無指定の部分はそのままにしてその日付を返します。

```ruby
Date.new(2010, 12, 23).change(year: 2011, month: 11)
# => Wed, 23 Nov 2011
```

存在しない日付が指定されると`ArgumentError`が発生します。

```ruby
Date.new(2010, 1, 31).change(month: 2)
# => ArgumentError: invalid date
```

NOTE: 定義は[`active_support/core_ext/date/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date/calculations.rb)にあります。

[Date#change]: https://api.rubyonrails.org/classes/Date.html#method-i-change

#### 期間（duration）

[`Duration`][ActiveSupport::Duration]オブジェクトは、日付に対して期間を加減算できます。

```ruby
d = Date.current
# => Mon, 09 Aug 2010
d + 1.year
# => Tue, 09 Aug 2011
d - 3.hours
# => Sun, 08 Aug 2010 21:00:00 UTC +00:00
```

これらの計算は、内部で`since`メソッドや`advance`メソッドに置き換えられます。たとえば、作り直したカレンダー内で正しくジャンプできます。

```ruby
Date.new(1582, 10, 4) + 1.day
# => Fri, 15 Oct 1582
```

[ActiveSupport::Duration]: https://api.rubyonrails.org/classes/ActiveSupport/Duration.html

#### タイムスタンプ

INFO: 以下のメソッドは可能であれば`Time`オブジェクトを返し、それ以外の場合は`DateTime`を返します。ユーザーのタイムゾーンが設定されていればそれも加味されます。

##### `beginning_of_day`、`end_of_day`

[`beginning_of_day`][Date#beginning_of_day]メソッドは、その日の開始時点 (00:00:00) のタイムスタンプを返します。

```ruby
date = Date.new(2010, 6, 7)
date.beginning_of_day # => Mon Jun 07 00:00:00 +0200 2010
```

[`end_of_day`][Date#end_of_day]メソッドは、その日の最後の時点 (23:59:59) のタイムスタンプを返します。

```ruby
date = Date.new(2010, 6, 7)
date.end_of_day # => Mon Jun 07 23:59:59 +0200 2010
```

[`at_beginning_of_day`][Date#at_beginning_of_day]と[`midnight`][Date#midnight]と[`at_midnight`][Date#at_midnight]は、`beginning_of_day`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date/calculations.rb)にあります。

[Date#at_beginning_of_day]: https://api.rubyonrails.org/classes/Date.html#method-i-at_beginning_of_day
[Date#at_midnight]: https://api.rubyonrails.org/classes/Date.html#method-i-at_midnight
[Date#beginning_of_day]: https://api.rubyonrails.org/classes/Date.html#method-i-beginning_of_day
[Date#end_of_day]: https://api.rubyonrails.org/classes/Date.html#method-i-end_of_day
[Date#midnight]: https://api.rubyonrails.org/classes/Date.html#method-i-midnight

##### `beginning_of_hour`、`end_of_hour`

[`beginning_of_hour`][DateTime#beginning_of_hour]メソッドは、その時（hour）の最初の時点 (hh:00:00) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_hour # => Mon Jun 07 19:00:00 +0200 2010
```

[`end_of_hour`][DateTime#end_of_hour]メソッドは、その時の最後の時点 (hh:59:59) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_hour # => Mon Jun 07 19:59:59 +0200 2010
```

[`at_beginning_of_hour`][DateTime#at_beginning_of_hour]は`beginning_of_hour`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

##### `beginning_of_minute`、`end_of_minute`

[`beginning_of_minute`][DateTime#beginning_of_minute]は、その分の最初の時点 (hh:mm:00) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.beginning_of_minute # => Mon Jun 07 19:55:00 +0200 2010
```

[`end_of_minute`][DateTime#end_of_minute]メソッドは、その分の最後の時点 (hh:mm:59) のタイムスタンプを返します。

```ruby
date = DateTime.new(2010, 6, 7, 19, 55, 25)
date.end_of_minute # => Mon Jun 07 19:55:59 +0200 2010
```

[`at_beginning_of_minute`][DateTime#at_beginning_of_minute]は`beginning_of_minute`のエイリアスです。

INFO: `beginning_of_hour`、`end_of_hour`、`beginning_of_minute`、`end_of_minute`は、`Time`および`DateTime`向けの実装ですが、`Date`向けの実装では**ありません**。時刻情報を含まない`Date`インスタンスに対して時間や分の最初や最後を問い合わせる意味はありません。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateTime#at_beginning_of_minute]: https://api.rubyonrails.org/classes/DateTime.html#method-i-at_beginning_of_minute
[DateTime#beginning_of_minute]: https://api.rubyonrails.org/classes/DateTime.html#method-i-beginning_of_minute
[DateTime#end_of_minute]: https://api.rubyonrails.org/classes/DateTime.html#method-i-end_of_minute

##### `ago`、`since`

[`ago`][Date#ago]メソッドは秒数を引数として受け取り、真夜中の時点からその秒数だけさかのぼった時点のタイムスタンプを返します。

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.ago(1)         # => Thu, 10 Jun 2010 23:59:59 EDT -04:00
```

[`since`][Date#since]メソッドは、同様にその秒数だけ先に進んだ時点のタイムスタンプを返します。

```ruby
date = Date.current # => Fri, 11 Jun 2010
date.since(1)       # => Fri, 11 Jun 2010 00:00:01 EDT -04:00
```

NOTE: 定義は[`active_support/core_ext/date/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date/calculations.rb)にあります。

[Date#ago]: https://api.rubyonrails.org/classes/Date.html#method-i-ago
[Date#since]: https://api.rubyonrails.org/classes/Date.html#method-i-since

`DateTime`の拡張
------------------------

WARNING: `DateTime`は夏時間 (DST) ルールについては関知しません。夏時間の変更中は、メソッドの一部がこのとおりに動作しないエッジケースがあります。たとえば、[`seconds_since_midnight`][DateTime#seconds_since_midnight]メソッドが返す秒数が実際の総量と合わない可能性があります。

### 計算

`DateTime`クラスは`Date`のサブクラスであり、`active_support/core_ext/date/calculations.rb`を読み込むことでこれらのメソッドとエイリアスを継承できます。ただしこれらは常に日時を返す点が`Date`と異なります。

以下のメソッドはすべて再実装されるため、これらを用いるために`active_support/core_ext/date/calculations.rb`を読み込む必要は **ありません**。

* [`beginning_of_day`][DateTime#beginning_of_day] / [`midnight`][DateTime#midnight] / [`at_midnight`][DateTime#at_midnight] / [`at_beginning_of_day`][DateTime#at_beginning_of_day]
* [`end_of_day`][DateTime#end_of_day]
* [`ago`][DateTime#ago]
* [`since`][DateTime#since] / [`in`][DateTime#in]


他方、[`advance`][DateTime#advance]と[`change`][DateTime#change]も定義されていて、さらに多くのオプションをサポートしています。これらについては後述します。

以下のメソッドは`active_support/core_ext/date_time/calculations.rb`にのみ実装されています。これらは`DateTime`インスタンスに対して使わないと意味がないためです。

* [`beginning_of_hour`][DateTime#beginning_of_hour] / [`at_beginning_of_hour`][DateTime#at_beginning_of_hour]
* [`end_of_hour`][DateTime#end_of_hour]

[DateTime#ago]: https://api.rubyonrails.org/classes/DateTime.html#method-i-ago
[DateTime#at_beginning_of_day]: https://api.rubyonrails.org/classes/DateTime.html#method-i-at_beginning_of_day
[DateTime#at_beginning_of_hour]: https://api.rubyonrails.org/classes/DateTime.html#method-i-at_beginning_of_hour
[DateTime#at_midnight]: https://api.rubyonrails.org/classes/DateTime.html#method-i-at_midnight
[DateTime#beginning_of_day]: https://api.rubyonrails.org/classes/DateTime.html#method-i-beginning_of_day
[DateTime#beginning_of_hour]: https://api.rubyonrails.org/classes/DateTime.html#method-i-beginning_of_hour
[DateTime#end_of_day]: https://api.rubyonrails.org/classes/DateTime.html#method-i-end_of_day
[DateTime#end_of_hour]: https://api.rubyonrails.org/classes/DateTime.html#method-i-end_of_hour
[DateTime#in]: https://api.rubyonrails.org/classes/DateTime.html#method-i-in
[DateTime#midnight]: https://api.rubyonrails.org/classes/DateTime.html#method-i-midnight

#### 名前付き日付時刻

##### `DateTime.current`

Active Supportでは、[`DateTime.current`][DateTime.current]を`Time.now.to_datetime`と同様に定義しています。ただし、`DateTime.current`はユーザータイムゾーンが定義されている場合に対応する点が異なります。インスタンスでは[`past?`][DateAndTime::Calculations#past?]および[`future?`][DateAndTime::Calculations#future?]という述語メソッドを利用でき、これらの定義は`Date.current`を起点としています。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateTime.current]: https://api.rubyonrails.org/classes/DateTime.html#method-c-current

#### その他の拡張

##### `seconds_since_midnight`

[`seconds_since_midnight`][DateTime#seconds_since_midnight]メソッドは、真夜中からの経過秒数を返します。

```ruby
now = DateTime.current     # => Mon, 07 Jun 2010 20:26:36 +0000
now.seconds_since_midnight # => 73596
```

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateTime#seconds_since_midnight]: https://api.rubyonrails.org/classes/DateTime.html#method-i-seconds_since_midnight

##### `utc`

[`utc`][DateTime#utc]メソッドは、レシーバの日付時刻をUTCで返します。

```ruby
now = DateTime.current # => Mon, 07 Jun 2010 19:27:52 -0400
now.utc                # => Mon, 07 Jun 2010 23:27:52 +0000
```

[`getutc`][DateTime#getutc]は`utc`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateTime#getutc]: https://api.rubyonrails.org/classes/DateTime.html#method-i-getutc
[DateTime#utc]: https://api.rubyonrails.org/classes/DateTime.html#method-i-utc

##### `utc?`

[`utc?`][DateTime#utc?]述語メソッドは、レシーバがそのタイムゾーンに合ったUTC時刻を持っているかどうかをチェックします。

```ruby
now = DateTime.now # => Mon, 07 Jun 2010 19:30:47 -0400
now.utc?          # => false
now.utc.utc?      # => true
```

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateTime#utc?]: https://api.rubyonrails.org/classes/DateTime.html#method-i-utc-3F

##### `advance`

[`advance`][DateTime#advance]メソッドは、日時を移動する最も一般的な方法です。このメソッドは`:years`、`:months`、`:weeks`、`:days`、`:hours`、`:minutes`および`:seconds`をキーに持つハッシュを受け取り、日時をできるだけ詳細な形式で、現在のキーで示されるとおりに返します。

```ruby
d = DateTime.current
# => Thu, 05 Aug 2010 11:33:31 +0000
d.advance(years: 1, months: 1, days: 1, hours: 1, minutes: 1, seconds: 1)
# => Tue, 06 Sep 2011 12:34:32 +0000
```

このメソッドは最初に、上で説明されている`Date#advance`に対する経過年(`:years`)、経過月 (`:months`)、経過週 (`:weeks`)、経過日 (`:days`) を元に移動先の日付を算出します。次に、算出された時点までの経過秒数を元に[`since`][DateTime#since]メソッドを呼び出し、時間を補正します。この実行順序には意味があります（極端なケースでは、順序が変わると計算結果も異なる場合があります）。この`Date#advance`の例はそれに該当し、これを延長することで、時間部分の相対的な計算順序がどのように影響するかを示せます。

もし仮に日付部分を最初に計算し（前述したとおり、相対的な計算順序も影響します）、次に時間部分を計算すると、以下のような結果が得られます。

```ruby
d = DateTime.new(2010, 2, 28, 23, 59, 59)
# => Sun, 28 Feb 2010 23:59:59 +0000
d.advance(months: 1, seconds: 1)
# => Mon, 29 Mar 2010 00:00:00 +0000
```

しかし計算順序が変わると、以下のように結果が変わる場合があります。

```ruby
d.advance(seconds: 1).advance(months: 1)
# => Thu, 01 Apr 2010 00:00:00 +0000
```

WARNING: `DateTime`は夏時間 (DST) を考慮しません。算出された時間が最終的に存在しない時間になっても警告やエラーは発生しません。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateTime#advance]: https://api.rubyonrails.org/classes/DateTime.html#method-i-advance
[DateTime#since]: https://api.rubyonrails.org/classes/DateTime.html#method-i-since

#### 要素の変更

[`change`][DateTime#change]メソッドを使うと、レシーバの日時の一部の要素だけを更新した新しい日時を得られます。変更する要素として、`:year`、`:month`、`:day`、`:hour`、`:min`、`:sec`、`:offset`、`:start`などを指定できます。

```ruby
now = DateTime.current
# => Tue, 08 Jun 2010 01:56:22 +0000
now.change(year: 2011, offset: Rational(-6, 24))
# => Wed, 08 Jun 2011 01:56:22 -0600
```

時（hour）がゼロの場合、分と秒の値も同様にゼロになります（指定のない場合）。

```ruby
now.change(hour: 0)
# => Tue, 08 Jun 2010 00:00:00 +0000
```

同様に、分がゼロの場合、秒の値も同様にゼロになります（指定のない場合）。

```ruby
now.change(min: 0)
# => Tue, 08 Jun 2010 01:00:00 +0000
```

存在しない日付が指定されると`ArgumentError`が発生します。

```ruby
DateTime.current.change(month: 2, day: 30)
# => ArgumentError: invalid date
```

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateTime#change]: https://api.rubyonrails.org/classes/DateTime.html#method-i-change

#### 期間（duration）

[`Duration`][ActiveSupport::Duration]オブジェクトは、日時に対して期間を加減算できます。

```ruby
now = DateTime.current
# => Mon, 09 Aug 2010 23:15:17 +0000
now + 1.year
# => Tue, 09 Aug 2011 23:15:17 +0000
now - 1.week
# => Mon, 02 Aug 2010 23:15:17 +0000
```

これらの計算は、内部で`since`メソッドや`advance`メソッドに置き換えられます。たとえば、作り直したカレンダー内で正しくジャンプできます。

```ruby
DateTime.new(1582, 10, 4, 23) + 1.hour
# => Fri, 15 Oct 1582 00:00:00 +0000
```

`Time`の拡張
--------------------

### 計算

これらは同様に動作します。関連するドキュメントを参照し、以下の相違点についても把握しておいてください。

* [`change`][Time#change]メソッドは追加の`:usec`（マイクロ秒）オプションも受け取れます。。
* `Time`は夏時間 (DST) を理解するので、以下のように夏時間を正しく算出できます。

```ruby
Time.zone_default
# => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>

# バルセロナでは夏時間により2010/03/28 02:00 +0100が2010/03/28 03:00 +0200になる
t = Time.local(2010, 3, 28, 1, 59, 59)
# => Sun Mar 28 01:59:59 +0100 2010
t.advance(seconds: 1)
# => Sun Mar 28 03:00:00 +0200 2010
```

* [`since`][Time#since]や[`ago`][Time#ago]の移動先の時間が`Time`で表現できない場合、`DateTime`オブジェクトが代わりに返されます。

[Time#ago]: https://api.rubyonrails.org/classes/Time.html#method-i-ago
[Time#change]: https://api.rubyonrails.org/classes/Time.html#method-i-change
[Time#since]: https://api.rubyonrails.org/classes/Time.html#method-i-since

#### `Time.current`

Active Supportでは、[`Time.current`][Time.current]を定義して現在のタイムゾーンにおける「今日」を定めています。このメソッドは`Time.now`と似ていますが、ユーザー定義のタイムゾーンがある場合にそれを考慮する点が異なります。Active Supportでは[`past?`][DateAndTime::Calculations#past?]、[`today?`][DateAndTime::Calculations#today?]、[`tomorrow?`][DateAndTime::Calculations#tomorrow?]、[`next_day?`][DateAndTime::Calculations#next_day?]、[`yesterday?`][DateAndTime::Calculations#yesterday?]、[`prev_day?`][DateAndTime::Calculations#prev_day?]、[`future?`][DateAndTime::Calculations#future?]を調べるインスタンス述語メソッドも定義されており、これらはすべてこの`Time.current`を起点にしています。

ユーザー定義のタイムゾーンを考慮するメソッドを用いて時刻を比較したい場合、`Time.now`ではなく必ず`Time.current`を使ってください。ユーザー定義のタイムゾーンは、システムのタイムゾーンより未来になる可能性があります（`Time.now`はデフォルトでシステムのタイムゾーンを使います）。つまり、`Time.now.to_date`が`Date.yesterday`と等しくなる可能性があるということです。

NOTE: 定義は[`active_support/core_ext/time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/time/calculations.rb)にあります。

[DateAndTime::Calculations#next_day?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-next_day-3F
[DateAndTime::Calculations#prev_day?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-prev_day-3F
[DateAndTime::Calculations#today?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-today-3F
[DateAndTime::Calculations#tomorrow?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-tomorrow-3F
[DateAndTime::Calculations#yesterday?]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-yesterday-3F


#### `all_day`、`all_week`、`all_month`、`all_quarter`、`all_year`

[`all_day`][DateAndTime::Calculations#all_day]メソッドは、現在時刻を含む「その日一日」を表す範囲を返します。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_day
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Mon, 09 Aug 2010 23:59:59 UTC +00:00
```

同様に、[`all_week`][DateAndTime::Calculations#all_week]（その週の期間）、[`all_month`][DateAndTime::Calculations#all_month]（その月の期間）、[`all_quarter`][DateAndTime::Calculations#all_quarter]（その四半期の期間）、[`all_year`][DateAndTime::Calculations#all_year]（その年の期間）も時間の範囲を生成できます。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now.all_week
# => Mon, 09 Aug 2010 00:00:00 UTC +00:00..Sun, 15 Aug 2010 23:59:59 UTC +00:00
now.all_week(:sunday)
# => Sun, 16 Sep 2012 00:00:00 UTC +00:00..Sat, 22 Sep 2012 23:59:59 UTC +00:00
now.all_month
# => Sat, 01 Aug 2010 00:00:00 UTC +00:00..Tue, 31 Aug 2010 23:59:59 UTC +00:00
now.all_quarter
# => Thu, 01 Jul 2010 00:00:00 UTC +00:00..Thu, 30 Sep 2010 23:59:59 UTC +00:00
now.all_year
# => Fri, 01 Jan 2010 00:00:00 UTC +00:00..Fri, 31 Dec 2010 23:59:59 UTC +00:00
```

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#all_day]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-all_day
[DateAndTime::Calculations#all_month]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-all_month
[DateAndTime::Calculations#all_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-all_quarter
[DateAndTime::Calculations#all_week]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-all_week
[DateAndTime::Calculations#all_year]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-all_year
[Time.current]: https://api.rubyonrails.org/classes/Time.html#method-c-current

#### `prev_day`、`next_day`

[`prev_day`][Time#prev_day]メソッドは指定の日の「前日」の日時を返し、[`next_day`][Time#next_day]は指定の日の「翌日」の日時を返します。

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_day               # => 2010-05-07 00:00:00 +0900
t.next_day               # => 2010-05-09 00:00:00 +0900
```

NOTE: 定義は[`active_support/core_ext/time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/time/calculations.rb)にあります。

[Time#next_day]: https://api.rubyonrails.org/classes/Time.html#method-i-next_day
[Time#prev_day]: https://api.rubyonrails.org/classes/Time.html#method-i-prev_day

#### `prev_month`、`next_month`

[`prev_month`][Time#prev_month]メソッドは指定の日の「前月」の同じ日の日時を返し、[`next_month`][Time#next_month]メソッドは指定の日の「翌月」の同じ日の日時を返します。

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_month             # => 2010-04-08 00:00:00 +0900
t.next_month             # => 2010-06-08 00:00:00 +0900
```

該当する日付が存在しない場合、対応する月の最終日を返します。

```ruby
Time.new(2000, 5, 31).prev_month # => 2000-04-30 00:00:00 +0900
Time.new(2000, 3, 31).prev_month # => 2000-02-29 00:00:00 +0900
Time.new(2000, 5, 31).next_month # => 2000-06-30 00:00:00 +0900
Time.new(2000, 1, 31).next_month # => 2000-02-29 00:00:00 +0900
```

NOTE: 定義は[`active_support/core_ext/time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/time/calculations.rb)にあります。

[Time#next_month]: https://api.rubyonrails.org/classes/Time.html#method-i-next_month
[Time#prev_month]: https://api.rubyonrails.org/classes/Time.html#method-i-prev_month

#### `prev_year`、`next_year`

[`prev_year`][Time#prev_year]メソッドは指定の日の「前年」の同月同日の日時を返し、[`next_year`][Time#next_year]メソッドは指定の日の「翌年」の同月同日の日時を返します。

```ruby
t = Time.new(2010, 5, 8) # => 2010-05-08 00:00:00 +0900
t.prev_year              # => 2009-05-08 00:00:00 +0900
t.next_year              # => 2011-05-08 00:00:00 +0900
```

うるう年の2月29日の場合、28日の日付を返します。

```ruby
t = Time.new(2000, 2, 29) # => 2000-02-29 00:00:00 +0900
t.prev_year               # => 1999-02-28 00:00:00 +0900
t.next_year               # => 2001-02-28 00:00:00 +0900
```

NOTE: 定義は[`active_support/core_ext/time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/time/calculations.rb)にあります。

[Time#next_year]: https://api.rubyonrails.org/classes/Time.html#method-i-next_year
[Time#prev_year]: https://api.rubyonrails.org/classes/Time.html#method-i-prev_year

#### `prev_quarter`、`next_quarter`

[`prev_quarter`][DateAndTime::Calculations#prev_quarter]メソッドは指定の日付の「前の四半期」の同じ日の日時を返し、[`next_quarter`][DateAndTime::Calculations#next_quarter]メソッドは指定の日付の「次の四半期」の同じ日の日時を返します。

```ruby
t = Time.local(2010, 5, 8) # => 2010-05-08 00:00:00 +0300
t.prev_quarter             # => 2010-02-08 00:00:00 +0200
t.next_quarter             # => 2010-08-08 00:00:00 +0300
```

該当する日付が存在しない場合、対応する月の最終日を返します。

```ruby
Time.local(2000, 7, 31).prev_quarter  # => 2000-04-30 00:00:00 +0300
Time.local(2000, 5, 31).prev_quarter  # => 2000-02-29 00:00:00 +0200
Time.local(2000, 10, 31).prev_quarter # => 2000-07-31 00:00:00 +0300
Time.local(2000, 11, 31).next_quarter # => 2001-03-01 00:00:00 +0200
```

[`last_quarter`][DateAndTime::Calculations#last_quarter]は`prev_quarter`のエイリアスです。

NOTE: 定義は[`active_support/core_ext/date_and_time/calculations.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/date_and_time/calculations.rb)にあります。

[DateAndTime::Calculations#last_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-last_quarter
[DateAndTime::Calculations#next_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-next_quarter
[DateAndTime::Calculations#prev_quarter]: https://api.rubyonrails.org/classes/DateAndTime/Calculations.html#method-i-prev_quarter

### 時間コンストラクタ

Active Supportの[`Time.current`][Time.current]の定義は、ユーザータイムゾーンが定義されている場合は`Time.zone.now`となり、定義されていない場合は`Time.now`にフォールバックします。

<!-- メモ: 実際にこうなっている
   def current
     ::Time.zone ? ::Time.zone.now : ::Time.now
   end
-->

```ruby
Time.zone_default
# => #<ActiveSupport::TimeZone:0x7f73654d4f38 @utc_offset=nil, @name="Madrid", ...>
Time.current
# => Fri, 06 Aug 2010 17:11:58 CEST +02:00
```

`DateTime`と同様、述語メソッド[`past?`][DateAndTime::Calculations#past?]と[`future?`][DateAndTime::Calculations#future?]は`Time.current`を起点とします。

構成される時間が、実行プラットフォームの`Time`でサポートされる範囲を超えている場合は、usec（マイクロ秒）は破棄され、`DateTime`オブジェクトが代わりに返されます。

#### 期間（duration）

[`Duration`][ActiveSupport::Duration]オブジェクトは、Timeオブジェクトに対して期間を加減算できます。

```ruby
now = Time.current
# => Mon, 09 Aug 2010 23:20:05 UTC +00:00
now + 1.year
# => Tue, 09 Aug 2011 23:21:11 UTC +00:00
now - 1.week
# => Mon, 02 Aug 2010 23:21:11 UTC +00:00
```

これらの計算は、内部で`since`メソッドや`advance`メソッドに置き換えられます。たとえば、作り直したカレンダー内で正しくジャンプできます。

```ruby
Time.utc(1582, 10, 3) + 5.days
# => Mon Oct 18 00:00:00 UTC 1582
```

`File`の拡張
--------------------

### `atomic_write`

[`File.atomic_write`][File.atomic_write]クラスメソッドを使うと、書きかけのコンテンツを誰にも読まれないようにファイルを保存できます。

このメソッドにファイル名を引数として渡すと、書き込み用にオープンされたファイルハンドルを生成します。ブロックが完了すると、`atomic_write`はファイルハンドルをクローズして処理を完了します。

Action Packは、このメソッドを利用して`all.css`などのキャッシュファイルへの書き込みを行ないます。

```ruby
File.atomic_write(joined_asset_path) do |cache|
  cache.write(join_asset_file_contents(asset_paths))
end
```

これを行うために、`atomic_write`は一時的なファイルを作成します。ブロック内のコードが実際に書き込むのはこのファイルです。この一時ファイルは完了時にリネームされます。リネームは、POSIXシステムのアトミック操作に基いて行われます。書き込み対象ファイルが既に存在する場合、`atomic_write`はそれを上書きしてオーナーとパーミッションを維持します。ただし、`atomic_write`メソッドがファイルのオーナーシップとパーミッションを変更できないケースがまれにあります。このエラーはキャッチされ、そのファイルがそれを必要とするプロセスからアクセスできるようにするために、ユーザーとファイルシステムを信頼してスキップします。

NOTE: `atomic_write`が行なうchmod操作が原因で、書き込み対象ファイルにACL（Access Control List）が設定されている場合は、ACLが再計算/変更されます。

WARNING: `atomic_write`は追記を行えません。

この補助ファイルは標準の一時ファイル用ディレクトリに書き込まれますが、第2引数でディレクトリを直接指定することもできます。

NOTE: 定義は[`active_support/core_ext/file/atomic.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/file/atomic.rb)にあります。

[File.atomic_write]: https://api.rubyonrails.org/classes/File.html#method-c-atomic_write

`NameError`の拡張
-------------------------

Active Supportは`NameError`に[`missing_name?`][NameError#missing_name?]メソッドを追加します。このメソッドは、引数として渡された名前が原因で例外が発生するかどうかをテストします。

渡される名前はシンボルまたは文字列です。シンボルを渡した場合は単なる定数名をテストし、文字列を渡した場合はフルパス (完全修飾) の定数名をテストします。

TIP: シンボルは、`:"ActiveRecord::Base"`で行なっているのと同じようにフルパスの定数として表せます。シンボルがそのように動作するのは利便性のためであり、技術的に必要だからではありません。

たとえば、`ArticlesController`のアクションが呼び出されると、Railsはその名前からすぐに推測できる`ArticleHelper`を使おうとします。ここではこのヘルパーモジュールが存在していなくても問題はないので、この定数名で例外が発生しても例外として扱わずに黙殺する必要があります。しかし、実際に不明な定数が原因で`articles_helper.rb`が`NameError`エラーを発生するという場合が考えられます。そのような場合は、改めて例外を発生させなくてはなりません。`missing_name?`メソッドは、この2つの場合を区別するために使われます。

```ruby
def default_helper_module!
  module_name = name.sub(/Controller$/, '')
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

NOTE: 定義は[`active_support/core_ext/name_error.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/name_error.rb)にあります。

[NameError#missing_name?]: https://api.rubyonrails.org/classes/NameError.html#method-i-missing_name-3F

`LoadError`の拡張
-------------------------

Active Supportは[`is_missing?`][LoadError#is_missing?]を`LoadError`に追加します。

`is_missing?`は、パス名を引数に取り、特定のファイルが原因で例外が発生するかどうかをテストします (".rb"拡張子が原因と思われる場合を除きます)。

たとえば、`ArticlesController`のアクションが呼び出されると、Railsは`articles_helper.rb`を読み込もうとしますが、このファイルは存在しないことがあります。ヘルパーモジュールは必須ではないので、Railsは読み込みエラーを例外扱いせずに黙殺します。しかし、ヘルパーモジュールが存在しないために別のライブラリが必要になり、それがさらに見つからないという場合が考えられます。Railsはそのような場合には例外を再発生させなければなりません。`is_missing?`メソッドは、この2つの場合を区別するために使われます。

```ruby
def default_helper_module!
  module_name = name.sub(/Controller$/, '')
  module_path = module_name.underscore
  helper module_path
rescue LoadError => e
  raise e unless e.is_missing? "helpers/#{module_path}_helper"
rescue NameError => e
  raise e unless e.missing_name? "#{module_name}Helper"
end
```

NOTE: 定義は[`active_support/core_ext/load_error.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/load_error.rb)にあります。

[LoadError#is_missing?]: https://api.rubyonrails.org/classes/LoadError.html#method-i-is_missing-3F

`Pathname`の拡張
-------------------------

### `existence`

[`existence`][Pathname#existence]メソッドは、名前付きファイルが存在する場合はレシーバーを返し、存在しない場合は`nil`を返します。これは、以下のような定番のファイル読み出しで便利です。

```ruby
content = Pathname.new("file").existence&.read
```

NOTE: 定義は[`active_support/core_ext/pathname/existence.rb`](https://github.com/rails/rails/blob/7-1-stable/activesupport/lib/active_support/core_ext/pathname/existence.rb)にあります。

[Pathname#existence]: https://api.rubyonrails.org/classes/Pathname.html#method-i-existence
