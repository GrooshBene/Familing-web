image = require '../lib/image'

module.exports = (app) ->
  app.use '/api', require './api'
