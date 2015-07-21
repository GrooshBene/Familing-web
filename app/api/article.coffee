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
    if not article?
      return res.sendStatus 404
    result = article.toJSON()
    # Populate comments. :(
    query =
      where:
        article: article.id
      sort: 'id DESC'
    db.collections.comment.find query
    .populate 'author'
    .then (comments) ->
      # Merge result and comments
      result.comments = comments
      res.json result
  .catch (e) ->
    next e

router.all '/self/create', auth.loginRequired, (req, res, next) ->
  return res.sendStatus 400 if not req.user.group?
  voteEntriesParam = param req, 'voteEntries'
  taggedParam = param req, 'tagged'
  photo = req.files.photo
  image.resize photo, 640
  .then () ->
    console.log req.body
    template =
      group: req.user.group.id
      type: parseInt(param(req, 'type'))
      name: param req, 'name'
      description: param req, 'description'
      canAdd: param req, 'canAdd'
      author: req.user.id
    template.allowed = 0 if template.type == 2
    template.solved = 0 if template.type == 3
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
          name: voteEntry
          article: article.id
        .then (voteEntries) ->
          article.voteEntries = voteEntries
          return article
      else
        # throw new Error('voteEntries is not an array')
        console.log 'emptyyy'
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
          gcm.sendArticle article, user, req.user
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
    console.log e.stack
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

router.all '/vote', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  articleObj = null
  db.collections.article.findOne id
  .populate 'author'
  .populate 'voteEntries'
  .populate 'voters'
  .populate 'tagged'
  .populate 'comments'
  .then (article) ->
    throw new Error('article is null') unless article?
    articleObj = article
    # valid voters. halp
    article.voters.forEach (voter) ->
      throw new Error('already voted') if voter.id == req.user.id
    # Search vote entry
    template =
      article: article.id
      name: param req, 'name'
    if article.canAdd
      return db.collections.voteentry.findOrCreate template, template
    else
      return db.collections.voteentry.find template
  .then (voteEntries) ->
    throw new Error('voteEntry is null') unless voteEntries.length > 0
    voteEntry = voteEntries[0]
    voteEntry.votes += 1
    return Q.ninvoke voteEntry, 'save'
  .then () ->
    articleObj.voters.add req.user.id
    return Q.ninvoke articleObj, 'save'
  .then () ->
    db.collections.article.findOne id
    .populate 'author'
    .populate 'voteEntries'
    .populate 'voters'
    .populate 'tagged'
    .populate 'comments'
  .then (article) ->
    res.json article
  .catch (e) ->
    console.log e.stack
    res.status 500
    res.send e.message
  .done()

router.all '/solve', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  articleObj = null
  db.collections.article.findOne id
  .populate 'author'
  .populate 'voteEntries'
  .populate 'voters'
  .populate 'tagged'
  .populate 'comments'
  .then (article) ->
    throw new Error('article is null') unless article?
    throw new Error('already set') if article.solved
    throw new Error('type incorrect') unless article.type == 3
    articleObj = article
    validOp = false
    # validate tagged / author
    validOp = true if article.author.id == req.user.id
    article.tagged.forEach (user) ->
      validOp = true if user.id == req.user.id
    throw new Error('no permission') unless validOp
    article.solved = true
    return Q.ninvoke article, 'save'
  .then () ->
    res.json articleObj
  .catch (e) ->
    res.status 500
    res.send e.message
  .done()

router.all '/allowed', auth.loginRequired, (req, res, next) ->
  id = param req, 'id'
  articleObj = null
  db.collections.article.findOne id
  .populate 'author'
  .populate 'voteEntries'
  .populate 'voters'
  .populate 'tagged'
  .populate 'comments'
  .then (article) ->
    throw new Error('article is null') unless article?
    throw new Error('already set') unless article.allowed == 0
    throw new Error('type incorrect') unless article.type == 2
    articleObj = article
    validOp = false
    # validate tagged / author
    validOp = true if article.author.id == req.user.id
    article.tagged.forEach (user) ->
      validOp = true if user.id == req.user.id
    throw new Error('no permission') unless validOp
    article.allowed = param req, 'allowed'
    return Q.ninvoke article, 'save'
  .then () ->
    res.json articleObj
  .catch (e) ->
    res.status 500
    res.send e.message
  .done()

module.exports = router
