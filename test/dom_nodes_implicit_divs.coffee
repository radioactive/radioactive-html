chai = require 'chai'
chai.should()

R = require './R'

describe 'dom_nodes_implicit_divs', ->

  # implicit divs
  it 'should compile:  #foo --> <div id="foo"/>', ->
    node = '#foo'._()
    node.nodeName.should.equal 'DIV'
    node.getAttribute('id').should.equal 'foo'

  it 'should compile:  #foo.clazz --> <div class="clazz" id="foo"/>', ->
    node = '#foo.clazz'._()
    console.log node.innerHTML
    node.nodeName.should.equal 'DIV'
    node.getAttribute('id').should.equal 'foo'
    node.getAttribute('class').should.equal 'clazz'

  it 'should compile:  #foo.clazz.clazz2 --> <div class="clazz clazz2" id="foo"/>', ->
    node = '#foo.clazz.clazz2'._()
    node.nodeName.should.equal 'DIV'
    node.getAttribute('id').should.equal 'foo'
    # is the order of classes guaranteed?
    # lets assume it's not and sort
    node.getAttribute('class').split(' ').sort().join(' ').should.equal('clazz clazz2')