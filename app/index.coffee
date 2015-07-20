image = require '../lib/image'

module.exports = (app) ->
  app.use '/api', require './api'
  app.use '/uploadtest', (req, res, next) ->
    image.resize req.files.file
    .then () ->
      console.log req.files
      res.json req.files.file
