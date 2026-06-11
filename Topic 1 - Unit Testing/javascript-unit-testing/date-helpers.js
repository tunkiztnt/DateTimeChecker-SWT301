function formatDisplay(parts) {
  return `${String(parts.day).padStart(2, "0")}/${String(parts.month).padStart(2, "0")}/${parts.year}`;
}

function isValidRange(day, month, year) {
  const intRegex = /^\d+$/;
  if (!intRegex.test(String(day)) || !intRegex.test(String(month)) || !intRegex.test(String(year))) return false;

  const d = parseInt(day, 10);
  const m = parseInt(month, 10);
  const y = parseInt(year, 10);
  
  if (d < 1 || d > 31) return false;
  if (m < 1 || m > 12) return false;
  if (y < 1000 || y > 3000) return false; // Match ProjectIntroduction original requirement range
  
  return true;
}

module.exports = {
  formatDisplay,
  isValidRange
};
