express = require('express')
app = express()
require('express-ws')(app)

browserify = require('browserify-middleware')
browserify.settings
	transform: ['coffeeify']
	extensions: ['.coffee']
	grep: /\.coffee$/

ws = require('ws')
ws.prototype.json =(o)->@send JSON.stringify(o)

devices = { 'ididid': {mac: 'ididid', powered: true}}
clientIdx = 0
clients = {}
handler = {}

app.get '/client/index.js', browserify(__dirname + '/client/index.coffee')

app.get '/', (req, res)->
	res.send("<script src='/client/index.js'></script>")
	res.end()
	for id, dev of devices
		dev.ws.json power: 'toggle'


app.ws '/ws', (ws, req)->
	console.log("websocket client connected")
	ws.on 'message', (msg)->
		console.log("websocket message: #{msg}")
		try
			info = JSON.parse(msg)
		catch
			console.log("failed to decode message")
			return

		for event, data of info
			handler[event]? ws, data

	ws.on 'close', ->
		console.log("Lost socket #{ws.address}.")
		if ws.address of devices
			delete devices[ws.address]

handler.client = (ws, data)->
	ws.id = (clientIdx += 1)
	clients[ws.id] = {ws, data}
	ws.json devices: devices

handler.toggle = (ws, id)->
	devices[id]?.ws.json power: 'toggle'

handler.device = (ws, data)->
	ws.id = data.mac
	console.log("registering device: ", ws.id)
	devices[ws.id] = {ws, info: data}
	ws.json registered: true

handler.update = (ws, data)->
	dev = devices[ws.id]
	dev.info[k] = v for k, v of data
	ws.json updated: true

app.listen 9001, -> console.log "listening on 9001."
