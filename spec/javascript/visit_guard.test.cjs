const assert = require("node:assert/strict")
const fs = require("node:fs")
const test = require("node:test")
const vm = require("node:vm")

const source = fs.readFileSync(`${__dirname}/../../app/javascript/visit_guard.js`, "utf8")
  .replace(/^export function /gm, "function ")
const context = {}
vm.runInNewContext(`${source}\nthis.nextVisitState = nextVisitState\nthis.shouldIgnoreClick = shouldIgnoreClick`, context)

test("访问开始后忽略再次点击，加载完成或失败后恢复", () => {
  let visiting = context.nextVisitState(false, "turbo:before-visit")
  assert.equal(context.shouldIgnoreClick(visiting, "A"), true)
  assert.equal(context.shouldIgnoreClick(visiting, "BUTTON"), true)
  assert.equal(context.shouldIgnoreClick(visiting, "DIV"), false)

  visiting = context.nextVisitState(visiting, "turbo:load")
  assert.equal(context.shouldIgnoreClick(visiting, "A"), false)

  visiting = context.nextVisitState(true, "turbo:fetch-request-error")
  assert.equal(visiting, false)
})
