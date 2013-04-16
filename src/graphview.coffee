
class GraphView

  setUp: =>
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

  displayGraph: =>
    graphConf = @config.graphs[@currentGraph]
    $('#container').html(@graph)
    $('h1#title').html(graphConf.title)
    @currentGraph = (@currentGraph + 1) % @config.graphs.length
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
    series = graph.series.concat(@config.settings.graphiteAdditionalSeries)
    "#{@config.sources.graphite}/render/?width=#{@imageWidth}&height=#{@imageHeight}&target=#{series.join(',')}&from=#{from}&graphOnly=false&hideLegend=true&areaMode=first&lineWidth=2"

  getCactiURL: (graph) ->
    endTime = Math.floor((new Date().getTime())/1000)
    startTime = endTime - (@config.settings.timeRange * 60 * 60)
    "#{@config.sources.cacti}/graph_image.php?action=zoom&local_graph_id=#{graph.id}&rra_id=0&graph_height=#{@imageHeight}&graph_width=#{@imageWidth}&graph_nolegend=1&graph_end=#{endTime}&graph_start=#{startTime}&view_type=tree&notitle=1"

  loadConfig: ->
    $.ajax('config.json', {'dataType': 'json'})
      .fail((x, status, error) -> 
          $('#container').html("Error loading config: #{status} (#{error})"))
      .success((data) => 
                  @config = data
                  @setUp())

  updateWindowSize: =>
    @imageHeight = $(window).height() - 50
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


