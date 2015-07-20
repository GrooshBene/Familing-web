module.exports = (req, key, defaultVal) ->
  return req.query[key] if req.query[key]?
  return req.body[key] if req.body[key]?
  return defaultVal
