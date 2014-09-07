gulp = require("gulp")
using = require("gulp-using")
watch = require("gulp-watch")
coffee = require("gulp-coffee")
coffeelint = require("gulp-coffeelint")
mocha = require("gulp-mocha")
plumber = require("gulp-plumber")
clean = require("gulp-rimraf")
filePath =
  clean:
    src: ["index*.js"]

  coffee:
    src: [
      "*.coffee"
      "!*-test.coffee"
      "!gulpfile.coffee"
    ]
    destDir: ""

  unit:
    triggers: [
      "index.js"
      "index-test.coffee"
    ]
    src: ["*-test.coffee"]

gulp.task "glob", ->
  pattern = filePath.coffee.src
  gulp.src pattern
  .pipe using()
  return

gulp.task "clean", ->
  gulp.src filePath.clean.src, read: false
  .pipe clean()

gulp.task "coffee", ->
  gulp.src filePath.coffee.src
  .pipe coffeelint()
  .pipe coffeelint.reporter()
  .pipe coffee(bare: true)
  .pipe gulp.dest filePath.coffee.destDir
  return

gulp.task "watch-coffee", ->
  watch
    glob: filePath.coffee.src
    name: "watch-coffee"
  , (files) ->
    files.pipe plumber()
    .pipe coffeelint()
    .pipe coffeelint.reporter()
    .pipe coffee(bare: true)
    .pipe using()
    .pipe gulp.dest("/") # tmp fix since path is absolute here
  return

gulp.task "unit", ->
  gulp.src filePath.unit.src, read: false
  .pipe using()
  .pipe mocha(reporter: "dot")
  return

gulp.task "watch-unit", ->
  watch
    glob: filePath.unit.triggers
    name: "watch-unit"
    emitOnGlob: false
  , ->
    gulp.src filePath.unit.src, read: false
    .pipe plumber()
    .pipe mocha(
      bail: true
      reporter: "dot"
    )
  return

gulp.task "watch", [
  "watch-coffee"
  "watch-unit"
]
gulp.task "default", ["watch"]