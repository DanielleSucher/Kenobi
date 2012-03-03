# Scraper to grab a user's Ask Metafilter answers and fav counts

$:.unshift File.expand_path('.')
require 'sqlite3'
require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'openssl'

agent = Mechanize.new
agent.ca_file = "cacert.pem" 

def parse_askme_questions(page)
    # Parse the mechanize object
    page = page.parser

    # collect the title of each question
    divs = page.css('div.copy')
    divs.pop #removes the next_page div from the end
    question_links = []
    divs.each do |div|
        question_links << div.search('a')
    end
    questions = []
    question_links.each do |link|
        questions << link.first.text # adds the title of each question to the questions array
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
    questions.each_with_index do |question,i|
        if fav_counts[i] > 2
            @should_answer_training << question
        else
            @should_not_answer_training << question
        end
    end

    puts "Should answer: #{@should_answer_training}"
    puts "Should NOT answer: #{@should_not_answer_training}"
end

def collect_urls(url)
    # adds url for each page of the user's askme answers to the array of urls
    html = Nokogiri::HTML(open(url))
    pages = []
    html.css('div[style="margin-left:30px;"] > a').each do |a|
        next_url = "/activity/#{@user_id}/comments/ask/" + a.text
        @askme_answer_page_urls << next_url
    end
end

def prep_for_scraping_answers
    puts "What's the user id of the user for whom you're trying to pick out good questions?"
    print ">> "
    @user_id = $stdin.gets.chomp

    url="http://www.metafilter.com/activity/#{@user_id}/comments/ask/" 
    @should_answer_training = []
    @should_not_answer_training = []

    # create array of urls for the rest of the user's askme answer pages
    @askme_answer_page_urls = []
    collect_urls(url)
end

def login_to_scrape_answers
# Use Mechanize to connect securely 
    @page = agent.get(url)
    @page = agent.click(@page.link_with(:text => "Login"))

    # You have to log in before scraping in order to be able to see favcnt spans
    login_form = @page.form_with( :action => 'logging-in.mefi')
    puts "You have to log in before scraping in order to be able to see how many favorites people's answers have received."
    puts "Kenobi uses Mechanize and SSL and doesn't save your login info anywhere."
    puts "What is your Metafilter username?"
    print ">> "
    @user_name = $stdin.gets.chomp
    puts "What is your Metafilter password?"
    print ">> "
    @user_pass = $stdin.gets.chomp
    login_form.user_name = @user_name
    login_form.user_pass = @user_pass
    @page = agent.submit(login_form, login_form.buttons.first)
end

# Parse the first page of answers
@page = agent.click(page.link_with(:text => "Click here"))
parse_askme_questions(page)

# Parse the remaining pages of answers
# @askme_answer_page_urls.each do |url|
#     page = agent.click(page.link_with(:href => url))
#     parse_askme_questions(page)
# end