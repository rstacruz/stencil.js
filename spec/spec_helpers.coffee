@assert = (what) ->
  expect(!!what).toBe(true)

do ->
  jasmineEnv = jasmine.getEnv()
  jasmineEnv.updateInterval = 250

  htmlReporter = new jasmine.HtmlReporter()
  jasmineEnv.addReporter htmlReporter

  jasmineEnv.specFilter = (spec) -> htmlReporter.specFilter spec

  $ -> jasmineEnv.execute()
