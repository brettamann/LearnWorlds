#!/usr/bin/env node
// Validate every JSON data file in the repo against its declared $schema.
//
// Walks:
//   data/**/*.json
//   content/**/*.json
//
// For each file:
//   1. Parse JSON
//   2. Read the $schema field (relative path to a schema file)
//   3. Resolve and load that schema
//   4. Run ajv validation
//   5. Report errors
//
// Exit codes:
//   0 — every file valid
//   1 — at least one file failed validation
//   2 — script error (missing dep, malformed input, etc.)
//
// Usage:
//   node tools/scripts/validate-data.mjs [--repo-root PATH] [--quiet] [-v]
//
// Dependencies:
//   ajv (peer; install via `npm install --no-save ajv ajv-formats`)
//   No package.json required — this script auto-installs deps in a sibling
//   node_modules/ if not found.

import { readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT_DEFAULT = path.resolve(__dirname, '..', '..');

// ---------- Argument parsing ----------

function parseArgs(argv) {
  const args = {
    repoRoot: REPO_ROOT_DEFAULT,
    quiet: false,
    verbose: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--repo-root') args.repoRoot = path.resolve(argv[++i]);
    else if (a === '--quiet') args.quiet = true;
    else if (a === '-v' || a === '--verbose') args.verbose = true;
    else if (a === '-h' || a === '--help') args.help = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(2);
    }
  }
  return args;
}

// ---------- Ensure ajv is installed ----------

async function ensureAjv() {
  const localNodeModules = path.join(__dirname, 'node_modules');
  const ajvDir = path.join(localNodeModules, 'ajv');

  if (!existsSync(ajvDir)) {
    console.log('Installing ajv + ajv-formats (one-time setup in tools/scripts/node_modules/)...');
    try {
      execSync('npm install --no-save --prefix . ajv@8 ajv-formats@3', {
        cwd: __dirname,
        stdio: 'inherit',
      });
    } catch (e) {
      console.error('Failed to install ajv. Run manually:');
      console.error('  cd tools/scripts && npm install --no-save ajv@8 ajv-formats@3');
      process.exit(2);
    }
  }

  // Dynamic import from the local install. Use the 2020-12 build so our schemas
  // (which declare $schema = "https://json-schema.org/draft/2020-12/schema") compile.
  const ajv2020Url = pathToFileURL(path.join(ajvDir, 'dist', '2020.js')).href;
  const ajvFormatsUrl = pathToFileURL(
    path.join(localNodeModules, 'ajv-formats', 'dist', 'index.js'),
  ).href;

  const { default: Ajv2020 } = await import(ajv2020Url);
  const { default: addFormats } = await import(ajvFormatsUrl);
  return { Ajv: Ajv2020, addFormats };
}

// ---------- File walking ----------

async function walkJsonFiles(rootDir) {
  const results = [];

  async function walk(dir) {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch (e) {
      return;
    }
    for (const e of entries) {
      const full = path.join(dir, e.name);
      // Skip hidden + node_modules.
      if (e.name.startsWith('.') || e.name === 'node_modules') continue;
      if (e.isDirectory()) await walk(full);
      else if (e.isFile() && e.name.endsWith('.json')) results.push(full);
    }
  }

  await walk(rootDir);
  return results.sort();
}

// ---------- Schema loading + caching ----------

class SchemaCache {
  constructor(repoRoot, ajv) {
    this.repoRoot = repoRoot;
    this.ajv = ajv;
    // Cache by normalized absolute path. Also handles the case where two data
    // files compute slightly different paths to the same schema file by
    // normalizing separators + casing on Windows.
    this.validators = new Map();
  }

  resolveSchemaPath(dataFilePath, schemaRef) {
    const dataDir = path.dirname(dataFilePath);
    const abs = path.resolve(dataDir, schemaRef);
    // Normalize for cross-platform stable caching.
    return path.normalize(abs).replace(/\\/g, '/').toLowerCase();
  }

  async getValidator(schemaPath) {
    if (this.validators.has(schemaPath)) return this.validators.get(schemaPath);
    if (!existsSync(schemaPath)) {
      throw new Error(`Schema file not found: ${schemaPath}`);
    }
    const raw = await readFile(schemaPath, 'utf8');
    const schema = JSON.parse(raw);

    // If this schema's $id is already registered with ajv (from a sibling
    // compile call), retrieve the existing validator instead of re-adding.
    let validate;
    if (schema.$id) {
      const existing = this.ajv.getSchema(schema.$id);
      if (existing) {
        validate = existing;
      }
    }
    if (!validate) {
      try {
        validate = this.ajv.compile(schema);
      } catch (e) {
        throw new Error(`Failed to compile schema ${schemaPath}: ${e.message}`);
      }
    }
    this.validators.set(schemaPath, validate);
    return validate;
  }
}

