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
  pos = _.filter arr, (el) ->
    /^(?!\!).*/.test el

  neg = _.filter arr, (el) ->
    /^(?=\!).*/.test el

  positives: pos
  negatives: neg


module.exports = (pat, opt) ->
  options = opt or {}
  patterns = pat or {}
  
  log.setLevel 'DEBUG' if options.debug

  log.debug "[gulp.grep()]"
  log.debug "  arg `patterns`: ", patterns
  log.debug "  arg `options`: ", options

  minimatchOpt = _.omit options, ['debug', 'restorable']
  log.debug "  minimatch options object:", minimatchOpt

  

  log.debug "  validating params..."
  throw new gutil.PluginError(
    PLUGIN_NAME,
    "`patterns` should be an array, string, or a function"
  ) if ([
    "string"
    "function"
  ].indexOf(typeof pat) is -1) and not Array.isArray(pat)
  
  log.debug "  normalizing params..."
  patterns = [patterns] if typeof patterns is "string"
  splitPatterns = _splitPositivesNegatives patterns

  log.debug "  splitPatterns", splitPatterns

  filteredOutStream = through.obj()  if options.restorable
 

  _transform = (file, enc, cb) ->
    log.debug "[_transform()]"
    if _match file
      log.debug "  match found: #{file.path}"
      @push file
      return cb()

    if options.restorable
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
    options.restorable || throw new gutil.PluginError(
      PLUGIN_NAME,
      "cannot call restoreFilteredOut() on a non-restorable stream.
      Create stream with { restorable: true } first."
    )
    filteredOutStream

  stream