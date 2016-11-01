el = require('./coffee-hyperscript')
EventHook = require './event-hook'
FastClick = require './fast-click'
_ = require 'lodash'

module.exports = render = (state, emit)->
	el 'main',
		el 'quickbar',
			_.map state.devices, (device, id)->
				el 'toggle',
					className: "#{if device.powered then 'on' else 'off'} #{if device.synced then '' else 'dirty'}"
					'ev-click': new FastClick ->
						emit 'toggle': id
					device.label
		el 'h1', 'Devices'
		el 'devices',
			_.map state.devices, (device, id)->
				el 'device',
					el 'address',
						el 'mac', device.mac
						el 'separator', '-'
						el 'ip', device.ip
					el 'label', device.label
					el 'control',
						el 'button',
							'ev-click': new EventHook ->

								emit 'toggle': id
							if device.powered then 'On' else 'Off'
						el 'button',
							'ev-click': new EventHook ->
								emit eval: {id, code: 'node.restart()'}
							'Reset'
						el 'input',
							'value': state.value
							'ev-keyup': new EventHook (e)->
								state.value = e.target.value
						el 'button',
							'ev-click': new EventHook ->
								emit eval: {id, code: state.value}
							'Eval'
						el 'textarea', device.log
