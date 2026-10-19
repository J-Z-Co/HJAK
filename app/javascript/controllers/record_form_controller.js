import { Controller } from "@hotwired/stimulus"

// 保存按钮上显示本次填了几项；血压两个框算一项
export default class extends Controller {
  static targets = [ "submit" ]

  connect() {
    this.count()
    // 桌面浏览器里，滚轮停在已聚焦的数字框上会改动数值；先让它失焦，滚轮就只滚页面
    this.onWheel = (event) => {
      if (event.target === document.activeElement && event.target.type === "number") event.target.blur()
    }
    this.element.addEventListener("wheel", this.onWheel, { passive: true })
  }

  disconnect() {
    this.element.removeEventListener("wheel", this.onWheel)
  }

  count() {
    const filled = new Set()
    this.element.querySelectorAll("input[name^='measurements[']").forEach((input) => {
      if (input.value.trim() !== "") filled.add(input.name.match(/^measurements\[([^\]]+)\]/)[1])
    })
    const label = this.submitTarget.dataset.label
    this.submitTarget.value = filled.size > 0 ? `${label}（${filled.size} 项）` : label
  }
}
