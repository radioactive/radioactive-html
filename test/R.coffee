core   = require '../src/core'

###
  Sets up the environment for testing.
  Don't try to require radioactive or jquery in your tests
  use this to access them
###

jsdom       = require 'jsdom'
window      = jsdom.jsdom("<html><body></body></html>").parentWindow
$           = require('../node_modules/jquery/dist/jquery') window
radioactive = require 'radioactive'

module.exports =
  $:           $
  jQuery:      $
  window:      window
  radioactive: radioactive
  core:        core radioactive, $, window.document