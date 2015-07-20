Q = require 'q'
express = require 'express'
randtoken = require 'rand-token'

db = require '../../lib/db'
auth = require '../../lib/auth'
param = require '../../lib/param'

router = express.Router()

router.all '/self/create', auth.loginRequired, (req, res, next) ->
  if not param(req, 'name')?
    return res.sendStatus 400
  if req.user.group?
    return res.sendStatus 403
  groupObj = null
  db.collections.group.create
    name: param req, 'name'
    inviteCode: randtoken.generate 8
  .then (group) ->
    groupObj = group
    req.user.group = group.id
    Q.ninvoke req.user, 'save'
  .then () ->
    groupObj.users = [req.user]
    res.json groupObj

router.all '/self/info', auth.loginRequired, (req, res, next) ->
  db.collections.group.findOne req.user.group.id
  .populate 'users'
  .then (group) ->
    if not group?
      return res.sendStatus 404
    result = null
    result = group.toJSON() if group?
    res.json result
  .catch (e) ->
    next e

router.all '/self/join', auth.loginRequired, (req, res, next) ->
  code = param req, 'code'
  if not code?
    return res.sendStatus 400
  if req.user.group?
    return res.sendStatus 403
  groupObj = null
  db.collections.group.findOne
    inviteCode: code
  .populate 'users'
  .then (group) ->
    if not group?
      return res.sendStatus 404
    groupObj = group
    req.user.group = group.id
    Q.ninvoke req.user, 'save'
  .then () ->
    groupObj.users.push req.user
    res.json groupObj
  .catch (e) ->
    next e

router.all '/info', (req, res, next) ->
  code = param req, 'code'
  db.collections.group.findOne
    inviteCode: code
  .populate 'users'
  .then (group) ->
    if not group?
      return res.sendStatus 404
    result = null
    result = group.toJSON() if group?
    res.json result
  .catch (e) ->
    next e

module.exports = router
