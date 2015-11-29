# coding: utf-8
require 'json'
require 'droonga/plugin'

module Droonga
  module Plugins
    module EPUBCFI
      extend Plugin
      register 'epubcfi'

      class Adapter < Droonga::Adapter
        def adapt_input(input_message)
          if ['search', 'select'].include? input_message.type
            dispatch_search_input(input_message)
          end
        end

        def adapt_output(output_message)
          books_result = output_message.body['Books_result']
          attributes = books_result['attributes']
          index = attributes.index {|attribute|
            attribute['name'] == 'indices'
          }
          return unless index
          main_text_index = attributes.index {|attribute|
            attribute['name'] == 'main_text'
          }
          attributes.delete_at index
          # attributes.delete_at main_text_index
          attributes << {'name' => 'epubcfi()'}

          records = books_result['records']
          return unless records
          records.each do |record|
            record << calc_cfi('ユーザーエージェント', record[main_text_index], record[index])
            # [index, main_text_index].sort.reverse_each do |i|
              record.delete_at index
            # end
          end
        end

        private

        def dispatch_search_input(input_message)
          output_attributes = input_message.body['queries']['Books_result']['output']['attributes']
          generate_epubcfi = output_attributes.reject! {|column| column == 'epubcfi()'}
          return unless generate_epubcfi
          output_attributes << 'indices'
          output_attributes << 'main_text' unless output_attributes.include? 'main_text'

          output_attributes = input_message.body['queries']['Books_result']['output']['epubcfi'] = true
        end

        def calc_cfi(query, main_text, raw_json)
          offsets = []
          indices = JSON.load(raw_json).each_pair.with_object({}) {|(offset, index), indices|
            offset = offset.to_i
            offsets << offset
            index = index.each_pair.with_object({}) {|(o, data), index|
              index[o.to_i] = data
            }
            indices[offset] = index
          }
          query_pos = main_text.index(/#{Regexp.escape(query)}/i)
          return unless query_pos
          offset_index = offsets.reverse.bsearch {|offset| offset <= query_pos}
          index_on_spine = offsets.index(offset_index) # FIXME
          data = indices[offset_index]
          query_pos_from_body = query_pos - offset_index
          parent_path_offset = data.keys.reverse.bsearch {|offset| offset <= query_pos_from_body}
          character_offset = query_pos_from_body - parent_path_offset
          parent_path_data = data[parent_path_offset]

          cfi = 'epubcfi(/6' # <spine>
          cfi << "/#{(index_on_spine + 1)* 2}!" # <itemref>
          cfi << "/4" # <body>
          parent_path_data.each do |(type, offset, options)|
            if type == 'element'
              cfi << "/#{(offset + 1) * 2}"
            else
              # cfi << "/#{offset * 2 + 1}" # FIXME: BiB/i bug
            end
          end
          cfi << ":#{character_offset}"
          cfi << ')'
        end
      end
    end
  end
end
