###! Stencil.js templating ###

class Listener
  constructor: (@$el, @model, rules) ->
    @events = @_flattenRules rules
    @memoize @, 'getSingleRunner'

    @bind()

  memoize: (obj, attr) ->
    all = (a,b,$el) ->
      # Hash the element
      $el.data('uniq') ? $el.data('uniq', Math.random())
      uniq = $el.data('uniq')
      [a,b,uniq]

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
    m = matcher.match(/^\s*([^\s]+)\s*(.*?)\s*$/)
    throw "Matcher error: '#{matcher}'" unless m

    action = m[1]
    selector = m[2]

    switch action
      # List remove?
      when 'remove'
        m = selector.match(/^(.*?)\s*<-\s*(.*?)\s*@\s*([A-Za-z0-9\-\_]+)$/)
        throw "Matcher error: '#{matcher}'" unless m
        @runners.remove.apply this, [selector, handler, $el, m[1], m[2], m[3]]

      # List add?
      when 'add'
        m = selector.match(/^(.*?)\s*>\s*([^>]+?)$/)
        throw "Matcher error: '#{matcher}'" unless m
        @runners.add.apply this, [selector, handler, $el, m[1], m[2]]

      # Attribute?
      when 'attr'
        m = selector.match(/^(.*?)\s*@([A-Za-z0-9\-\_]+)$/)
        throw "Matcher error: '#{matcher}'" unless m
        @runners.attr.apply this, [selector, handler, $el, m[1], m[2]]

      when 'html', 'text'
        @runners.default.apply this, [selector, handler, $el]

      else
        throw "Unknown action: '#{action}'"

  runners:
    default: (selector, handler, $el) ->
      fn = _.bind(handler, @model)
      (args) =>
        $el.find(selector).html fn(args...)

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
        if typeof args[0].length is 'number'
          args[0].each (model) =>
            work [model]
        # Single
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
$.fn.stencil = (args...) ->
  new Listener this, args...

