import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="email-alert"
export default class extends Controller {
  static targets = ["form", "table"]

  // Called when the form input changes
  update() {
    this.formTarget.requestSubmit(); // Submits the form via Turbo
  }

  // Show loading indicator before the fetch starts
  showLoading() {
    this.tableTarget.classList.add("loading");
  }

  // Hide loading indicator after the fetch completes
  hideLoading() {
    this.tableTarget.classList.remove("loading");
  }
}
