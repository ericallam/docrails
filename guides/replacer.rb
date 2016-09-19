#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

REPLACE_LIST = {}

# DSL
# `from`, `to` could be string or regex.
def replace(target:, from:, to:)
  actual_target = "./source/ja/#{target}"
  REPLACE_LIST[actual_target] = [] unless REPLACE_LIST[actual_target]
  REPLACE_LIST[actual_target] << [from, to]
end

def delete(target:, from:)
  replace(target: target, from: from, to: "")
end

replace target: "active_record_basics.md", from: "rake", to: "bin/rails"
replace target: "active_record_migrations.md", from: "rake", to: "bin/rails"
replace target: "asset_pipeline.md", from: "rakeタスク", to: "タスク"
replace target: "asset_pipeline.md", from: "rake", to: "bin/rails"
replace target: "configuring.md", from: "rakeタスク", to: "タスク"
replace target: "configuring.md", from: "rake", to: "bin/rails"
replace target: "engines.md", from: "rake", to: "bin/rails"
replace target: "getting_started.md", from: "rakeコマンド", to: "コマンド"
replace target: "getting_started.md", from: "rake", to: "bin/rails"

REMOVED_PRAG = <<-EOD
Railsには、rakeコマンドラインユーティリティを使用して生成できるビルトインヘルプもあります。   

* `rake doc:guides`を実行すると、本Railsガイドの完全なコピーがアプリケーションの`doc/guides`フォルダに生成されます。ブラウザで`doc/guides/index.html`を開くことでガイドを参照できます。   
* `rake doc:rails`を実行すると、Rails APIドキュメントの完全なコピーがアプリケーションの`doc/api`フォルダに生成されます。ブラウザで`doc/api/index.html`を開いてAPIドキュメントを参照できます。    

TIP: `doc:guides` rakeタスクを使用してRailsガイドをローカル生成するには、RedCloth gemをインストールする必要があります。RedCloth gemを`Gemfile`に追記して`bundle install`を実行することで利用できるようになります。
EOD

delete target: "getting_started.md", from: REMOVED_PRAG
replace target: "rails_application_templates.md", from: "bin/rake", to: "bin/rails"
replace target: "rails_application_templates.md", from: "rails:template", to: "app:template"
replace target: "testing.md", from: "rakeタスク", to: "タスク"

# Replace sentences which have opportunity
Dir.glob(["./source/ja/*.md", "./source/ja/*.yaml"]) do |filename|
  text = File.read(filename)

  # Global replacement
  unless %w(release_notes upgrading_ruby_on_rails).any? { |s| filename.include? s }
    text.gsub! "bin/rake", "bin/rails"
  end

  # Chapter-specific replacement
  case filename
  when 'active_record_basics.md'
    text.gsub! "rake", "bin/rails"
  when 'active_record_migrations.md'
  when 'asset_pipeline.md'
  when 'command_line.md'
  when 'configuring.md'
  when 'engines.md'
  when 'getting_started.md'
  when 'plugins.md'
  when 'rails_application_templates.md'
  when 'rails_on_rack.md'
  when 'testing.md'
  end

  if REPLACE_LIST[filename]
    REPLACE_LIST[filename].each do |(from, to)|
      text.gsub!(from, to)
    end
  end

  File.write(filename, text)
end

