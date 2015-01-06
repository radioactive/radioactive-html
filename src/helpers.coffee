ut  = require 'ut'
env = require './env'

module.exports =
  is_ext_component: ( v ) ->
    try
      return yes if v instanceof Ext.Component
    no
  
  is_dom_node: ( v ) ->
    try
      return yes if v.ownerDocument is env.document()
    no
  
  is_jquery_obj: ( v ) ->
    try
      return yes if v instanceof env.jQuery()
    no

  # cb = ( [remove, add] ) ->
  jquery_find_watch: ( jquery_selector, $elm, cb, delay = 50 ) ->
    current = []
    ival = ut.interval delay, ->
      last = current
      current = env.jQuery()( jquery_selector, $elm ).toArray()
      [added, removed] = ut.arrdiff current, last
      if ( added.length + removed.length ) isnt 0
        cb added, removed
    -> clearInterval ival