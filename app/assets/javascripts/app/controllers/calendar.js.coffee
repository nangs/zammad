class Index extends App.ControllerContent
  events:
    'click .js-new':         'new'
    'click .js-edit':        'edit'
    'click .js-delete':      'delete'
    'click .js-default':     'default'
    'click .js-description': 'description'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @interval(@load, 60000)
    #@load()

  load: =>
    @ajax(
      id:   'calendar_index'
      type: 'GET'
      url:  @apiPath + '/calendars'
      processData: true
      success: (data, status, xhr) =>

        App.Config.set('ical_feeds', data.ical_feeds)
        App.Config.set('timezones', data.timezones)

        # load assets
        App.Collection.loadAssets(data.assets)

        @render(data)
    )

  render: =>
    calendars = App.Calendar.search(
      sortBy: 'name'
    )
    for calendar in calendars

      # validate config
      for day in ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        if !calendar.business_hours[day]
          calendar.business_hours[day] = {}
      for day, meta of calendar.business_hours
        if !meta.active
          meta.active = false
        if !meta.timeframes
          meta.timeframes = []

      # get preview public holidays
      public_holidays_preview = {}
      if calendar.public_holidays
        from = new Date().setTime(new Date().getTime() - (5*24*60*60*1000))
        till = new Date().setTime(new Date().getTime() + (70*24*60*60*1000))
        keys = Object.keys(calendar.public_holidays).reverse()
        #for day, comment of calendar.public_holidays
        for day in keys
          itemTime = new Date( Date.parse( "#{day}T00:00:00Z" ) )
          if itemTime < till && itemTime > from
            public_holidays_preview[day] = calendar.public_holidays[day]
      calendar.public_holidays_preview = public_holidays_preview

    # show description button, only if content exists
    showDescription = false
    if App.Calendar.description
      if !_.isEmpty(calendars)
        showDescription = true
      else
        description = marked(App[ @genericObject ].description)

    @html App.view('calendar/index')(
      calendars:       calendars
      showDescription: showDescription
      description:     description
    )

  release: =>
    if @subscribeId
      App.Calendar.unsubscribe(@subscribeId)

  new: =>
    new App.ControllerGenericNew(
      pageData:
        title: 'Calendars'
        object: 'Calendar'
        objects: 'Calendars'
      genericObject: 'Calendar'
      callback:      @load
      container:     @el.closest('.content')
      large:         true
    )

  edit: (e) =>
    id = $(e.target).closest('.action').data('id')
    new App.ControllerGenericEdit(
      id: id
      pageData:
        title: 'Calendars'
        object: 'Calendar'
        objects: 'Calendars'
      genericObject: 'Calendar'
      callback:      @load
      container:     @el.closest('.content')
      large:         true
    )

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Calendar.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @load
    )

  default: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Calendar.find(id)
    item.default = true
    item.save(
      done: =>
        @load()
      fail: =>
        @load()
    )

  description: (e) =>
    new App.ControllerGenericDescription(
      description: App.Calendar.description
      container:   @el.closest('.content')
    )

App.Config.set( 'Calendars', { prio: 2400, name: 'Calendars', parent: '#manage', target: '#manage/calendars', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )