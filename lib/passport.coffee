passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy
FacebookTokenStrategy = require('passport-facebook-token').Strategy
LocalApiKeyStrategy = require('passport-localapikey').Strategy
LocalStrategy = require('passport-local').Strategy

debug = require 'debug'
log = debug 'app:passport'

db = require './db'
config = require './config'
protocol = require './protocol'

log 'Loading passport'

fbVerifyLogin = protocol.oauth.login.bind this, 'facebook'

log 'Registering Facebook strategy'
passport.use new FacebookStrategy config.auth.facebook, fbVerifyLogin
passport.use new FacebookTokenStrategy config.auth.facebook, fbVerifyLogin

log 'Registering Local strategy'
passport.use new LocalStrategy protocol.local.login

log 'Registering Local API key strategy'
passport.use new LocalApiKeyStrategy (apikey, done) ->
  log 'Finding user information with the API key'
  db.collections.user.findOne
    token: apikey
  .populate 'group'
  .populate 'tagged'
  .then (user) ->
    log 'Found user. Done!'
    done null, user

module.exports = passport