// ---------- Main ----------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node tools/scripts/validate-data.mjs [--repo-root PATH] [--quiet] [-v]');
    process.exit(0);
  }

  const { Ajv, addFormats } = await ensureAjv();

  const ajv = new Ajv({
    allErrors: true,
    strict: false, // some of our schemas use non-strict patterns; relax to keep ajv happy
    allowUnionTypes: true,
  });
  addFormats(ajv);

  const cache = new SchemaCache(args.repoRoot, ajv);

  // Walk data/ and content/.
  const dataFiles = [
    ...(await walkJsonFiles(path.join(args.repoRoot, 'data'))),
    ...(await walkJsonFiles(path.join(args.repoRoot, 'content'))),
  ];

  if (dataFiles.length === 0) {
    console.error('No JSON files found under data/ or content/.');
    process.exit(2);
  }

  if (!args.quiet) {
    console.log(`Validating ${dataFiles.length} JSON file(s) under data/ and content/...`);
    console.log('');
  }

  let okCount = 0;
  let skippedCount = 0;
  const failures = [];

  for (const filePath of dataFiles) {
    const rel = path.relative(args.repoRoot, filePath).replace(/\\/g, '/');

    let dataRaw;
    try {
      dataRaw = await readFile(filePath, 'utf8');
    } catch (e) {
      failures.push({ file: rel, error: `read failed: ${e.message}` });
      continue;
    }

    let data;
    try {
      data = JSON.parse(dataRaw);
    } catch (e) {
      failures.push({ file: rel, error: `parse failed: ${e.message}` });
      continue;
    }

    const schemaRef = data?.$schema;
    if (!schemaRef || typeof schemaRef !== 'string') {
      // Files without $schema are skipped (e.g., harvest manifests, tool outputs).
      if (args.verbose) console.log(`SKIP   ${rel} (no $schema field)`);
      skippedCount++;
      continue;
    }
    // Skip external $schema (json-schema.org / https URLs); only validate locally-referenced schemas.
    if (/^https?:/i.test(schemaRef)) {
      if (args.verbose) console.log(`SKIP   ${rel} ($schema is external URL)`);
      skippedCount++;
      continue;
    }

    const schemaPath = cache.resolveSchemaPath(filePath, schemaRef);
    let validate;
    try {
      validate = await cache.getValidator(schemaPath);
    } catch (e) {
      failures.push({ file: rel, error: e.message });
      continue;
    }

    const valid = validate(data);
    if (valid) {
      okCount++;
      if (!args.quiet) console.log(`OK     ${rel}`);
    } else {
      const errors = validate.errors || [];
      failures.push({
        file: rel,
        schema: path.relative(args.repoRoot, schemaPath).replace(/\\/g, '/'),
        errors: errors.map((e) => ({
          path: e.instancePath || '(root)',
          schemaPath: e.schemaPath,
          message: e.message,
          params: e.params,
        })),
      });
      if (!args.quiet) console.log(`FAIL   ${rel}  (${errors.length} error${errors.length === 1 ? '' : 's'})`);
    }
  }

  console.log('');
  console.log('Summary:');
  console.log(`  Validated: ${dataFiles.length}`);
  console.log(`  OK:        ${okCount}`);
  console.log(`  Skipped:   ${skippedCount} (no $schema field; treated as non-data files)`);
  console.log(`  Failed:    ${failures.length}`);
  console.log('');

  if (failures.length > 0) {
    console.log('Failures:');
    for (const f of failures) {
      console.log(`\n  ${f.file}`);
      if (f.schema) console.log(`    Schema: ${f.schema}`);
      if (f.error) console.log(`    ${f.error}`);
      if (f.errors) {
        for (const e of f.errors) {
          console.log(`    - ${e.path}: ${e.message}`);
          if (e.params) {
            const paramsStr = Object.entries(e.params)
              .map(([k, v]) => `${k}=${JSON.stringify(v)}`)
              .join(', ');
            if (paramsStr) console.log(`      (${paramsStr})`);
          }
        }
      }
    }
    console.log('');
    process.exit(1);
  }

  console.log('All valid. ✓');
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(2);
});
