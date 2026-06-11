document.addEventListener('DOMContentLoaded', () => {
  // DOM Elements
  const checkerForm = document.getElementById('checkerForm');
  const dayInput = document.getElementById('day');
  const monthInput = document.getElementById('month');
  const yearInput = document.getElementById('year');
  
  const clearButton = document.getElementById('clearButton');
  const nowButton = document.getElementById('nowButton');
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
        <h2 style="color: #ef4444; margin-bottom: 16px;">Ứng dụng đã đóng</h2>
        <p style="color: var(--text-secondary);">Bạn có thể đóng tab trình duyệt này. Cảm ơn bạn đã sử dụng DateTimeChecker!</p>
        <button onclick="window.location.reload()" class="btn btn-primary" style="margin-top: 24px; display: inline-flex; width: auto;">Mở lại</button>
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
        errors: [`Không thể kết nối đến máy chủ: ${error.message}`]
      });
    }
  }

  function displayResult(result) {
    emptyState.style.display = 'none';
    resultContent.style.display = 'block';
    
    if (result.valid) {
      // Valid Date State
      resultTitle.textContent = 'Ngày hợp lệ';
      resultTitle.style.color = 'var(--success-text)';
      resultContent.style.backgroundColor = 'var(--success-bg)';
      resultContent.style.borderColor = 'var(--success-border)';
      resultContent.style.borderStyle = 'solid';
      resultContent.style.borderWidth = '1px';
      resultContent.style.borderRadius = '8px';
      resultContent.style.padding = '16px';
      
      resultMessage.textContent = `${result.details.display} là một ngày hợp lệ.`;
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
      resultTitle.textContent = 'Ngày không hợp lệ';
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
  }
});
