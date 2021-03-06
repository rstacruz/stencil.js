Person = Backbone.Model.extend({})

People = Backbone.Collection.extend
  model: Person

describe 'Stencil', ->
  PersonView = Backbone.View.extend
    template: '''
      <div id='post'>
        <h2>x</h2>
        <span class='email'></span>
        <textarea></textarea>
        <input type='text'>
      </div>
      '''

    initialize: ->
      @render()

    render: ->
      @$el.html @template
      $("#test").append @$el
      this

  beforeEach ->
    @view = new PersonView

  afterEach ->
    @stencil.unbind()
    @view.remove()

  describe 'Contexts', ->
    it 'should work', ->
      @view.person = new Person name: 'Jason', email: 'jason@hi.com'

      @stencil = @view.$el.stencil @view.person,
        'change:name':
          'text h2': -> @person.get 'name'
      , @view

      @stencil.run 'change:name'

      expect(@view.$el).toContainHtml '<h2>Jason</h2>'
      expect(@view.$el).not.toContainHtml '<span class="email">jason@hi.com</span>'

  describe 'Value runner', ->
    beforeEach ->
      @view.person = new Person name: 'Jane'

      @stencil = @view.$el.stencil @view.person,
        'change:name':
          'val textarea': -> @person.get 'name'
          'val input[type="text"]': -> @person.get 'name'
      , @view

    it 'for textarea', ->
      @stencil.run 'change:name'
      expect(@view.$el.find('textarea').val()).toEqual "Jane"

    it 'for text input', ->
      @stencil.run 'change:name'
      expect(@view.$el.find('input').val()).toEqual "Jane"

  describe 'Multi events', ->
    beforeEach ->
      @view.person = new Person firstname: 'Jason', lastname: 'Bourne'

      @stencil = @view.$el.stencil @view.person,
        'change:firstname change:lastname':
          'text h2': -> @get('firstname') + " " + @get('lastname')

    it 'should work (1)', ->
      @stencil.run 'change:firstname'
      expect(@view.$el).toContainHtml '<h2>Jason Bourne</h2>'

    it 'should work (2)', ->
      @stencil.run 'change:lastname'
      expect(@view.$el).toContainHtml '<h2>Jason Bourne</h2>'

  describe 'Bindngs', ->
    beforeEach ->
      @person = new Person name: 'Jason', email: 'jason@hi.com'

      @stencil = @view.$el.stencil @person,
        '_start':
          'attr @data-id': -> @cid
        'change:name':
          'text h2': -> @get 'name'
        'change:email':
          'text .email': -> @get 'email'
        'change:title':
          'attr h2@title': -> @get 'title'

    it 'should not run at first', ->
      expect(@view.$el).not.toContainHtml '<h2>Jason</h2>'
      expect(@view.$el).not.toContainHtml '<span class="email">jason@hi.com</span>'

    it 'single run', ->
      @stencil.run 'change:name'
      expect(@view.$el).toContainHtml '<h2>Jason</h2>'
      expect(@view.$el).not.toContainHtml '<span class="email">jason@hi.com</span>'

    it 'should be able to run() with glob', ->
      @stencil.run 'change:*'
      expect(@view.$el).toContainHtml '<h2>Jason</h2>'
      expect(@view.$el).toContainHtml '<span class="email">jason@hi.com</span>'

    it 'should respond to events', ->
      @person.set name: 'Aubrey'
      expect(@view.$el).toContainHtml '<h2>Aubrey</h2>'

      @person.set name: 'Malcolm'
      expect(@view.$el).toContainHtml '<h2>Malcolm</h2>'

    it 'should change attributes', ->
      @person.set title: 'Creative director'
      expect(@view.$('h2')).toHaveAttr 'title', 'Creative director'

    it 'should change attributes of itself', ->
      @stencil.run '_start'
      expect(@view.$el).toHaveAttr 'data-id', @person.cid

    it 'should unbind with unbind()', ->
      @person.set name: 'Aubrey'
      expect(@view.$el).toContainHtml '<h2>Aubrey</h2>'

      @stencil.unbind()

      @person.set name: 'Malcolm'
      expect(@view.$el).not.toContainHtml '<h2>Malcolm</h2>'

      @stencil.bind()

      @person.set name: 'Harold'
      expect(@view.$el).toContainHtml '<h2>Harold</h2>'

describe 'Collections', ->
  PeopleView = Backbone.View.extend
    template: '''
      <ul id='people'>
        <li>
          <h2>x</h2>
          <span class='email'>x</span>
        </li>
      </ul>
      '''

    initialize: ->
      @render()

    render: ->
      @$el.html @template
      $("#test").append @$el
      this

  persons = [
    new Person name: "Criss", email: 'criss@me.com'
    new Person name: "Sidney", email: 'sid@me.com'
    new Person name: "Rain", email: 'rain@me.com'
  ]

  beforeEach ->
    @view = new PeopleView
    @people = new People

  afterEach ->
    @view.remove()

  describe 'groups', ->
    beforeEach ->
      @stencil = @view.$el.stencil @people,
        'reset':
          'html ul': -> ''

        'add, reset':
          'add ul > li':
            'attr @data-id': (person) -> person.cid
            'text h2':       (person) -> person.get 'name'

        'remove':
          'remove ul > li @data-id':
            (person) -> person.cid

    it 'should add', ->
      @people.add persons[0]

      expect(@view.$el.find('li').length).toBe 1
      expect(@view.$el.find('li h2')).toHaveText persons[0].get('name')

    it 'should add again', ->
      @people.add persons[1]

      expect(@view.$el.find('li').length).toBe 1
      expect(@view.$el.find('li h2')).toHaveText persons[1].get('name')

    it 'should add multiple', ->
      @people.add persons[1]
      @people.add persons[0]

      expect(@people.models.length).toBe 2
      expect(@view.$el.find('li').length).toBe 2

    it 'should work with first reset', ->
      @people.reset([persons[1], persons[0]])

      expect(@people.models.length).toBe 2
      expect(@view.$el.find('li').length).toBe 2

    it 'should work with second empty reset', ->
      @people.reset([persons[1], persons[0]])

      @people.reset([])
      expect(@view.$el.find('li').length).toBe 0

    it 'should work with second non-empty reset', ->
      @people.reset([persons[1], persons[0]])

      @people.reset([persons[2]])
      expect(@view.$el.find('li').length).toBe 1

    it 'should work with remove', ->
      @people.reset([persons[1], persons[0]])

      expect(@view.$el.find('li').length).toBe 2
      @people.remove persons[1]

      expect(@view.$el.find('li').length).toBe 1
      expect(@view.$el).not.toContainHtml persons[1].get('name')
      expect(@view.$el).toContainHtml persons[0].get('name')

  describe 'Non-Backbone models', ->
    template = '''
      <ul id='people'>
        <li>
          <span></span>
        </li>
      </ul>
      '''

    beforeEach ->
      @$el = $(template)
      @bindings =
        add:
          'add  > li':
            'html span': (person) -> person.name

    it 'add a single person', ->
      stencil = @$el.stencil null, @bindings
      stencil.run 'add', (name: "Rose")

      expect(@$el).toContainHtml '<span>Rose</span>'

    it 'add multiple', ->
      people = [ (name: "Jackie"), (name: "Tyler") ]
      stencil = @$el.stencil people, @bindings
      stencil.run 'add', people

      expect(@$el).toContainHtml '<span>Jackie</span>'
