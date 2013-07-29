
class GraphView

  setUp: =>
    if not @config.settings.header ? true
      $('#header').hide()
    if not @config.settings.clock ? true
      $('#date').hide()

    @jenkinsTemplate = Handlebars.compile($("#jenkins-template").html())
    @updateWindowSize()
    $(window).resize(@updateWindowSize)
    @currentScreen = 0
    @preloadContent(@config.graphs[0])
    @displayContent()

  preloadContent: (graph) ->
    @contentLoaded = false
    @loadStart = new Date()
    switch graph.source
      when "iframe" then @preloadIframe(graph.url)
      when "graphite", "cacti" then @preloadImage(@getURL(graph))
      when "jenkins" then @preloadJenkins(graph.jobs)
      else
        @content = "Unknown content type: #{graph.source}"
        @contentLoaded = true

  preloadImage: (url) ->
    @content = new Image()
    $(@content).bind('load', =>
      @contentLoaded = true
    )
    @content.src = url

  preloadIframe: (url) ->
    @content = $(document.createElement('iframe'))
    @content.attr({
      src: url,
      width: @imageWidth, 
      height: @imageHeight,
      scrolling: "no",
      frameborder: "no"
    })
    @contentLoaded = true

  preloadJenkins: (jobs) ->
    job_data = []
    url = "#{@config.sources.jenkins}/api/json?jsonp=?"
    $.getJSON(url, (data) =>
      for job in data.jobs
        if jobs == "all" or job.name in jobs
          job_data.push({"name": job.name, "status": job.color})
      @content = @jenkinsTemplate({"jobs": job_data})
      @contentLoaded = true
    )

  displayContent: =>
    # Wait for our image to load, but not more than 2 minutes
    if not @contentLoaded and ((new Date()) - @loadStart) < 120000
      setTimeout(@displayContent, 1000)
      return
    graphConf = @config.graphs[@currentScreen]
    $('#container').html(@content)
    $('h1#title').html(graphConf.title)
    @currentScreen = (@currentScreen + 1) % @config.graphs.length
    setTimeout(@displayContent, @config.settings.dwellTime)
    @preloadContent(@config.graphs[@currentScreen])

  getURL: (graph) ->
    if graph.source == 'graphite'
      @getGraphiteURL(graph)
    else if graph.source == 'cacti'
      @getCactiURL(graph)

  getGraphiteURL: (graph) ->
    if graph.from?
      from = graph.from
    else
      from = "-#{@config.settings.timeRange} hours"
    series = graph.series
    if not graph.noAdditional?
      series = series.concat(@config.settings.graphiteAdditionalSeries)
    url = "#{@config.sources.graphite}/render/?width=#{@imageWidth}&height=#{@imageHeight}"
    url += "&target=#{series.join('&target=')}&from=#{from}"
    url += "&graphOnly=false"
    if graph.areaMode?
      url += "&areaMode=#{graph.areaMode}"
    else
      url += "&areaMode=first"
    url+= "&lineWidth=2"
    if not @config.settings.showLegend
      url += "&hideLegend=true"
    if graph.yMin?
      url += "&yMin=#{graph.yMin}"
    if graph.yMax?
      url += "&yMax=#{graph.yMax}"
    if graph.fontSize?
      url += "&fontSize=#{graph.fontSize}"
    url

  getCactiURL: (graph) ->
    endTime = Math.floor((new Date().getTime())/1000)
    startTime = endTime - (@config.settings.timeRange * 60 * 60)
    "#{@config.sources.cacti}/graph_image.php?action=zoom&local_graph_id=#{graph.id}&rra_id=0&graph_height=#{@imageHeight}&graph_width=#{@imageWidth}&graph_nolegend=1&graph_end=#{endTime}&graph_start=#{startTime}&view_type=tree&notitle=1"

  loadConfig: ->
    url = $.url().param('config') ? 'config.json'

    $.ajax(url, {'dataType': 'json'})
      .fail((x, status, error) -> 
          $('#container').html("Error loading config: #{status} (#{error})"))
      .success((data) => 
                  @config = data
                  @setUp())

  updateWindowSize: =>
    @imageHeight = $(window).height() - 60
    @imageWidth = $(window).width()

  start: => @loadConfig()

zeroPad = (value) ->
  value = value.toString()
  value = "0" + value while (value.length < 2)
  value

renderDate = ->
  date = new Date
  "#{date.getUTCFullYear()}/#{zeroPad(date.getUTCMonth() + 1)}/#{zeroPad(date.getUTCDate())} #{zeroPad(date.getUTCHours())}:#{zeroPad(date.getUTCMinutes())}:#{zeroPad(date.getUTCSeconds())} UTC"

updateDate = ->
  $('span#date').html(renderDate())
  setTimeout(updateDate, 500)

gv = new GraphView

$(document).ready(-> 
   gv.start()
   updateDate()
)


