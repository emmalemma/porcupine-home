module.exports = class EventHook
  constructor: (@handler)->
    console.log 'new hook'
  hook: (node, prop, prev)->
    console.log 'hook attached'
    event = prop.substr 3
    node.addEventListener event, @handler

  unhook: (node, prop, next)->
    event = prop.substr 3
    node.removeEventListener event, @handler

module.exports.StopPropagationHook = new EventHook (e)->e.stopPropagation()
