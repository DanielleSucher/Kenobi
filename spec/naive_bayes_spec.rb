$:.unshift File.expand_path('.')
require 'naive_bayes'

describe "NaiveBayes" do 

	before(:each) do
		categories = ["good","bad"]
		@classifier = NaiveBayes.new(categories)
		good = ["cat","cats","rat","dogs"]
		bad = ["dogs","dogs and cats", "dog", "dog and bunny"]
		good.each { |each| @classifier.train("good",each) }
		bad.each { |each| @classifier.train("bad",each) }
		@test = "dog"

	end

	describe "Train" do
		it "should add the right word counts to each category" do
			@classifier.words["good"]["dog"].should be == 1
			@classifier.words["good"]["cat"].should be == 2
			@classifier.words["good"]["rat"].should be == 1
			@classifier.words["bad"]["dog"].should be == 4
			@classifier.words["bad"]["cat"].should be == 1
			@classifier.words["bad"]["rat"].should be == nil
		end
	end

	describe "Classify" do
		it "should calculate the correct classification" do
			@classifier.classify(@test).should be == "bad"
		end	
	end
end

