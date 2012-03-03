# A naive Bayesian classifier to determine which Ask Metafilter questions a user should answer,
# depending on where, of the questions they've answered before, their answers have received the most favorites

# Remember, the more questions a user has answered before, the more accurate this will be!

$:.unshift File.expand_path('.')
require 'stemmer'
require 'naive_bayes'
require 'sqlite3'
require 'open-uri'
require 'nokogiri'
require 'askme_answers_scraper'
require 'askme_questions_scraper'

puts "First, you need to train Kenobi with your old AskMe answers!"
# Set up a new Ask Metafilter naive bayesian classifier
	# Could add several gradations, but not an infinitely fine range, basically.
	# Let's start with should_answer including any question where at least one of the user's answers gets >3 favs 
categories = [ "should_answer", "should_not_answer"]
@classifier = NaiveBayes.new(categories)

# Scrape AskMe for a given user's answers
@answer_scraper = AskMeAnswerScraper.new
@answer_scraper.scrape_logged_in

# Train the classifier with the scrapings
@answer_scraper.should_answer_training.each do |question|
	@classifier.train("should_answer", question)
end
@answer_scraper.should_not_answer_training.each do |question|
	@classifier.train("should_not_answer", question)
end

# Scrape AskMe for questions to classify
@question_scraper = AskMeQuestionScraper.new
@question_scraper.scrape

# Classify the new questions
puts "You should answer:"
@question_scraper.new_questions.each do |question|
	if @classifier.classify(question[:content]) == "should_answer"
		puts "http://ask.metafilter.com#{question[:url]}"
	end
end
puts "You should NOT answer:"
@question_scraper.new_questions.each do |question|
	if @classifier.classify(question[:content]) == "should_not_answer"
		puts "http://ask.metafilter.com#{question[:url]}"
	end
end