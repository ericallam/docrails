# -*- coding: utf-8 -*-
require 'nokogiri'
require 'cgi'

class Dash < Struct.new(:output_dir, :docset_filename)
  class << self
    def generate(output_dir, docset_filename)
      new(output_dir, docset_filename).generate
    end
  end

  def initialize(*)
    super
    self.output_dir = File.absolute_path(output_dir)
  end

  def generate
    puts "Output Dir: #{output_dir}"

    FileUtils.rm_r(docset_path) if Dir.exists? docset_path

    FileUtils.mkdir_p documents_dir
    build_info_plist
    initialize_sqlite
    copy_assets output_dir, documents_dir

    each_file_paths do |file_path|
      create_html_and_register_index(file_path)
    end
  end

  private

  def each_file_paths
    Dir.glob("#{output_dir}/*.html").each do|file_path|
      next if file_path =~ /release_notes.html\z/
      next if File.basename(file_path) =~ /\A_/
      yield file_path
    end
  end

  def contents_dir
    File.join(docset_path, 'Contents')
  end

  def resources_dir
    File.join(contents_dir, 'Resources')
  end

  def documents_dir
    File.join(resources_dir, 'Documents')
  end

  def docset_path
    File.join(output_dir, docset_filename)
  end

  def create_html_and_register_index(html_path)
    doc_name = File.basename(html_path)
    html_body = File.read(html_path)
    html_body.scan(/(<h[1-5]( [^>]+)?>(.*?)<\/h([1-5])>)/).each do |match|
      tag = match[0]
      name = ActionView::Base.full_sanitizer.sanitize(match[2])
      puts "Index: #{name}"
      hash = Digest::MD5.hexdigest name

      # Add Anchor to Header Tag
      html_body.sub!(tag, %{<a name="#{hash}"></a>#{tag}})

      # Add Search Index
      index_name = CGI.unescapeHTML(name).gsub("'"){ "''" }
      sqlite %{INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('#{index_name}', 'Guide', '#{doc_name}##{hash}');}
    end
    # relative
    html_body.gsub!('src="/images/', 'src="./images/')
    html_body.gsub!('href="/"', 'src="./index.html"')

    # Remove Navigation and Header
    doc = Nokogiri::HTML.parse(html_body, nil, 'utf-8')
    doc.search("#topNav").remove
    doc.search("#header").remove

    File.write("#{documents_dir}/#{doc_name}", doc.to_html)
  end

  def copy_assets(source_dir, destination_dir)
    %w{images stylesheets}.each do |dir|
      src = "#{source_dir}/#{dir}"
      dst = "#{destination_dir}/#{dir}"
      FileUtils.rm_r dst if Dir.exists? dst
      FileUtils.cp_r src, dst
    end
  end

  def initialize_sqlite
    @sqlite_db = "#{resources_dir}/docSet.dsidx"
    sqlite "DROP TABLE IF EXISTS searchIndex;"
    sqlite "CREATE TABLE IF NOT EXISTS searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"
    sqlite "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);"
  end

  def sqlite(query)
    `sqlite3  #{@sqlite_db} "#{query}"`
  end

  def build_info_plist
    File.write("#{contents_dir}/Info.plist", <<-HTML)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleIdentifier</key>
    <string>railsguidesjp</string>
    <key>CFBundleName</key>
    <string>Railsガイド</string>
    <key>DocSetPlatformFamily</key>
    <string>rails</string>
    <key>isDashDocset</key>
    <true/>
  </dict>
</plist>
    HTML
  end
end
