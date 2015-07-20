Q = require 'q'
debug = require 'debug'
log = debug 'app:middleware'

passport = require './passport'
multer = require 'multer'
morgan = require 'morgan'
bodyParser = require 'body-parser'
serveStatic = require 'serve-static'

module.exports = (app) ->
  Q.fcall () ->
    log 'Registering middlewares'
    app.use morgan 'dev'
    app.use serveStatic process.cwd() + '/public'
    app.use '/uploads', serveStatic process.cwd() + '/uploads'
    app.use bodyParser.urlencoded
      extended: false
    app.use multer
      dest: 'uploads'
      rename: (fieldname, filename) ->
        filename.replace(/\W+/g, '-').toLowerCase() + Date.now()
    # JSON is not required, right?
    app.use passport.initialize()
