el = require('./coffee-hyperscript')
EventHook = require './event-hook'

module.exports = render = (state, emit)->
	el 'main',
		el 'h1', 'Devices'
		el 'devices',
			for id, device of state.devices
				el 'device',
					el 'id', id
					el 'powered', device.powered
					el 'control',
						el 'button',
							'ev-click': new EventHook ->
								emit 'toggle': id
							'Toggle'
