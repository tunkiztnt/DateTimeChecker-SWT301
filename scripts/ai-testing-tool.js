const { spawn, execSync } = require('child_process');
const readline = require('readline');
const path = require('path');
const fs = require('fs');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function ask(query) {
  return new Promise((resolve) => rl.question(query, resolve));
}

async function callGemini(apiKey, prompt) {
  const modelName = process.env.GEMINI_MODEL || 'gemini-3.1-flash-lite';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      contents: [{
        parts: [{
          text: prompt
        }]
      }]
    })
  });
  
  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Gemini API error (${response.status}): ${errText}`);
  }
  
  const data = await response.json();
  if (data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts[0]) {
    return data.candidates[0].content.parts[0].text;
  }
  throw new Error("Invalid response format from Gemini API");
}

const simulatedTestCases = [
  { id: "TC01", name: "Valid Date (Leap Year)", day: "29", month: "2", year: "2024", expected: "valid", message: "29/02/2024 is correct date time!" },
  { id: "TC02", name: "Invalid Date (Non-Leap Year)", day: "29", month: "2", year: "2023", expected: "invalid", message: "29/02/2023 is NOT correct date time!" },
  { id: "TC03", name: "Day Decimal Error", day: "1.5", month: "2", year: "2020", expected: "error", message: "Input data for Day is incorrect format!" },
  { id: "TC04", name: "Day Out of Range", day: "32", month: "2", year: "2020", expected: "error", message: "Input data for Day is out of range!" },
  { id: "TC05", name: "Month Decimal Error", day: "15", month: "6.5", year: "2020", expected: "error", message: "Input data for Month is incorrect format!" },
  { id: "TC06", name: "Month Out of Range", day: "15", month: "13", year: "2020", expected: "error", message: "Input data for Month is out of range!" },
  { id: "TC07", name: "Year Decimal Error", day: "15", month: "6", year: "2020.5", expected: "error", message: "Input data for Year is incorrect format!" },
  { id: "TC08", name: "Year Out of Range", day: "15", month: "6", year: "999", expected: "error", message: "Input data for Year is out of range!" },
  { id: "TC09", name: "Clear Button Functionality", day: "15", month: "6", year: "2026", expected: "clear", message: "" },
  { id: "TC10", name: "Close Confirm Modal", day: "", month: "", year: "", expected: "close", message: "" }
];

function extractPlaywrightResults(jsonReportPath) {
  if (!fs.existsSync(jsonReportPath)) return {};
  try {
    const raw = fs.readFileSync(jsonReportPath, 'utf8');
    const data = JSON.parse(raw);
    const resultsMap = {};
    
    function traverse(suite) {
      if (suite.specs) {
        for (const spec of suite.specs) {
          const match = spec.title.match(/^(TC\d+):/);
          if (match) {
            const tcId = match[1];
            const testObj = spec.tests && spec.tests[0];
            const resultObj = testObj && testObj.results && testObj.results[0];
            const status = resultObj ? resultObj.status : 'unknown';
            
            let errMsg = '';
            if (resultObj && resultObj.errors && resultObj.errors.length > 0) {
              errMsg = resultObj.errors.map(e => e.message || '').join('\n').split('\n')[0];
              errMsg = errMsg.replace(/\u001b\[\d+m/g, ''); // strip ansi escape characters
            }
            
            resultsMap[tcId] = {
              status: status,
              error: errMsg
            };
          }
        }
      }
      if (suite.suites) {
        for (const subSuite of suite.suites) {
          traverse(subSuite);
        }
      }
    }
    
    if (data.suites) {
      for (const suite of data.suites) {
        traverse(suite);
      }
    }
    return resultsMap;
  } catch (err) {
    console.error("Error parsing Playwright JSON report:", err);
    return {};
  }
}

async function run() {
  console.clear();
  console.log("\x1b[36m============================================================");
  console.log("      AI-ASSISTED TESTING ASSISTANT DASHBOARD (SWT301)      ");
  console.log("============================================================\x1b[0m");

  // Load API key and model from local .env file if it exists
  const dotenvPath = path.join(__dirname, '..', '.env');
  if (fs.existsSync(dotenvPath)) {
    const envContent = fs.readFileSync(dotenvPath, 'utf8');
    const match = envContent.match(/GEMINI_API_KEY\s*=\s*([^\r\n]*)/);
    if (match && match[1]) {
      process.env.GEMINI_API_KEY = match[1].trim();
    }
    const modelMatch = envContent.match(/GEMINI_MODEL\s*=\s*([^\r\n]*)/);
    if (modelMatch && modelMatch[1]) {
      process.env.GEMINI_MODEL = modelMatch[1].trim();
    }
  }

  // Step 0: Check or prompt for Gemini API Key
  let apiKey = process.env.GEMINI_API_KEY;
  let useLiveAI = false;
  
  if (!apiKey) {
    console.log("\x1b[33m[AI CONFIG] No GEMINI_API_KEY found in environment or .env file.\x1b[0m");
    const inputKey = await ask("\x1b[35mPlease enter your Gemini API Key (or press Enter to use Simulated AI): \x1b[0m");
    if (inputKey.trim()) {
      apiKey = inputKey.trim();
      useLiveAI = true;
      try {
        fs.writeFileSync(dotenvPath, `GEMINI_API_KEY=${apiKey}\n`);
        console.log("\x1b[32m[AI CONFIG] Saved API Key to .env file for future runs.\x1b[0m");
      } catch (err) {
        console.log("\x1b[31m[AI CONFIG WARNING] Failed to save API Key to .env file:\x1b[0m", err.message);
      }
    }
  } else {
    useLiveAI = true;
    console.log("\x1b[32m[AI CONFIG] Found GEMINI_API_KEY in .env file or environment. Using live AI model.\x1b[0m");
  }

  // Step 0.5: Ask user for custom testing request
  console.log("");
  console.log("\x1b[33mDescribe what you want the AI to test in natural language.\x1b[0m");
  console.log("\x1b[33mExamples:\x1b[0m");
  console.log("  - 'generate 5 test cases for leap years'");
  console.log("  - 'test boundary values for day and month'");
  console.log("  - 'test incorrect input format error handling'");
  console.log("");
  
  let userPrompt = await ask("\x1b[35mEnter your testing request (or press Enter for default suite): \x1b[0m");
  userPrompt = userPrompt.trim();
  if (!userPrompt) {
    userPrompt = "Generate a balanced suite of 8 E2E test cases using Equivalence Partitioning, Boundary Value Analysis, and Error Guessing.";
  }
  console.log(`\x1b[32m[AI CONFIG] Testing request: "${userPrompt}"\x1b[0m`);

  // Parse requested count from user prompt (e.g. "20 test case")
  let requestedCount = null;
  const countMatch = userPrompt.match(/(\d+)\s*(?:test\s*case|case|test|scenario|câu|tc)/i);
  if (countMatch && countMatch[1]) {
    requestedCount = parseInt(countMatch[1], 10);
  }

  let limitDescription = "between 3 and 30 E2E test cases";
  let targetCount = 8;
  if (requestedCount && requestedCount >= 3 && requestedCount <= 30) {
    limitDescription = `exactly ${requestedCount} E2E test cases`;
    targetCount = requestedCount;
  } else if (requestedCount) {
    // If they requested a number outside 3-30, log warning and set to closest boundary
    targetCount = requestedCount < 3 ? 3 : 30;
    limitDescription = `exactly ${targetCount} E2E test cases`;
    console.log(`\x1b[33m[AI CONFIG WARNING] Requested count ${requestedCount} is outside allowed range (3-30). Limiting to ${targetCount}.\x1b[0m`);
  }

  console.log("\n\x1b[33m[STEP 1] AI Analyzing requirements and generating test suite...\x1b[0m");
  
  let testSuiteJson = [];
  if (useLiveAI) {
    try {
      const modelName = process.env.GEMINI_MODEL || 'gemini-3.1-flash-lite';
      console.log(`\x1b[34m[Gemini API] Querying ${modelName} for test design proposal...\x1b[0m`);
      const prompt = `Act as an expert AI Software Testing Agent. We are testing a Java date validation application (DateTimeChecker) with the following specifications:
- Day: integer between 1 and 31.
- Month: integer between 1 and 12.
- Year: integer between 1000 and 3000.

Message rules in the app:
- If valid: "{dd}/{mm}/{yyyy} is correct date time!" (dd and mm must be 2 digits, yyyy must be 4 digits, e.g. "29/02/2024 is correct date time!")
- If invalid (correct format but invalid date like 29/02/2023): "{dd}/{mm}/{yyyy} is NOT correct date time!"
- If error (format/range issues):
  - Day not integer/empty: "Input data for Day is incorrect format!"
  - Day out of range: "Input data for Day is out of range!"
  - Month not integer/empty: "Input data for Month is incorrect format!"
  - Month out of range: "Input data for Month is out of range!"
  - Year not integer/empty: "Input data for Year is incorrect format!"
  - Year out of range: "Input data for Year is out of range!"

User Request for testing: "${userPrompt}"

Generate E2E test cases matching the user request. You must generate exactly ${targetCount} E2E test cases.
CRITICAL: The returned JSON array must contain EXACTLY ${targetCount} objects. Do not return 10 or any other number. If you run out of ideas, vary the inputs (e.g. different months, different leap years, invalid years like 999 or 3001, etc.) to get exactly ${targetCount} test cases.

Return ONLY a valid JSON array of objects. Do not wrap in markdown block or any additional text.
Each object must have the following fields:
- "id": string (e.g. "TC01", "TC02", etc.)
- "name": string (brief name, e.g. "Valid Leap Year")
- "testType": string (e.g. "BVA", "EP", "Error Guessing", "UI Test", etc. reflecting the test design technique/type used)
- "day": string (input day value)
- "month": string (input month value)
- "year": string (input year value)
- "expected": string (must be one of: "valid", "invalid", "error")
- "message": string (the expected message in the popup based on the message rules above)
`;
      
      const responseText = await callGemini(apiKey, prompt);
      
      // Parse JSON from response
      let cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replace(/^```[a-zA-Z]*\n/, '').replace(/\n```$/, '');
      }
      cleanJson = cleanJson.trim();
      
      testSuiteJson = JSON.parse(cleanJson);
      
      if (!Array.isArray(testSuiteJson) || testSuiteJson.length === 0) {
        throw new Error("Gemini returned invalid JSON structure");
      }
      
      // Ensure exact limit is respected
      if (testSuiteJson.length > targetCount) {
        testSuiteJson = testSuiteJson.slice(0, targetCount);
      } else if (testSuiteJson.length < targetCount) {
        console.log(`\x1b[33m[AI CONFIG WARNING] Gemini generated ${testSuiteJson.length} cases but ${targetCount} were requested. Generating smart variations to complete the suite...\x1b[0m`);
        const baseLength = testSuiteJson.length;
        for (let idx = baseLength; idx < targetCount; idx++) {
          const baseCase = testSuiteJson[idx % baseLength];
          const copy = { ...baseCase };
          copy.id = `TC${(idx + 1).toString().padStart(2, '0')}`;
          
          if (copy.expected === 'valid' || copy.expected === 'invalid') {
            const yearNum = parseInt(copy.year, 10);
            if (!isNaN(yearNum) && yearNum >= 1000 && yearNum < 3000) {
              const newYear = (yearNum + Math.floor(idx / baseLength)) % 2000 + 1000;
              copy.year = newYear.toString();
              const isLeap = (year) => (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
              const currLeap = isLeap(newYear);
              if (copy.day === "29" && copy.month === "2") {
                if (currLeap) {
                  copy.expected = "valid";
                  copy.message = `29/02/${copy.year} is correct date time!`;
                } else {
                  copy.expected = "invalid";
                  copy.message = `29/02/${copy.year} is NOT correct date time!`;
                }
              } else {
                const dPad = (copy.day || "01").padStart(2, '0');
                const mPad = (copy.month || "01").padStart(2, '0');
                if (copy.expected === 'valid') {
                  copy.message = `${dPad}/${mPad}/${copy.year} is correct date time!`;
                } else {
                  copy.message = `${dPad}/${mPad}/${copy.year} is NOT correct date time!`;
                }
              }
            }
          } else if (copy.expected === 'error') {
            if (copy.day && !isNaN(parseInt(copy.day, 10))) {
              const dNum = parseInt(copy.day, 10);
              if (dNum > 31) {
                copy.day = (dNum + (idx - baseLength)).toString();
              } else if (dNum < 1) {
                copy.day = (dNum - (idx - baseLength)).toString();
              }
            } else if (copy.month && !isNaN(parseInt(copy.month, 10))) {
              const mNum = parseInt(copy.month, 10);
              if (mNum > 12) {
                copy.month = (mNum + (idx - baseLength)).toString();
              } else if (mNum < 1) {
                copy.month = (mNum - (idx - baseLength)).toString();
              }
            } else if (copy.year && !isNaN(parseInt(copy.year, 10))) {
              const yNum = parseInt(copy.year, 10);
              if (yNum > 3000) {
                copy.year = (yNum + (idx - baseLength)).toString();
              } else if (yNum < 1000) {
                copy.year = (yNum - (idx - baseLength)).toString();
              }
            }
          }
          copy.name = `${copy.name} (Variant ${Math.floor(idx / baseLength) + 1})`;
          testSuiteJson.push(copy);
        }
      }
      console.log("\n\x1b[32m[AI GENERATION COMPLETE] Live Gemini Model Proposed the following Test Suite:\x1b[0m");
    } catch (e) {
      console.log(`\n\x1b[31m[Gemini API Error] failed to call Gemini API: ${e.message}\x1b[0m`);
      console.log("\x1b[33mFalling back to Simulated Local AI Model...\x1b[0m");
      useLiveAI = false;
    }
  }
  
  if (!useLiveAI) {
    await new Promise(r => setTimeout(r, 1500));
    testSuiteJson = [];
    const query = userPrompt.toLowerCase();
    
    let filtered = simulatedTestCases;
    if (query.includes("leap")) {
      filtered = simulatedTestCases.filter(t => t.name.toLowerCase().includes("leap"));
    } else if (query.includes("range") || query.includes("limit") || query.includes("boundary") || query.includes("bva")) {
      filtered = simulatedTestCases.filter(t => t.name.toLowerCase().includes("range") || t.name.toLowerCase().includes("out of"));
    } else if (query.includes("decimal") || query.includes("format") || query.includes("error") || query.includes("ep")) {
      filtered = simulatedTestCases.filter(t => t.expected === "error" && (t.name.toLowerCase().includes("decimal") || t.name.toLowerCase().includes("out of")));
    } else if (query.includes("clear") || query.includes("reset")) {
      filtered = simulatedTestCases.filter(t => t.expected === "clear");
    } else if (query.includes("close") || query.includes("exit")) {
      filtered = simulatedTestCases.filter(t => t.expected === "close");
    }
    
    if (filtered.length === 0) {
      filtered = simulatedTestCases.slice(0, 6);
    }
    
    // Scale up simulated cases to match the requested targetCount
    for (let idx = 0; idx < targetCount; idx++) {
      const baseCase = filtered[idx % filtered.length];
      const copy = { ...baseCase };
      copy.id = `TC${(idx + 1).toString().padStart(2, '0')}`;
      // Slightly modify name if repeated to make them unique
      if (idx >= filtered.length) {
        copy.name = `${copy.name} (Variant ${Math.floor(idx / filtered.length) + 1})`;
      }
      testSuiteJson.push(copy);
    }
    console.log("\n\x1b[32m[AI GENERATION COMPLETE] Simulated Local AI Proposed the following Test Suite:\x1b[0m");
  }
  
  // Write the generated test cases to a JSON file for Playwright to read
  const generatedTestsPath = path.join(__dirname, '..', 'tests', 'generated_tests.json');
  fs.writeFileSync(generatedTestsPath, JSON.stringify(testSuiteJson, null, 2));
  
  console.log("------------------------------------------------------------");
  testSuiteJson.forEach((tc) => {
    console.log(`  - ${tc.id}: ${tc.name} [Type: ${tc.testType || "EP"}]`);
    if (tc.expected !== 'clear' && tc.expected !== 'close') {
      console.log(`    [Input] Day: "${tc.day}", Month: "${tc.month}", Year: "${tc.year}"`);
      console.log(`    [Expected] ${tc.expected.toUpperCase()} -> "${tc.message}"`);
    }
  });
  console.log("------------------------------------------------------------");
  
  console.log("\n\x1b[31m>>> HUMAN-IN-THE-LOOP CONTROL REQUIRED <<<\x1b[0m");
  console.log("AI can suggest test designs, but humans must sign off to prevent false assumptions.");
  const approveGen = await ask("\x1b[35mDo you approve the AI-generated test suite? (Y/N): \x1b[0m");
  
  if (approveGen.trim().toLowerCase() !== 'y') {
    console.log("\n\x1b[31m[EXIT] Test suite rejected by Human. Testing terminated.\x1b[0m");
    rl.close();
    process.exit(0);
  }
  
  console.log("\n\x1b[32m[APPROVED] Test suite approved. Proceeding to execution...\x1b[0m");
  let rerun = true;
  while (rerun) {
    const healedLogPath = path.join(__dirname, '..', 'tests', 'healed-log.json');
    if (fs.existsSync(healedLogPath)) {
      try {
        fs.unlinkSync(healedLogPath);
      } catch (e) {}
    }

    console.log("\n\x1b[33m[AI CONFIG] AI Self-Healing helps recover broken locators (e.g. changed submit buttons) visually.\x1b[0m");
    const enableSelfHealing = await ask("\x1b[35mEnable AI Self-Healing Locator Recovery? (Y/N) [Default: Y]: \x1b[0m");
    if (enableSelfHealing.trim().toLowerCase() === 'n') {
      process.env.SELF_HEALING = 'false';
      console.log("\x1b[31m[AI CONFIG] AI Self-Healing disabled. Traditional E2E execution selected.\x1b[0m");
    } else {
      process.env.SELF_HEALING = 'true';
      console.log("\x1b[32m[AI CONFIG] AI Self-Healing enabled. Visual locator recovery active.\x1b[0m");
    }
    
    // Start server
    console.log("\n\x1b[33m[SERVER] Compiling Java code and starting local server...\x1b[0m");
    let serverProcess;
    try {
      // Compile first
      execSync('powershell -ExecutionPolicy Bypass -File .\\scripts\\build.ps1', { stdio: ['ignore', 'inherit', 'inherit'] });
      
      // Start java server in background
      serverProcess = spawn('java', ['-cp', 'out/classes', 'com.datetimechecker.App'], {
        detached: false,
        stdio: 'pipe'
      });
      
      serverProcess.stdout.on('data', (data) => {
        // console.log(`[Java Server]: ${data}`);
      });
      
      serverProcess.stderr.on('data', (data) => {
        console.error(`[Java Server Error]: ${data}`);
      });
      
      // Wait for server to start
      await new Promise(r => setTimeout(r, 2000));
      console.log("\x1b[32m[SERVER READY] Java Server is listening on http://localhost:4173\x1b[0m");
    } catch (err) {
      console.error("\x1b[31mFailed to start server:\x1b[0m", err);
      rl.close();
      process.exit(1);
    }
    
    console.log("\n\x1b[33m[STEP 2] Running Playwright E2E tests (Opening Chromium browser)...\x1b[0m");
    console.log("Watch the browser open and perform actions automatically!");
    
    // Run Playwright
    let testSuccess = false;
    try {
      if (process.argv.includes('--headless')) {
        process.env.HEADLESS = 'true';
      }
      execSync('npx playwright test', { stdio: ['ignore', 'inherit', 'inherit'] });
      testSuccess = true;
    } catch (err) {
      console.log("\n\x1b[31m[TEST FAIL] Playwright test suite execution failed.\x1b[0m");
    }
    
    // Stop server
    console.log("\n\x1b[33m[SERVER] Shutting down Java server...\x1b[0m");
    if (serverProcess) {
      serverProcess.kill('SIGINT');
    }
    // Fallback kill using stop-server script
    try {
      execSync('powershell -ExecutionPolicy Bypass -File .\\scripts\\stop-server.ps1', { stdio: 'ignore' });
    } catch (e) {}
    
    // Read healed-log.json dynamically
    let healedLogs = [];
    try {
      if (fs.existsSync(healedLogPath)) {
        healedLogs = JSON.parse(fs.readFileSync(healedLogPath, 'utf8'));
      }
    } catch (e) {
      console.error("Error reading healed-log.json:", e);
    }
    const healedCount = healedLogs.length;
    let healedDetailStr = "0";
    if (healedCount > 0) {
      const descriptions = healedLogs.map(l => `${l.id}: '${l.selector}' -> '${l.healedTo}'`);
      if (descriptions.length > 3) {
        healedDetailStr = `${healedCount} (${descriptions.slice(0, 3).join(', ')} ... and ${healedCount - 3} more)`;
      } else {
        healedDetailStr = `${healedCount} (${descriptions.join(', ')})`;
      }
    }

    const totalCount = testSuiteJson.length;
    const reportPath = path.join(__dirname, '..', 'playwright-report', 'results.json');
    const resultsMap = extractPlaywrightResults(reportPath);
    
    console.log("\n\x1b[32m===============================================================================================================================================================================");
    console.log("                                                                           DETAILED TEST EXECUTION REPORT                                                                      ");
    console.log("===============================================================================================================================================================================\x1b[0m");
    
    // Table Headers
    const headers = [
      "ID".padEnd(6),
      "Test Case Name".padEnd(30),
      "Test Type".padEnd(28),
      "Inputs/Desc".padEnd(20),
      "Expected".padEnd(30),
      "Actual Result".padEnd(30),
      "Status".padEnd(8)
    ];
    console.log(headers.join(" | "));
    console.log("-".repeat(170));
    
    let passedCount = 0;
    let failedCount = 0;
    
    testSuiteJson.forEach((tc) => {
      const runRes = resultsMap[tc.id] || { status: 'failed', error: 'Test did not run' };
      const isPass = runRes.status === 'passed';
      if (isPass) {
        passedCount++;
      } else {
        failedCount++;
      }
      
      const idStr = tc.id.padEnd(6);
      
      let nameClean = tc.name;
      if (nameClean.length > 28) nameClean = nameClean.slice(0, 25) + "...";
      const nameStr = nameClean.padEnd(30);

      let typeClean = tc.testType || "Equivalence Partitioning";
      if (typeClean === "EP") typeClean = "Equivalence Partitioning";
      if (typeClean === "BVA") typeClean = "Boundary Value Analysis";
      if (typeClean.length > 26) typeClean = typeClean.slice(0, 25) + "...";
      const typeStr = typeClean.padEnd(28);
      
      let descClean = "";
      if (tc.expected === 'clear') descClean = "Clear inputs";
      else if (tc.expected === 'close') descClean = "Close confirm";
      else descClean = `D:${tc.day || ''}, M:${tc.month || ''}, Y:${tc.year || ''}`;
      if (descClean.length > 18) descClean = descClean.slice(0, 15) + "...";
      const descStr = descClean.padEnd(20);
      
      let expClean = "";
      if (tc.expected === 'clear') expClean = "Inputs cleared";
      else if (tc.expected === 'close') expClean = "Modal closed";
      else expClean = tc.message;
      if (expClean.length > 28) expClean = expClean.slice(0, 25) + "...";
      const expStr = expClean.padEnd(30);
      
      let actClean = "";
      if (isPass) {
        actClean = expClean;
      } else {
        actClean = runRes.error || "Execution failed";
      }
      if (actClean.length > 28) actClean = actClean.slice(0, 25) + "...";
      const actStr = actClean.padEnd(30);
      
      console.log(`${idStr} | ${nameStr} | ${typeStr} | ${descStr} | ${expStr} | ${actStr} | ${isPass ? "\x1b[32mPASS\x1b[0m" : "\x1b[31mFAIL\x1b[0m"}`);
    });
    
    console.log("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
    console.log(`  - Total Tests Run: ${totalCount}`);
    console.log(`  - Passed: \x1b[32m${passedCount}\x1b[0m`);
    console.log(`  - Failed: ${failedCount > 0 ? `\x1b[31m${failedCount}\x1b[0m` : `0`}`);
    console.log(`  - Self-Healed Locators: ${healedCount > 0 ? `\x1b[33m${healedDetailStr}\x1b[0m` : '0'}`);
    console.log("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
  
    // Save textual report (no ANSI color codes)
    let fileReport = "";
    fileReport += "===============================================================================================================================================================================\n";
    fileReport += "                                                                           DETAILED TEST EXECUTION REPORT                                                                      \n";
    fileReport += "===============================================================================================================================================================================\n";
    fileReport += headers.join(" | ") + "\n";
    fileReport += "-".repeat(170) + "\n";
    
    testSuiteJson.forEach((tc) => {
      const runRes = resultsMap[tc.id] || { status: 'failed', error: 'Test did not run' };
      const isPass = runRes.status === 'passed';
      const idStr = tc.id.padEnd(6);
      let nameClean = tc.name;
      if (nameClean.length > 28) nameClean = nameClean.slice(0, 25) + "...";
      const nameStr = nameClean.padEnd(30);

      let typeClean = tc.testType || "Equivalence Partitioning";
      if (typeClean === "EP") typeClean = "Equivalence Partitioning";
      if (typeClean === "BVA") typeClean = "Boundary Value Analysis";
      if (typeClean.length > 26) typeClean = typeClean.slice(0, 25) + "...";
      const typeStr = typeClean.padEnd(28);
      
      let descClean = "";
      if (tc.expected === 'clear') descClean = "Clear inputs";
      else if (tc.expected === 'close') descClean = "Close confirm";
      else descClean = `D:${tc.day || ''}, M:${tc.month || ''}, Y:${tc.year || ''}`;
      if (descClean.length > 18) descClean = descClean.slice(0, 15) + "...";
      const descStr = descClean.padEnd(20);
      
      let expClean = "";
      if (tc.expected === 'clear') expClean = "Inputs cleared";
      else if (tc.expected === 'close') expClean = "Modal closed";
      else expClean = tc.message;
      if (expClean.length > 28) expClean = expClean.slice(0, 25) + "...";
      const expStr = expClean.padEnd(30);
      
      let actClean = "";
      if (isPass) {
        actClean = expClean;
      } else {
        actClean = runRes.error || "Execution failed";
      }
      if (actClean.length > 28) actClean = actClean.slice(0, 25) + "...";
      const actStr = actClean.padEnd(30);
      const statusStr = (isPass ? "PASS" : "FAIL").padEnd(8);
      
      fileReport += `${idStr} | ${nameStr} | ${typeStr} | ${descStr} | ${expStr} | ${actStr} | ${statusStr}\n`;
    });
    
    fileReport += "-".repeat(170) + "\n";
    fileReport += `  - Total Tests Run: ${totalCount}\n`;
    fileReport += `  - Passed: ${passedCount}\n`;
    fileReport += `  - Failed: ${failedCount}\n`;
    fileReport += `  - Self-Healed Locators: ${healedDetailStr}\n`;
    fileReport += "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
    
    // Helper to escape values for CSV
    function escapeCSV(val) {
      if (val === null || val === undefined) return '""';
      const str = String(val);
      const escaped = str.replace(/"/g, '""');
      return `"${escaped}"`;
    }
  
    // Generate CSV report
    let csvContent = "\uFEFF"; // Add UTF-8 BOM for Microsoft Excel compatibility
    csvContent += "ID,Test Case Name,Test Type,Inputs/Description,Expected,Actual Result,Status\n";
    
    testSuiteJson.forEach((tc) => {
      const runRes = resultsMap[tc.id] || { status: 'failed', error: 'Test did not run' };
      const isPass = runRes.status === 'passed';
      
      let descClean = "";
      if (tc.expected === 'clear') descClean = "Clear inputs";
      else if (tc.expected === 'close') descClean = "Close confirm";
      else descClean = `D:${tc.day || ''}, M:${tc.month || ''}, Y:${tc.year || ''}`;
      
      let expClean = "";
      if (tc.expected === 'clear') expClean = "Inputs cleared";
      else if (tc.expected === 'close') expClean = "Modal closed";
      else expClean = tc.message;
      
      let actClean = "";
      if (isPass) {
        actClean = expClean;
      } else {
        actClean = runRes.error || "Execution failed";
      }
      
      const statusStr = isPass ? "PASS" : "FAIL";
      let testTypeStr = tc.testType || "Equivalence Partitioning";
      if (testTypeStr === "EP") testTypeStr = "Equivalence Partitioning";
      if (testTypeStr === "BVA") testTypeStr = "Boundary Value Analysis";
      
      csvContent += `${escapeCSV(tc.id)},${escapeCSV(tc.name)},${escapeCSV(testTypeStr)},${escapeCSV(descClean)},${escapeCSV(expClean)},${escapeCSV(actClean)},${escapeCSV(statusStr)}\n`;
    });
  
    try {
      const detailedReportPath = path.join(__dirname, '..', 'playwright-report', 'detailed-execution-report.txt');
      const csvReportPath = path.join(__dirname, '..', 'playwright-report', 'detailed-execution-report.csv');
      const detailedReportDir = path.dirname(detailedReportPath);
      if (!fs.existsSync(detailedReportDir)) {
        fs.mkdirSync(detailedReportDir, { recursive: true });
      }
      fs.writeFileSync(detailedReportPath, fileReport);
      fs.writeFileSync(csvReportPath, csvContent);
      console.log(`\n\x1b[32m[REPORT] Detailed text report saved to: ${detailedReportPath}\x1b[0m`);
      console.log(`\x1b[32m[REPORT] Detailed CSV report saved to: ${csvReportPath}\x1b[0m`);
    } catch (err) {
      console.error("Failed to write detailed test report files:", err);
    }
  
    if (testSuccess) {
      console.log("\n\x1b[31m>>> HUMAN-IN-THE-LOOP QUALITY SIGN-OFF <<<\x1b[0m");
      const approveResult = await ask("\x1b[35mDo you accept these test results and sign-off on the build? (Y/N): \x1b[0m");
      
      if (approveResult.trim().toLowerCase() === 'y') {
        console.log("\n\x1b[32m[PASSED] Build successfully signed off by Human. Ready for release!\x1b[0m");
      } else {
        console.log("\n\x1b[31m[REJECTED] Build rejected by Human sign-off.\x1b[0m");
      }
    } else {
      console.log("\n\x1b[31m[REJECTED] Build failed due to test execution failures.\x1b[0m");
    }
    
    console.log("");
    const answer = await ask("\x1b[35mDo you want to re-run the same test suite (e.g. to compare with/without AI Self-Healing)? (Y/N) [Default: N]: \x1b[0m");
    if (answer.trim().toLowerCase() !== 'y') {
      rerun = false;
    }
  }
  
  // Clean up generated json tests file
  try {
    if (fs.existsSync(generatedTestsPath)) {
      fs.unlinkSync(generatedTestsPath);
    }
  } catch (e) {}
  
  rl.close();
}

run();
