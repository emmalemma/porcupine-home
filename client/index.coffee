el = require('./coffee-hyperscript')
VDom = require 'virtual-dom'
render = require('./render')

update = null
handle = {}
devices = {}
state = {devices}

ws = new WebSocket("ws://#{location.host}/ws")
WebSocket.prototype.json =(o)->@send JSON.stringify o
ws.onopen =->
	ws.json client: 'register'

ws.onmessage = ({data: msg})->
	console.log "Message rec:", msg
	o = JSON.parse msg
	for event, data of o
		handle[event]? data

emit = ws.json.bind ws

handle.devices = (data)->
	for id, newdata of data
		dev = devices[id] ?= {}
		dev[k] = v for k, v of newdata
	do update

currentDom = null
rootElement = null
do initialize = ->
	rootElement = VDom.create currentDom = render(state, emit)
	html = VDom.create el 'html',
		el 'head',
			el 'meta', charset: 'UTF-8'
			el 'link', res: 'stylesheet', href: 'http://fonts.googleapis.com/css?family=Play|Comfortaa|Poiret+One'
			el 'link', rel: 'stylesheet', href: 'demo.css'
		el 'body'

	document.replaceChild html, document.documentElement
	document.body.appendChild rootElement

update = ->
	newDom = render(state, emit)
	patch = VDom.diff currentDom, newDom
	rootElement = VDom.patch rootElement, patch
	# console.log 'patching dom', newDom, 'patch', patch
	currentDom = newDom
