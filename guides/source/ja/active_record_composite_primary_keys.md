Active Record の複合主キー
======================

このガイドでは、データベーステーブルで利用できる複合主キー（composite primary keys）について紹介します。

このガイドの内容:

* 複合主キーを持つテーブルを作成する
* 複合主キーでモデルのクエリを実行する
* モデルのクエリや関連付けで複合主キーを利用できるようにする
* 複合主キーを使っているモデル用のフォームを作成する
* コントローラのパラメータから複合主キーを抽出する
* 複合主キーがあるテーブルでデータベースフィクスチャを利用する

--------------------------------------------------------------------------------

複合主キーについて
--------------------------------

テーブルのすべての行を一意に識別するために単一のカラム値だけでは不十分な場合、2つ以上のカラムの組み合わせが必要になることがあります。このような状況は、主キーとして単一の`id`カラムを持たないレガシーなデータベーススキーマを使わなければならない場合や、シャーディング/マルチテナンシー向けにスキーマを変更する場合に該当します。

複合主キーを導入すると複雑になり、単一の主キーカラムよりも遅くなる可能性があります。複合主キーを使う前に、そのユースケースでどうしても必要であることを確認しておきましょう。

複合主キーのマイグレーション
--------------------------------

`create_table`に`:primary_key`オプションで配列の値を渡すことで、複合主キーを持つテーブルを作成できます。

```ruby
class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products, primary_key: [:store_id, :sku] do |t|
      t.integer :store_id
      t.string :sku
      t.text :description
    end
  end
end
```

モデルへのクエリ
---------------

### `#find`の場合

テーブルで複合主キーを使っている場合は、レコードを[`#find`][`find`]で検索するときに配列を渡す必要があります。

```irb
# productを「store_id 3」と「sku "XYZ12345"」で検索する
irb> product = Product.find([3, "XYZ12345"])
=> #<Product store_id: 3, sku: "XYZ12345", description: "Yellow socks">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM products WHERE store_id = 3 AND sku = "XYZ12345"
```

複合IDで複数のレコードを検索するには、`#find`に「配列の配列」を渡します。

```irb
# productsを主キー「[1, "ABC98765"]と[7, "ZZZ11111"]」で検索する
irb> products = Product.find([[1, "ABC98765"], [7, "ZZZ11111"]])
=> [
  #<Product store_id: 1, sku: "ABC98765", description: "Red Hat">,
  #<Product store_id: 7, sku: "ZZZ11111", description: "Green Pants">
]
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM products WHERE (store_id = 1 AND sku = 'ABC98765' OR store_id = 7 AND sku = 'ZZZ11111')
```

複合主キーを持つモデルは、ORDER BY（順序付け）でも複合主キー全体を使います。


```irb
irb> product = Product.first
=> #<Product store_id: 1, sku: "ABC98765", description: "Red Hat">
```

上と同等のSQLは以下のようになります。

```sql
SELECT * FROM products ORDER BY products.store_id ASC, products.sku ASC LIMIT 1
```

### `#where`の場合

[`#where`][`where`]では、以下のようにタプル的な構文でハッシュ条件を指定できます。
これは、複合主キーのリレーションでクエリを実行するときに便利です。

```ruby
Product.where(Product.primary_key => [[1, "ABC98765"], [7, "ZZZ11111"]])
```

#### 条件で`:id`を指定する場合

[`find_by`][]や[`where`][]などのメソッドで条件を指定するときに`id`を使うと、モデルの`:id`属性と一致します（これは、渡すIDが主キーでなければならない[`find`][]と異なります）。

`:id`が主キー**でない**モデル（複合主キーを使っているモデルなど）で`find_by(id:)`を使う場合は注意が必要です。詳しくは[Active Recordクエリガイド][Active Record Querying]を参照してください。

