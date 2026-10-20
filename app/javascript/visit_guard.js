export function nextVisitState(visiting, eventName) {
  if (eventName === "turbo:before-visit") return true
  if (eventName === "turbo:load" || eventName === "turbo:fetch-request-error") return false
  return visiting
}

export function shouldIgnoreClick(visiting, tagName) {
  return visiting && [ "A", "BUTTON", "INPUT" ].includes(tagName)
}

export function installVisitGuard(target = document) {
  let visiting = false
  const remember = (eventName) => {
    visiting = nextVisitState(visiting, eventName)
  }
  target.addEventListener("turbo:before-visit", () => remember("turbo:before-visit"))
  target.addEventListener("turbo:load", () => remember("turbo:load"))
  target.addEventListener("turbo:fetch-request-error", () => remember("turbo:fetch-request-error"))
  target.addEventListener("click", (event) => {
    const control = event.target?.closest?.("a, button, input[type=submit]")
    if (!control || !shouldIgnoreClick(visiting, control.tagName)) return
    event.preventDefault()
    event.stopPropagation()
  }, true)
}
