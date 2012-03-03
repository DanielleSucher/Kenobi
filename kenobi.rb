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

AskMeAnswerScraper.new.scrape_logged_in

# Test:

# Set up a new Ask Metafilter naive bayesian classifier
# Could add several gradations, but not an infinitely fine range, basically.
# Let's start with should_answer including any question where at least one of the user's answers gets >3 favs 
categories = ["should_answer","should_not_answer"]
classifier = NaiveBayes.new(categories)

# Scrape metafilter

# Train the classifier with the scrapings
# something.each { |sample| classifier.train("should_answer", sample) }
# something_else.each { |sample| classifier.train("should_not_answer", sample) }

# # Define what we want to classify, for this test
# test = ""

# puts "Conclusion: #{classifier.classify(test)}"

# puts "Scaled details: #{classifier.relative_odds(test)}"


