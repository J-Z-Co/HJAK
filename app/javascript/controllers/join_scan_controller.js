import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "codePanel", "scanPanel", "failure", "code", "reader", "codeTab", "scanTab" ]

  disconnect() {
    this.stop()
  }

  showCode() {
    this.stop()
    this.codePanelTarget.classList.remove("hidden")
    this.scanPanelTarget.classList.add("hidden")
    this.#select(this.codeTabTarget)
  }

  async showScan() {
    this.failureTarget.classList.add("hidden")
    this.codePanelTarget.classList.add("hidden")
    this.scanPanelTarget.classList.remove("hidden")
    this.#select(this.scanTabTarget)
    await this.start()
  }

  async start() {
    await this.stop()
    try {
      const module = await import("html5-qrcode")
      const Html5Qrcode = module.Html5Qrcode
      this.scanner = new Html5Qrcode(this.readerTarget.id)
      await this.scanner.start(
        { facingMode: "environment" },
        { fps: 8, qrbox: { width: 220, height: 220 } },
        (text) => {
          this.stop()
          const url = new URL("/groups/join", window.location.origin)
          url.searchParams.set("code", text)
          window.location.assign(url)
        }
      )
    } catch (_error) {
      this.failureTarget.classList.remove("hidden")
      this.showCode()
    }
  }

  async stop() {
    if (!this.scanner) return

    const scanner = this.scanner
    this.scanner = null
    try {
      if (scanner.isScanning) await scanner.stop()
      scanner.clear()
    } catch (_error) {
      // 相机已经关掉时再停一次，不需要打断离开页面。
    }
  }

  #select(tab) {
    [ this.codeTabTarget, this.scanTabTarget ].forEach((item) => item.setAttribute("aria-selected", item === tab))
  }
}
