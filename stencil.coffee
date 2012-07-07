###!
 * Stencil.js templating
###

class Listener
  constructor: (@$el, @model, rules) ->
    @events = @_flattenRules rules

    @memoize @runners, 'listAdd'
    @memoize @runners, 'listRemove'
    # @memoize @runners, 'attribute'
    # @memoize @runners, 'default'
    # @memoize @, 'getRunner'

    @bind()

  memoize: (obj, attr) ->
    all = (args...) -> all
    fn = obj[attr]
    obj[attr] = _.memoize fn, all

  bind: ->
    @unbind()

    # Save the handlers so we can unbind them later if need be.
    @handlers = {}
    _.each @events, (directives, event) =>
      @handlers[event] = (args...) => @run event, args
      @model.on event, @handlers[event]

    this

  unbind: ->
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

  run: (events='*', args) ->
    return @runGlob(events)  if events.indexOf('*') > -1
    events = [events]  unless _.isArray(events)

    @runDirectives @getDirectivesFor(events), @$el, args

  # Given a hash of directives, run them against element {$el}. Pass the
  # arguments {args} to the handlers.
  runDirectives: (directives, $el, args) ->
    _.each directives, (action, selector) =>
      @getRunner(selector, action, $el)(args)

  # Returns a runner for a given directive (ie, selector/action pair).
  getRunner: (selector, action, $el) ->
    # List remove?
    if m = selector.match(/^\s*(.*?)\s*<-\s*(.*?)\s*@\s*([A-Za-z0-9\-\_]+)\s*$/)
      @runners.listRemove.apply this, [selector, action, $el, m[1], m[2], m[3]]

    # List add?
    else if m = selector.match(/^\s*(.*?)\s*->\s*(.*?)\s*$/)
      @runners.listAdd.apply this, [selector, action, $el, m[1], m[2]]

    # Attribute?
    else if m = selector.match(/^\s*(.*?)\s*@\s*([A-Za-z0-9\-\_]+)\s*$/)
      @runners.attribute.apply this, [selector, action, $el, m[1], m[2]]

    else
      @runners.default.apply this, [selector, action, $el]

  runners:
    default: (selector, action, $el) ->
      fn = _.bind(action, @model)
      (args) =>
        $el.find(selector).html fn(args...)

    attribute: (selector, action, $el, m1, m2) ->
      $_el = $el
      $_el = $_el.find(m1)  if m1.length
      fn = _.bind(action, @model)
      (args) =>
        $_el.attr m2, fn(args...)

    listAdd: (selector, action, $el, m1, m2) ->
      $_el = $el
      $_el = $_el.find(m1)  if m1.length
      $tpl = $($_el.find(m2)[0]).remove()

      (args) =>
        $new = $tpl.clone()
        $new.attr 'data-random', Math.random() # Workaround!
        @runDirectives(action, $new, args)
        $_el.append $new

    listRemove: (selector, action, $el, m1, m2, attribute) ->
      $_el = $el
      $_el = $_el.find(m1)  if m1.length
      fn = _.bind(action, @model)
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
$.fn.stencil = (args...) ->
  new Listener this, args...

