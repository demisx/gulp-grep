"use strict"
gutil = require "gulp-util"
through = require "through2"
minimatch = require "minimatch"
_ = require "lodash"

PLUGIN_NAME = "gulp-grep"

_splitPositivesNegatives = (arr) ->
  pos = _.remove arr, (el) ->
    /^(?!\!).*/.test el
  neg = _.remove arr, (el) ->
    /^(?=\!).*/.test el

  positives: pos
  negatives: neg


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
  splitPatterns = _splitPositivesNegatives patterns

  filteredOutStream = through.obj()  if opt.restorable
 

  _transform = (file, enc, cb) ->
    gutil.log "[DEBUG] --> Executing _transform()" if opt.debug
    if _match file
      gutil.log "[DEBUG] match found: #{file.path}" if opt.debug
      @push file
      return cb()

    if opt.restorable
      gutil.log "[DEBUG] writing #{file.path} to filteredOutStream" if opt.debug
      filteredOutStream.write file
    
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
        # splitPatterns = _splitPositivesNegatives(patterns)

        gutil.log "[DEBUG] positives: #{splitPatterns.positives}" if opt.debug
        gutil.log "[DEBUG] negatives: #{splitPatterns.negatives}" if opt.debug

        for pattern in splitPatterns.positives
          do (pattern) ->
            result = result || minimatch(file.path, pattern, opt)
          break if result

        for pattern in splitPatterns.negatives
          do (pattern) ->
            result = result && minimatch(file.path, pattern, opt)
          break if not result

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