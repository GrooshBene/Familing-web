Q = require 'q'
express = require 'express'

db = require '../../lib/db'
auth = require '../../lib/auth'
param = require '../../lib/param'
gcm = require '../../lib/gcm'
image = require '../../lib/image'

router = express.Router()

router.all '/list', (req, res, next) ->
  group = param req, 'group'
  category = param req, 'category', null
  category = null if category == -1
  type = param req, 'type', null
  state = param req, 'state', 0
  amount = param req, 'amount', 20
  start = param req, 'start', (2<<28) # OK, this is definitely not the best way
  name = param req, 'name', ''
  return res.sendStatus 400 if not group?
  # Build criteria
  where =
    group: group
  where.category = category if category?
  where.type = type if type?
  where.name =
    contains: name
  where.state = state if state?
  where.id =
    '<': start

  query =
    where: where
    sort: 'id DESC'
  query.limit = amount if amount?
  db.collections.article.find query
  .populate 'author'
  .populate 'responder' # Don't populate comments - it's not likely to be used
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

router.all '/self/info', auth.loginRequired, handleInfo

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
  group = parseInt param(req, 'group')
  if isNaN group
    return res.sendStatus 400
  user = req.user.id
  # Build criteria
  where =
    or: [
      author: user
    ,
      responder: user
    ]
  where.group = group unless group == -1
  query =
    where: where
    sort: 'id DESC'
  db.collections.article.find query
  .populate 'author'
  .populate 'responder' # Don't populate comments - it's not likely to be used
  .then (articles) ->
    result = articles.map (article) ->
      return article.toJSON()
    res.json result
  .catch (e) ->
    next e

router.all '/self/confirm', auth.loginRequired, (req, res, next) ->
  id = parseInt param(req, 'id')
  if isNaN id
    return res.sendStatus 400
  db.collections.article.findOne id
  .populate 'author'
  .populate 'responder'
  .then (article) ->
    return if not article?
    switch article.state
      when 0
        # return res.sendStatus 403 if article.author == req.user.id
        return db.collections.article.update id,
          state: 2
          responder: req.user.id
          description: article.description+"\n응답한 사용자: "+req.user.name
        .populate 'author'
        .populate 'responder'
      when 2
        return unless article.author.id == req.user.id
        state = 3
        state = 4 if article.type == 2 || article.type == 3
        return db.collections.article.update id,
          state: state
        .populate 'author'
        .populate 'responder'
      when 3
        return unless article.responder.id == req.user.id
        return db.collections.article.update id,
          state: 4
        .populate 'author'
        .populate 'responder'
      else
        return res.sendStatus 403
  .then (articles) ->
    if articles && articles.length > 0
      article = articles[0]
      if articles[0].state == 4
        # Save changes to the server.
        return db.collections.user.findOne article.author
        .then (author) ->
          switch article.type
            when 0
              author.take += 1
            when 1
              author.give += 1
            when 2
              author.give += 1
            when 3
              author.exchange += 1
          db.collections.user.update author.id,
            take: author.take
            give: author.give
            exchange: author.exchange
        .then () ->
          db.collections.user.findOne article.responder
        .then (responder) ->
          switch article.type
            when 0
              responder.give += 1
            when 1
              responder.take += 1
            when 2
              responder.take += 1
            when 3
              responder.exchange += 1
          db.collections.user.update responder.id,
            take: responder.take
            give: responder.give
            exchange: responder.exchange
        .then () ->
          article
      return articles[0]
    else
      throw new Error()
  .then (article) ->
    # Issue GCM push notification
    gcm.sendArticle article, req.user
    res.json article.toJSON()
  .catch (e) ->
    console.log e
    return res.sendStatus 422

router.all '/self/cancel', auth.loginRequired, (req, res, next) ->
  id = parseInt param(req, 'id')
  if isNaN id
    return res.sendStatus 400
  db.collections.article.update
    id: id
    state: 2
    author: req.user.id
  ,
    state: 0
    responder: null
  .populate 'author'
  .populate 'responder'
  .then (articles) ->
    if articles && articles.length > 0
      gcm.sendArticle articles[0], req.user
      res.json articles[0].toJSON()
    else
      return res.sendStatus 403

module.exports = router
