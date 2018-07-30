express = require('express')

expressWS = require('express-ws')

browserify = require('browserify-middleware')
browserify.settings
	transform: ['coffeeify']
	extensions: ['.coffee']
	grep: /\.coffee$/

app = express()

styleDir = __dirname + '/style'

wshandler = (ws, req)->
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

process.env.SSL_CERT_PATH or= '/Users/bonobo/porcupine@home/certbot/live/home.emmalem.ma/fullchain.pem'
process.env.SSL_KEY_PATH or= '/Users/bonobo/porcupine@home/certbot/live/home.emmalem.ma/privkey.pem'

if process.env.SSL_CERT_PATH
	https = require('https')
	fs = require('fs')
	credentials =
		cert: fs.readFileSync(process.env.SSL_CERT_PATH)
		key: fs.readFileSync(process.env.SSL_KEY_PATH)
	server = https.createServer(credentials, app)
	server.listen 9002, -> console.log "listening on 9002 [SSL]"
	app.use('/js', express.static(__dirname + '/js'))
	pubWS = express()
	expressWS pubWS
	pubWS.ws '/ws', wshandler
	.use('/.well-known', express.static(__dirname + '/static/.well-known'))
	.get '*', (req, res)->
		res.redirect('https://home.emmalem.ma'+req.url)
	.listen 9001, -> console.log "listening on 9001 [redirect]"
else
	stylus = require 'express-stylus'
	nib = require 'nib'
	app.use stylus
	  src: styleDir
	  use: [nib()]
	  import: ['nib']

	app.get '/js/index.js', browserify(__dirname + '/client/index.coffee')

	http = require('http')
	server = http.createServer(app).listen 9001, -> console.log "listening on 9001 [UNSECURED]"

expressWS(app, server)

ws = require('ws')
ws.prototype.json =(o)->@send JSON.stringify(o)

devices = {}
clientIdx = 0
clients = {}
handler = {}

app.use('/css', express.static(styleDir))

app.get '/', (req, res)->
	res.send("<script src='/js/index.js'></script>")
	res.end()


app.ws '/ws', wshandler

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

heaterId = humidifierId = null
handler.device = (ws, data)->
	ws.id = data.mac
	ws.device = yes
	data.log = "[registered]\n"
	devices[ws.id] = {ws, info: data}
	if data.label is 'Heater'
		heaterId = ws.id
	else if data.label is 'Humidifier'
		humidifierId = ws.id
	ws.json registered: true

handler.eval = (ws, {id, code})->
	devices[id]?.ws.json eval: code

handler.update = (ws, data)->
	dev = devices[ws.id]
	return unless dev
	dev.info[k] = v for k, v of data
	ws.json updated: true
	newdata = {}
	newdata[ws.id] = data
	broadcast devices: newdata

handler.log = (ws, data)->
	broadcast log: {id: ws.id, data}

handler.temp = (ws, data)->
	console.log('received temp data:', data)
	if data.temp < 24
		devices[heaterId]?.ws.json power: 'on'
	else
		devices[heaterId]?.ws.json power: 'off'

	if data.humidity < 65
		devices[humidifierId]?.ws.json power: 'on'
	else
		devices[humidifierId]?.ws.json power: 'off'
