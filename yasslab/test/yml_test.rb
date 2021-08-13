require 'test/unit'

class TestYaml < MiniTest::Unit::TestCase
  def test_exists_documents_yaml
    assert(File.exists?('./guides/source/ja/documents.yaml', true))
  end

  def test_load_yaml
    assert_nothing_raised do
      Psych.load_file('./guides/source/ja/documents.yaml')
    end
  end
end
