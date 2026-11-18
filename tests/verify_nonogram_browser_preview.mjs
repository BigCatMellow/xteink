import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { runInNewContext } from 'node:vm';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(resolve(root, 'games/nonogram/preview.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'Preview script is present');
const cut = script.indexOf('function loadLevel(');
assert.ok(cut > 0, 'Generator can be isolated from UI rendering');
const context = { document: { querySelector: () => ({}) } };
runInNewContext(script.slice(0, cut) + '\nglobalThis.previewLevel = generateDevice;', context);

const lua = `
package.path='app/?.lua;'..package.path
local Generator=require('generator')
for level=13,56 do
  local result=Generator.generate_v2(level)
  print(level..'|'..table.concat(result.rows,',')..'|'..(result.rounds or 0))
end
for _,level in ipairs({999999998,999999999}) do
  local result=Generator.generate_v2(level)
  print(level..'|'..table.concat(result.rows,',')..'|'..result.rounds)
end
`;
const run = spawnSync('lua', ['-'], {
  cwd: resolve(root, 'games/nonogram'), input: lua, encoding: 'utf8'
});
assert.equal(run.status, 0, run.stderr || 'Lua generator failed');
let checked = 0;
for (const record of run.stdout.trim().split('\n')) {
  const [rawLevel, rawRows, rawRounds] = record.split('|');
  const level = Number(rawLevel);
  const preview = context.previewLevel(level);
  assert.equal(preview.rows.join(','), rawRows, `Device image parity: level ${level}`);
  assert.equal(preview.passes, Number(rawRounds), `Deduction passes: level ${level}`);
  checked++;
}
assert.equal(checked, 46);
assert.ok(!html.includes('const pictures='),'Preview cannot contain preset levels');
console.log(`PASS: ${checked} browser levels exactly match Lua generated boards and deduction passes`);
