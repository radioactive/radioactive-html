
module.exports = ( radioactive, jQuery, document ) ->

  # env is required by several modules
  env = require './env'
  env.radioactive   = -> radioactive
  env.jQuery        = -> jQuery
  env.document      = -> document

  $ = jQuery

  htmltags         = require 'htmltags'
  create_collector = require 'collector'
  ut               = require 'ut'
  # Ext              = require './Ext'
  xtypes           = require 'xtypes'
  rthp             = require './raw_tag_head_parser'
  cssc             = require './css_class_util'
  tpp              = require './tag_props_parser'
  tag_args_to_props_and_content = require './tag_args_to_props_and_content'
  bidibinder       = require 'bidibinder'
  helpers          = require './helpers'

  interval = ut.interval
  delay    = ut.delay

  rsub     = ( v, cb ) ->
    if is_func v
      radioactive.react v, (e, r) ->
        log_err e
        cb r
    else
      cb v
      ->

  rsub_now = ( v, cb ) ->
    r = rrun v
    cb r.error, r.result
    rsub v, cb

  rrun = ( f ) ->
    try
      result: radioactive.mute(f)()
    catch e
      error: e

  log_err = ( e ) ->
    ut.err e
    try
      window._last_error = e

  reactive_snapshot = ( v ) -> if is_func v then radioactive.mute(v)() else v

  is_func  = ( v ) -> typeof v is 'function'

  collector = create_collector()

  merge_css_classes = ( head_classes, inline_class_decl, classflags ) ->
    mfcs = []
    mfcs.push [ head_classes, yes ] if head_classes.length > 0
    mfcs.push [ inline_class_decl, yes ] if inline_class_decl?
    # -- classflags
    ut.kv classflags, ( clazz, flag ) -> mfcs.push [ clazz, flag ]
    merged = cssc.mfc mfcs
    merged = merged.sort()
    merged.join ' '


  ext_comp_innerhtml = ( comp, cb ) -> ut.delay 1, ->
    key = '___innerhtml___'
    if comp[key]?
      cb comp[key]
    else
      do xxx = ->
        try
          if ( $elm = $(comp.element.dom).find( '.x-innerhtml' ) )?
            if $elm[0]?
              cb comp[key] = $elm[0]
              return
        ut.delay 100, xxx

  ext_get_component_element = ( c, cb ) -> ut.delay 1, ->
    return cb c.element if c.element?
    c.on 'initialize', f = ->
      cb c.element
      c.un 'initialize', f


  apply_props_on_html_node = ( $e, props ) ->

    undos = []

    # process css classes and add it to properties map
    # ( which will be processed below )
    props.properties.class = do ( c = props.properties.class ) -> ->
      merge_css_classes [], c, props.classflags

    # -- _special properties

    # -- _bind
    do ( p = props.properties ) ->
      if p._bind?
        process_bind $e, p._bind
        delete p._bind

    # -- _html
    do ( p = props.properties ) ->
      if p._html?
        undos.push rsub_now p._html, ( v ) -> $e.html v
        delete p._html

    # -- _onclick
    if props.properties._onclick?
      do ( h = props.properties._onclick ) ->
        if $e[0].tagName is 'A'
          props.properties.href ?= '#'
          props.listeners.click = (e) -> e.preventDefault() ; h()
        else
          props.listeners.click = (e) -> h()
      delete props.properties._onclick

    # -- listeners
    ut.kv props.listeners, ( event, handler ) ->
      $e.on event, handler
      undos.push -> $e.off event, handler

    # -- other properties
    ut.kv props.properties, ( prop, value ) ->
      $e.prop prop, reactive_snapshot  # set it right away
      undos.push rsub_now value, ( v ) -> $e.prop prop, v # and then subscribe

    # -- polling watchers
    # fixed to 300 but we should allow users to specify this
    ut.kkv props.watchers, ( prop, event, handler ) ->
      if event is '_poll'
        iv = setInterval ( -> handler.handler $e.prop prop ), 300
        -> clearInterval iv

    # -- event-guarded watchers
    ut.kkv props.watchers, ( prop, event, handler ) ->
      if event isnt '_poll'
        if handler.bidirectional
          binder = bidibinder
            get_a: -> handler.handler()
            set_a: (v) -> handler.handler v
            get_b: -> $e.prop prop
            set_b: (v) -> $e.prop prop, v
          react_stopper = radioactive.react -> binder.touch_a()
          $e.on event, fn = -> binder.touch_b()
          ->
            $e.off event, fn
            react_stopper()
        else
          $e.on event, fn = -> handler.handler $e.prop prop
          -> $e.off event, fn

    # -- styles
    ut.kv props.styles, ( prop, value ) ->
      $e.css prop, reactive_snapshot value # set it right away
      undos.push rsub_now value, ( v ) -> $e.css prop, v # and then subscribe

    ut.kv props.queries, ( k, v ) ->
      undos.push apply_query_tag $e, k, v

    -> u() for u in undos


  process_bind = ( $e, bind ) ->
    unless is_func bind
      throw new Error '_bind requires a cell (function)'
    read_only = bind.length is 0 # no arguments
    cell_is_origin = yes # default to this for now
    cell = bind
    # TODO: use heuristics to do the right thing depending on the type of $e
    #       for now we just use val()
    # TODO: lifecycle
    # TODO: we need low-level access to the monitor ( synchronous )
    mutex    = off
    val_on_e = undefined
    $e.on 'change', ->
      val_on_e = $e.val()
      cell val_on_e
    $e.val()




  create_html = ( head, props, content ) -> # : DOMNode
    # TODO: we are storing the UNDOs but not doing anything with them
    undos = []
    # search for a few special cases
    switch head.tag
      when 'text'
        node = document.createTextNode('')
        switch typeof content
          when 'function' then undos.push rsub content, (v) -> node.data = v
          when 'string' then node.data = content
          when 'number' then node.data = content.toString()
        # else we do nothing...
        node
      else
        unless htmltags head.tag
          throw new Error 'Unknown HTML tag: ' + head.tag
        $e = $ '<' + head.tag + '>'
        # extract id and classes from head and
        # add them to the props array
        props.properties.id = head.id if head.id?
        props.classflags[c] = yes for c in head.classes
        # apply the props
        undos.push apply_props_on_html_node $e, props
        # apply content
        undos.push rsub_html_elm_content $e, content if content?
        $e[0]


  # http://stackoverflow.com/questions/18745130/extjs-component-vs-element-vs-other
  create_ext = ( head, props, content ) ->

    pending_subscriptions = []
    pending_watchers = []
    config = {}

    undos = []

    clazz = xtype2class head.tag.split('-').join('.')

    props.properties.id = head.id if head.id?
    props.classflags[c] = yes for c in head.classes

    # css classes
    props.properties.cls = do ( c = props.properties.cls ) -> ->
      merge_css_classes [], c, props.classflags

    # -- listeners
    config.listeners = props.listeners if props.listeners?
    ###
    TODO: accept objects with more options
        tap:
          fn: -> @hide()
          single: true
          scope: @
    ###

    # TODO: we should be able to add html properties to component.element directly

    # TODO: setting styles should also work
    # but they should be set on the element

    # -- polling watchers
    ut.kkv props.watchers, ( prop, event, handler ) ->
      if event is '_poll'
        pending_watchers.push ( comp ) ->
          getter = ut.getter prop
          intv = setInterval (-> handler comp[getter]()), 300
          -> clearInterval intv


    # -- watchers
    ut.kkv props.watchers, ( prop, event, handler ) ->
      if event isnt '_poll'
        pending_watchers.push ( comp ) ->
          getter = ut.getter prop
          comp.on event, fn = -> handler comp[getter]()
          -> comp.un event, fn


    # -- html config property ( may be reactive )
    if is_func props.properties.html
      html_func_property = props.properties.html
      # custom html is added to a nested div with class 'x-innerhtml'
      # we add some html in order for the framework to create it
      # we will eventually replace it with our own content
      props.properties.html = '<div></div>'

    # -- regular properties
    ut.kv props.properties, ( prop, value ) ->
      unless is_func value
        config[prop] = value
      else # reactive
        # we get the value so we can pass it as a config normally
        # but we make sure that reactivity does not propagate up
        r = rrun value
        log_err r.error
        config[prop] = r.result
        if r.monitor?
          # those that have a monitor will be reactive
          pending_subscriptions.push ( comp ) ->
            setter = ut.setter prop
            if typeof comp[setter] is 'function'
              rsub value, ( r ) -> comp[setter] r
            else
              console.warn """
                Ext Component #{comp.$className} has no setter for property '#{prop}' and
                  you are passing a reactive function as value.
                  The value won't be updated even if it changes later on.
                  """


    # children/content
    if is_func content then do ->
      # run once in a reactive context
      res = rrun -> collector.run content
      log_err res.error
      config.items = []
      if res.result instanceof Array
        config.items = res.result[...-1] # we discard the last item
      # and set reactivity if necessary
      if res.monitor?
        pending_subscriptions.push ( comp ) ->
          rsub ( -> collector.run content ), ( r ) ->
            comp.setItems r[...-1]

    # create the component
    component = Ext().create clazz, config

    # queries
    # ( styles are set on component.element )
    unless ut.obj_empty props.queries
      do ->
        undo_func = null
        undos.push -> undo_func?()
        ext_get_component_element component, ( elm ) ->
          ut.kv props.queries, ( k, v ) ->
            undo_func = apply_query_tag $(elm.dom), k, v

    # styles
    # ( styles are set on component.element )
    do ->
      undo_func = null
      undos.push -> undo_func?()
      ext_get_component_element component, ( elm ) ->
        ut.kv props.styles, ( name, value ) ->
          $elm = $ elm.dom
          undo_func = rsub value, (v) ->
            $elm.css name, value

    # setup reactive html content if present
    if html_func_property? then do ->
      undo_func = null
      undos.push -> undo_func?()
      ext_comp_innerhtml component, (elm) ->
        undo_func = rsub_html_elm_content elm, html_func_property

    # setup watchers ( output )
    # setup reactivity ( input )
    undos.push p component for p in pending_subscriptions.concat pending_watchers

    # add reference to implicit collection if any is defined
    collector component if collector.defined()

    # cancel subscriptions when element is destroyed
    component.on 'destroy', -> u() for u in undos

    # return newly created component
    component


  apply_query_tag = ( $elm, query, raw_props ) ->
    undos = []
    if query is '__empty__'
      undos.push apply_props_on_html_node $elm, tpp raw_props
    else
      helpers.jquery_find_watch query, $elm, ( added, removed ) ->
        #apply_props_on_html_node for x in added
        console.log 'added', added
        console.log 'removed', removed
      -> # return undo func as always


  rsub_html_elm_content = ( domnode, content ) ->
    elm = $ domnode
    reset_content = ->
      # can we achieve this using innerHtml?
      if elm.text()? then elm.text ''
      elm.children().remove()
    set_content = ( c ) ->
      # box it as array to make the logic within this
      # method easier to understand
      return set_content [ c ] unless c instanceof Array
      reset_content()
      c = c.concat()
      c.pop() if c.length > 1 # has collected content. we discard the last value
      # remove any null or undefined elements
      c = ut.collapse_arr c
      return if c.length is 0
      for x in c then do ( x ) ->
        switch typeof x
          when 'string'
            elm.text x
          when 'number'
            elm.text x + ''
          when 'object'
            if helpers.is_dom_node x
              elm.append x
            else if helpers.is_jquery_obj x
              elm.append x
            else if helpers.is_ext_component x
              if x.getHeight() is null
                console.warn """
                  When adding an Ext component as child to a DOM node
                  You need to set height manually
                  ( it won't participate in the framework's layout )
                  """
              elm.append x.element.dom
            else
              console.error "Don't know how to add this child to a DOMNode ", x
    if is_func content
      rsub ( -> collector.run content ), set_content
    else
      set_content content

  String::_ = ->
    str = @ + ''
    str = 'ra:insert' if str is ''

    # default behaviour
    do_collect = collector.defined()
    do_return  = not collector.defined()

    if str.indexOf('<<') is 0
      str = str.substring 2
      do_collect = yes
      do_return  = yes
    else if str.indexOf('<') is 0
      str = str.substring 1
      do_collect = no
      do_return  = yes

    do_return = yes # TODO: this is for backwards compatibility

    ret = declare_tag_rec str, ut.arr(arguments), ( not do_collect )

    if do_return
      if ret instanceof Array then ret[0] else ret
    else
      undefined


  declare_insert_tag = ( args ) ->
    if args.length isnt 1
      throw new Error 'insert tag takes exactly one argument'
    e = args[0]
    e = [e] unless e instanceof Array
    for x in e
      collector res = if is_func(x) then x() else x
    res
    undefined

  declare_tag_rec = ( head, args, dont_collect = false ) ->
    head = head.split ' ' unless head instanceof Array
    declare_tag head.shift(),
      ( if head.length is 0 then args else [ -> declare_tag_rec head, args ] ),
      dont_collect

  declare_tag = ( head_str, args, dont_collect = false ) ->
    ta2pc = tag_args_to_props_and_content
    head_str = head_str.trim()
    head = rthp head_str
    ns = head.ns or 'html'
    if ns is 'ra'
      switch head.tag
        when 'each'
          throw new Error 'ra:each not implemented yet'
        when 'insert'
          declare_insert_tag args
    else
      { props, content } = ta2pc args
      props = tpp props
      switch ns
        when 'html'
          n = create_html head, props, content
          collector n if collector.defined() and ( not dont_collect )
          n
        when 'ext'
          create_ext head, props, content
        else
          throw new Error 'unrecognized namespace ' + ns

  xtype2class = ( t ) -> if ( t.indexOf(".") is -1 ) then xtypes[t] else t

  export: ( context ) ->
    # TODO: export all HTML tags
    tags = 'a p'.split ' '
    for tag in tags then do ( tag ) ->
      context[tag.toUpperCase()] = -> String::_.apply tag, arguments
