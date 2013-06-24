require 'fileutils'

module EPUBSearcher
  class Database
    def initialize
      @db_path = nil
    end

    def create_command_open_db
      command = 'groonga'
      if !File.exists?(db_path)
        command << ' -n'
      end
      command << ' ' + db_path
      return command
    end

    def db_path
      @db_path || File.join(__dir__, '..', '..', 'db', 'epub-searcher.db')
    end

    def db_path=(path)
      @db_path = path
    end

    def setup_database
      FileUtils.mkdir_p(File.dirname(db_path))

      piped_stdin, stdin = IO.pipe
      pid = spawn(create_command_open_db, :in => piped_stdin, :out => '/dev/null')
      stdin.write(create_groonga_command_setup_database)
      stdin.flush
      stdin.close

      Process.waitpid pid
    end

    private
    def create_groonga_command_setup_database
      <<EOS
table_create Books TABLE_NO_KEY
column_create Books author COLUMN_SCALAR ShortText
column_create Books main_text COLUMN_SCALAR LongText
column_create Books title COLUMN_SCALAR ShortText
EOS
    end
  end
end

