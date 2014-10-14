#!/bin/sh

# Update HTMLs using 'archive.zip' downloaded by GTT

ruby allocate.rb
rm -rf output
bundle exec rake guides:generate:html
