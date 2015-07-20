express = require 'express'
Q = require 'q'

db = require './lib/db'
middleware = require './lib/middleware'
appHook = require './app/'

app = express()

Q.fcall () ->
  console.log 'Bill.im server starting up'
.then db.init
.then middleware.bind null, app
.then appHook.bind null, app
.then () ->
  app.listen 8000, () ->
    throw err if err?
    console.log "Listening at port #{8000}"
.done()
