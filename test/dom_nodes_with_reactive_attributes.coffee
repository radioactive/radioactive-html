chai = require 'chai'
chai.should()

R = require './R'
radioactive = R.radioactive

# http://www.w3schools.com/jsref/dom_obj_node.asp
describe.skip 'raml.nodes', ->
  it 'should compile an anchor tag with an href attribute', ->
    c = radioactive.cell '#'
    node = 'a'._ href: c
    node.nodeName.should.equal 'A'
    node.getAttribute('href').should.equal '#'
    c '#f'
    node.getAttribute('href').should.equal '#f'
    c '#g'
    node.getAttribute('href').should.equal '#g'