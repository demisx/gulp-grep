require('coffee-script/register');

var gulp = require('gulp'),
  using = require('gulp-using'),
  watch = require('gulp-watch'),
  coffee = require('gulp-coffee'),
  coffeelint = require('gulp-coffeelint'),
  mocha = require('gulp-mocha'),
  plumber = require('gulp-plumber'),
  clean = require('gulp-rimraf')

var filePath = {
  clean: { 
    src: ['index*.js']
  },
  coffee: { 
    src: ['*.coffee', '!*-test.coffee'], 
    destDir: '/'       
  },
  unit: { 
    triggers: ['*.js', '*-test.coffee', '!gulpfile.js'],
    src: ['*-test.coffee']
  }
};

gulp.task('glob', function () {
  var pattern = filePath.unit.src;
  gulp.src(pattern)
    .pipe(using());
})

gulp.task('clean', function() {
  return gulp.src(filePath.clean.src, {read: false})
    .pipe(clean());
});

gulp.task('coffee', function () {
  gulp.src(filePath.coffee.src)
    // .pipe(using({ prefix: 'Before' }))
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
    .pipe(coffee({ bare: true }))
    // .pipe(using({ prefix: 'After' }))
    .pipe(gulp.dest(filePath.coffee.destDir));
});

gulp.task('watch-coffee', function () {
  watch({ glob: filePath.coffee.src, name: 'watch-coffee' }, function(files) {
    return files.pipe(using({ prefix: 'Before coffee' }))
      .pipe(plumber())
      .pipe(coffeelint())
      .pipe(coffeelint.reporter())
      .pipe(coffee({ bare: true }))
      // .pipe(using({ prefix: 'After coffee' }))
      .pipe(gulp.dest(filePath.coffee.destDir))
  });
});

gulp.task('unit', function () {
   gulp.src(filePath.unit.src, { read: false })
    .pipe(using())
    .pipe(mocha({ reporter: 'dot' }));
});

gulp.task('watch-unit', function () {
  watch({ glob: filePath.unit.triggers, name:"watch-unit", emitOnGlob: false }, function() {
    return gulp.src(filePath.unit.src, { read: false })
      .pipe(plumber())
      .pipe(mocha({ bail: true, reporter: 'dot' }))
      // FIXME: Removing using() call hides compilation errors in mocha
      .pipe(using({ prefix: 'Tested' }))
  });  
});

gulp.task('watch', ['watch-coffee', 'watch-unit']);
gulp.task('default', ['watch']);
