# Graphview

*A simple app to rotate full-screen graphs on a systems monitoring display*

Inspired by [CactiView](https://github.com/lozzd/cactiview), Graphview
runs entirely in the browser, and provides graph image preloading to
avoid progressive loading annoyance on slow connections.

Supports displaying graphs from Cacti and Graphite, iframes (like New
Relic), Jenkins build status (currently poorly styled), as well showing the time.

## Usage

Check out example-config.json for how to configure. It needs to be
served from a webserver to work. It will try and load config.json by
default; you can override using ?config=filename.json.

## Credits

-- Russ Garrett <russ@garrett.co.uk>
