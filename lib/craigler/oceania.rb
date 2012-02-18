module Craigler
  module OCEANIA
    STATES = { :australia => [:adelaide, :brisbane, :cairns, :canberra, :darwin, :goldcoast, :hobart, :melbourne, :ntl, :perth, :sydney, :wollongong]
             , :new_zealand => [:auckland, :christchurch, :dunedin, :wellington]
             }

    class << self
      # Alternate interface to {Search#initialize}
      #
      # @param category [Symbol] the category to search
      # @param options [Hash] options passed to {Search#initialize}.
      def search(category, options = {})
        options = options.merge({ :only => category })
        results = Search.new(options.delete(:for), options).results()
        results.each {|result| yield(result) } if block_given?
        results
      end

      # Wrapper for {Search#initialize}
      #
      # @param (see Search#initialize)
      def find(search_term, options = {})
        results = Search.new(search_term, options).results()
        results.each {|result| yield(result) } if block_given?
        results
      end
    end
  end
end
