bcrypt = require 'bcryptjs'
Waterline = require 'waterline'

hashPassword = (passport, next) ->
  if passport.password
    bcrypt.hash passport.password, 10, (err, hash) ->
      passport.password = hash
      next err, passport
  else
    next null, passport

module.exports =
  User: Waterline.Collection.extend
    identity: 'user'
    connection: 'default'
    attributes:
      name:
        type: 'string'
        required: true
      description: 'string'
      photo: 'string'
      group:
        model: 'group'
      enabled:
        type: 'boolean'
        required: true
        defaultsTo: true
      token: 'string'
      gcm: 'string'
      passport:
        model: 'passport'
      toJSON: () ->
        obj = @toObject()
        delete obj.passport
        delete obj.token
        delete obj.gcm
        return obj
  Passport: Waterline.Collection.extend
    identity: 'passport'
    connection: 'default'
    attributes:
      user:
        model: 'user'
      type:
        type: 'string'
        required: true
      identifier: 'string'
      accessToken: 'string'
      refreshToken: 'string'
      password: 'string'
      validatePassword: (password, next) ->
        bcrypt.compare password, this.password, next
    beforeCreate: (passport, next) ->
      hashPassword passport, next
    beforeUpdate: (passport, next) ->
      hashPassword passport, next
  Group: Waterline.Collection.extend
    identity: 'group'
    connection: 'default'
    attributes:
      name:
        type: 'string'
        required: true
      description: 'string'
      users:
        collection: 'user'
  Article: Waterline.Collection.extend
    identity: 'article'
    connection: 'default'
    attributes:
      group:
        model: 'group'
        required: true
      type:
        type: 'integer'
        required: true
        in: [0, 1, 2, 3] # 빌려주세요, 빌려드려요, 교환해요, 드려요
      category:
        type: 'integer'
        required: true
      state:
        type: 'integer'
        required: true
        in: [0, 1, 2, 3, 4] # 대기 중, 삭제 됨, 승인, 빌려줌, 완료
        defaultsTo: 0
      name:
        type: 'string'
        required: true
      photo: 'string'
      description: 'string'
      reward: 'string'
      location: 'string'
      author:
        model: 'user'
        required: true
      responder:
        model: 'user'
      comments:
        collection: 'comment'
        via: 'article'
  Comment: Waterline.Collection.extend
    identity: 'comment'
    connection: 'default'
    attributes:
      description:
        type: 'string'
        required: true
      author:
        model: 'user'
        required: true
      secret:
        type: 'boolean'
        required: true
        defaultsTo: false
      article:
        model: 'article'
        required: true
      reply:
        model: 'user'
