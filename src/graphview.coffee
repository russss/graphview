
class GraphView

  setUp: =>
    @graphLoaded = false

    if not @config.settings.header ? true
      $('#header').hide()
    if not @config.settings.clock ? true
      $('#date').hide()

    @updateWindowSize()
    $(window).resize(@updateWindowSize)
    @currentGraph = 0
    @preloadGraph(@config.graphs[0])
    @displayGraph()

  preloadGraph: (graph) ->
    if graph.source == 'iframe'
      @preloadIframe(graph.url)
    else
      @preloadImage(@getURL(graph))

  preloadImage: (url) ->
    @graph = new Image()
    $(@graph).bind('load', =>
      @graphLoaded = true
    )
    @graph.src = url

  preloadIframe: (url) ->
    @graph = $(document.createElement('iframe'))
    @graph.attr({
      src: url,
      width: @imageWidth, 
      height: @imageHeight,
      scrolling: "no",
      frameborder: "no"
    })
    @graphLoaded = true

  displayGraph: =>
    if not @graphLoaded
      # Wait for our image to load
      setTimeout(@displayGraph, 1000)
      return
    graphConf = @config.graphs[@currentGraph]
    $('#container').html(@graph)
    $('h1#title').html(graphConf.title)
    @currentGraph = (@currentGraph + 1) % @config.graphs.length
    @graphLoaded = false
    console.log(@config.settings.dwellTime)
    setTimeout(@displayGraph, @config.settings.dwellTime)
    @preloadGraph(@config.graphs[@currentGraph])

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
    url += "&graphOnly=false&hideLegend=true&areaMode=first&lineWidth=2"
    if graph.yMin?
      url += "&yMin=#{graph.yMin}"
    if graph.yMax?
      url += "&yMax=#{graph.yMax}"
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


