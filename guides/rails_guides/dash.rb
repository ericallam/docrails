require 'redcarpet'
require 'coderay'
require "cgi"

module Dash
  extend self

  def generate(source_dir, output_dir, out_dir, logfile, debug: false)
    @debug = debug
    html_body = ''
    file_name = 'asset_pipeline'

    docset_path = "#{output_dir}/#{out_dir}"
    FileUtils.rm_r(docset_path) if Dir.exists? docset_path
    @contents_dir = "#{docset_path}/Contents"
    @resources_dir = "#{@contents_dir}/Resources"
    @documents_dir = "#{@resources_dir}/Documents"

    FileUtils.mkdir_p @documents_dir
    build_info_plist
    initialize_sqlite

    Dir.chdir output_dir do
      Dir.glob("#{source_dir}/*.md").each do|file_path|
        next if file_path =~ /release_notes.md\z/
        doc_name = File.basename(file_path).sub(".md", "")

        File.open(file_path) do |file|
          html_body = create_html_and_register_index(file, doc_name)
        end

        build_html(doc_name, html_body)
      end
    end
  end

  def create_html_and_register_index(file, doc_name)
    # CodeBlock
    html_body = markdown.render(file.read.gsub("\r\n", "\n").gsub(/^(```)([a-z]{1,10})\n(.*?)\n```/m){|s|
      CodeRay.scan($3, $2).div
    })
    # Create Index <h1>..<h5>
    html_body.scan(/<h[1-5]>(.*)<\/h([1-5])>/).each do |attr|
      name   = attr.first
      header = attr.last
      plain_name = name.gsub(%r{</?code>}, '').gsub(%r{</?em>}, "")
      hash = Digest::MD5.hexdigest name
      # Add ID to Header
      html_body.sub!("<h#{header}>#{name}</h#{header}>", %{<h#{header} id="#{hash}">#{name}</h#{header}>})
      index_name = CGI.unescapeHTML(plain_name).gsub("'"){ "''" }
      cmd =%{INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{index_name}', 'Guide', '#{doc_name}.html##{hash}');}
      sqlite cmd
    end
    html_body
  end

  def markdown
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink: true, tables: true,
      fenced_code_blocks: true
    )
  end

  def initialize_sqlite
    @sqlite_db = "#{@resources_dir}/docSet.dsidx"
    sqlite "DROP TABLE IF EXISTS searchIndex;"
    sqlite "CREATE TABLE IF NOT EXISTS searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"
    sqlite "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);"
  end

  def sqlite(query)
    puts "[SQLite] #{query}" if @debug
    `sqlite3  #{@sqlite_db} "#{query}"`
  end

  def build_html(file_name, html_body)
    File.write("#{@documents_dir}/#{file_name}.html", <<-HTML)
<!doctype html>
<html class="no-js" lang="">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="x-ua-compatible" content="ie=edge">
    <title></title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="css/normalize.css">
    <link rel="stylesheet" href="css/main.css">
    <style type="text/css">
      pre {
        background: #002A35!important;
        color: #93A1A1!important;
        padding: 6px;
        border-radius: 2px;
      }
    </style>
  </head>
  <body> #{html_body} </body>
</html>
    HTML
  end

  def build_info_plist
    file = "#{@contents_dir}/Info.plist"
    File.delete if File.exists? file
    File.write(file, <<-HTML)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleIdentifier</key>
    <string>railsguides</string>
    <key>CFBundleName</key>
    <string>RailsGuides</string>
    <key>DocSetPlatformFamily</key>
    <string>railsguides</string>
    <key>isDashDocset</key>
    <true/>
  </dict>
</plist>
    HTML
  end
end

