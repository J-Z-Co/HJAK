import { Controller } from "@hotwired/stimulus"

// 已经从主屏幕图标打开时，不再提示怎么添加
export default class extends Controller {
  static targets = [ "ios", "android" ]

  connect() {
    const standalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
    if (standalone) {
      this.element.remove()
      return
    }

    const apple = /iPhone|iPad|iPod/.test(window.navigator.userAgent)
    const panel = apple ? this.iosTarget : this.androidTarget
    panel.classList.remove("hidden")
  }
}
