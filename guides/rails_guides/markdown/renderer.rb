# frozen_string_literal: true
require 'rouge'

module RailsGuides
  class Markdown
    class Renderer < Redcarpet::Render::HTML
      cattr_accessor :edge, :version

      def block_code(code, language)
        <<-HTML
<div class="code_container">
<pre class="highlight">
#{Rouge::Formatters::HTML.new.format(Rouge::Lexers.const_get(brush_for(language)).new.lex(code)).chop}
</pre>
</div>
HTML
      end

      def link(url, title, content)
        if /(^https|^http):\/\/api.rubyonrails.org/.match?(url)
          %(<a href="#{api_link(url)}">#{content}</a>)
        elsif title
          %(<a href="#{url}" title="#{title}">#{content}</a>)
        else
          %(<a href="#{url}">#{content}</a>)
        end
      end

      def header(text, header_level)
        # Always increase the heading level by 1, so we can use h1, h2 heading in the document
        header_level += 1

        %(<h#{header_level}>#{text}</h#{header_level}>)
      end

      def paragraph(text)
        if text =~ %r{^NOTE:\s+Defined\s+in\s+<code>(.*?)</code>\.?$}
          %(<div class="note"><p>Defined in <code><a href="#{github_file_url($1)}">#{$1}</a></code>.</p></div>)
        elsif text =~ /^(TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)[.:]/
          convert_notes(text)
        elsif text.include?("DO NOT READ THIS FILE ON GITHUB")
        elsif text =~ /^\[<sup>(\d+)\]:<\/sup> (.+)$/
          linkback = %(<a href="#footnote-#{$1}-ref"><sup>#{$1}</sup></a>)
          %(<p class="footnote" id="footnote-#{$1}">#{linkback} #{$2}</p>)
        else
          text = convert_footnotes(text)
          "<p>#{text}</p>"
        end
      end

      private

        def convert_footnotes(text)
          text.gsub(/\[<sup>(\d+)\]<\/sup>/i) do
            %(<sup class="footnote" id="footnote-#{$1}-ref">) +
              %(<a href="#footnote-#{$1}">#{$1}</a></sup>)
          end
        end

        def brush_for(code_type)
          case code_type
          when "ruby", "rb"
            "Ruby"
          when "js"
            "Javascript"
          when "sql"
            "SQL"
          when "erb", "html+erb"
            "ERB"
          when "html"
            "XML" # HTML is understood, but there are .xml rules in the CSS
          when "bash"
            "ConsoleLexer"
          else
            "PlainText"
          end
        end

        def convert_notes(body)
          # The following regexp detects special labels followed by a
          # paragraph, perhaps at the end of the document.
          #
          # It is important that we do not eat more than one newline
          # because formatting may be wrong otherwise. For example,
          # if a bulleted list follows, the first item is not rendered
          # as a list item, but as a paragraph starting with a plain
          # asterisk.
          body.gsub(/^(TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)[.:](.*?)(\n(?=\n)|\Z)/m) do
            css_class = \
              case $1
              when "CAUTION", "IMPORTANT"
                "warning"
              when "TIP"
                "info"
              else
                $1.downcase
              end
            %(<div class="#{css_class}"><p>#{$2.strip}</p></div>)
          end
        end

        def github_file_url(file_path)
          tree = version || edge

          root = file_path[%r{(\w+)/}, 1]
          path = \
            case root
            when "abstract_controller", "action_controller", "action_dispatch"
              "actionpack/lib/#{file_path}"
            when /\A(action|active)_/
              "#{root.sub("_", "")}/lib/#{file_path}"
            else
              file_path
            end

          "https://github.com/rails/rails/tree/#{tree}/#{path}"
        end

        def api_link(url)
          if url =~ %r{(^https|^http)://api\.rubyonrails\.org/v\d+\.}
            url
          elsif edge
            url.sub("api", "edgeapi")
          else
            url.sub(/(?<=\.org)/, "/#{version}")
          end
        end
    end
  end
end
