# [Slider.js](http://demo.greweb.fr/slider) by @greweb 

# Util function : modulo for negative values
mod = (X,Y) -> X-Y*Math.floor(X/Y)

# RequestAnimationFrame polyfill : https://gist.github.com/997619
requestAnimationFrame = `function(a,b){while(a--&&!(b=window["oR0msR0mozR0webkitR0r".split(0)[a]+"equestAnimationFrame"]));return b||function(a){setTimeout(a,15)}}(5)`

# return the current millisecond timestamp
currentTime = `function(){return new Date().getTime()}`


# Slider template
# ---------------
tmplSlider = (o) ->
  slider = $("""
  <div class="slider">
    <div class="loader"><span class="spinner"></span> Loading photos... (<span class="percent">0</span>%)</div>
    <div class="slide-images"></div>
    <div class="options">
      <a class="prevSlide" href="javascript:;">prev</a>
      <span class="slide-pager"></span>
      <a class="nextSlide" href="javascript:;">next</a>
    </div>
  </div>
  """)
  slider.find('.slide-images').append(
    $.map(o.slides, (slide) -> $('<div class="slide-image">'+
      (slide.link ? '<a href="'+slide.link+'" target="_blank">')+
      '<img src="'+slide.src+'">'+
      (slide.name ? '<span class="caption">'+slide.name+'</span>')+
      (slide.link ? '</a>')+
      '</div>')[0]
    )
  )
  slider.find('.slide-pager').append $.map(o.slides, (slide, i) ->
    $('<a href="javascript:;">' + (i + 1) + '</a>')[0]
  )
  slider

# Slider - a lightweight slider
# -----------------------------
# Constructor : init container node and current slide number
class Slider
  constructor: (container) -> @container = $(container)
  current: 0
  lastHumanNav: 0
  duration: 5000
  tmpl: tmplSlider
  
  # Util function : return the circular value of num
  circular: (num) -> mod num, @slides.size()

  # Go to slide number `num` : update both DOM and this.current
  slide: (num = 0) ->
    # num must be between 0 and nbslides-1
    num = Math.max(0, Math.min(num, @slides.size()-1))
    if @slides && @pages
      # Move current class in **slides**
      @slides.eq(@current).removeClass "current"
      @slides.eq(num).addClass "current"
      # Move current class in **pages**
      @pages.eq(@current).removeClass "current"
      @pages.eq(num).addClass "current"
    @current = num
    this

  # Go to circular next slide (will call `slide`)
  next: -> @slide @circular(@current+1)

  # Go to circular previous slide (will call `slide`)
  prev: -> @slide @circular(@current-1)

  # Change the duration between each slide
  setDuration: (@duration = 5000) ->

  # Change the slider transition CSS class
  setTransition: (transition) ->
    if @node
      @node.removeClass(@transition) if @transition
      @node.addClass(transition) if transition
    @transition = transition
    this

  # Change the slider theme CSS class
  setTheme: (theme = "theme-dark") ->
    if @node
      @node.removeClass(@theme) if @theme
      @node.addClass(theme) if theme
    @theme = theme
    this

  # set slider size
  setSize: (@w="640px", @h="430px") ->
    if @node
      @node.width w
      @node.find(".slide-image").width w
      @node.find(".slide-images, .slider-image").height h
    this

  # Fetch photos with a JSON providing its `url`.
  # If `options` is defined, passing it in request params.
  # If `transformer` is defined, using it to transform the json
  # to a compatible json to pass to `Slider.setPhotos`.
  fetchJson: (url, options, transformer) ->
    params = $.extend({}, options)
    transformer ?= (json) -> json
    $.getJSON url, params, (json) => @setPhotos transformer(json)
    this

  # Sync slider data to DOM
  _sync: ->
    @setTransition @transition
    @setTheme @theme
    @setSize @w, @h
    @slide @current if @slides
  
  # `slides` : format: array of { src, name, link (optional) } 
  setPhotos: (@photos) ->
    # Templating and appending to DOM
    @node = @tmpl(slides: photos).addClass("loading")
    @container.empty().append @node
    @current = 0
    @_sync()
    # Loading all images before showing the slider
    nbLoad = 0
    imgs = @node.find(".slide-image img").bind("load", =>
      total = imgs.size()
      if ++nbLoad == total
        @node.removeClass "loading"
        @start()
      # Update loader progression (in percent)
      @node.find(".loader .percent").text Math.floor(100 * nbLoad / total)
    )
    @node.find(".loader").text "No photo"  if imgs.size() == 0
    this
  
  # Start the slider
  start: ->
    @slides = @node.find(".slide-image")
    @pages = @node.find(".slide-pager a")
    @_sync()
    @_bind()
    this
  
  # Bind slider DOM events for navigation
  _bind: ->
    @node.find(".prevSlide").click => @prev()
    @node.find(".nextSlide").click => @next()
    self = this
    @node.find(".slide-pager a").each (i) ->
      $(this).click -> self.slide i
    now = -> currentTime()
    @node.find(".options a").click => @lastHumanNav = now()
    
    if not @timeout
      loop_ = =>
        @next() if now() - @lastHumanNav > 2000
        @timeout = setTimeout(loop_, @duration)
      @timeout = setTimeout(loop_, @duration)
    this


