## Getting started

To start, create a binding object that links your model events to Pure
directives.

    binding = $(@el).stencil @model, 
      'change:name':
        'h2': -> @get('name')
        'a.permalink@href': -> @url()

      'change:content':
        '.content': -> @get('content')

This makes it so that everytime the `change:name` happens on the model, the h2
text and a.permalink's href attribute is updated with `model.get('name')` and
`model.url()` respectively.

    # Assuming this throws a 'change:name' event, h2 and a.permalink will
    # get updated.
    @model.set 'name', 'Hello'

You can run all directives at once. This is great for initializing the element
with content:

    binding.run('*')
    binding.run('change:*')

## Directives

Directives are usually selectors:

    'h2': -> @get('name')       # <h2>Hello</h2>

Attributes are okay:

    'a@href': -> @url()         # <a href='/url/'></a>

Self attributes are cool too (it works on the top level element):

    '@data-id': -> @id          # <div id='id-here'>

## Multiple events

You can comma-separate the events.

    binding = $(@el).listenTo @model,
      'change:first_name,change:last_name':
        'h2': -> @get('last_name') + ", " + @get('first_name')

## Backbone usage example

ListenTo does not require Backbone, but it's best used for Backbone models.

    class PersonView extends Backbone.View
      bindings:
        'change:first_name':
          'h2 .first': -> @get('first_name')
        'change:last_name':
          'h2 .last': -> @get('first_name')

      initialize: (@model) ->
        @binding = @$el.listenTo(@model, @bindings)

## Collections

    class AddressBook extends Backbone.View
      bindings:
        'add':
          'ul -> li':
            '@data-id': (person) -> person.id
            'h3':       (person) -> person.get('name')
            '.add':     (person) -> person.get('address')
        'remove':
          '- ul li@data-id': (person) -> person.id

      initialize: (@collection) ->
        @binding = @$el.listenTo(@collection, @bindings)

## Attributes

You can access your binding's data using the following attributes:

    binding.model
    binding.el
    binding.events
