gulp-grep
============

A [gulp](https://github.com/gulpjs/gulp) plugin for filtering out file objects 
from the stream based on a glob match or a conditional function.

## Usage

### Use case 1
Filter in file objects matching certain criteria and perform some actions on them.

```js
// via a conditional function
var grep = require('gulp-grep'),
  deletedFilesFilter = grep(function(file) {
    return file.event === 'deleted';
  })

gulp.src(['app/**/*.*'], { read: false }) // set `read` to false if you don't want to read file contents
  .pipe(deletedFilesFilter)
  // only deleted files passed down from here on
  .pipe(doSomethingOnDeletedFiles())
  ... ... ... 
});
```

```js
// via a glob
var grep = require('gulp-grep')

gulp.src('app/**/*.*', { read: false }) 
  // filter in CoffeeScript files
  .pipe(grep('**/*.coffee'))
  // only CoffeeScript files are passed downstream from here on
  .pipe(doSomethingOnCoffeeFiles())
  ... ... ... 
});
```

### Use case 2
Filter in file objects matching certain criteria, perform some actions on them, then
restore filtered-out file objects downstream to perform additional actions on them too.

**Please note**:
* the stream filter needs to be created as `{restorable: true}` in
order to be able to restore the filetered out by this filter objects later in the stream pipeline.
* if you don't pipe `allFilesFilter` in the example below prior to restoring 
filtered-out objects, the latter will be joined with the 
filtered-in objects and passed downstream together.

```js
// via a glob
var grep = require('gulp-grep'),
  coffee = require('gulp-coffee'),
  coffeeScriptFilter = grep(['**/*.coffee','!**/*-test.coffee'], { restorable: true }),
  htmlFilter = grep('**/*.html'),
  allFilesFilter = grep('**/*.*')

gulp.src(['app/**/*.*', 'test/*.js'],  { read: false })
  // filter in CoffeeScript files
  .pipe(coffeeScriptFilter)
  // perform some actions on filtered-in CoffeScript files
  .pipe(coffee())
  ... ... ... 
  // include this if you don't want coffee files passing downstream
  .pipe(allFilesFilter)
  // restore files previously filtered-out by `coffeeScriptFilter`
  .pipe(coffeeScriptFilter.restoreFilteredOut())
  // Filter in html files
  .pipe(htmlFilter)
  // perform some actions on filered in html files
  .pipe(html())
  ... ... ...
});
```


## API

```
grep(pattern [, options])
```

* `pattern` := String | Array | Function
The pattern that you want to match against the file objects passing 
through the stream. It can be a string, array or a conditional function. 
String or array must be given as glob patterns (see [node-glob](https://github.com/isaacs/node-glob) for
example of patterns). If specifying the pattern as a conditional `function` it will be
called with a `file` object and it needs to return `true` or `false` for including
or excluding this `file` object from the stream respectively.
* `options`
  * `restorable` := true | false (default)
  Set this option to true if you want to be able to restore filtered-out
  objects downstream later on
  * `debug` := true | false (default)
  Set this option to true if you want to turn in debuging mode and see what
  exactly is going on under the hood.
  * `...` any other option is passed through to [minmatch](https://github.com/isaacs/minimatch)
  module


## License

[MIT License](http://en.wikipedia.org/wiki/MIT_License)