[`find_by`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find_by
[`where`]: https://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-where
[`find`]: https://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html#method-i-find

[Active Record Querying]: active_record_querying.html#条件をidで指定する

複合主キーを持つモデルの関連付け
-------------------------------------------------------

Railsは多くの場合、追加情報を必要とせずに、複合主キーをモデル間の関連付けで「主キー〜外部キー」情報を推論できます。以下の例をご覧ください。

```ruby
class Order < ApplicationRecord
  self.primary_key = [:shop_id, :id]
  has_many :books
end

class Book < ApplicationRecord
  belongs_to :order
end
```

ここでRailsは、1件のorder（注文）とそのbooks（本）の関連付けの主キーに`:id`カラムが使われると仮定します。これは、通常の`has_many`関連付けや`belongs_to`関連付けと同様です。Railsは、`books`テーブル上の外部キーカラムが`:order_id`であると推測します。
ある本の注文に、以下のようにアクセスするとします。

```ruby
order = Order.create!(id: [1, 2], status: "pending")
book = order.books.create!(title: "A Cool Book")

book.reload.order
```

この場合、以下のSQLを生成してorderにアクセスします。

```sql
SELECT * FROM orders WHERE id = 2
```

これが期待通りに動作するのは、このモデルの複合主キーに`:id`カラムが含まれており、かつ`:id`カラムがすべてのレコードで一意である場合だけです。関連付けで完全な複合主キーを使うには、その関連付けで`query_constraints`オプションを設定してください。このオプションは、関連付けられるレコードをクエリするときに複合外部キーを指定します。例:

```ruby
class Author < ApplicationRecord
  self.primary_key = [:first_name, :last_name]
  has_many :books, query_constraints: [:first_name, :last_name]
end

class Book < ApplicationRecord
  belongs_to :author, query_constraints: [:author_first_name, :author_last_name]
end
```

以下のように、ある本のauthor（著者）にアクセスするとします。

```ruby
author = Author.create!(first_name: "Jane", last_name: "Doe")
book = author.books.create!(title: "A Cool Book")

book.reload.author
```

この場合、以下のようにSQLクエリで`:first_name`と`:last_name`が使われます。

```sql
SELECT * FROM authors WHERE first_name = 'Jane' AND last_name = 'Doe'
```

複合主キーを使うフォーム
---------------------------

複合主キーを持つモデルでもフォームを作成できます。フォームビルダー構文について詳しくは、[フォームヘルパーガイド][Form Helpers]を参照してください。

[Form Helpers]: form_helpers.html

複合主キー`[:author_id, :id]`を持つ`@book`モデルオブジェクトの場合を例にします。

```ruby
@book = Book.find([2, 25])
# => #<Book id: 25, title: "Some book", author_id: 2>
```

以下のフォームを作成します。

```erb
<%= form_with model: @book do |form| %>
  <%= form.text_field :title %>
  <%= form.submit %>
<% end %>
```

出力は以下のようになります。

```html
<form action="/books/2_25" method="post" accept-charset="UTF-8" >
  <input name="authenticity_token" type="hidden" value="..." />
  <input type="text" name="book[title]" id="book_title" value="My book" />
  <input type="submit" name="commit" value="Update Book" data-disable-with="Update Book">
</form>
```

生成されたURLには、`author_id`と`id`がアンダースコア区切りの形で含まれていることにご注目ください。
送信後、コントローラーはパラメータから主キーの値を抽出して、単一の主キーと同様にレコードを更新できます。詳しくは次のセクションを参照してください。

複合主キーのパラメータ
------------------------

れているため、各値を抽出してActive Recordに渡す必要があります。このユースケースでは、`extract_value`メソッドを活用できます。

以下のコントローラがあるとします。

```ruby
class BooksController < ApplicationController
  def show
    # URLパラメータから複合ID値を抽出する
    id = params.extract_value(:id)
    # この複合IDでbookを検索する
    @book = Book.find(id)
    # デフォルトのレンダリング動作でビューを表示する
  end
end
```

ルーティングは以下のようになっているとします。

```ruby
get '/books/:id', to: 'books#show'
```

ユーザーがURL `/books/4_2`を開くと、コントローラは複合主キーの値`["4", "2"]`を抽出して`Book.find`に渡し、ビューで正しいレコードを表示します。`extract_value`メソッドは、区切られた任意のパラメータから配列を抽出するのに利用できます。

複合主キーのフィクスチャ
------------------------------

複合主キーテーブル用のフィクスチャは、通常のテーブルとかなり似ています。
idカラムを使う場合は、通常と同様にカラムを省略できます。

```ruby
class Book < ApplicationRecord
  self.primary_key = [:author_id, :id]
  belongs_to :author
end
```

```yml
# books.yml
alices_adventure_in_wonderland:
  author_id: <%= ActiveRecord::FixtureSet.identify(:lewis_carroll) %>
  title: "Alice's Adventures in Wonderland"
```

ただし、フィクスチャで複合主キーのリレーションシップをサポートするには、以下のように`composite_identify`メソッドを使わなければなりません。

```ruby
class BookOrder < ApplicationRecord
  self.primary_key = [:shop_id, :id]
  belongs_to :order, query_constraints: [:shop_id, :order_id]
  belongs_to :book, query_constraints: [:author_id, :book_id]
end
```

```yml
# book_orders.yml
alices_adventure_in_wonderland_in_books:
  author: lewis_carroll
  book_id: <%= ActiveRecord::FixtureSet.composite_identify(
              :alices_adventure_in_wonderland, Book.primary_key)[:id] %>
  shop: book_store
  order_id: <%= ActiveRecord::FixtureSet.composite_identify(
              :books, Order.primary_key)[:id] %>
```
