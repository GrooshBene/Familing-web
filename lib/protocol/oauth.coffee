db = require '../db'
debug = require 'debug'
log = debug 'app:passport'

module.exports.login = (type, accessToken, refreshToken, profile, done) ->
  userTemplate =
    name: 'Name unknown'
    photo: null
  if profile && profile.displayName
    userTemplate.name = profile.displayName
  if profile && profile.photos && profile.photos[0]
    userTemplate.photo = profile.photos[0].value
  log 'Finding passport information'
  db.collections.passport.findOrCreate
    identifier: profile.id
    type: type
  ,
    accessToken: accessToken
    refreshToken: refreshToken
    identifier: profile.id
    type: type
  .then (passportObj) ->
    if passportObj.user?
      log 'Found passport and user; Finding user'
      return db.collections.user.findOne passportObj.user
      .populate 'group'
    else
      userObj = null
      log 'Found passport and no user; Creating user'
      userTemplate.passport = passportObj.id
      return db.collections.user.create userTemplate
      .populate 'group'
      .then (user) ->
        userObj = user
        log 'Applying user id into passport'
        return db.collections.passport.update passportObj.id,
          user: user.id
      .then () -> userObj
  .then (user) ->
    log 'Found user. Done!'
    done null, user
  .catch (error) ->
    done error, false,
      message: 'Internal server error'
  .done()
