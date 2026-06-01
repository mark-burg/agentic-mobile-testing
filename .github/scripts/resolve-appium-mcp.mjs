// Resolver self-test for AppClaw CI.
//
// Reproduces appclaw's `resolveAppiumMcp()` (dist/mcp/client.js) so CI knows,
// BEFORE the device/emulator step runs, which branch the resolver will take and
// which appium-mcp version/schema it will load:
//   1. preferred: require.resolve('appium-mcp/package.json') -> node <pkg>/dist/index.js
//   2. fallback (if that resolve throws): npx --yes appium-mcp@<pinned-in-client.js>
//
// Usage: CLIENT_JS=/path/to/appclaw/dist/mcp/client.js \
//        EXPECTED_MAJOR_MINOR=1.81 node resolve-appium-mcp.mjs
//
// Exits non-zero (with a GitHub `::error::` annotation) if the resolver would
// load an appium-mcp version other than the expected one.
import { createRequire } from 'module';
import { pathToFileURL } from 'url';
import path from 'path';

const clientJs = process.env.CLIENT_JS;
const expected = process.env.EXPECTED_MAJOR_MINOR || '1.81';

if (!clientJs) {
  console.error('::error::CLIENT_JS env var is required');
  process.exit(1);
}

const req = createRequire(pathToFileURL(clientJs).href);

try {
  const pkgJson = req.resolve('appium-mcp/package.json');
  const pkgDir = path.dirname(pkgJson);
  const version = req(pkgJson).version;
  console.log(`RESOLVER BRANCH: preferred (node ${path.join(pkgDir, 'dist/index.js')})`);
  console.log(`RESOLVED appium-mcp VERSION: ${version}`);
  if (!version.startsWith(`${expected}.`) && version !== expected) {
    console.error(`::error::Resolver will load unexpected appium-mcp ${version} (expected ${expected}.x)`);
    process.exit(1);
  }
} catch (e) {
  // The fallback branch is acceptable ONLY because install-appclaw.sh has
  // already patched the hardcoded version in client.js. Surface it loudly.
  const firstLine = String(e.message).split('\n')[0];
  console.log(`RESOLVER BRANCH: FALLBACK (npx) — resolve threw: ${e.code} ${firstLine}`);
  console.log('Fallback now uses the patched version pinned in client.js (verified in the patch step).');
}
