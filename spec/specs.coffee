Person = Backbone.Model.extend({})

People = Backbone.Collection.extend
  model: Person

describe 'Stencil', ->
  PersonView = Backbone.View.extend
    template: '''
      <div id='post'>
        <h2>x</h2>
        <span class='email'></span>
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
  ]

  beforeEach ->
    @view = new PeopleView
    @people = new People

  afterEach ->
    @view.remove()

  describe 'groups', ->
    beforeEach ->
      @stencil = @view.$el.stencil @people,
        'add':
          'add ul > li':
            'attr @data-id': (person) -> person.cid
            'text h2':       (person) -> person.get 'name'

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

    xit 'should work with reset', ->
      @people.reset([persons[1], persons[0]])

      expect(@people.models.length).toBe 2
      alert @view.$el.html()
      # expect(@view.$el.find('li').length).toBe 2
