# Scraper to grab a user's Ask Metafilter answers and fav counts

$:.unshift File.expand_path('.')
require 'stemmer'
require 'naive_bayes'
require 'sqlite3'
require 'open-uri'
require 'nokogiri'