simpleTransitionFunction = ( clipFunction ) ->
    render: (self, from, to, progress) ->
      {width, height} = self.canvas[0]
      ctx = self.ctx
      self.drawImage self.images[from]
      ctx.save()
      ctx.beginPath()
      clipFunction ctx, width, height, progress
      ctx.clip()
      self.drawImage self.images[to]
      ctx.restore()


YantsTransitionFunctions =
  # A clock load effect
  clock: simpleTransitionFunction (ctx, w, h, p) ->
    ctx.moveTo w/2, h/2
    ctx.arc w/2, h/2, Math.max(w, h), 0, Math.PI*2*p, false

  # A circle open effect
  circle: simpleTransitionFunction (ctx, w, h, p) ->
    ctx.moveTo w/2, h/2
    ctx.arc w/2, h/2, 0.6*p*Math.max(w, h), 0, Math.PI*2, false

  # A vertical open effect
  verticalOpen: simpleTransitionFunction (ctx, w, h, p) ->
    ctx.rect (1-p)*w/2, 0, w*p, h

  # A horizontal open effect
  horizontalOpen: simpleTransitionFunction (ctx, w, h, p) ->
    ctx.rect 0, (1-p)*h/2, w, h*p

  # A blured fade left effect
  fadeLeft: 
    init: (self, from, to) ->
      {width, height} = self.canvas[0]
      self.clean()
      self.drawImage self.images[from]
      fromData = self.ctx.getImageData 0, 0, width, height
      self.clean()
      self.drawImage self.images[to]
      toData = self.ctx.getImageData 0, 0, width, height
      output = self.ctx.createImageData width, height
      return fromData: fromData, toData: toData, output: output

    render: (self, from, to, progress, data) ->
      blur = 150
      {width, height} = self.canvas[0]
      ctx = self.ctx
      fd = data.fromData.data
      td = data.toData.data
      out = data.output.data
      
      `(function(){
       for (var x = 0; x < width; x += 1) {
         p1 = Math.min(Math.max(x-width*progress, 0), blur)/blur
         p2 = 1-p1
        for (var y = 0; y < height; y += 1) {
         var b = (y*width + x)*4
         for (var c = 0; c < 3; c += 1) {
           var i = b + c;
           out[i] = p1 * (fd[i] ) + p2 * (td[i] )
         }
         out[b + 3] = 255;
       }
     }
      }())`
      self.ctx.putImageData data.output, 0, 0


tmplSliderWithCanvas = (o) ->
  node = tmplSlider o
  node.find('div.slide-images').after('<canvas class="slide-images" />')
  node

# Let's add canvas transitions
class SliderWithCanvas extends Slider
  transitionFunction: YantsTransitionFunctions.clock
  transitionDuration: 1000
  tmpl: tmplSliderWithCanvas

  _sync: () ->
    renderMode = @renderMode
    super
    @setRenderMode(renderMode)

  start: () ->
    @notCanvas = @node.find '.slide-images:not(canvas)'
    @canvas = @node.find 'canvas.slide-images'
    @ctx = @canvas[0].getContext '2d'
    @images = $.map(@photos, ((photo) => 
      img = new Image()
      img.src = photo.src
      img
    )) if @photos
    super

  setSize: (w, h) ->
    super w, h
    @canvas.attr("height", h).attr("width", w) if @canvas
    this

  setRenderMode: (@renderMode) ->
    if @canvas
      if @renderMode is 'canvas'
        @drawImage @images[@current]
        @notCanvas.hide()
        @canvas.show()
      else
        @canvas.hide()
        @notCanvas.show()
    this

  setTransition: (transition) -> 
    @setRenderMode 'css'
    super transition
    this

  # Change the slider transition function (for the canvas animation)
  setTransitionFunction: (@transitionFunction) -> 
    @setRenderMode 'canvas'
    this

  # Change the slider transition duration (means the time of the transition)
  setTransitionDuration: (@duration) ->
    @setRenderMode 'canvas'
    this

  slide: (num) ->
    @fromSlide = @current
    @toSlide = num
    @transitionStart = currentTime()
    if @ctx and @renderMode is 'canvas'
      @startRender()
    super num

  clean: -> @ctx.clearRect 0, 0, @canvas[0].width, @canvas[0].height

  drawImage: (img) -> 
    {width, height} = @canvas[0]
    @ctx.drawImage img, 0, 0, width, width*img.height/img.width

  startRender: ->
    if @transitionFunction.init
      @tfdata = @transitionFunction.init this, @fromSlide, @toSlide
    @render()

  render: ->
    now = currentTime()
    if now >= @transitionStart
      progress = Math.min(1, (now - @transitionStart) / @transitionDuration)
      if progress == 1
        @clean()
        @drawImage @images[@toSlide]
      else
        @transitionFunction.render this, @fromSlide, @toSlide, progress, @tfdata
        requestAnimationFrame (=>@render()), @canvas[0]


window.Slider = SliderWithCanvas
window.YantsTransitionFunctions = YantsTransitionFunctions