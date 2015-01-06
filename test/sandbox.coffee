ut = require 'ut'
R = require './R'

console.log n = '#foo.clazz'._()
console.log n.nodeName
console.log n.getAttribute 'id'
console.log n.getAttribute 'class'
ut.delay 1000, ->
  console.log n.getAttribute 'class'