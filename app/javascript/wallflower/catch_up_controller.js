import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.page = this.element.ownerDocument
    this.catchUp = this.catchUp.bind(this)
    this.page.addEventListener("visibilitychange", this.catchUp)
  }

  catchUp() {
    if (this.page.visibilityState !== "visible") return

    const view = this.page.defaultView
    view.Turbo.visit(view.location.href, { action: "replace" })
  }
}
