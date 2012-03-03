# A naive Bayesian classifier to determine which Ask Metafilter questions a user should answer,
# depending on where, of the questions they've answered before, their answers have received the most favorites

# Remember, the more questions a user has answered before, the more accurate this will be!

$:.unshift File.expand_path('.')
require 'stemmer'
require 'naive_bayes'

# Test:

# Set up a new <s>Ask Metafilter</s> evil/less_evil naive bayesian classifier
categories = ["evil","less_evil"]
classifier = NaiveBayes.new(categories)

# Pick some testing samples
evil = ["night time", "sweet dreams", "some light left", "dusk till dawn", "tween the daylight and the dark", "dusky eyes", "what dreams may come"]
less_evil = ["frabjous day", "day light", "final days", "kittens", "kitties", "cat lady", "lady di", "why not a cat", "women are not necessarily like cats"]

# Train the classifier
evil.each { |sample| classifier.train("evil", sample) }
less_evil.each { |sample| classifier.train("less_evil", sample) }

# Define what we want to classify, for this test
test = "kittens and cats dream cutely"

puts "Conclusion: #{classifier.classify(test)}"

puts "Relative odds: #{classifier.relative_odds(test)}"


