# 2014/12/15
# Created by @hanachin_ (@hanachin on GitHub)
# Copyright (C) MIT License 2014

# disable web security to download files
casper = require('casper').create
  pageSettings:
    webSecurityEnabled: false

# Google Translator Toolkit endpoints
GOOGLE_TRANSLATOR_TOOLKIT_URL = 'http://translate.google.com/toolkit/'
GOOGLE_TRANSLATOR_TOOLKIT_DOCSDOWNLOAD_URL = "http://translate.google.com/toolkit/docsdownload"

# signin and ajax delay
DEFAULT_WAIT_MS = 3000

# cli args
GOOGLE_ACCOUNT_EMAIL    = casper.cli.get 'email'
GOOGLE_ACCOUNT_PASSWORD = casper.cli.get 'password'
DOWNLOAD_LABEL          = casper.cli.get 'label'
ARCHIVE_PATH            = casper.cli.get 'archive'

# usage
unless GOOGLE_ACCOUNT_EMAIL && GOOGLE_ACCOUNT_PASSWORD && DOWNLOAD_LABEL && ARCHIVE_PATH
  casper.echo 'Usage: casperjs download_archive.coffee --email=<YOUR_EMAIL_ADDRESS> --password=<YOUR_PASSWORD> --label=<DOWNLOAD_LABEL> --archive=<ARCHIVE_FILE_NAME>'
  casper.exit()

# error
casper.on 'page.error', (msg, trace) ->
  @echo "Error: #{msg}", "ERROR"

# output downloaded filename
casper.on 'downloaded.file', (targetPath) ->
  casper.echo "Downloaded: #{targetPath}"

# signin
casper.start GOOGLE_TRANSLATOR_TOOLKIT_URL
casper.then ->
  @fill '#gaia_loginform', Email: GOOGLE_ACCOUNT_EMAIL, Passwd: GOOGLE_ACCOUNT_PASSWORD, true
  @wait DEFAULT_WAIT_MS

# select download targets
casper.then ->
  @clickLabel DOWNLOAD_LABEL, 'a'
  @wait DEFAULT_WAIT_MS

# download files <3
casper.then ->
  downloadUrl = @evaluate (docsdownloadUrl) ->
    docs = document.querySelectorAll('.gtc-list-body tr')
    dids = (doc.id.replace(/^[^:]+:(.+)$/, '$1') for doc in docs)
    didsQueryString = ("dids=#{did}" for did in dids).join('&')
    "#{docsdownloadUrl}?#{didsQueryString}"
  , GOOGLE_TRANSLATOR_TOOLKIT_DOCSDOWNLOAD_URL

  casper.echo "Downloading: #{downloadUrl}"
  @download(downloadUrl, ARCHIVE_PATH)

casper.run()
