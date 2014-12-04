#!/bin/sh

# Update HTMLs using 'archive.zip' downloaded by GTT

ruby allocate.rb
rm -rf output
bundle exec rake guides:generate:html
cp ./source/favicon.ico ./output/

# Then, manually type these commands:
#   $ git add .
#   $ git commit -m "Publish foo bar"
#   $ git push origin japanese
#   $ git push heroku japanese:master

