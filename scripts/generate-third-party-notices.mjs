import { promises as fs } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url))
const projectRoot = path.resolve(scriptDirectory, '..')
const harnessRoot = path.join(projectRoot, 'harness')
const lockPath = path.join(harnessRoot, 'package-lock.json')
const outputPath = path.join(projectRoot, 'build', 'THIRD_PARTY_LICENSES.txt')

const lock = JSON.parse(await fs.readFile(lockPath, 'utf8'))
const packagePaths = Object.keys(lock.packages ?? {})
  .filter(packagePath => packagePath.includes('node_modules/'))
  .sort((left, right) => left.localeCompare(right, 'en'))

const licenseNames = [
  'LICENSE',
  'LICENSE.md',
  'LICENSE.txt',
  'LICENCE',
  'LICENCE.md',
  'LICENCE.txt',
  'COPYING',
  'NOTICE',
]

const sections = []
const seen = new Set()

for (const packagePath of packagePaths) {
  const packageRoot = path.join(harnessRoot, ...packagePath.split('/'))
  const manifestPath = path.join(packageRoot, 'package.json')

  let manifest
  try {
    manifest = JSON.parse(await fs.readFile(manifestPath, 'utf8'))
  } catch {
    continue
  }

  const identity = `${manifest.name ?? packagePath}@${manifest.version ?? 'unknown'}`
  if (seen.has(identity)) continue
  seen.add(identity)

  const license = typeof manifest.license === 'string'
    ? manifest.license
    : manifest.license?.type ?? 'Not declared'
  const repository = typeof manifest.repository === 'string'
    ? manifest.repository
    : manifest.repository?.url

  const entries = await fs.readdir(packageRoot, { withFileTypes: true })
  const candidate = licenseNames
    .map(name => entries.find(entry => entry.isFile() && entry.name.toLowerCase() === name.toLowerCase()))
    .find(Boolean)

  let licenseText = '[No license file was included in this npm package.]'
  if (candidate) {
    licenseText = (await fs.readFile(path.join(packageRoot, candidate.name), 'utf8')).trim()
  }

  sections.push([
    '-'.repeat(78),
    identity,
    `Declared license: ${license}`,
    repository ? `Repository: ${repository}` : undefined,
    candidate ? `Included file: ${candidate.name}` : undefined,
    '',
    licenseText,
    '',
  ].filter(value => value !== undefined).join('\n'))
}

const header = [
  'THIRD-PARTY LICENSES FOR DEEPSEEK HARNESS DESKTOP',
  '',
  'This file is generated from the npm packages bundled in harness/node_modules.',
  'Package versions are pinned by harness/package-lock.json.',
  `Generated package count: ${sections.length}`,
  '',
].join('\n')

await fs.mkdir(path.dirname(outputPath), { recursive: true })
await fs.writeFile(outputPath, `${header}${sections.join('\n')}\n`, 'utf8')
console.log(`Generated ${path.relative(projectRoot, outputPath)} for ${sections.length} packages.`)
