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

router.all '/listByUsers', auth.loginRequired, (req, res, next) ->
  db.collections.group.findOne req.user.group.id
  .populate 'users'
  .then (group) ->
    if not group?
      return res.sendStatus 404
    Q.all group.users.map (user) ->
      user = user.toJSON()
      return db.collections.article.find
        where:
          group: group.id
          author: user.id
        sort: 'id DESC'
      .populate 'author'
      .then (articles) ->
        user.articles = articles
        return user
    .then (users) ->
      res.json users
  .catch (e) ->
    next e

router.all '/info', (req, res, next) ->
  id = parseInt param(req, 'id')
  if isNaN id
    return res.sendStatus 400
  db.collections.article.findOne id
  .populate 'author'
  .populate 'voteEntries'
  .populate 'voters'
  .populate 'tagged'
  .populate 'comments'
  .then (article) ->
    req.json article
  .catch (e) ->
    next e

router.all '/self/create', auth.loginRequired, (req, res, next) ->
  return res.sendStatus 400 if not req.user.group?
  voteEntriesParam = param req, 'voteEntries'
  taggedParam = param req, 'tagged'
  photo = req.files.photo
  image.resize photo
  .then () ->
    template =
      group: req.user.group.id
      type: parseInt param req, 'type'
      name: param req, 'name'
      description: param req, 'description'
      canAdd: param req, 'canAdd'
      author: req.user.id
    template.canAdd = false if template.type == 1
    template.photo = photo.path if photo? && photo.path?
    db.collections.article.create template
    .populate 'tagged'
    .populate 'voteEntries'
  .then (article) ->
    if article.type == 3
      # 어떻게 할까요
      # Helpppppp
      if Array.isArray voteEntriesParam
        db.collections.voteentry.create voteEntriesParam.map (voteEntry) ->
          return
            name: voteEntry
            article: article.id
        .then (voteEntries) ->
          article.voteEntries = voteEntries
          return article
      else
        throw new Error('voteEntries is not an array')
    else if article.type == 1
      # 해보고 싶어요
      # Add voteEntry with predefined data.
      db.collections.voteentry.create [
        name: '찬성'
        article: article.id
      ,
        name: '반대'
        article: article.id
      ]
      .then (voteEntries) ->
        article.voteEntries = voteEntries
        return article
    else
      return article
  .then (article) ->
    # Tagged...
    if Array.isArray taggedParam
      taggedParam.forEach (userId) ->
        article.tagged.add userId
        db.collections.user.findOne userId
        .exec (err, user) ->
          return console.log err if err?
          # Send push nofication
          console.log user
      return Q.ninvoke article, 'save'
      .then () ->
        return article
    else
      return article
  .then (article) ->
    obj = article.toJSON()
    obj.author = req.user.toJSON()
    res.json obj
  .catch (e) ->
    res.status 400
    res.send e.message

router.all '/self/modify', auth.loginRequired, (req, res, next) ->
  res.status 500
  res.send 'Not going to implement it'

router.all '/self/delete', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  author = req.user.id
  query =
    id: id
    author: author
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
