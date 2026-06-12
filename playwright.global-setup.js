const { spawnSync } = require('child_process');
const path = require('path');

module.exports = async () => {
  const script = path.join(__dirname, 'scripts', 'start-server.ps1');
  const result = spawnSync(
    'powershell',
    ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script],
    { cwd: __dirname, stdio: 'inherit' }
  );

  if (result.status !== 0) {
    throw new Error(`Failed to start DateTimeChecker server. Exit code: ${result.status}`);
  }
};
