import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async refresh(event) {
    event.preventDefault()
    if (window.caches) {
      const keys = await window.caches.keys()
      await Promise.all(keys.filter((key) => key.startsWith("phoenix-")).map((key) => window.caches.delete(key)))
    }
    window.location.reload()
  }
}
