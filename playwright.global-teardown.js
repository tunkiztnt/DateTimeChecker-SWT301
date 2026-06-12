const { spawnSync } = require('child_process');
const path = require('path');

module.exports = async () => {
  const script = path.join(__dirname, 'scripts', 'stop-server.ps1');
  spawnSync(
    'powershell',
    ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script],
    { cwd: __dirname, stdio: 'inherit' }
  );
};
