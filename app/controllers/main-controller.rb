require 'groonga/client'

Epub::App.controllers do

  layout :layout
  get :index do
    query_words = params[:q]

    right_query = query_words && !query_words.empty?
    if right_query
      hit_records = search_from_groonga(query_words)

      @results = Array.new
      hit_records.each do |record|
        @results << record
      end
    end

    render 'index'
  end

end

def search_from_groonga(query_words)
  records = nil
  Groonga::Client.open do |client|
    select = client.select(
      :table => :Books,
      :query => query_words,
      :match_columns => 'author,title,main_text',
      :output_columns => 'author,title,snippet_html(main_text)',
      :command_version => 2,
    )
    records = select.records
  end
  records
end
