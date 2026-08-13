import { promises as fs } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const requiredFiles = [
  '.github/workflows/source-check.yml',
  '.github/workflows/windows-release.yml',
  '.gitignore',
  'LICENSE',
  'README.md',
  'README.en.md',
  'THIRD_PARTY_NOTICES.md',
  'build/deepseek-harness.svg',
  'harness/package-lock.json',
  'harness/package.json',
  'main.js',
  'package-lock.json',
  'package.json',
  'preload.js',
  'scripts/build-windows.ps1',
  'scripts/package-source.ps1',
  'scripts/prepare-runtime.ps1',
  'shell.html',
]

for (const relativePath of requiredFiles) {
  await fs.access(path.join(projectRoot, relativePath))
}

const manifest = JSON.parse(await fs.readFile(path.join(projectRoot, 'package.json'), 'utf8'))
const harnessManifest = JSON.parse(await fs.readFile(path.join(projectRoot, 'harness/package.json'), 'utf8'))

if (manifest.devDependencies?.electron !== '43.4.0') {
  throw new Error('Electron must remain pinned to 43.4.0 for this release.')
}
if (harnessManifest.dependencies?.['@deepseek-ai/dsh'] !== '0.1.0-rc.6') {
  throw new Error('DeepSeek Harness must remain pinned to 0.1.0-rc.6 for this release.')
}

const expectedInstallScripts = {
  '@deepseek-ai/dsh-subprocess-local@0.1.0-rc.6': true,
  '@google/genai@1.52.0': true,
  'koffi@3.1.4': true,
  'node-pty@1.1.0': true,
  'protobufjs@7.6.5': true,
}
if (JSON.stringify(harnessManifest.allowScripts) !== JSON.stringify(expectedInstallScripts)) {
  throw new Error('The audited Harness install-script allowlist has changed.')
}
if (manifest.build?.win?.signExecutable !== false) {
  throw new Error('Unsigned community builds must explicitly set win.signExecutable=false.')
}
if (manifest.build?.nsis?.allowToChangeInstallationDirectory !== false) {
  throw new Error('The installer path must remain fixed to avoid legacy Windows path limits.')
}

const publicFiles = ['main.js', 'preload.js', 'shell.html', 'README.md', 'README.en.md', '.env.example']
for (const relativePath of publicFiles) {
  const content = await fs.readFile(path.join(projectRoot, relativePath), 'utf8')
  if (/C:\\Users\\[^\\]+/i.test(content)) {
    throw new Error(`A user-specific Windows path was found in ${relativePath}.`)
  }
  if (/DEEPSEEK_API_KEY\s*=\s*\S+/i.test(content)) {
    throw new Error(`A populated DEEPSEEK_API_KEY was found in ${relativePath}.`)
  }
}

console.log('Source verification passed.')
