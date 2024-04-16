# frozen_string_literal: true
module Oclc
  module LcCallSlips
    # This class is responsible for searching a given
    # Marc::DataField for the keywords that a selector
    # is interested in.
    class KeywordField
      def initialize(field:, keywords:)
        @field = field
        @keywords = keywords
      end

      def match?
        keyword_field? && field_contains_keywords?
      end

      private

      attr_reader :field, :keywords

      def keyword_field?
        field.is_a?(MARC::DataField) && field.tag.match?(/^[12578]/)
      end

      def field_contains_keywords?
        field.any? { |subfield| subfield_contains_keywords?(subfield) }
      end

      def subfield_contains_keywords?(subfield)
        words_in_subfield = subfield.value.split(' ')
        words_in_subfield.any? { |found_word| word_is_keyword? found_word }
      end

      def word_is_keyword?(word)
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
