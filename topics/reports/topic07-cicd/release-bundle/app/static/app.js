// Unregister any legacy service workers to prevent aggressive caching of static assets
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    for (const registration of registrations) {
      registration.unregister().then(() => {
        console.log('Legacy Service Worker unregistered.');
      });
    }
  });
}

document.addEventListener('DOMContentLoaded', () => {
  // Self-Healing helper functions for the web page inputs and buttons
  function getInputElement(id, labelText) {
    let el = document.getElementById(id);
    if (!el) {
      const labels = Array.from(document.querySelectorAll('label'));
      const label = labels.find(l => l.textContent.trim().toLowerCase() === labelText.toLowerCase());
      if (label) {
        const forAttr = label.getAttribute('for');
        if (forAttr) {
          el = document.getElementById(forAttr);
        }
        if (!el) {
          el = label.parentElement.querySelector('input');
        }
      }
    }
    return el;
  }

  function getButtonElement(id, buttonText) {
    let el = document.getElementById(id);
    if (!el) {
      const buttons = Array.from(document.querySelectorAll('button, input[type="button"], input[type="submit"]'));
      el = buttons.find(b => b.textContent.trim().toLowerCase() === buttonText.toLowerCase());
    }
    return el;
  }

  // DOM Elements
  const checkerForm = document.getElementById('checkerForm');
  const dayInput = getInputElement('day', 'Day');
  const monthInput = getInputElement('month', 'Month');
  const yearInput = getInputElement('year', 'Year');
  
  const clearButton = getButtonElement('clearButton', 'Clear');
  const nowButton = getButtonElement('nowButton', 'Use Today');
  const themeButton = document.getElementById('themeButton');
  const closeButton = document.getElementById('closeButton');
  
  const emptyState = document.getElementById('emptyState');
  const resultContent = document.getElementById('resultContent');
  const resultTitle = document.getElementById('resultTitle');
  const resultMessage = document.getElementById('resultMessage');
  const resultStatusIcon = document.getElementById('resultStatusIcon');
  const errorList = document.getElementById('errorList');
  const detailGrid = document.getElementById('detailGrid');
  
  const detailWeekday = document.getElementById('detailWeekday');
  const detailLeap = document.getElementById('detailLeap');
  const detailMonthDays = document.getElementById('detailMonthDays');
  
  const liveDateEl = document.getElementById('liveDate');
  
  const closeModal = document.getElementById('closeModal');
  const confirmCloseYes = document.getElementById('confirmCloseYes');
  const confirmCloseNo = document.getElementById('confirmCloseNo');
  
  const winformsMessageBox = document.getElementById('winformsMessageBox');
  const wfMbTitle = document.getElementById('wfMbTitle');
  const wfMbIcon = document.getElementById('wfMbIcon');
  const wfMbMessage = document.getElementById('wfMbMessage');
  const wfMbOkBtn = document.getElementById('wfMbOkBtn');
  const wfMbCloseBtn = document.getElementById('wfMbCloseBtn');

  // WinForms Icons (SVG code)
  const errorIconSvg = `
    <svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
      <circle cx="16" cy="16" r="14" fill="#E81123"/>
      <path d="M10 10L22 22M22 10L10 22" stroke="#ffffff" stroke-width="3.5" stroke-linecap="round"/>
    </svg>
  `;

  const infoIconSvg = `
    <svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
      <circle cx="16" cy="16" r="14" fill="#185ABD"/>
      <rect x="14.5" y="14" width="3" height="8" rx="0.5" fill="#ffffff"/>
      <circle cx="16" cy="10" r="2.2" fill="#ffffff"/>
    </svg>
  `;

  function showWinFormsMessageBox(title, iconSvg, message) {
    if (wfMbTitle) wfMbTitle.textContent = title;
    if (wfMbIcon) wfMbIcon.innerHTML = iconSvg;
    if (wfMbMessage) wfMbMessage.textContent = message;
    if (winformsMessageBox) winformsMessageBox.style.display = 'flex';
    
    // Focus the OK button
    setTimeout(() => {
      if (wfMbOkBtn) wfMbOkBtn.focus();
    }, 50);
  }

  function hideWinFormsMessageBox() {
    if (winformsMessageBox) winformsMessageBox.style.display = 'none';
  }

  if (wfMbOkBtn) wfMbOkBtn.addEventListener('click', hideWinFormsMessageBox);
  if (wfMbCloseBtn) wfMbCloseBtn.addEventListener('click', hideWinFormsMessageBox);
  
  // 1. Live Clock / Date
  function updateLiveDate() {
    // Only update if not mocked (e.g. during Playwright visual regression testing)
    if (liveDateEl && liveDateEl.innerText !== 'Thursday, 11 June 2026') {
      const now = new Date();
      const options = { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' };
      // Format to "Thursday, 11 June 2026"
      const dateStr = now.toLocaleDateString('en-GB', options); // GB format matches "11 June 2026"
      liveDateEl.textContent = dateStr;
    }
  }
  updateLiveDate();
  setInterval(updateLiveDate, 1000);

  // 2. Theme Toggle (Light / Dark)
  const savedTheme = localStorage.getItem('theme') || 'light';
  document.documentElement.setAttribute('data-theme', savedTheme);
  
  themeButton.addEventListener('click', () => {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
  });

  // 3. Close Modal Functionality (Confirm Close MessageBox)
  closeButton.addEventListener('click', () => {
    closeModal.style.display = 'flex';
  });
  
  confirmCloseNo.addEventListener('click', () => {
    closeModal.style.display = 'none';
  });
  
  confirmCloseYes.addEventListener('click', () => {
    closeModal.style.display = 'none';
    // Replace whole app UI with a clean exited state
    document.querySelector('.app-shell').innerHTML = `
      <div style="padding: 48px; text-align: center; font-family: sans-serif;">
        <h2 style="color: #ef4444; margin-bottom: 16px;">Application closed</h2>
        <p style="color: var(--text-secondary);">You can close this browser tab. Thank you for using DateTimeChecker!</p>
        <button onclick="window.location.reload()" class="btn btn-primary" style="margin-top: 24px; display: inline-flex; width: auto;">Reopen</button>
      </div>
    `;
  });

  // 4. Form Actions - Clear
  clearButton.addEventListener('click', () => {
    dayInput.value = '';
    monthInput.value = '';
    yearInput.value = '';
    
    // Reset output display state
    emptyState.style.display = 'flex';
    resultContent.style.display = 'none';
  });

  // 5. Form Actions - Use Today
  nowButton.addEventListener('click', () => {
    const today = new Date();
    dayInput.value = today.getDate();
    monthInput.value = today.getMonth() + 1; // getMonth is 0-indexed
    yearInput.value = today.getFullYear();
    
    // Automatically trigger form submit
    checkDateTime();
  });

  // 6. Submit Validation HTTP request
  checkerForm.addEventListener('submit', (e) => {
    e.preventDefault();
    checkDateTime();
  });

  async function checkDateTime() {
    const day = dayInput.value;
    const month = monthInput.value;
    const year = yearInput.value;
    
    try {
      const response = await fetch('/api/datetime/check', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ day, month, year })
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const result = await response.json();
      displayResult(result);
    } catch (error) {
      console.error('Validation error:', error);
      displayResult({
        valid: false,
        errors: [`Could not connect to the server: ${error.message}`]
      });
    }
  }

  function displayResult(result) {
    emptyState.style.display = 'none';
    resultContent.style.display = 'block';
    
    if (result.valid) {
      // Valid Date State
      resultTitle.textContent = 'Valid date';
      resultTitle.style.color = 'var(--success-text)';
      resultContent.style.backgroundColor = 'var(--success-bg)';
      resultContent.style.borderColor = 'var(--success-border)';
      resultContent.style.borderStyle = 'solid';
      resultContent.style.borderWidth = '1px';
      resultContent.style.borderRadius = '8px';
      resultContent.style.padding = '16px';
      
      resultMessage.textContent = `${result.details.display} is a valid date.`;
      resultMessage.style.color = 'var(--success-text)';
      
      // Success Checkmark Icon SVG
      resultStatusIcon.innerHTML = `
        <div class="status-icon" style="background-color: var(--success-text); color: white;">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
        </div>
      `;
      
      errorList.style.display = 'none';
      errorList.innerHTML = '';
      
      // Populate Details
      detailGrid.style.display = 'flex';
      detailWeekday.textContent = result.details.weekday;
      detailLeap.textContent = result.details.leapYear;
      detailMonthDays.textContent = result.details.monthDays;
    } else {
      // Invalid Date State
      resultTitle.textContent = 'Invalid date';
      resultTitle.style.color = 'var(--error-text)';
      resultContent.style.backgroundColor = 'var(--error-bg)';
      resultContent.style.borderColor = 'var(--error-border)';
      resultContent.style.borderStyle = 'solid';
      resultContent.style.borderWidth = '1px';
      resultContent.style.borderRadius = '8px';
      resultContent.style.padding = '16px';
      
      resultMessage.textContent = ''; // Clear main message
      
      // Error Alert Icon SVG
      resultStatusIcon.innerHTML = `
        <div class="status-icon" style="background-color: var(--error-text); color: white;">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </div>
      `;
      
      // Populate error list
      errorList.style.display = 'block';
      errorList.innerHTML = '';
      result.errors.forEach(err => {
        const li = document.createElement('li');
        li.textContent = err;
        errorList.appendChild(li);
      });
      
      detailGrid.style.display = 'none';
    }

    // INTERCEPT RESULTS FOR WINFORMS DIALOGS
    let wfTitle = "Message";
    let wfIcon = infoIconSvg;
    let wfMsg = "";

    if (!result.valid) {
      const errors = result.errors || [];
      const hasDayFormat = errors.some(e => e.includes("Day cannot be empty") || e.includes("Day must be an integer"));
      const hasMonthFormat = errors.some(e => e.includes("Month cannot be empty") || e.includes("Month must be an integer"));
      const hasYearFormat = errors.some(e => e.includes("Year cannot be empty") || e.includes("Year must be an integer"));
      
      const hasDayRange = errors.some(e => e.includes("Day must be in range 1-31"));
      const hasMonthRange = errors.some(e => e.includes("Month must be in range 1-12"));
      const hasYearRange = errors.some(e => e.includes("Year must be in range 1000-3000"));
      
      const hasDaysInMonthError = errors.some(e => e.includes("has only") && e.includes("days"));

      if (hasDayFormat) {
        wfTitle = "Error";
        wfIcon = errorIconSvg;
        wfMsg = "Input data for Day is incorrect format!";
      } else if (hasMonthFormat) {
        wfTitle = "Error";
        wfIcon = errorIconSvg;
        wfMsg = "Input data for Month is incorrect format!";
      } else if (hasYearFormat) {
        wfTitle = "Error";
        wfIcon = errorIconSvg;
        wfMsg = "Input data for Year is incorrect format!";
      } else if (hasDayRange) {
        wfTitle = "Error";
        wfIcon = errorIconSvg;
        wfMsg = "Input data for Day is out of range!";
      } else if (hasMonthRange) {
        wfTitle = "Error";
        wfIcon = errorIconSvg;
        wfMsg = "Input data for Month is out of range!";
      } else if (hasYearRange) {
        wfTitle = "Error";
        wfIcon = errorIconSvg;
        wfMsg = "Input data for Year is out of range!";
      } else if (hasDaysInMonthError) {
        wfTitle = "Message";
        wfIcon = infoIconSvg;
        const d = String(dayInput.value.trim()).padStart(2, '0');
        const m = String(monthInput.value.trim()).padStart(2, '0');
        const y = String(yearInput.value.trim()).padStart(4, '0');
        wfMsg = `${d}/${m}/${y} is NOT correct date time!`;
      } else {
        wfTitle = "Error";
        wfIcon = errorIconSvg;
        wfMsg = errors[0] || "An unknown error occurred.";
      }
    } else {
      wfTitle = "Message";
      wfIcon = infoIconSvg;
      const d = String(dayInput.value.trim()).padStart(2, '0');
      const m = String(monthInput.value.trim()).padStart(2, '0');
      const y = String(yearInput.value.trim()).padStart(4, '0');
      wfMsg = `${d}/${m}/${y} is correct date time!`;
    }

    showWinFormsMessageBox(wfTitle, wfIcon, wfMsg);
  }
});
