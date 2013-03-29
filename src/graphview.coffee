
class GraphView
  setUp: =>
    @updateWindowSize()
    $(window).resize(@updateWindowSize)
    @currentImage = 0
    @preloadImage(@getURL(@config.graphs[0]))
    @displayImage()

  preloadImage: (url) ->
    @img = new Image()
    @img.src = url

  displayImage: =>
    $('#container').html(@img)
    @currentImage = (@currentImage + 1) % @config.graphs.length
    setTimeout(@displayImage, @config.settings.dwellTime)
    @preloadImage(@getURL(@config.graphs[@currentImage]))

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
    "#{@config.sources.graphite}/render/?width=#{@imageWidth}&height=#{@imageHeight}&target=#{graph.series.join(',')}&from=#{from}&graphOnly=false&hideLegend=true&areaMode=first&lineWidth=2"

  getCactiURL: (graph) ->
    endTime = Math.floor((new Date().getTime())/1000)
    startTime = endTime - (@config.settings.timeRange * 60 * 60)
    "#{@config.sources.cacti}/graph_image.php?action=zoom&local_graph_id=#{graph.id}&rra_id=0&graph_height=#{@imageHeight}&graph_width=#{@imageWidth}&graph_nolegend=1&graph_end=#{endTime}&graph_start=#{startTime}&view_type=tree&notitle=1"

  loadConfig: ->
    $.ajax('config.json')
      .fail((x, status, error) -> 
          $('#container').html("Error loading config: #{status} (#{error})"))
      .success((data) => 
                  @config = data
                  @setUp())

  updateWindowSize: =>
    @imageHeight = $(window).height()
    @imageWidth = $(window).width()

  start: => @loadConfig()

gv = new GraphView

$(document).ready(gv.start)
