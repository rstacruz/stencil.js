v1.1.0 - Feb 12, 2013
---------------------

New `val` runner, which allows you to change values of input fields.

``` coffee
bindings =
  'change:name':
    'val textarea': -> @get('name')

stencil = $(...).stencil(@model, bindings)
```

Changed the syntax of multiple events to space-separated. The old 
comma-separated syntax still works for backward-compatibility.

``` coffee
bindings =
  'change:first_name change:last_name':
    'html h2': -> @model.get('last_name') + ", " + @model.get('first_name')

stencil = $(@el).stencil @model, bindings, this
```

You can now pass a 3rd parameter to `.stencil()` to define the context of 
functions. In fact, this is now the prescribed syntax.

``` coffee
# Notice how the function here calls `@model`. The `this` in this case
# comes from the 3rd parameter passed onto `.stencil()`.

@bindings =
  'change:name':
    'html h2': -> @model.get('name')

@stencil = @$el.stencil(@model, @bindings, this)
```

Version is now available via `$.stencil.version`.

``` coffee
alert($.stencil.version);  //=> "1.1.0"
```

v1.0.0 -- July 7, 2012
----------------------

Initial release.
