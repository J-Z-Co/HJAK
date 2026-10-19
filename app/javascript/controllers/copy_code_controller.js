import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      this.label ??= this.element.textContent
      this.element.textContent = "已复制"
      clearTimeout(this.timer)
      this.timer = setTimeout(() => { this.element.textContent = this.label }, 2000)
    })
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
