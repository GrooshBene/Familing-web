Waterline = require 'waterline'
Q = require 'q'
debug = require 'debug'
log = debug 'app:db'

collections = require './collections'
config = require './config'

# Init ORM instance
orm = new Waterline()

# Load ORM instance
init = () ->
  Q.fcall () ->
    log 'Starting up the database'
    # Upload models to ORM
    for key, collection of collections
      log "Loading collection #{key}"
      orm.loadCollection collection
    Q.ninvoke orm, 'initialize', config.db
  .then (models) ->
    log 'Load complete'
    module.exports.collections = models.collections;
    module.exports.connections = models.connections;
  , (e) ->
    log 'An error has occured while loading the database'
    throw e

module.exports = 
  init: init
