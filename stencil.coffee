###! Stencil.js templating/binding engine
https://github.com/rstacruz/stencil.js
####

uniqCount = 0

class Listener
  constructor: (@$el, model, rules) ->
    unless rules?
      rules = model; model = null

    @model = model
    @events = @_flattenRules rules
    @memoize @, 'getSingleRunner'

    @bind()

  memoize: (obj, attr) ->
    # Hash the element
    hasher = (a, b, $el) ->
      uniq = $el[0].uniq ?= uniqCount++
      [a, b, uniq]

    fn = obj[attr]
    obj[attr] = _.memoize fn, hasher

  bind: ->
    return unless @model?.on

    @unbind()

    # Save the handlers so we can unbind them later if need be.
    @handlers = {}
    _.each @events, (directives, event) =>
      @handlers[event] = (args...) => @run event, args...
      @model.on event, @handlers[event]

    this

  unbind: ->
    return unless @model?.off

    if @handlers
      _.each @handlers, (fn, event) => @model.off event, fn
      @handlers = null

    this

  # Flattens the rule list, taking comma-separated selectors into
  # consideration.
  _flattenRules: (rules) ->
    re = {}
    _.each rules, (directives, eventList) =>
      events = eventList.split(/, */)
      _.each events, (event) =>
        re[event] ?= {}
        _.extend re[event], directives

    re

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
      fn = _.bind(handler, @model)
      (args) =>
        val = fn(args...)
        $el.find(selector)[action](val)

    html: (selector, handler, $el) ->
      @runners.default.apply this, [selector, handler, $el, 'html']

    text: (selector, handler, $el) ->
      @runners.default.apply this, [selector, handler, $el, 'text']

    attr: (selector, handler, $el, m1, m2) ->
      $_el = $el
      $_el = $_el.find(m1)  if m1.length
      fn = _.bind(handler, @model)
      (args) =>
        $_el.attr m2, fn(args...)

    add: (selector, handler, $el, m1, m2) ->
      $_el = $el
      $_el = $_el.find(m1)  if m1.length
      $tpl = $($_el.find(m2)[0]).remove()

      (args) =>
        work = (_args) =>
          $new = $tpl.clone()
          runner = @getRunner handler, $new
          runner(_args)
          $_el.append $new

        # Collection reset
        if _.isArray(args[0])
          _.each args[0], (model) => work [model]

        else if args[0].each
          args[0].each (model) => work [model]

        # Single reset
        else
          work args

    remove: (selector, handler, $el, m1, m2, attribute) ->
      $_el = $el
      $_el = $_el.find(m1)  if m1.length
      fn = _.bind(handler, @model)

      (args) =>
        val = fn(args...)
        $_el.find(m2).filter("[#{attribute}=\"#{val}\"]").remove()

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
$.fn.stencil = (model, bindings) ->
  new Listener this, model, bindings

