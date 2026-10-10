#!/usr/bin/env node
/**
 * PONT STUDIO — Tide Rush
 * Parle à StudioMCP en JSON-RPC over stdio.
 *
 * Usage:
 *   node tools/studio_bridge.js list                    -> liste les outils
 *   node tools/studio_bridge.js call <tool> '<json>'    -> appelle un outil
 *   node tools/studio_bridge.js exec '<code lua>'       -> raccourci: run_code
 */
const { spawn } = require('child_process');

const STUDIO_MCP = '/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP';

function die(msg) { console.error('ERREUR: ' + msg); process.exit(1); }

const cmd = process.argv[2];

if (!cmd) {
  console.log(`Usage:
  node tools/studio_bridge.js list                liste les outils Studio
  node tools/studio_bridge.js call <tool> '<json>' appelle un outil
  node tools/studio_bridge.js exec '<lua>'         exécute du Lua dans Studio`);
  process.exit(0);
}

const child = spawn(STUDIO_MCP, [], { stdio: ['pipe', 'pipe', 'pipe'] });
let buffer = '';
const pending = new Map();
let nextId = 1;

child.stdout.on('data', (d) => {
  buffer += d.toString();
  let idx;
  while ((idx = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, idx).trim();
    buffer = buffer.slice(idx + 1);
    if (!line) continue;
    let msg;
    try { msg = JSON.parse(line); } catch (e) { continue; }
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    }
  }
});

child.stderr.on('data', (d) => process.stderr.write('[studiomcp] ' + d.toString()));

function request(method, params) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, (msg) => {
      if (msg.error) reject(new Error(JSON.stringify(msg.error)));
      else resolve(msg.result);
    });
    child.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
    setTimeout(() => { if (pending.has(id)) { pending.delete(id); reject(new Error('timeout 30s')); } }, 30000);
  });
}

(async () => {
  try {
    await request('initialize', {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: { name: 'tide-rush-bridge', version: '1.0.0' }
    });
    child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');

    if (cmd === 'list') {
      const res = await request('tools/list', {});
      console.log(JSON.stringify(res, null, 2));
    } else if (cmd === 'call') {
      const tool = process.argv[3];
      const args = process.argv[4] ? JSON.parse(process.argv[4]) : {};
      const res = await request('tools/call', { name: tool, arguments: args });
      console.log(JSON.stringify(res, null, 2));
    } else if (cmd === 'exec') {
      const code = process.argv[3];
      if (!code) die('code lua manquant');
      const res = await request('tools/call', { name: 'run_code', arguments: { code } });
      console.log(JSON.stringify(res, null, 2));
    } else {
      die('commande inconnue: ' + cmd);
    }
  } catch (e) {
    die(e.message);
  } finally {
    child.kill();
  }
})();
