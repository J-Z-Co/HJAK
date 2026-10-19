import { Controller } from "@hotwired/stimulus"

// 页顶提示几秒后淡出；提醒（alert）留得更久
export default class extends Controller {
  connect() {
    const wait = this.element.querySelector("[role=alert]") ? 6000 : 2800
    this.timer = setTimeout(() => {
      this.element.style.transition = "opacity 300ms ease, transform 300ms ease"
      this.element.style.opacity = "0"
      this.element.style.transform = "translateY(-8px)"
      setTimeout(() => this.element.remove(), 320)
    }, wait)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
