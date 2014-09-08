expect = require("chai").expect
grep = require "./"

describe "grep()", ->
  context "throws error", ->
    it "if `patterns` parameter is missing", ->
      expect(grep)
        .to.throw /should be an array, string, or a function/
      return

    it "if `patterns` parameter is a number", ->
      expect(grep, 3)
        .to.throw /should be an array, string, or a function/
      return

    it "if trying to restore filtered objects on a non-restorable stream", ->
      expect(grep('some pattern').restoreFilteredOut)
        .to.throw /cannot call restoreFilteredOut\(\) on a non-restorable stream/
      return
    return

  context "returns a transform stream object", ->
    it "when called with a string pattern", ->
      expect(grep "some string").to.respondTo "_transform"
      return

    it "when called with an Array pattern", ->
      expect(grep []).to.respondTo "_transform"
      return

    it "when called with a Function pattern", ->
      expect(grep Function).to.respondTo "_transform"
      return

    it "with `restoreFilteredOut` method", ->
      expect(grep "some string").to.have.ownProperty "restoreFilteredOut"
      return
    return

  context "filters out objects from stream", ->
    it "when `patterns` is a Function", () ->
      patterns = (file) ->
        file.path.match /^.*\.js$/

      grepFilter = grep patterns
      objectCounter = 0

      grepFilter.on "data", () ->
        objectCounter++
        return

      grepFilter.write { path: "./dir1/file1.coffee" }
      grepFilter.write { path: "./dir2/file2.js" }
      grepFilter.write { path: "./dir2/file3.js.bak" }
      grepFilter.end()
      
      expect(objectCounter).to.equal 1
      return

    it "when `patterns` is an Array", () ->
      patterns = ['*.js', '**/*.bak']

      grepFilter = grep patterns
      objectCounter = 0

      grepFilter.on "data", () ->
        objectCounter++
        return

      grepFilter.write { path: "dir1/file1.coffee" }
      grepFilter.write { path: "dir2/file2.js" }
      grepFilter.write { path: "file2.js" }
      grepFilter.write { path: "dir2/file3.js.bak" }
      grepFilter.end()
      
      expect(objectCounter).to.equal 2
      return
    return

  describe "restoreFilteredOut()", ->
    it 'restores stream with filtered out matches', () ->
      patterns = ['*.js', '**/*.bak']

      grepFilter = grep patterns, { restorable: true }

      grepFilter.on "finish", () ->
        restoreFilteredOut = grepFilter.restoreFilteredOut()
        expect(restoreFilteredOut._readableState.length).to.equal 3
        return
      
      grepFilter.write { path: "README.md" }
      grepFilter.write { path: "dir1/file1.coffee" }
      grepFilter.write { path: "dir2/file2.js" }
      grepFilter.write { path: "file2.js" }
      grepFilter.write { path: "dir2/file3.js.bak" }
      grepFilter.end()
      return
    return

  return

