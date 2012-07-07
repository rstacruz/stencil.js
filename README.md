# Stencil.js (experimental!)

Fast JS binding engine (slash template engine).

Perfect with [Backbone.js][b]!

## How to use

You'll need [underscore.js][u] and [jQuery][j] or Zepto.

``` html
<script src='underscore.js'></script>
<script src='jquery.js'></script>
<script src='stencil.js'></script>  <!-- yay! -->
```

[u]: http://underscorejs.org
[j]: http://jquery.com
[b]: http://backbonejs.org

## Backbone usage example

Stencil does not require Backbone. However, it's best used to bind events to
Backbone models/collections to make HTML respond to it.

``` coffee
class PersonView extends Backbone.View
  # Let's define a simple HTML template.
  template:
    '''
    <div class='person'>
      <h2>
        <span class='first'></span>
        <span class='last'></span>
      </h2>
    </div>
    '''

  # These are the bindings that will be bound to a model (change:first_name,
  # change:last_name), along with directives on how to respond to those events.
  bindings:
    'change:first_name':
      'html h2 .first':     -> @get('first_name')
      'html .avatar@title': -> @get('first_name')

    'change:last_name':
      'html h2 .last': -> @get('first_name')

  initialize: (@model) ->
    # Let's render the element! First, let's bring in the static HTML template:
    @$el.html template

    # Then let's make a stencil that binds your bindings to your model:
    @stencil = @$el.stencil(@model, @bindings)

    # Now let's trigger all the `change` bindings, which will effectively
    # populate the element:
    @stencil.run 'change:*'

    # We're done. Yay!
```

Let's try it:

``` coffee
person = new Person first_name: "Jack", last_name: "Harkness"

# Just making the view will populate the element (by running 'change:*').
view = new PersonView model: person, el: $(".person")

# Now change something in the model. Backbone will trigger the
# 'change:last_name' event...
person.set last_name: "Boe"

# ...which the stencil will catch, and the view will respond. Hooray!
```

## Non-Backbone usage

``` coffee
# Let's build a simple stencil...
stencil = $("#foo").stencil
  'edit':
    'html h2 .first':     (p) -> p.first_name
    'html .avatar@title': (p) -> p.first_name
    'html h2 .last':      (p) -> p.last_name

# Then let's say your data looks like:
person = (first_name: "Rose", last_name: "Tyler")

# Now you can run it!
stencil.run 'edit', person
```

## Getting started

To start, create a stencil object that links your model events to
directives.

``` coffee
bindings =
  'change:name':
    'html h2': -> @get('name')
    'attr a.permalink@href': -> @url()

  'change:content':
    'html .content': -> @get('content')

# Backbone:
stencil = $(@el).stencil @model, bindings

# Not Backbone:
stencil = $(@el).stencil bindings
```

The `model` parameter is (1) where events will be bound to, and (2) the `this`
in the functions that you'll define in your bindings. It is optional.

This makes it so that everytime the `change:name` happens on the model, the h2
text and a.permalink's href attribute is updated with `model.get('name')` and
`model.url()` respectively.

Stencil automatically binds to the given model as long as it responds to `.on`
or `.off`. Great for Backbone models or collections!

``` coffee
# Assuming this throws a 'change:name' event, h2 and a.permalink will
# get updated.
@model.set 'name', 'Hello'
```

You can run all directives at once. This is great for initializing the element
with content:

``` coffee
stencil.run('change:*')
```

## Binding directives

You can have a directive to edit HTML from an element:

``` coffee
'html h2': -> @get('name')       # <h2>Hello</h2>
```

or text:

``` coffee
'text h2': -> @get('name')       # <h2>Hello</h2>
```

Attributes are okay:

``` coffee
'attr a@href': -> @url()         # <a href='/url/'></a>
```

Self attributes are cool too (it works on the top level element):

``` coffee
'attr @data-id': -> @id          # <div id='id-here'>
```

## Multiple events

You can comma-separate the events.

``` coffee
stencil = $(@el).stencil @model,
  'change:first_name, change:last_name':
    'html h2': -> @get('last_name') + ", " + @get('first_name')
```

## Working with arrays and collections

To add, make a directive with a matcher `add PARENT > CHILD`.

To remove, you'll need `remove SELECTOR @ATTR`. Yes, you'll need attr, because
that's what matches the thing to be deleted.

``` coffee
class AddressBook extends Backbone.View
  bindings:
    # We'll make a binding to a Backbone collection's `add` and `reset` events.
    'add, reset':

      # The # To add, make a directive with a matcher `add PARENT > CHILD`.
      # Whenever the above events (add/reset) are triggered, this directive will
      # add a `li` to the `ul`, and executes the sub-directives to populate the
      # `li`.
      #
      # If the event is triggered with an object that's an array or a list (such
      # as a Backbone collection, in the case of 'reset'), it will be iterated
      # though and one element will be added for each item.
      #
      # If it's called with a non-array/list (such as a Model, in the case of
      # the 'add' event), one element will be added.
      'add ul > li':
          'attr @data-id': (person) -> person.cid
          'text h3':       (person) -> person.get('name')
          'text .add':     (person) -> person.get('address')

    # To remove, you'll need `remove SELECTOR @ATTR`. Yes, you'll need attr,
    # because that's what matches the thing to be deleted.
    # This will delete any `ul li` that has a 'data-id' attribute that matches
    # the person's cid.
    'remove':
      'remove ul li@data-id': (person) -> person.cid

  initialize: (@collection) ->
    @$el.html @template
    @stencil = @$el.stencil(@collection, @bindings)

    # Let's simulate a reset to populate it.
    @stencil.run 'reset', @collection
```

## Attributes

You can access your stencil's data using the following attributes:

``` coffee
stencil.model
stencil.el
stencil.events
```
