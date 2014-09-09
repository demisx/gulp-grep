"use strict"
gutil = require "gulp-util"
through = require "through2"
minimatch = require "minimatch"
_  = require "lodash"

log4js = require 'log4js'

log4js.configure "#{__dirname}/log4js.config.json", {}
log = log4js.getLogger()

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
  
  log.setLevel 'DEBUG' if opt.debug

  log.debug "[gulp.grep()]"
  log.debug "  arg `patterns`: ", patterns
  log.debug "  arg `options`: ", opt

  minimatchOpt = _.omit opt, ['debug', 'restorable']
  log.debug "  minimatch options object:", minimatchOpt

  

  log.debug "  validating params..."
  throw new gutil.PluginError(
    PLUGIN_NAME,
    "`patterns` should be an array, string, or a function"
  ) if ([
    "string"
    "function"
  ].indexOf(typeof patterns) is -1) and not Array.isArray(patterns)
  
  log.debug "  normalizing params..."
  patterns = [patterns] if typeof patterns is "string"
  splitPatterns = _splitPositivesNegatives patterns

  filteredOutStream = through.obj()  if opt.restorable
 

  _transform = (file, enc, cb) ->
    log.debug "[_transform()]"
    if _match file
      log.debug "  match found: #{file.path}"
      @push file
      return cb()

    if opt.restorable
      log.debug "  writing #{file.path} to filteredOutStream"
      filteredOutStream.write file
    
    cb()
    return

  _flush = (cb) ->
    log.debug "[_flush()]"
    filteredOutStream and filteredOutStream.end()
    cb()
    return


  _match = (file) ->
    log.debug "[_match()]"
    log.debug "  file: #{file}"
    result = undefined
    switch typeof patterns
      when "function"
        result = patterns(file)
      else
        # splitPatterns = _splitPositivesNegatives(patterns)

        log.debug "  positives: #{splitPatterns.positives}"
        log.debug "  negatives: #{splitPatterns.negatives}"

        for pattern in splitPatterns.positives
          do (pattern) ->
            result = result || minimatch(file.path, pattern, minimatchOpt)
          break if result

        for pattern in splitPatterns.negatives
          do (pattern) ->
            result = result && minimatch(file.path, pattern, minimatchOpt)
          break if not result

    log.debug " match?: #{result}"
    result

  stream = through.obj(_transform, _flush)

  stream.restoreFilteredOut = ->
    log.debug "[restoreFilteredOut()]"
    opt.restorable || throw new gutil.PluginError(
      PLUGIN_NAME,
      "cannot call restoreFilteredOut() on a non-restorable stream.
      Create stream with { restorable: true } first."
    )
    filteredOutStream

  stream