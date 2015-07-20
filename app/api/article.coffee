Q = require 'q'
express = require 'express'

db = require '../../lib/db'
auth = require '../../lib/auth'
param = require '../../lib/param'
gcm = require '../../lib/gcm'
image = require '../../lib/image'

router = express.Router()

router.all '/list', auth.loginRequired, (req, res, next) ->
  return res.sendStatus 400 if not req.user.group?
  # Build criteria
  where =
    group: req.user.group.id
  query =
    where: where
    sort: 'id DESC'
  db.collections.article.find query
  .populate 'author'
  .then (articles) ->
    result = articles.map (article) ->
      return article.toJSON()
    res.json result
  .catch (e) ->
    next e

handleInfo = (req, res, next) ->
  id = parseInt param(req, 'id')
  if isNaN id
    return res.sendStatus 400
  db.collections.article.findOne id
  .populate 'author'
  .populate 'responder'
  .then (article) ->
    if not article?
      return res.sendStatus 404
    result = article.toJSON()
    # Populate comments. :(
    query =
      where:
        article: article.id
        or: [
          secret: false
        ]
      sort: 'id DESC'
    if req.user?
      query.where.or.push
        reply: req.user.id
      if req.user.id == article.author.id
        delete query.where.or
    db.collections.comment.find query
    .then (comments) ->
      # Merge result and comments
      result.comments = comments
      res.json result
  .catch (e) ->
    next e

router.all '/info', handleInfo

router.all '/self/create', auth.loginRequired, (req, res, next) ->
  photo = req.files.photo
  image.resize photo
  .then () ->
    template =
      group: param req, 'group'
      category: param req, 'category'
      type: param req, 'type'
      name: param req, 'name'
      description: param req, 'description'
      reward: param req, 'reward'
      location: param req, 'location'
      author: req.user.id
    template.photo = photo.path if photo? && photo.path?
    db.collections.article.create template
  .then (article) ->
    obj = article.toJSON()
    obj.author = req.user
    res.json obj
  .catch (e) ->
    res.sendStatus 400

router.all '/self/modify', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  author = req.user.id
  query =
    id: id
    author: author
    state: 0
  template =
    category: param req, 'category'
    type: param req, 'type'
    name: param req, 'name'
    description: param req, 'description'
    reward: param req, 'reward'
    location: param req, 'location'
  db.collections.article.update query, template
  .populate 'author'
  .populate 'responder'
  .then (articles) ->
    return res.sendStatus 422 if articles.length == 0
    res.json articles[0].toJSON()
  .catch (e) ->
    res.sendStatus 400

router.all '/self/delete', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  author = req.user.id
  query =
    id: id
    author: author
    state: 0
  db.collections.article.destroy query
  .then () ->
    res.sendStatus 200
  .catch (e) ->
    res.sendStatus 400

router.all '/self/list', auth.loginRequired, (req, res, next) ->
  return res.sendStatus 400 if not req.user.group?
  # Build criteria
  where =
    or: [
      author: req.user.id
    ,
      id: req.user.tagged.map (v) ->
        return v.id
    ]
  query =
    where: where
    sort: 'id DESC'
  db.collections.article.find query
  .populate 'author'
  .populate 'tagged'
  .then (articles) ->
    result = articles.map (article) ->
      return article.toJSON()
    res.json result
  .catch (e) ->
    next e

module.exports = router
