import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "body", "expand", "collapse", "actions", "replies", "replyToggle", "replyForm", "listOpen" ]
  static values = { count: Number }

  connect() {
    this.expanded = false
    this.#fit()
    requestAnimationFrame(() => this.#fit())
  }

  expand() {
    this.expanded = true
    this.bodyTarget.classList.remove("line-clamp-2")
    this.expandTarget.classList.add("hidden")
    this.collapseTarget.classList.remove("hidden")
    this.actionsTarget.classList.remove("hidden")
  }

  collapse() {
    this.expanded = false
    this.bodyTarget.classList.add("line-clamp-2")
    this.collapseTarget.classList.add("hidden")
    this.#fit()
  }

  showReply() {
    if (!this.hasReplyFormTarget) return
    this.replyFormTarget.classList.remove("hidden")
    this.replyFormTarget.querySelector("textarea")?.focus()
  }

  refit() {
    this.#fit()
  }

  toggleReplies() {
    this.repliesTarget.classList.toggle("hidden")
    const open = !this.repliesTarget.classList.contains("hidden")
    this.replyToggleTarget.textContent = open ? "点击隐藏补充意见" : `存在 ${this.countValue} 条补充意见`
    if (this.hasListOpenTarget) this.listOpenTarget.value = open ? "1" : "0"
    if (open) requestAnimationFrame(() => this.#refitChildren())
  }

  vote(event) {
    const button = event.currentTarget
    if (button.disabled) return
    button.disabled = true

    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
    fetch(button.dataset.url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        Accept: "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ choice: button.dataset.choice })
    }).then(async (response) => {
      if (!response.ok) {
        button.disabled = false
        return
      }
      const data = await response.json()
      const count = button.querySelector("[data-count]")
      if (count) count.textContent = data[button.dataset.choice === "wrong" ? "wrong_count" : "reasonable_count"]
    }).catch(() => {
      button.disabled = false
    })
  }

  #refitChildren() {
    this.repliesTarget.querySelectorAll(":scope > [data-controller~='suggestion-card']").forEach((element) => {
      this.application.getControllerForElementAndIdentifier(element, "suggestion-card")?.refit()
    })
  }

  #fit() {
    if (this.expanded) return
    const overflow = this.bodyTarget.scrollHeight > this.bodyTarget.clientHeight + 1
    this.expandTarget.classList.toggle("hidden", !overflow)
    this.actionsTarget.classList.toggle("hidden", overflow)
    if (!overflow) this.collapseTarget.classList.add("hidden")
  }
}
