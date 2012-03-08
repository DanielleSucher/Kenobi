# Scraper to grab new AskMe questions

$:.unshift File.expand_path('.')
require 'open-uri'
require 'nokogiri'

class AskMeQuestionScraper
    attr_accessor :new_questions

    def initialize
        @new_questions = []
        @url="http://ask.metafilter.com"
    end

    def parse_askme_questions(url)
        # Parse an ASkMe new questions page
 		html = Nokogiri::HTML(open(url))

        # collect the divs of each question
        divs = html.css('div.post')

        divs.each_with_index do |div,i|
            # collect the relative url for each question
            span = div.search('span').first
            span = span.search('a')[0]['href']
            # collect the text for each question
        	content = div.text
        	content = content.split("[more inside]")[0]
            @new_questions << { :content => content, :url => span } unless span.include?('http://')
        end
    end

    def scrape_next_page(url)
        # adds url for the next page of older questions
        html = Nokogiri::HTML(open(url))
	        # Except that's the wrong css identifier still, need to change it
        next_link = html.search('p#navigation > a')
        next_link = next_link[0]['href']
        @next_page = @url + next_link
    end

    def scrape
        # Parse the first page of questions
        # puts "How many pages back do you want to analyze, after the front page?"
        # count = $stdin.gets.chomp.to_i
        self.parse_askme_questions(@url)
        # Parse the remaining pages of answers
        # @next_page = @url
        # count.times do
        	# self.scrape_next_page(@next_page)
        	# parse_askme_questions(@next_page)
        # end
    end
end