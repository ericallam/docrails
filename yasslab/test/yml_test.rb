require 'test/unit'

class TestYaml < MiniTest::Unit::TestCase
  def test_yaml_load
    assert_nothing_raised do
      Psych.load_file('/home/shishi/dev/src/github.com/yasslab/railsguides.jp/guides/source/ja/documents.yaml')
    end
  end
end
