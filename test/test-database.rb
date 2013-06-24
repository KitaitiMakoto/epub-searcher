require 'test-unit'

require 'epub/parser'
require 'epub-searcher/database'

class TestDatabase < Test::Unit::TestCase
  class TestGroonga < self
    def setup
      @database = EPUBSearcher::Database.new
      @database.db_path = db_path
      remove_db_directory
    end

    def teardown
      remove_db_directory
    end

    def remove_db_directory
      FileUtils.rm_rf(File.dirname(@database.db_path))
    end

    def test_setup_database
      @database.setup_database

      dump_command = "groonga #{@database.db_path} dump"
      dumped_text = `#{dump_command}`

      expected = File.read(fixture_path('defined_schema_dump_expected.txt'))
      assert_equal(expected, dumped_text)
    end
  end

  private
  def fixture_path(basename)
    File.join(__dir__, 'fixtures', basename)
  end

  def db_path
    File.join(__dir__, 'tmp', 'db', 'epub-searcher.db')
  end
end
