require 'erb'

module Craigler
  class Search
    include ERB::Util
    
    attr_reader :search_term, :categories, :locations
    
    # Creates a wrapper object for a craigslist search
    #
    # === Options
    # [:in]
    #   Specifies the location(s) to search in. Defaults to <tt>:anywhere</tt>.
    # [:only]
    #   Specifies the category or categories to search in. Defaults to <tt>:all_for_sale_or_wanted</tt>
    def initialize(search_term, options = {})
      raise InvalidSearchTerm if search_term.nil? || search_term == ''
      
      @search_term = search_term
      @results     = nil
      _parse_options(options)
    end
    
    # Returns the results of the search. If this is the first time
    # calling #results then they will be fetched over the internet and cached in the search object.
    #
    # === Options
    # [:page_limit]
    #   Maximum number of pages to fetch results from. Defaults to <tt>4</tt>.
    #   <b>Note:</b> A location may, and often does, have more than one searchable
    #   url assciated with it, e.g., {California}[http://geo.craigslist.org/iso/us/ca]. Because
    #   <tt>:page_limit</tt> is applied seperately to each url within the location, searching <tt>:in => :california</tt>
    #   with a <tt>:page_limit => 4</tt> could potentially make up to 100 page requests.</em>
    # [:refresh]
    #   Set to <tt>true</tt> to force an update across the internet.
    def results(options = {})
      options = { :page_limit => 4, :refresh => false }.merge(options)
      return @results unless @results.nil? || options[:refresh]
      
      @results  = []
      last_page = options[:page_limit] - 1 # pages start at 0
      
      _for_each_locations_search_url() do |location, url|
        (0..last_page).each do |page|
          results = _extract_items_from_url(location, "#{url}&s=#{page*25}")
          @results.push(*results)
          break if results.size < RESULTS_PER_PAGE
        end
      end
      
      results
    end
    
    private
    def _parse_options(options)
      options     = {:in => LOCATIONS.keys, :only => :all_for_sale_or_wanted}.merge(options)
      @locations  = options[:in].is_a?(Array) ? options[:in] : [options[:in]]
      @categories = options[:only].is_a?(Array) ? options[:only] : [options[:only]] 
      
      @locations.each() do |location|
        raise InvalidLocation unless location == :anywhere || LOCATIONS.key?(location)
      end
      
      @categories.each() do |category|
        raise InvalidCategory unless category == :all_for_sale_or_wanted || CATEGORIES.key?(category)
      end
    end
    
    def _for_each_locations_search_url()
      @locations.each do |location|
        LOCATIONS[location].each do |url|
          @categories.each do |category|
            yield(location, "#{url}search/#{CATEGORIES[category]}?query=#{url_encode(@search_term)}&format=rss")
          end
        end
      end
    end
    
    def _extract_items_from_url(location, url)
      (Hpricot(open(url))/'item').collect { |item| {
        :url          => item['rdf:about'],
        :title        => (item%'title').inner_text,
        :location     => location.to_s,
        :published_at => Time.parse((item%'dc:date').inner_text)
      }}
    end
  end
end