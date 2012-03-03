A naive Bayesian classifier to determine which Ask Metafilter questions a user should answer,
depending on where, of the questions they've answered before, their answers have received the most favorites

Remember, the more questions a user has answered before, the more accurate this will be!

This is the single best explanation of Bayes' Theorem I know of, incidentally - http://yudkowsky.net/rational/bayes

And if you're interested in the history of Bayes' Theorem - http://lesswrong.com/lw/774/a_history_of_bayes_theorem/

Dependencies:
gem install stemmer
gem install nokogiri
gem install sqlite3
gem install rspec (if you feel like running the tests for some weird reason, is all)

VERY in-progress.