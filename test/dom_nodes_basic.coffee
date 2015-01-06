chai = require 'chai'
chai.should()

R = require './R'

describe 'dom_nodes_basic', ->
  it 'should compile: div --> <div/>', ->
    node = 'div'._()
    node.nodeName.should.equal 'DIV'
  it 'should compile: p --> <p/>', ->
    node = 'p'._()
    node.nodeName.should.equal 'P'