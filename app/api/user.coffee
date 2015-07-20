Q = require 'q'
express = require 'express'

db = require '../../lib/db'
auth = require '../../lib/auth'
param = require '../../lib/param'

router = express.Router()

router.all '/self/info', auth.loginRequired, (req, res, next) ->
  res.json req.user.toJSON()

router.all '/self/delete', auth.loginRequired, (req, res, next) ->
  # Delete passport associated with the user
  db.collections.passport.destroy req.user.passport
  .then () ->
    db.collections.user.update req.user.id,
      enabled: false
      token: null
  .then () ->
    res.sendStatus 200
  .catch (e) ->
    next e

router.all '/self/gcm', auth.loginRequired, (req, res, next) ->
  req.user.gcm = param req, 'gcm'
  req.user.save (err) ->
    return next err if err
    res.sendStatus 200

router.all '/info', (req, res, next) ->
  id = parseInt param(req, 'id')
  if isNaN id
    return res.sendStatus 400
  db.collections.user.findOne id
  .populate 'group'
  .then (user) ->
    if not user?
      return res.sendStatus 404
    result = null
    result = user.toJSON() if user?
    res.json result
  .catch (e) ->
    next e

module.exports = router
