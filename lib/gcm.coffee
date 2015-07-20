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
      if comment.reply != article.author
        db.collections.user.findOne article.author
        .then (user) ->
          return unless user?
          send user.gcm,
            title: '게시글 댓글'
            body: "#{author.name}님이 회원님의 게시글에 댓글을 달았습니다."
            icon: 'ic_launcher'
          ,
            id: article.id
      # Send notification to reply
      if comment.reply?
        db.collections.user.findOne comment.reply
        .then (user) ->
          return unless user?
          send user.gcm,
            title: '댓글의 답글'
            body: "#{author.name}님이 회원님의 댓글에 답글을 달았습니다."
            icon: 'ic_launcher'
          ,
            id: article.id

sendArticle = (article, user) ->
  switch article.state
    when 0
      # Send notification to responder
      send article.responder.gcm,
        title: '요청 취소'
        body: "#{article.author.name}님이 회원님의 요청을 취소했습니다."
        icon: 'ic_launcher'
      ,
        id: article.id
    when 2
      # Send notification to author
      send article.author.gcm,
        title: '요청 수락'
        body: "#{article.responder.name}님이 회원님의 요청을 수락했습니다."
        icon: 'ic_launcher'
      ,
        id: article.id
    when 3
      # Send notification to responder
      send article.responder.gcm,
        title: '빌려줌'
        body: "#{article.author.name}님에게 물건을 빌려주었습니다."
        icon: 'ic_launcher'
      ,
        id: article.id
    when 4
      # Send notification to author
      send article.author.gcm,
        title: '요청 완료'
        body: "#{article.responder.name}님과의 거래가 끝났습니다."
        icon: 'ic_launcher'
      ,
        id: article.id

module.exports =
  send: send
  sendComment: sendComment
  sendArticle: sendArticle
