step '表示されている内部リンクは、すべて有効である' do
  _, internal_links = all('a').partition {|link| link[:href].start_with? 'http' }
  fragment_links = internal_links.select {|link| link[:href] =~ /#/ }

  # ["#active-record-enums"], ["/asset_pipeline.html#css%E3%81%A8erb"]
  same_pages, other_pages = fragment_links.partition {|link| link[:href] =~ /\A#/ }

  same_pages.each do |link|
    expect(link).to_not be_dead_fragment(page)
  end

  other_pages.each do |link|
    file, _ = link[:href].split("#", 2)
    original_page_path = page.current_path
    visit file
    expect(link).to_not be_dead_fragment(page, original_page_path)
  end
end
