
SERIAL = 0
serial = -> SERIAL++
key_func = ( a ) -> a


class ViewManager

  constructor: ( @factory, @cache = 50, @key = null  ) ->
    @_current   = []
    @_cached    = []
    @key ?= key_func

  purge: ->
    x.update_index? -2 for x in @_cached
    @_cached = []

  get: ( items ) ->

    version   = serial()
    existing  = @_current.concat @_cached
    @_current = []

    find_existing = ( item ) =>
      return x for x in existing when @key(item) is x.key
      null

    for item, i in items then do ( item, i ) =>
      b = find_existing item
      if ( b = find_existing item )?
        # found a cached version. reuse it
        b.version = version
        b.update_index? i
        @_current.push  b
      else
        # need to create a new one
        r = @factory item, i
        @_current.push 
          key:          @key item
          version:      version
          update_index: r.update_index
          result:       r.result

    # we now have the new Bs created
    # what we need to do is to see which elements we purge from
    # the cache to make space for the new ones

    # first, lets remove all those that are being used in current
    cache_candidates = existing.filter ( x ) -> x.version isnt version
    
    if cache_candidates.length > @cache
      # no need to purge
      new_cache = cache_candidates
    else
      # oops. we need to remove some
      # lets order them by version
      cache_candidates = cache_candidates.sort ( b1, b2 ) ->
        b1.version > b2.version
      new_cache = []

      for b, i in cache_candidates
        fits_in_cache = ( i < @cache )
        # store it if it fits
        if fits_in_cache
          new_cache.push b 
        else
          b.update_index? -2 # good bye

    # store the new cache
    @_cached = new_cache
    # update their indexes to reflect the fact
    # that they are part of the cache now
    x.update_index? -1 for x in @_cached

    # return the current collection of bs
    ( c.result for c in @_current )


###
item won't change. it is the item retrieved from the collection
index is reactive and will change.
an index of 0, 1, 2, 3 etc indicates the current position of
this item within the collection
an index of -1 indicates that this item is not in the collection
but that the view is cached and may be reused
an index of -2 indicates that this view was removed from the cache
and won't be reused
###

# we export a minimal api
module.exports = main = ( factory, cache = 50, key_func = null ) ->
  m = new ViewManager factory, cache, key_func
  x = ( items ) -> m.get items
  x.get = x
  x.purge = -> m.purge()
  x



test = ->
  console.log 'testing caching map'
  factory = ( item, index ) ->
    console.log 'creating instance for item ' + item
    result: -> "item " + item + " index " + index
    update_index: ( i ) ->
      console.log 'update index for item ' + item + ' , ' + i
      index = i

  m = new ViewManager factory
  m = main factory

  result = m [0..10]
  console.log( r() for r in result )
  
  result = m [5..15]
  console.log( r() for r in result )

  result = m [0..5]
  console.log( r() for r in result )

  m.purge()
  console.log 'purge'

  result = m [5..10]
  console.log( r() for r in result )

