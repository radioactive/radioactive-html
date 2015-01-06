chai = require 'chai'
chai.should()

R = require './R'

# http://www.w3schools.com/jsref/dom_obj_node.asp
describe.skip 'raml.nodes', ->

  it 'should compile:  a#foo --> <a id="foo"/>', ->
    node = 'a#foo'._()
    node.nodeName.should.equal 'A'
    node.getAttribute('id').should.equal 'foo'

  it 'should compile:  a#foo.clazz --> <a class="clazz" id="foo"/>', ->
    node = 'a#foo.clazz'._()
    node.nodeName.should.equal 'A'
    node.getAttribute('id').should.equal 'foo'
    node.getAttribute('class').should.equal 'clazz'

  it 'should compile:  a#foo.clazz.clazz2 --> <a class="clazz clazz2" id="foo"/>', ->
    node = 'a#foo.clazz.clazz2'._()
    node.nodeName.should.equal 'A'
    node.getAttribute('id').should.equal 'foo'
    # is the order of classes guaranteed?
    # lets assume it's not and sort
    node.getAttribute('class').split(' ').sort().join(' ').should.equal('clazz clazz2')