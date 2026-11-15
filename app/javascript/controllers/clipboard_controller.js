import { Controller } from "@hotwired/stimulus"

// Copies a value to the clipboard and briefly confirms on the button.
export default class extends Controller {
  static values = { text: String, label: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.flash("Copied!")
    } catch {
      this.flash("Couldn't copy — press and hold the link instead")
    }
  }

  flash(message) {
    this.element.textContent = message
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { this.element.textContent = this.labelValue }, 2000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
