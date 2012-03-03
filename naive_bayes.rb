# Created mostly while following the tutorial at http://blog.saush.com/2009/02/11/naive-bayesian-classifiers-and-ruby/

$:.unshift File.expand_path('.')
require 'stemmer'
require 'sqlite3'

# Currently set to actually just store the data in memory, not in sqlite

class NaiveBayes
    attr_accessor :words

    # Initialize with a list of the categories for this clasifier
    def initialize(categories)
        @words = Hash.new # Hash of categories => hashes of word => count (in that category)
        @total_words = 0 # total number of words trained
        @categories_documents = Hash.new # hash of category names => documents trained for each
        @total_documents = 0 # total number of documents trained
        @categories_words = Hash.new # hash of category names => documents trained for each
        @threshold = 1.5 # how much more likely x has to be than y to bother declaring it

        categories.each do |category|
            @words[category] = Hash.new 
            @categories_documents[category] = 0 # total number of documents trained for each category
            @categories_words[category] = 0 # total number of words trained for each category       
        end
    end

    # Train the classifier!
    def train(category,document)
        word_count(document).each do |word,count|
            @words[category][word] ||= 0 # Stemming here would be redundant
            @words[category][word] += count
            @total_words += count
            @categories_words[category] += count
        end
        @categories_documents[category] += 1
        @total_documents += 1
    end

    # find the probability for each category and return a hash, category => probability thereof
    def probabilities(document)
        odds = Hash.new
        @words.each_key do |category| # Each key means each of the categories, remember
            odds[category] = probability(category,document)
        end
        odds
    end

    # Classify any given document into one of the categories
    def classify(document)
        sorted = probabilities(document).sort { |a,b| a[1]<=>b[1] } # sorts by value, asc
        best = sorted.pop
        second_best = sorted.pop
        best[1]/second_best[1] > @threshold ? best[0] : "Unknown"
    end

    def relative_odds(document) #  a complete set of relative odds rather than a single absolute odd
        probs = probabilities(document).sort { |a,b| a[1]<=>b[1] } # sorts by value, asc
        totals = 0
        relative = {}
        probs.each { |prob| totals += prob[1]}
        probs.each { |prob| relative[prob[0]] = "#{prob[1]/totals * 100}%" }
        relative
    end

    private

        def word_count(document)
            words = document.gsub(/[^\w\s]/,"").split 
            word_hash = Hash.new
            words.each do |word|
                word.downcase!
                key = word.stem
                unless COMMON_WORDS.include?(word) # Remove common words
                    word_hash[key] ||= 0
                    word_hash[key] += 1 # Each word is a key, and maps to the count of how often it appears
                end
            end
            word_hash
        end

        def word_probability(category,word)
            # Basically the probability of a word in a category is the number of times it occurred 
            # in that category, divided by the number of words in that category altogether. 
            # Except we pretend every occured at least once per category, to avoid errors when encountering
            # words never encountered during training.
            # So, it's: (times the word occurs in this category + 1)/total number of words in this category
            (@words[category][word].to_f + 1)/@categories_words[category].to_f
        end

        def document_probability(category,document)
            doc_prob = 1 # The document exists we're looking at exists, yep.
            word_count(document).each do |word|
                doc_prob *= word_probability(category,word[0]) # gets the word stem, not its count
            end
            # This calculates the probability of the document given the category, by multiplying
            # the probability of the document (100%, baby!) by the probability of each word 
            # in the document, given the category and how many times it appears
            doc_prob
        end

        def category_probability(category)
            # This is just the probability that any random document might be in this category.
            @categories_documents[category].to_f/@total_documents.to_f
        end

        def probability(category,document)
            document_probability(category,document) * category_probability(category)
            # Pr(category|document) = (Pr(document|category) * Pr(category))/Pr(document)
            # The probability of category given the document = 
            # the probability of the document given the category * the probability of the category
            # (Divided by the probability of the documents, which I think we're assuming is always 1)
        end

        # SIGNIFICANTLY trimmed down
        COMMON_WORDS = ['a','an','and','the','them','he','him','her','she','their','we',
            'to','be','some','on','or','by','i']
end