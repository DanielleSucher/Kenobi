# Scraper to grab a user's Ask Metafilter answers and fav counts

$:.unshift File.expand_path('.')
require 'sqlite3'
require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'openssl'

class AskMeAnswerScraper
    attr_accessor :should_answer_training, :should_not_answer_training

    def initialize
        @agent = Mechanize.new
        @agent.ca_file = "cacert.pem" 
        @should_answer_training = []
        @should_not_answer_training = []
        @askme_answer_page_urls = []
    end

    def scrape_question_text(page)
        html = page.parser
        div = html.css('div.copy').first
        content = div.text.split(/$/)
        if content[1].include?("favorites")
            content = content[0].split("posted by")[0]
        else
            content = content[2].gsub(/\n|\r/,"")
        end
    end

    def parse_askme_answers
        # Parse the mechanize object
        html = @page.parser

        # collect the title of each question
        divs = html.css('div.copy')
        divs.pop #removes the next_page div from the end
        question_links = []
        divs.each do |div|
            question_links << div.search('a')
        end

        # adds the above-the-cut text of each question to the questions array
        questions = []
        divs.each_with_index do |div,i|
            question_page = @agent.click(@page.link_with(:href => question_links[i][0]["href"]))
            content = self.scrape_question_text(question_page)
            questions << content
        end

        # in each of those divs, each blockquote holds one answer
        blockquotes = {}
        divs.each_with_index do |div,i|
            # answers = div.search('blockquote').text.gsub(/\r\n\s{2,}/," ").gsub(/\r\n/,"")
            blockquotes[i] = div.search('blockquote')
        end
        
        # Now get the vote count for each div/question/answer 
            # (what does this do when a user has multiple answers with favs to one question?)
        fav_counts = {}
        blockquotes.each do |key,val|
            fav_counts[key] = val.css('span[id *= "favcnt"]').text.gsub(/\D/,"").to_i
        end

        # Add questions with vote counts > 2 to @should_answer_training and the rest to @should_not_answer_training
            # Consider changing the cutoff later
        questions.each_with_index do |question,i|
            if fav_counts[i] > 2
                @should_answer_training << question
            else
                @should_not_answer_training << question
            end
        end
    end

    def collect_urls
        # adds url for each page of the user's askme answers to the array of urls
        html = Nokogiri::HTML(open(@url))
        pages = []
        html.css('div[style="margin-left:30px;"] > a').each do |a|
            next_url = "/activity/#{@user_id}/comments/ask/" + a.text
            @askme_answer_page_urls << next_url
        end
    end

    def prep_for_scraping_answers
        # Dave, for example: 106020
        puts "What's the user id of the user for whom you're trying to pick out good questions?"
        print ">> "
        @user_id = $stdin.gets.chomp

        @url="http://www.metafilter.com/activity/#{@user_id}/comments/ask/" 

        # create array of urls for the rest of the user's askme answer pages
       self.collect_urls
    end

    def login_to_scrape_answers
    # Use Mechanize to connect securely 
        @page = @agent.get(@url)
        @page = @agent.click(@page.link_with(:text => "Login"))

        # You have to log in before scraping in order to be able to see favcnt spans
        login_form = @page.form_with( :action => 'logging-in.mefi')
        puts "You have to log in before scraping in order to be able to see how many favorites people's answers have received."
        puts "Kenobi uses Mechanize and SSL and doesn't save your login info anywhere."
        puts "If you're nervous, feel free to temporarily change your Metafilter password just while training Kenobi."
        puts "Don't worry, we'll wait!"
        puts "What is your Metafilter username?"
        print ">> "
        @user_name = $stdin.gets.chomp
        puts "What is your Metafilter password?"
        print ">> "
        @user_pass = $stdin.gets.chomp
        login_form.user_name = @user_name
        login_form.user_pass = @user_pass
        @page = @agent.submit(login_form, login_form.buttons.first)
    end

    def scrape_logged_in
        # do the prep work
        self.prep_for_scraping_answers
        self.login_to_scrape_answers
        # Parse the first page of answers
        @page = @agent.click(@page.link_with(:text => "Click here"))
        self.parse_askme_answers
        # Parse the remaining pages of answers
        # @askme_answer_page_urls.each do |url|
        #     @page = @agent.click(page.link_with(:href => url))
        #     self.parse_askme_answers(@page)
        # end
    end
end