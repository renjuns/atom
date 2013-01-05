fs = require 'fs'

describe "Config", ->
  describe ".get(keyPath) and .set(keyPath, value)", ->
    it "allows a key path's value to be read and written", ->
      expect(config.set("foo.bar.baz", 42)).toBe 42
      expect(config.get("foo.bar.baz")).toBe 42
      expect(config.get("bogus.key.path")).toBeUndefined()

    it "updates observers and saves when a key path is set", ->
      observeHandler = jasmine.createSpy "observeHandler"
      config.observe "foo.bar.baz", observeHandler
      observeHandler.reset()

      config.set("foo.bar.baz", 42)

      expect(config.save).toHaveBeenCalled()
      expect(observeHandler).toHaveBeenCalledWith 42

  describe ".save()", ->
    beforeEach ->
      spyOn(fs, 'write')
      jasmine.unspy config, 'save'

    it "writes any non-default properties to the config.json in the user's .atom directory", ->
      config.set("a.b.c", 1)
      config.set("a.b.d", 2)
      config.set("x.y.z", 3)
      config.setDefaults("a.b", e: 4, f: 5)

      fs.write.reset()
      config.save()

      writtenConfig = JSON.parse(fs.write.argsForCall[0][1])
      expect(writtenConfig).toEqual config.settings

  describe ".setDefaults(keyPath, defaults)", ->
    it "assigns any previously-unassigned keys to the object at the key path", ->
      config.set("foo.bar.baz", a: 1)
      config.setDefaults("foo.bar.baz", a: 2, b: 3, c: 4)
      expect(config.get("foo.bar.baz.a")).toBe 1
      expect(config.get("foo.bar.baz.b")).toBe 3
      expect(config.get("foo.bar.baz.c")).toBe 4

      config.setDefaults("foo.quux", x: 0, y: 1)
      expect(config.get("foo.quux.x")).toBe 0
      expect(config.get("foo.quux.y")).toBe 1

  describe ".update()", ->
    it "updates observers if a value is mutated without the use of .set", ->
      config.set("foo.bar.baz", ["a"])
      observeHandler = jasmine.createSpy "observeHandler"
      config.observe "foo.bar.baz", observeHandler
      observeHandler.reset()

      config.get("foo.bar.baz").push("b")
      config.update()
      expect(observeHandler).toHaveBeenCalledWith config.get("foo.bar.baz")
      observeHandler.reset()

      config.update()
      expect(observeHandler).not.toHaveBeenCalled()

  describe ".observe(keyPath)", ->
    observeHandler = null

    beforeEach ->
      observeHandler = jasmine.createSpy("observeHandler")
      config.set("foo.bar.baz", "value 1")
      config.observe "foo.bar.baz", observeHandler

    it "fires the given callback with the current value at the keypath", ->
      expect(observeHandler).toHaveBeenCalledWith("value 1")

    it "fires the callback every time the observed value changes", ->
      observeHandler.reset() # clear the initial call
      config.set('foo.bar.baz', "value 2")
      expect(observeHandler).toHaveBeenCalledWith("value 2")
      observeHandler.reset()

      config.set('foo.bar.baz', "value 1")
      expect(observeHandler).toHaveBeenCalledWith("value 1")

    it "fires the callback when the full key path goes into and out of existence", ->
      observeHandler.reset() # clear the initial call
      config.set("foo.bar", undefined)

      expect(observeHandler).toHaveBeenCalledWith(undefined)
      observeHandler.reset()

      config.set("foo.bar.baz", "i'm back")
      expect(observeHandler).toHaveBeenCalledWith("i'm back")
