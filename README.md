# Stencil

Fast JS binding engine (slash template engine).

Perfect with Backbone!

## How to use

You'll need [underscore.js][u] and [jQuery][j] or Zepto.

``` html
<script src='underscore.js'></script>
<script src='jquery.js'></script>
<script src='stencil.js'></script>  <!-- yay! -->
```

[u]: http://underscorejs.org
[uj: http://jquery.com

## Getting started

To start, create a stencil object that links your model events to
directives.

``` coffee
stencil = $(@el).stencil @model,
  'change:name':
    'html h2': -> @get('name')
    'attr a.permalink@href': -> @url()

  'change:content':
    'html .content': -> @get('content')
```

This makes it so that everytime the `change:name` happens on the model, the h2
text and a.permalink's href attribute is updated with `model.get('name')` and
`model.url()` respectively.

``` coffee
# Assuming this throws a 'change:name' event, h2 and a.permalink will
# get updated.
@model.set 'name', 'Hello'
```

You can run all directives at once. This is great for initializing the element
with content:

``` coffee
stencil.run('*')
stencil.run('change:*')
```

## Directives

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

## Backbone usage example

Stencil does not require Backbone, but it's best used for Backbone models.

``` coffee
class PersonView extends Backbone.View
  stencils:
    'change:first_name':
      'html h2 .first': -> @get('first_name')
    'change:last_name':
      'html h2 .last': -> @get('first_name')

  initialize: (@model) ->
    @stencil = @$el.stencil(@model, @stencils)
```

## Collections

To add, make a directive with a matcher `add PARENT > CHILD`.

To remove, you'll need `remove SELECTOR @ATTR`. Yes, you'll need attr, because
that's what matches the thing to be deleted.

``` coffee
class AddressBook extends Backbone.View
  stencils:
    'add':
      'add ul > li':
        'attr @data-id': (person) -> person.id
        'text h3':       (person) -> person.get('name')
        'text .add':     (person) -> person.get('address')
    'remove':
      'remove ul li@data-id': (person) -> person.id

  initialize: (@collection) ->
    @stencil = @$el.stencil(@collection, @stencils)
```

## Attributes

You can access your stencil's data using the following attributes:

``` coffee
stencil.model
stencil.el
stencil.events
```
