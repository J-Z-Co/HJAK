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

  // 浏览器的 step 校验会在安卓上静默拦截提交。这里在提交前把多出来的小数四舍五入，服务端会再做一次。
  round() {
    this.element.querySelectorAll("input[data-decimals]").forEach((input) => {
      const rounded = roundHalfUp(input.value, Number(input.dataset.decimals))
      if (rounded !== null) input.value = rounded
    })
  }

  count() {
    if (!this.hasSubmitTarget) return

    const filled = new Set()
    this.element.querySelectorAll("input[name^='measurements[']").forEach((input) => {
      if (input.value.trim() !== "") filled.add(input.name.match(/^measurements\[([^\]]+)\]/)[1])
    })
    const label = this.submitTarget.dataset.label
    this.submitTarget.value = filled.size > 0 ? `${label}（${filled.size} 项）` : label
  }
}

function roundHalfUp(raw, digits) {
  let text = raw.trim().replace(/[，。．]/g, ".")
  if (text === "") return null

  const negative = text.startsWith("-")
  if (negative) text = text.slice(1)
  if (!/^\d+(\.\d+)?$/.test(text)) return null

  const [ whole, fraction = "" ] = text.split(".")
  if (fraction.length <= digits) return stripTrailingZeros(negative, whole, fraction)

  let carry = Number(fraction[digits]) >= 5
  const kept = (whole + fraction.slice(0, digits)).split("")
  if (carry) {
    for (let index = kept.length - 1; index >= 0; index -= 1) {
      if (kept[index] === "9") {
        kept[index] = "0"
      } else {
        kept[index] = String(Number(kept[index]) + 1)
        carry = false
        break
      }
    }
    if (carry) kept.unshift("1")
  }

  const joined = kept.join("").replace(/^0+(?=\d)/, "")
  if (digits === 0) return `${negative ? "-" : ""}${joined || "0"}`.replace(/^-0$/, "0")

  const splitAt = joined.length - digits
  const nextWhole = splitAt > 0 ? joined.slice(0, splitAt) : "0"
  const nextFraction = splitAt > 0 ? joined.slice(splitAt) : joined.padStart(digits, "0")
  return stripTrailingZeros(negative, nextWhole, nextFraction)
}

function stripTrailingZeros(negative, whole, fraction) {
  const trimmed = fraction.replace(/0+$/, "")
  const body = trimmed ? `${whole || "0"}.${trimmed}` : (whole || "0")
  return negative && body !== "0" ? `-${body}` : body
}
