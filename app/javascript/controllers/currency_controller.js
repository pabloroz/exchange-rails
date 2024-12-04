import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="currency"
export default class extends Controller {
  static targets = ["tableBody"];

  connect() {
    const currency = this.element.dataset.currency;
    if (currency) {
      this.fetchCurrencyRates(currency);
    } else {
      this.fetchCurrencies();
    }
  }

  async fetchCurrencies() {
    const apiUrl = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json";

    this.tableBodyTarget.innerHTML = `<tr><td colspan="2">Loading...</td></tr>`; // Show loading indicator

    try {
      const response = await fetch(apiUrl);
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }

      const currencies = await response.json();
      this.tableBodyTarget.innerHTML = ""; // Clear loading indicator
      this.renderCurrencies(currencies);
    } catch (error) {
      console.error("Error fetching currencies:", error);
      this.tableBodyTarget.innerHTML = `<tr><td colspan="2">Error loading currencies</td></tr>`;
    }
  }

  async fetchCurrencyRates(currency) {
    const apiUrl = `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/${currency.toLowerCase()}.json`;

    this.tableBodyTarget.innerHTML = `<tr><td colspan="2">Loading...</td></tr>`; // Show loading indicator

    try {
      const response = await fetch(apiUrl);
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }

      const rates = await response.json();
      this.tableBodyTarget.innerHTML = ""; // Clear loading indicator
      this.renderCurrencyRates(currency, rates[currency.toLowerCase()]);
    } catch (error) {
      console.error("Error fetching currency rates:", error);
      this.tableBodyTarget.innerHTML = `<tr><td colspan="2">Error loading exchange rates</td></tr>`;
    }
  }

  renderCurrencies(currencies) {
    Object.entries(currencies).forEach(([code, name]) => {
      const row = document.createElement("tr");
      row.innerHTML = `
        <td><a href="/${code.toUpperCase()}" data-action="click->currency#fetchCurrencyRates">${code.toUpperCase()}</a></td>
        <td>${name}</td>
      `;
      this.tableBodyTarget.appendChild(row);
    });
  }

  renderCurrencyRates(currency, rates) {
    Object.entries(rates).forEach(([pair, rate]) => {
      const row = document.createElement("tr");
      row.innerHTML = `
        <td>${pair.toUpperCase()}</td>
        <td>${rate}</td>
        <td>
          <a href="/email_alerts/new?base_currency=${currency.toUpperCase()}&quote_currency=${pair.toUpperCase()}&multiplier=${rate}" class="btn btn-primary">
            Create Alert
          </a>
        </td>
      `;
      this.tableBodyTarget.appendChild(row);
    });
  }
}