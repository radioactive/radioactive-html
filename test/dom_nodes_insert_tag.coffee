chai = require 'chai'
chai.should()

R = require './R'
$ = R.$

describe.skip 'the _insert tag', ->
  it 'should accept DOM Element Nodes', ->
    p = ( $('<p>').text 'H' )[0]
    res = R.nodes ->
        'hr'._()
        '_insert'._ p
        'hr'._()
    res.should.have.length 3
    res[0].nodeName.should.equal 'HR'
    res[1].nodeName.should.equal 'P'
    res[2].nodeName.should.equal 'HR'

  it 'should accept jQuery Selections of length 1', ->
    p = ( $('<p>').text 'H' )
    res = R.nodes ->
        'hr'._()
        '_insert'._ p
        'hr'._()
    res.should.have.length 3
    res[0].nodeName.should.equal 'HR'
    res[1].nodeName.should.equal 'P'
    res[2].nodeName.should.equal 'HR'

  # TODO
  it.skip 'should accept jQuery Selections of length > 1', ->
    p1 = $('<p>').text 'P1'
    p2 = $('<p>').text 'P2'
    div = $('<div>')
    div.append p1
    div.append p2

    console.log div instanceof Array

    res = R.nodes ->
        'hr'._()
        '_insert'._ div.children()
        'hr'._()

    res.should.have.length 4
    res[0].nodeName.should.equal 'HR'
    res[1].nodeName.should.equal 'P'
    res[2].nodeName.should.equal 'P'
    res[3].nodeName.should.equal 'HR'