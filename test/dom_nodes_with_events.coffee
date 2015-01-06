chai = require 'chai'
chai.should()

# this test will only run on Node.js

###
jsdom = require('jsdom').jsdom
window = jsdom().createWindow()
$ = require('jquery').create window

R = require './R'


trigger_click = ( domnode ) ->
  evt = window.document.createEvent "MouseEvents"
  evt.initEvent "click", yes, yes
  domnode.dispatchEvent evt


# http://www.howtocreate.co.uk/tutorials/javascript/domevents


describe 'radioactive.nodes', ->
  it 'should compile elements with DOM events', ->
    clicks = 0
    f = -> 'div'._ '!click': -> clicks++
    res = R.nodes f
    res.should.have.length 1
    node = res[0]
    node.nodeName.should.equal 'DIV'
    clicks.should.equal 0
    trigger_click node
    clicks.should.equal 1

  it 'should accept the on___ syntax for events', ->
    clicks = 0
    f = -> 'div'._ 'onclick': -> clicks++
    res = R.nodes f
    res.should.have.length 1
    node = res[0]
    node.nodeName.should.equal 'DIV'
    clicks.should.equal 0
    trigger_click node
    clicks.should.equal 1
###