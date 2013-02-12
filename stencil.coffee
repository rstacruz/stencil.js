###! Stencil.js templating/binding engine
https://github.com/rstacruz/stencil.js
####

uniqCount = 0

# Helper function for matching a selector in a given element's descedants.
$find = ($el, sub) ->
  if sub.length then $el.find(sub) else $el

# Stencil object.
# Doing $('...').stencil returns an instance of this is.
#
class Stencil
  # A hash of { eventName: function } pairs of the functions that are bound to
  # the model object. The functions are generated (compiled) functions. It's
  # stored here so later they can be easily unbind()ed.
  #
  # handlers: {}

  # A hash of the supplied rules. These are flattened, taking comma-separated
  # event names into consideration. This hash looks like this:
  #   { 'change': { 'text h1': (function), 'text h2': (function) }, ... }
  #
  # events: {}

  constructor: (@$el, @model, rules, context) ->
    @events = @_flattenRules rules
    @context = context ? @model
    @_memoize this, 'getSingleRunner'

    @bind()

  # Makes a function cache results based on the given parameters.
  # This is used to compile your directives into simple functions.
  _memoize: (obj, attr) ->
    # The hasher used for the functions as a key for the cache store.
    hasher = (a, b, $el) ->
      uniq = $el[0].uniq ?= uniqCount++
      [a, b, uniq]

    obj[attr] = _.memoize obj[attr], hasher

  bind: ->
    # If there is no model supplied, or if it doesn't support events, don't
    # bother binding and just silently move on. This will be the case of
    # `$('...').stencil(bindings)` (called without a model).
    if @model?.on

      # Unbind first just to be sure. (This will do nothing if it hasn't been bound before)
      @unbind()

      # Save the handlers so we can unbind them later if need be.
      @handlers = {}
      _.each @events, (directives, event) =>
        @handlers[event] = (args...) => @run event, args...
        @model.on event, @handlers[event]

    this

  # Unbinds.
  unbind: ->
    if @model?.off and @handlers
      _.each @handlers, (fn, event) => @model.off event, fn
      @handlers = null

    this

  # Flattens the rule list, taking comma-separated selectors into
  # consideration.
  _flattenRules: (rules) ->
    re = {}
    _.each rules, (directives, eventList) =>
      # Account for the old syntax of comma-separated event names
      events = eventList.replace(/,/g, ' ').split(/\ +/)
      _.each events, (event) =>
        re[event] ?= {}
        _.extend re[event], directives

    re

  # Runs a group of events.
  run: (events='*', args...) ->
    return @runGlob(events)  if events.indexOf('*') > -1
    events = [events]  unless _.isArray(events)

    @runDirectives @getDirectivesFor(events), args
    this

  # Given a hash of directives, run them against element {$el}. Pass the
  # arguments {args} to the handlers.
  runDirectives: (directives, args, $el=@$el) ->
    fn = @getRunner(directives, $el)
    fn(args)

  getRunner: (directives, $el=@$el) ->
    runners = _.map directives, (handler, matcher) =>
      @getSingleRunner(matcher, handler, $el)

    (args) ->
      _.each runners, (runner) -> runner(args)

  # Returns a runner for a given directive (ie, matcher/handler pair).
  getSingleRunner: (matcher, handler, $el) ->
    match = (str, regex) ->
      return []  unless regex
      m = str.match(regex)
      throw "Matcher error: '#{str}'" unless m
      m

    m = match matcher, @formats.selector
    action = m[1]
    selector = m[2]

    throw "Unknown action: '#{action}'" unless @runners[action]

    m = match selector, @formats[action]
    @runners[action].apply this, [selector, handler, $el, m[1], m[2], m[3]]

  formats:
    selector: /^\s*([^\s]+)\s*(.*?)\s*$/
    add:      /^(.*?)\s*>\s*([^>]+?)$/
    attr:     /^(.*?)\s*@([A-Za-z0-9\-\_]+)$/
    remove:   /^(.*?)\s*>\s*([^>]+?)\s*@([A-Za-z0-9\-\_]+)\s*$/

  runners:
    default: (selector, handler, $el, action) ->
      fn = _.bind(handler, @context)
      (args) =>
        val = fn(args...)
        $find($el, selector)[action](val)

    html: (selector, handler, $el) ->
      @runners.default.apply this, [selector, handler, $el, 'html']

    text: (selector, handler, $el) ->
      @runners.default.apply this, [selector, handler, $el, 'text']

    val: (selector, handler, $el) ->
      @runners.default.apply this, [selector, handler, $el, 'val']

    # It should be 'val', but we'll allow 'value' too.
    value: (selector, handler, $el) ->
      @runners.default.apply this, [selector, handler, $el, 'val']

    attr: (selector, handler, $el, sub, attribute) ->
      $_el = $find($el, sub)
      fn = _.bind(handler, @context)

      (args) =>
        $_el.attr attribute, fn(args...)

    add: (selector, handler, $el, sub, template) ->
      $_el = $find($el, sub)
      $tpl = $($_el.find(template)[0]).remove()

      (args) =>
        work = (_args) =>
          $new = $tpl.clone()
          runner = @getRunner handler, $new
          runner(_args)
          $_el.append $new

        # Handle Backbone collection 'reset' events, or arrays.  If the 'add'
        # action was invoked with a collection/array (such as `.run('reset',
        # [a,b,c])`), iterate over them and add them all.
        if _.isArray(args[0])
          _.each args[0], (model) => work [model]

        else if args[0].each
          args[0].each (model) => work [model]

        # Else, assume it's a single item (like in Backbone 'add' events).
        # Handles the case of `.run('add', person)`.
        else
          work args

    remove: (selector, handler, $el, m1, m2, attribute) ->
      $_el = $find($el, m1)
      fn = _.bind(handler, @context)

      (args) =>
        val = fn(args...)
        $find($_el, m2).filter("[#{attribute}=\"#{val}\"]").remove()

  runGlob: (glob) ->
    events = _.filter _.keys(@events), (event) ->
      event.match new RegExp("^#{glob.replace('*', '.*')}$") # TODO: RegExp.escape
    @run events

  # Returns directives for the given list of events.
  getDirectivesFor: (events) ->
    events = [events]  unless _.isArray(events)

    directives = {}
    _.each events, (event) =>
      if typeof @events[event] is 'object'
        _.extend directives, @events[event]

    directives

# jQuery/Zepto
$.fn.stencil = (args...) ->
  new Stencil this, args...

