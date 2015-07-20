Q = require 'q'
express = require 'express'
randtoken = require 'rand-token'

passport = require '../../lib/passport'
auth = require '../../lib/auth'
protocol = require '../../lib/protocol/'
db = require '../../lib/db'
param = require '../../lib/param'

callbackLogin = (req, res, next, err, user, info) ->
  if err
    res.status 401
    return res.send err.message
  if !user
    res.sendStatus 401
    return
  # Generate token and save...
  user.token = randtoken.generate 32
  db.collections.user.update user.id,
    token: user.token
  .populate 'group'
  .then (users) ->
    userSerialized = user.toJSON()
    userSerialized.token = user.token
    res.json userSerialized
  .catch (err) ->
    res.sendStatus 500
  .done()

handleLogin = (method, req, res, next) ->
  callback = callbackLogin.bind(null, req, res, next)
  passport.authenticate(method, callback)(req, res, next)

router = express.Router()

#router.all '/facebook/token', handleLogin.bind null, 'facebook-token'
#router.get '/facebook', handleLogin.bind null, 'facebook'
#router.get '/facebook/callback', handleLogin.bind null, 'facebook'

router.all '/login', handleLogin.bind null, 'local'
router.all '/register', (req, res, next) ->
  callback = callbackLogin.bind(null, req, res, next)
  username = param req, 'username'
  password = param req, 'password'
  name = param req, 'name'
  protocol.local.register username, password, name, callback

router.all '/logout', auth.loginRequired, (req, res, next) ->
  req.user.token = null
  req.user.save (err) ->
    if err
      res.status 401
      return res.send err.message
    res.sendStatus 200

module.exports = router
