Q = require 'q'
express = require 'express'

db = require '../../lib/db'
auth = require '../../lib/auth'
param = require '../../lib/param'
gcm = require '../../lib/gcm'

router = express.Router()

router.all '/create', auth.loginRequired, (req, res, next) ->
  template =
    description: param req, 'description'
    secret: param req, 'secret'
    reply: param req, 'reply'
    article: param req, 'article'
    author: req.user.id
  db.collections.comment.create template
  .then (comment) ->
    gcm.sendComment comment, req.user
    res.json comment.toJSON()
  .catch (e) ->
    res.sendStatus 400

router.all '/modify', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  author = req.user.id
  query =
    id: id
    author: author
  template =
    description: param req, 'description'
  db.collections.comment.update query, template
  .then (comments) ->
    return res.sendStatus 422 if comments.length == 0
    res.json comments[0].toJSON()
  .catch (e) ->
    res.sendStatus 400

router.all '/delete', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  author = req.user.id
  query =
    id: id
    author: author
  db.collections.comment.destroy query
  .then () ->
    res.sendStatus 200
  .catch (e) ->
    res.sendStatus 400

module.exports = router
