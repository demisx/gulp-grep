"use strict"
gutil = require("gulp-util")
through = require("through2")
minimatch = require("minimatch")
PLUGIN_NAME = "gulp-grep"
module.exports = (patterns, opt) ->
  opt = opt or {}

  if opt.debug
    gutil.log("[DEBUG] --> Executing gulp.grep()]")
    gutil.log("[DEBUG] arg `patterns`: ", patterns)
    gutil.log("[DEBUG] arg `opt`: ", opt)

  gutil.log "[DEBUG] --> Validating params..." if opt.debug
  throw new gutil.PluginError(
    PLUGIN_NAME,
    "`patterns` should be an array, string, or a function"
  ) if ([
    "string"
    "function"
  ].indexOf(typeof patterns) is -1) and not Array.isArray(patterns)
  
  gutil.log "[DEBUG] --> Normalizing params..." if opt.debug
  patterns = [patterns] if typeof patterns is "string"
  
  gutil.log "[DEBUG] --> Normalizing params..." if opt.debug
  filteredOutStream = through.obj()  if opt.restorable
 
  _transform = (file, enc, cb) ->
    gutil.log "[DEBUG] --> Executing _transform()" if opt.debug
    if _match file
      gutil.log "[DEBUG] match found: #{file.path}" if opt.debug
      @push file
      return cb()

    if opt.restorable
      gutil.log "[DEBUG] writing #{file.path} to filteredOutStream" if opt.debug
      filteredOutStream.write file, cb
    else
      cb()
    return

  _flush = (cb) ->
    gutil.log "[DEBUG] --> Executing _flush()" if opt.debug
    filteredOutStream and filteredOutStream.end()
    cb()
    return

  _match = (file) ->
    gutil.log "[DEBUG] --> Executing _match()" if opt.debug
    gutil.log "[DEBUG] file: #{file}" if opt.debug
    result = undefined
    switch typeof patterns
      when "function"
        result = patterns(file)
      else
        for pattern in patterns
          do (pattern) ->
            result = result || minimatch(file.path, pattern)

    gutil.log "[DEBUG] match result: #{result}" if opt.debug
    result

  stream = through.obj(_transform, _flush)

  stream.restoreFilteredOut = ->
    gutil.log "[DEBUG] --> Executing restoreFilteredOut()" if opt.debug
    opt.restorable || throw new gutil.PluginError(
      PLUGIN_NAME,
      "cannot call restoreFilteredOut() on a non-restorable stream.
      Create stream with { restorable: true } first."
    )
    filteredOutStream

  stream