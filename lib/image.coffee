gm = require 'gm'
Q = require 'q'

isImage = (file) ->
  return false unless file?
  return false unless file.mimetype?
  return file.mimetype.slice(0, 5) == 'image'
resize = (file, callback) ->
  return Q.resolve() unless isImage file
  image = gm file.path
  # Should not use hard coding.
  .resize 720, 720, '>'
  .autoOrient()
  .noProfile()
  # Use promise...
  return Q.ninvoke image, 'write', file.path

module.exports =
  isImage: isImage
  resize: resize
