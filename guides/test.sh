#!/bin/sh

# Test Markdown files using 'check_typo.rb'

for article in `ls source | grep md`
do
    echo "Testing ${article}"
    ruby check_typo.rb "./source/${article}"
done
