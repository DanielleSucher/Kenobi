# Created mostly while following the tutorial at http://blog.saush.com/2009/02/11/naive-bayesian-classifiers-and-ruby/

$:.unshift File.expand_path('.')
require 'stemmer'
require 'sqlite3'
require 'open-uri'
require 'nokogiri'

# Currently set to actually just store the data in memory, not in sqlite

class NaiveBayes
    attr_accessor :word_counts, :best, :second_best

    # Initialize with a list of the categories for this clasifier
    def initialize(categories)
        @word_counts = Hash.new # Hash of categories => hashes of word => count (in that category)
        @total_words = 0 # total number of words trained
        @categories_documents = Hash.new # hash of category names => documents trained for each
        @total_documents = 0 # total number of documents trained
        @categories_words = Hash.new # hash of category names => documents trained for each
        @threshold = 2.5 # how much more likely x has to be than y to bother declaring it

        categories.each do |category|
            @word_counts[category] = Hash.new 
            @categories_documents[category] = 0 # total number of documents trained for each category
            @categories_words[category] = 0 # total number of words trained for each category       
        end
    end

    # Train the classifier!
    def train(category,document)
        word_count(document).each do |word,count|
            @word_counts[category][word] ||= 0 # Stemming here would be redundant
            @word_counts[category][word] += count
            @total_words += count
            @categories_words[category] += count
        end
        @categories_documents[category] += 1
        @total_documents += 1
    end

    # find the probability for each category and return a hash, category => probability thereof
    def probabilities(document)
        odds = Hash.new
        @word_counts.each_key do |category| # Each key means each of the categories, remember
            odds[category] = probability(category,document)
        end
        odds
    end

    # Classify any given document into one of the categories
    def classify(document)
        sorted = probabilities(document).sort { |a,b| a[1]<=>b[1] } # sorts by value, asc
        @best,@second_best = sorted.pop, sorted.pop
        best[1]/second_best[1] > @threshold ? result = best[0] : result = "Unknown"
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
            # Except we pretend every occured at least onceper category, to avoid errors when encountering
            # words never encountered during training.
            # So, it's: (times the word occurs in this category + 1)/total number of words in this category
            (@word_counts[category][word.stem].to_f + 1)/@categories_words[category].to_f 
            # Have to change at least one operand to a float so the result can be a float (or all? not sure)
        end

        def document_probability(category,document)
            doc_prob = 1 # The document exists we're looking at exists, yep.
            word_count(document).each do |word|
                doc_prob *= word_probability(category,word[0]) # gets the word, not its count
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

        # Needs to be significantly trimmed down from the sample, because I think some of these words
        # may be less common and more indicative of meaning on Ask Metafilter
        COMMON_WORDS = ['a','again','ago','ain\'t','all','alone','also','am','amid','amidst','among','amongst',
                        'an','and','another','any','anybody','anyhow','anyone','anything','anyway','anyways',
                        'anywhere','apart','appear','appreciate','appropriate','are','aren\'t','around','as','a\'s','aside','ask','asking','associated','at','available','away','awfully','b','back','backward','backwards','be','became','because','become','becomes','becoming','been','before','beforehand','begin','behind','being','believe','below','beside','besides','best','better','between','beyond','both','brief','but','by','c','came','can','cannot','cant','can\'t','caption','cause','causes','certain','certainly','changes','clearly','c\'mon','co','co.','com','come','comes','concerning','consequently','consider','considering','contain','containing','contains','corresponding','could','couldn\'t','course','c\'s','currently','d','dare','daren\'t','definitely','described','despite','did','didn\'t','different','directly','do','does','doesn\'t','doing','done','don\'t','down','downwards','during','e','each','edu','eg','eight','eighty','either','else','elsewhere','end','ending','enough','entirely','especially','et','etc','even','ever','evermore','every','everybody','everyone','everything','everywhere','ex','exactly','example','except','f','fairly','far','farther','few','fewer','fifth','first','five','followed','following','follows','for','forever','former','formerly','forth','forward','found','four','from','further','furthermore','g','get','gets','getting','given','gives','go','goes','going','gone','got','gotten','greetings','h','had','hadn\'t','half','happens','hardly','has','hasn\'t','have','haven\'t','having','he','he\'d','he\'ll','hello','help','hence','her','here','hereafter','hereby','herein','here\'s','hereupon','hers','herself','he\'s','hi','him','himself','his','hither','hopefully','how','howbeit','however','hundred','i','i\'d','ie','if','ignored','i\'ll','i\'m','immediate','in','inasmuch','inc','inc.','indeed','indicate','indicated','indicates','inner','inside','insofar','instead','into','inward','is','isn\'t','it','it\'d','it\'ll','its','it\'s','itself','i\'ve','j','just','k','keep','keeps','kept','know','known','knows','l','last','lately','later','latter','latterly','least','less','lest','let','let\'s','like','liked','likely','likewise','little','look','looking','looks','low','lower','ltd','m','made','mainly','make','makes','many','may','maybe','mayn\'t','me','mean','meantime','meanwhile','merely','might','mightn\'t','mine','minus','miss','more','moreover','most','mostly','mr','mrs','much','must','mustn\'t','my','myself','n','name','namely','nd','near','nearly','necessary','need','needn\'t','needs','neither','never','neverf','neverless','nevertheless','new','next','nine','ninety','no','nobody','non','none','nonetheless','noone','no-one','nor','normally','not','nothing','notwithstanding','novel','now','nowhere','o','obviously','of','off','often','oh','ok','okay','old','on','once','one','ones','one\'s','only','onto','opposite','or','other','others','otherwise','ought','oughtn\'t','our','ours','ourselves','out','outside','over','overall','own','p','particular','particularly','past','per','perhaps','placed','please','plus','possible','presumably','probably','provided','provides','q','que','quite','qv','r','rather','rd','re','really','reasonably','recent','recently','regarding','regardless','regards','relatively','respectively','right','round','s','said','same','saw','say','saying','says','second','secondly','see','seeing','seem','seemed','seeming','seems','seen','self','selves','sensible','sent','serious','seriously','seven','several','shall','shan\'t','she','she\'d','she\'ll','she\'s','should','shouldn\'t','since','six','so','some','somebody','someday','somehow','someone','something','sometime','sometimes','somewhat','somewhere','soon','sorry','specified','specify','specifying','still','sub','such','sup','sure','t','take','taken','taking','tell','tends','th','than','thank','thanks','thanx','that','that\'ll','thats','that\'s','that\'ve','the','their','theirs','them','themselves','then','thence','there','thereafter','thereby','there\'d','therefore','therein','there\'ll','there\'re','theres','there\'s','thereupon','there\'ve','these','they','they\'d','they\'ll','they\'re','they\'ve','thing','things','think','third','thirty','this','thorough','thoroughly','those','though','three','through','throughout','thru','thus','till','to','together','too','took','toward','towards','tried','tries','truly','try','trying','t\'s','twice','two','u','un','under','underneath','undoing','unfortunately','unless','unlike','unlikely','until','unto','up','upon','upwards','us','use','used','useful','uses','using','usually','v','value','various','versus','very','via','viz','vs','w','want','wants','was','wasn\'t','way','we','we\'d','welcome','well','we\'ll','went','were','we\'re','weren\'t','we\'ve','what','whatever','what\'ll','what\'s','what\'ve','when','whence','whenever','where','whereafter','whereas','whereby','wherein','where\'s','whereupon','wherever','whether','which','whichever','while','whilst','whither','who','who\'d','whoever','whole','who\'ll','whom','whomever','who\'s','whose','why','will','willing','wish','with','within','without','wonder','won\'t','would','wouldn\'t','x','y','yes','yet','you','you\'d','you\'ll','your','you\'re','yours','yourself','yourselves','you\'ve','z','zero']

end