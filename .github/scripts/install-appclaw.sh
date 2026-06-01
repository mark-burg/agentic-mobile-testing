#!/usr/bin/env bash
#
# Install AppClaw and deterministically pin its transitive `appium-mcp` server.
#
# WHY THIS EXISTS
# ---------------
# `appclaw@1.3.4` depends on `appium-mcp: ^1.67.0`. The old 1.67.0
# `appium_session_management` schema expects `capabilities` as an OBJECT
# (`z.record`), but appclaw sends it as a JSON STRING — producing
# "expected record, received string" and a failed session.
#
# appclaw resolves the appium-mcp server at runtime in `dist/mcp/client.js`:
#   1. PREFERRED: `require.resolve('appium-mcp/package.json')` then spawn
#      `node <pkg>/dist/index.js`  → uses whatever is installed (our pin).
#   2. FALLBACK (if that resolve throws): spawn `npx --yes appium-mcp@1.67.0`
#      → the hardcoded OLD record-schema version.
# CI has been observed to take the FALLBACK branch, so pinning the installed
# package alone is NOT enough — we ALSO rewrite the hardcoded fallback version
# so BOTH branches load the good (string-schema) build.
#
# USAGE
#   .github/scripts/install-appclaw.sh
#
# ENV (all optional; defaults shown)
#   APPCLAW_VERSION=1.3.4      appclaw version to install globally
#   APPIUM_MCP_VERSION=1.81.4  appium-mcp version to pin (string capabilities schema)
set -euo pipefail

APPCLAW_VERSION="${APPCLAW_VERSION:-1.3.4}"
APPIUM_MCP_VERSION="${APPIUM_MCP_VERSION:-1.81.4}"
# Major.minor used by the resolver self-test to validate the loaded version.
EXPECTED_MAJOR_MINOR="${APPIUM_MCP_VERSION%.*}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "::group::Installing appclaw@${APPCLAW_VERSION}"
npm install -g "appclaw@${APPCLAW_VERSION}" mjpeg-consumer
echo "::endgroup::"

APPCLAW_DIR="$(npm root -g)/appclaw"

echo "::group::Pinning appium-mcp@${APPIUM_MCP_VERSION} (string capabilities schema)"
cd "$APPCLAW_DIR"
npm install "appium-mcp@${APPIUM_MCP_VERSION}"
node -e "console.log('appium-mcp pinned to', require('appium-mcp/package.json').version)"
echo "::endgroup::"

echo "::group::Patching hardcoded appium-mcp fallback in client.js"
CLIENT_JS="$APPCLAW_DIR/dist/mcp/client.js"
# Rewrite any hardcoded `appium-mcp@<old>` fallback so the resolver's fallback
# branch can never load the old record-schema build.
sed -i -E "s/appium-mcp@[0-9]+\.[0-9]+\.[0-9]+/appium-mcp@${APPIUM_MCP_VERSION}/g" "$CLIENT_JS"
echo "appium-mcp@ references remaining in client.js:"
grep -n "appium-mcp@" "$CLIENT_JS" || echo "  (none)"
# Fail if any appium-mcp@<version> reference is NOT the version we pinned.
if grep -n "appium-mcp@" "$CLIENT_JS" | grep -qv "appium-mcp@${APPIUM_MCP_VERSION}"; then
  echo "::error::client.js still references an unpinned appium-mcp version after patching"
  exit 1
fi
echo "::endgroup::"

echo "::group::Resolver self-test (which appium-mcp will appclaw actually spawn?)"
CLIENT_JS="$CLIENT_JS" EXPECTED_MAJOR_MINOR="$EXPECTED_MAJOR_MINOR" \
  node "$SCRIPT_DIR/resolve-appium-mcp.mjs"

# Confirm the schema the locally-installed server declares for capabilities.
SESSION_JS="$APPCLAW_DIR/node_modules/appium-mcp/dist/tools/session/session.js"
if [ -f "$SESSION_JS" ]; then
  echo "capabilities schema in installed server:"
  grep -nE "capabilities: z\.(string|record|object)" "$SESSION_JS" \
    || grep -n "capabilities: z" "$SESSION_JS" \
    || true
fi
echo "::endgroup::"
