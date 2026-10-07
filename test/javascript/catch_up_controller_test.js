import { test } from "node:test"
import assert from "node:assert/strict"
import CatchUpController from "../../app/javascript/wallflower/catch_up_controller.js"

function pageAt(href) {
  const listeners = {}
  const visits = []
  const page = {
    visibilityState: "visible",
    visits,
    addEventListener(name, listener) { listeners[name] = listener },
    removeEventListener(name, listener) { if (listeners[name] === listener) delete listeners[name] },
    becomes(state) {
      page.visibilityState = state
      listeners.visibilitychange?.()
    },
    defaultView: {
      location: { href },
      Turbo: { visit: (url, options) => visits.push({ url, options }) }
    }
  }
  return page
}

function catchUpOn(page) {
  const controller = new CatchUpController({ scope: { element: { ownerDocument: page } } })
  controller.connect()
  return controller
}

test("a page shown again after being hidden reloads itself in place", () => {
  const page = pageAt("http://example.test/wallflower/tasks/1")
  catchUpOn(page)

  page.becomes("hidden")
  page.becomes("visible")

  assert.deepEqual(page.visits, [{ url: "http://example.test/wallflower/tasks/1", options: { action: "replace" } }])
})
