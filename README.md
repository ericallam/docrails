[![Build Status](https://travis-ci.org/yasslab/railsguides.jp.svg?branch=japanese)](https://travis-ci.org/yasslab/railsguides.jp)

## 日本語訳について 

本リポジトリは[Ruby on Rails Guides](http://guides.rubyonrails.org/)を日本語に訳したものです。   
Railsガイドでは、Railsの各機能の仕組みや最新の機能、リリース情報などがまとまっています。

Ruby on Rails ガイド   
http://railsguides.jp/

これからRailsを勉強する方は「Railsチュートリアル」がオススメです。   
Railsガイドと同様に、RailsチュートリアルもWeb版は無料で読めます :)

Ruby on Rails チュートリアル：実例を使ってRailsを学ぼう   
http://railstutorial.jp/


## フィードバックについて

本ガイドを読んで、誤字・脱字・誤訳などを見かけましたら、本リポジトリの [Issue](https://github.com/yasslab/railsguides.jp/issues) にてお気軽に報告して頂けると幸いです。「直接Pull Request を送りたい!」という場合には、下記の「翻訳の流れ」や「チャットルーム」を参照してください。

なお、原著レベルでの間違いを見つけましたら、[Railsのドキュメントに貢献する](http://railsguides.jp/contributing_to_ruby_on_rails.html#rails%E3%81%AE%E3%83%89%E3%82%AD%E3%83%A5%E3%83%A1%E3%83%B3%E3%83%88%E3%81%AB%E8%B2%A2%E7%8C%AE%E3%81%99%E3%82%8B) を参考にしてください。また、Railsガイドの生成方法については、[Railsガイドのガイドライン](http://railsguides.jp/ruby_on_rails_guides_guidelines.html)を参考にしてください。

本ガイドの品質向上に向けて、皆さまのご協力が得られれば幸いです。よろしくお願い致します。

## 継続的翻訳システムについて (段階的に移行中)

[![Railsガイドを支える継続的翻訳システム - SpeakerDeck](https://raw.githubusercontent.com/yasslab/railsguides.jp/japanese/images/continuous_translation_system.png)](https://speakerdeck.com/yasulab/continuous-translation-system-at-rwc2015)

本リポジトリの仕組みについては、上記のスライドで詳しく解説されています。    
本リポジトリにPull Requestを送付したい方は、下記の「翻訳の流れ」を参照してください。    
(特に④と⑤を見ておくとよいかもしれません)

### 翻訳の流れ (現在の構成)

![翻訳の流れ](https://raw.githubusercontent.com/yasslab/railsguides.jp/japanese/images/flow-of-translation.png)
参考: [[翻訳]Ruby on Rails 4.1リリース前にアップグレードガイドを先行翻訳した & 同じ翻訳を2回しないで済むようにした](http://techracho.bpsinc.jp/hachi8833/2014_03_28/16037)

### ①  原著との差分更新の方法
   - [bin/merge-upstream](https://github.com/yasslab/railsguides.jp/blob/japanese/bin/merge-upstream) を実行すると最新版が `guides/source` 内に取り込まれます。
   - 特に、原著を手元で確認したいとき、原著にPRを送付したいときに便利です。
   - 原著にPRを送るときは、事前に[Railsのドキュメントに貢献する](http://railsguides.jp/contributing_to_ruby_on_rails.html#rails%E3%81%AE%E3%83%89%E3%82%AD%E3%83%A5%E3%83%A1%E3%83%B3%E3%83%88%E3%81%AB%E8%B2%A2%E7%8C%AE%E3%81%99%E3%82%8B)に目を通しておくとよいです :)

### ②  GTTに最新のドキュメントをアップロードする

- Google Translator Toolkit: https://translate.google.com/toolkit/
- Markdownは対応してないので、必要に応じてファイル名を `hogehoge.md.txt` などに変更する。
- ※必ずRailsガイド用の翻訳メモリに結びつけること. (shared TM は使わない)
- cf. [翻訳メモリの使用 - Translate ヘルプ - Google Help](https://support.google.com/translate/toolkit/answer/147863?hl=ja)

**GTT は共有が面倒なので，エディタなどで `guides/source/ja` 内の Markdown ファイルを直接編集して Pull Request して頂いても大丈夫です :+1: その際は，@yasulab などが別途 GTT 上の翻訳メモリに訳文を格納します．**

### ③  GTT上で英語→日本語に翻訳する (訳文は翻訳メモリに格納)

- 詳細: [Google Translator Toolkitと翻訳メモリ(ノーカット版) : RubyWorld Conference 2013より](http://techracho.bpsinc.jp/hachi8833/2013_12_16/14889)
- GTTの使用方法や文体などに関しては[こちら](https://www.facebook.com/notes/ruby-on-rails-tutorial-%E7%BF%BB%E8%A8%B3%E3%82%B0%E3%83%AB%E3%83%BC%E3%83%97/google-translator-toolkit-gtt-%E3%81%AE%E4%BD%BF%E3%81%84%E6%96%B9/170100333166820)を参考にしてください。
- ※CSSの関係で、行頭が`(TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)[.:]`から始まる場合、`(TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)`は訳さないでください。

### ④  日本語のHTMLファイルの生成方法

1. `/guides` ディレクトリに移動する
2. Google Translator Toolkit から訳文のファイルをダウンロードする (要: ダウンロード権限)
3. [main.sh](https://github.com/yasslab/railsguides.jp/blob/japanese/guides/main.sh) を実行して、`archive.zip`の展開からHTML生成までの必要な処理します。例えば、
   - 適切なファイル名/拡張子に変換
   - [翻訳専用の特殊タグ](https://github.com/yasslab/railsguides.jp/wiki/%E7%BF%BB%E8%A8%B3%E3%81%AB%E9%96%A2%E3%81%99%E3%82%8BTIPS)の置換
   - MarkdownファイルからHTMLファイルを生成、など
   - 詳細は `main.sh` を参照してください

**※ Pull Request を送付する場合は `guides/source/ja` 以下の Markdown を直接修正してください** 

### ⑤  Herokuにデプロイ

- Commit が Push されたときに WebHook が飛び、Travis CI が走ります。
- Travis CIのtestがパスすれば、自動でHerokuにデプロイされます。
- 詳細: [Automatic deploys - Heroku Dev Center](https://devcenter.heroku.com/articles/github-integration#automatic-deploys)

## 協力者

- [@hachi8833](https://github.com/hachi8833) (共同発起人)
- [@yasulab](https://github.com/yasulab) (共同発起人)
- [@yui-knk](https://github.com/yui-knk) (コミッター)
- [@riseshia](https://github.com/riseshia) (コミッター)
- 他，[Issues](https://github.com/yasslab/railsguides.jp/issues?q=) や [Pull Request](https://github.com/yasslab/railsguides.jp/graphs/contributors)  を送ってくださった多くの方々.

and supported/sponsored by [YassLab](http://yasslab.jp/).

[![YassLab Logo](https://dl.dropboxusercontent.com/u/2819285/yasslab_logo_copy.png)](http://yasslab.jp)

### 協力者の相談部屋 (チャットルーム)

[idobata.io](https://idobata.io) の [yasslab/railsguides.jp](https://idobata.io/organizations/yasslab/rooms/railsguides/join_request/c89d1d3b-d6d1-4baa-9271-145fbd0c4734) 部屋にて，Rails ガイドに関する情報交換しています．   
覗いてみるだけの方も歓迎なので，是非お気軽に立ち寄ってみてください :D

[![井戸端会議の風景](https://raw.githubusercontent.com/yasslab/railsguides.jp/japanese/images/idobata-ss.png)](https://idobata.io/organizations/yasslab/rooms/railsguides/join_request/c89d1d3b-d6d1-4baa-9271-145fbd0c4734)

## ライセンス

[![CC BY-SA International](https://raw.githubusercontent.com/yasslab/railsguides.jp/japanese/images/CC-BY-SA.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.ja)

本ガイドは[クリエイティブ・コモンズ 表示-継承 4.0 国際](https://creativecommons.org/licenses/by-sa/4.0/deed.ja) (CC BY-SA 4.0) ライセンスに基づいて公開されています。

「Rails」および「Ruby on Rails」という名称、そして Rails のロゴは、David Heinemeier Hansson による登録商標で、すべての権利を有しています。

[Ruby on Rails](http://rubyonrails.org/)は[MITライセンス](http://www.opensource.org/licenses/MIT)に基づいて公開されています。
