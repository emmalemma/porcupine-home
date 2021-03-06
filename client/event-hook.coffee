module.exports = class EventHook
  constructor: (@handler)->
  hook: (node, prop, prev)->
    event = prop.substr 3
    node.addEventListener event, @handler

  unhook: (node, prop, next)->
    event = prop.substr 3
    node.removeEventListener event, @handler

module.exports.StopPropagationHook = new EventHook (e)->e.stopPropagation()
