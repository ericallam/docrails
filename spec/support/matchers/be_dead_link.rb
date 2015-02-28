require 'uri'

# cf: https://gist.github.com/hanachin/9968957
RSpec::Matchers.define :be_dead_fragment do |page, original_page_path=nil|
  define_method :id_from_link do |link|
    _, fragment = link[:href].split("#", 2)
    id = URI.unescape(fragment)
  end

  match do |link|
    begin
      !page.find_by_id(id_from_link(link))
    rescue
      true
    end
  end

  failure_message_when_negated do |link|
    if original_page_path
      "Link(id: #{id_from_link(link)}, text: #{link.text}, original_page_path: #{original_page_path}) is dead fragment"
    else
      "Link(id: #{id_from_link(link)}, text: #{link.text}) is dead fragment"
    end
  end

  failure_message do |link|
    if original_page_path
      "Link(id: #{id_from_link(link)}, text: #{link.text}, original_page_path: #{original_page_path}) is not dead fragment"
    else
      "Link(id: #{id_from_link(link)}, text: #{link.text}) is not dead fragment"
    end
  end
end
