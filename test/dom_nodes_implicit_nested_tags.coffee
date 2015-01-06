chai = require 'chai'
chai.should()

R = require './R'

describe 'raml.nodes', ->

  it 'should compile:  "li a" --> <li><a/></li>', ->
    node = 'li a'._()
    node.nodeName.should.equal 'LI'
    node.hasChildNodes().should.equal yes
    node.childNodes.should.have.length 1
    node.childNodes[0].tagName.should.equal 'A'

  it 'should compile:  "#foo.bar #baz" --> <div id="foo" class="bar"><div id="baz"></div></div>', ->
    node = '#foo.bar #baz'._()
    node.nodeName.should.equal 'DIV'
    node.getAttribute("id").should.equal 'foo'
    node.getAttribute("class").should.equal 'bar'

    node.hasChildNodes().should.equal yes
    node.childNodes.should.have.length 1
    
    node = node.childNodes[0]
    node.tagName.should.equal 'DIV'
    node.getAttribute("id").should.equal 'baz'