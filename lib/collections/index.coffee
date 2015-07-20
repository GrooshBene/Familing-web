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
      tagged: # I really hate to do this
        collection: 'article'
        via: 'tagged'
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
      inviteCode: 'string'
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
        in: [0, 1, 2, 3] # 게시글, 해보고 싶어요, 허락해 주세요, 어떻게 할까요
      name:
        type: 'string'
        required: true
      photo: 'array' # String[]
      description: 'string'
      allowed: # 허락해 주세요에만 해당
        type: 'integer'
        in: [0, 1, 2] # 대기, 승낙, 거절
        defaultsTo: 0
      solved: # 어떻게 할까요에만 해당
        type: 'boolean'
        defaultsTo: false
      agree: 'integer'
      decline: 'integer'
      votes:
        collection: 'user'
      author:
        model: 'user'
        required: true
      tagged:
        collection: 'user'
        via: 'tagged'
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
      article:
        model: 'article'
        required: true
