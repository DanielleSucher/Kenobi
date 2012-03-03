# Scraper to grab new AskMe questions

$:.unshift File.expand_path('.')
require 'sqlite3'
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

        # collect the relative url for each question
        question_links = []
        divs.each_with_index do |div,i|
             span = div.search('span').first
             span = span.search('a')[0]['href']
             question_links << span
        end

        # collect the text for each question
        divs.each_with_index do |div,i|
        	content = div.text
        	content = content.split("[more inside]")[0]
            @new_questions << { :content => content, :url => question_links[i] }
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
        self.parse_askme_questions(@url)
        # Parse the remaining pages of answers
        # @askme_answer_page_urls.each do |url|
        #     @page = @agent.click(page.link_with(:href => url))
        #     self.parse_askme_answers(@page)
        # end
    end
end

@test = AskMeQuestionScraper.new
@test.scrape
puts @test.new_questions[0]