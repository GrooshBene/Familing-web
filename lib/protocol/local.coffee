db = require '../db'
debug = require 'debug'
log = debug 'app:passport'
Q = require 'q'

module.exports.register = (username, password, name, done) ->
  log 'Finding passport information'
  userObj = null
  passportObj = null
  Q.fcall () ->
    throw new Error('username is null') if !username? || username == ''
    throw new Error('password is null') if !password? || password == ''
    throw new Error('name is null') if !name? || name == ''
    return db.collections.passport.find
      identifier: username
      type: 'local'
  .then (passports) ->
    throw new Error('already exists') if passports.length > 0
    log 'Creating passport'
    return db.collections.passport.create
      identifier: username
      password: password
      type: 'local'
  .then (passport) ->
    passportObj = passport
    log 'Creating user'
    return db.collections.user.create
      name: name
      passport: passport.id
    .populate 'group'
    .populate 'tagged'
  .then (user) ->
    userObj = user
    log 'Applying user id into passport'
    return db.collections.passport.update passportObj.id,
      user: user.id
  .then () -> userObj
  .then (user) ->
    log 'Built user. Done!'
    done null, user
  .catch (error) ->
    done error, false,
      message: 'Internal server error'
  .done()

module.exports.login = (username, password, done) ->
  log 'Finding passport information'
  passportObj = null
  db.collections.passport.find
    identifier: username
    type: 'local'
  .then (passports) ->
    throw new Error('user does not exist') if passports.length == 0
    passportObj = passports[0]
    return Q.ninvoke passportObj, 'validatePassword', password
  .then (valid) ->
    throw new Error('password incorrect') unless valid
    if passportObj.user?
      log 'Found passport and user; Finding user'
      return db.collections.user.findOne passportObj.user
      .populate 'group'
      .populate 'tagged'
    else
      userObj = null
      log 'Found passport and no user; Nope.'
      throw new Error('auth fail')
  .then (user) ->
    log 'Found user. Done!'
    done null, user
  .catch (error) ->
    done error, false,
      message: 'Internal server error'
  .done()
