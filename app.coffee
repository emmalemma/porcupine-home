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

devices = {}
clientIdx = 0
clients = {}
handler = {}

app.get '/client/index.js', browserify(__dirname + '/client/index.coffee')

stylus = require 'express-stylus'
nib = require 'nib'
styleDir = __dirname + '/style'
app.use stylus
  src: styleDir
  use: [nib()]
  import: ['nib']
app.use(express.static(styleDir))

app.get '/', (req, res)->
	res.send("<script src='/client/index.js'></script>")
	res.end()


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
		if ws.device
			delete devices[ws.id]
		if ws.client
			delete clients[ws.id]

broadcast =(msg)->
	for idx, client of clients
		client.ws.json msg

handler.client = (ws, data)->
	ws.id = (clientIdx += 1)
	ws.client = yes
	clients[ws.id] = {ws, data}
	devs = {}
	devs[id] = dev.info for id, dev of devices
	ws.json devices: devs

handler.toggle = (ws, id)->
	devices[id]?.ws.json power: 'toggle'

handler.device = (ws, data)->
	ws.id = data.mac
	ws.device = yes
	console.log("registering device: ", ws.id)
	data.log = "[registered]\n"
	devices[ws.id] = {ws, info: data}
	ws.json registered: true

handler.eval = (ws, {id, code})->
	devices[id]?.ws.json eval: code

handler.update = (ws, data)->
	dev = devices[ws.id]
	dev.info[k] = v for k, v of data
	ws.json updated: true
	newdata = {}
	newdata[ws.id] = data
	broadcast devices: newdata

handler.log = (ws, data)->
	broadcast log: {id: ws.id, data}

app.listen 9001, -> console.log "listening on 9001."
