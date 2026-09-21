# frozen_string_literal: true
module Oclc
  module LcCallSlips
    # This class is responsible for searching a given
    # Marc::DataField for the keywords that a selector
    # is interested in.
    class KeywordField
      def match?(field:, keywords:)
        keyword_field?(field:) && field_contains_keywords?(field:, keywords:)
      end

      private

      def keyword_field?(field:)
        field.is_a?(MARC::DataField) && field.tag.match?(/^[12578]/)
      end

      def field_contains_keywords?(field:, keywords:)
        field.any? { |subfield| subfield_contains_keywords?(subfield:, keywords:) }
      end

      def subfield_contains_keywords?(subfield:, keywords:)
        words_in_subfield = subfield.value.split(' ')
        words_in_subfield.any? { |found_word| word_is_keyword?(found_word, keywords:) }
      end

      def word_is_keyword?(word, keywords:)
        keywords.any? do |desired_keyword|
          # Add ^ and $ to make sure that we match the whole world,
          # then turn the * wildcard into .*
          desired_keyword_as_regexp = Regexp.new('^' + desired_keyword.gsub('*', '.*') + '$', 'i')
          normalize(word).match? desired_keyword_as_regexp
        end
      end

      def normalize(word)
        word.sub(/[[:punct:]]?$/, '')
      end
    end
  end
end
