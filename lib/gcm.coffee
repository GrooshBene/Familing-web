gcm = require 'node-gcm'
config = require './config'
db = require './db'
debug = require 'debug'
log = debug 'app:gcm'

sender = new gcm.Sender config.gcm.key

sender.handler = (err, result) ->
  if err
    log 'Failed to send push notification'
    log err
  else
    log 'Successfully sent push notification'
    log result

send = (target, notification, data) ->
  log 'Sending notification'
  log notification
  # return unless target?
  message = new gcm.Message()
  message.addData data
  message.addNotification notification
  sender.sendNoRetry message, [target], sender.handler

sendComment = (comment, user) ->
  # Send notification to article author
  db.collections.article.findOne comment.article
  .then (article) ->
    db.collections.user.findOne comment.author
    .then (author) ->
      db.collections.user.findOne article.author
      .then (user) ->
        return unless user?
        send user.gcm,
          title: '게시글 댓글'
          body: "#{author.name}님이 회원님의 게시글에 댓글을 달았습니다."
          icon: 'ic_launcher'
        ,
          id: article.id

sendArticle = (article, user, author) ->
  send user.gcm,
    title: '게시글 태그됨'
    body: "#{author.name}님이 회원님을 게시글에 태그했습니다."
    icon: 'ic_launcher'
  ,
    id: article.id

module.exports =
  send: send
  sendComment: sendComment
  sendArticle: sendArticle
