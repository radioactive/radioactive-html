chai = require 'chai'
chai.should()

R = require './R'

# http://www.w3schools.com/jsref/dom_obj_node.asp
describe.skip 'raml.nodes', ->

  it 'should compile:  li -> a --> <li><a/></li>', ->
    res = R.nodes -> 'li'._ -> 'a'._()
    res.should.have.length 1
    node = res[0]
    node.nodeName.should.equal 'LI'
    node.hasChildNodes().should.equal yes
    node.childNodes.should.have.length 1
    node.childNodes[0].tagName.should.equal 'A'

  it 'should compile:  #foo.bar -> #baz --> <div id="foo" class="bar"><div id="baz"></div></div>',  ->
    res = R.nodes -> '#foo.bar'._ -> '#baz'._()
    res.should.have.length 1
    
    node = res[0]
    node.nodeName.should.equal 'DIV'
    node.getAttribute("id").should.equal 'foo'
    node.getAttribute("class").should.equal 'bar'

    node.hasChildNodes().should.equal yes
    node.childNodes.should.have.length 1
    
    node = node.childNodes[0]
    node.tagName.should.equal 'DIV'
    node.getAttribute("id").should.equal 'baz'