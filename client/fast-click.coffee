event = if 'ontouchstart' of window
  'touchstart'
else
    'click'

module.exports = class FastClick
  constructor: (@handler)->
  hook: (node, prop, prev)->
    node.addEventListener event, @handler

  unhook: (node, prop, next)->
    node.removeEventListener event, @handler
