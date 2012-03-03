$:.unshift File.expand_path('.')
require 'naive_bayes'

describe "NaiveBayes" do 

	before(:each) do
		categories = ["good","bad"]
		@classifier = NaiveBayes.new(categories)
		good = ["kittens and cats","cats","cat","fuzzy rumpus","fuzzies for life"]
		bad = ["failure","censorship", "censor your life","failing at life", "sad cats"]
		good.each { |each| @classifier.train("good",each) }
		bad.each { |each| @classifier.train("bad",each) }
		@test = "a kitten should love cats and life"

	end

	describe "Train" do
		it "should add the right word counts to each category" do
			@classifier.word_counts["good"]["cat"].should be == 3
			@classifier.word_counts["good"]["life"].should be == 1
			@classifier.word_counts["bad"]["cat"].should be == 1
			@classifier.word_counts["bad"]["life"].should be == 2
		end
	end

	describe "Classify" do
		it "should calculate the correct classification" do
			# category_probability("good") = 5/10
			# category_probability("evil") = 5/10
			# word stems in test: kitten, cat, love, life
			# total good stems: 5
			# total evil stems: 6
			# kitten: good => 1, evil => 0
			# cat: good => 3, evil => 1
			# love: good => 0, evil => 0
			# life: good =>1, evil => 1
			# good: 2/5 * 4/5 * 1/5  * 2/5 = 0.0256
			# evil: 1/6 * 2/6 * 1/6 * 2/6 = 0.0030864197530864196
			@classifier.classify(@test).should be == "good"
		end
	end
end

