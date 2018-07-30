el = require('./coffee-hyperscript')
VDom = require 'virtual-dom'
render = require('./render')

update = null
handle = {}
devices = {}
state = {devices, value: '=node.chipid()'}

wsdelay = 0
ws = null
do resetws =->
	wsdelay = 30 * 1000
	ws = new WebSocket("wss://home.emmalem.ma/ws")
	wsdelay = 0
	WebSocket.prototype.json =(o)->@send JSON.stringify o
	ws.onopen =->
		ws.json client: 'register'

	ws.onmessage = ({data: msg})->
		console.log "Message rec:", msg
		o = JSON.parse msg
		for event, data of o
			handle[event]? data

	ws.onclose =->
		setTimeout resetws, wsdelay


emit = (msg)->
	ws.json msg
	if msg.toggle and (dev = devices[msg.toggle])
		dev.synced = no
		dev.powered = not dev.powered
		update()

handle.devices = (data)->
	for id, newdata of data
		dev = devices[id] ?= {}
		dev[k] = v for k, v of newdata
		dev[k].synced = true
	do update

handle.log = ({id, data})->
	devices[id]?.log += data
	update()

currentDom = null
rootElement = null
do initialize = ->
	rootElement = VDom.create currentDom = render(state, emit)
	html = VDom.create el 'html',
		el 'head',
			el 'meta', charset: 'UTF-8'
			el 'meta', name:"viewport", content:"width=device-width, user-scalable=no"
			el 'link', res: 'stylesheet', href: 'https://fonts.googleapis.com/css?family=Play|Comfortaa|Poiret+One'
			el 'link', rel: 'stylesheet', href: '/css/index.css'
		el 'body'

	document.replaceChild html, document.documentElement
	document.body.appendChild rootElement

update = ->
	newDom = render(state, emit)
	patch = VDom.diff currentDom, newDom
	rootElement = VDom.patch rootElement, patch
	# console.log 'patching dom', newDom, 'patch', patch
	currentDom = newDom
