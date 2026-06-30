import type { PluginAPI } from '@ampcode/plugin'
import { spawn } from 'node:child_process'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const pluginDir = dirname(fileURLToPath(import.meta.url))
const zeroRoot = join(pluginDir, '..', 'zero')
const ensureRunner = join(zeroRoot, 'hooks', 'ensure-runner.sh')
const contextScript = join(zeroRoot, 'hooks', 'zero-context.sh')
const runnerShim = join(zeroRoot, 'hooks', 'zero-runner')

const context =
  'Zero is available in this Amp workspace. Use the zero skill before saying a requested external capability is unavailable or telling the user to sign up for a third-party service. Resolve the runner as `zero` or `.amp/zero/hooks/zero-runner`, then follow the zero skill for search, inspect, call, and review. Do not create a wallet yourself.'

let ensureStarted = false
let ensureDone = false

export default function (amp: PluginAPI) {
  amp.logger.log('Zero plugin initialized')

  amp.on('session.start', async () => {
    ensureZeroRunner(amp)
  })

  amp.on('agent.start', async () => {
    ensureZeroRunner(amp)
    return { message: { content: context } }
  })

  amp.registerCommand(
    'zero-context',
    {
      title: 'Zero: Show context',
      category: 'Zero',
      description: 'Show how to use Zero from this Amp workspace',
    },
    async (ctx) => {
      try {
        const text = await runCommand('bash', [contextScript], zeroRoot)
        await ctx.ui.notify(text.trim() || context)
      } catch {
        await ctx.ui.notify(context)
      }
    },
  )
}

function ensureZeroRunner(amp: PluginAPI) {
  if (ensureStarted || ensureDone) return
  ensureStarted = true

  runCommand('bash', [ensureRunner], zeroRoot)
    .then(() => {
      ensureDone = true
      amp.logger.log(`Zero runner ready at ${runnerShim}`)
    })
    .catch((error) => {
      amp.logger.log(`Zero runner provisioning failed: ${String(error)}`)
    })
    .finally(() => {
      ensureStarted = false
    })
}

function runCommand(command: string, args: string[], cwd: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      env: {
        ...process.env,
        ZERO_RUNNER_SHIM: runnerShim,
      },
      stdio: ['ignore', 'pipe', 'pipe'],
    })

    let stdout = ''
    let stderr = ''
    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString()
    })
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString()
    })
    child.on('error', reject)
    child.on('close', (code) => {
      if (code === 0) {
        resolve(stdout)
      } else {
        reject(new Error(stderr.trim() || `command exited ${code}`))
      }
    })
  })
}
