// SysinitSpec Plugin for OpenCode
// Provides bidirectional sync between OpenCode todos and beads tasks
// Auto-detects planning intent and generates OpenSpec PRDs

import { watch } from "fs"
import { readFile } from "fs/promises"
import { join } from "path"

// Track last sync timestamps for conflict resolution
const lastSync = new Map()

// Planning detection patterns
const planningPatterns = [
  /(?:add|implement|create|build|design)\s+(?:a|an|the)?\s+(\w+(?:\s+\w+){0,5})/i,
  /(?:support|enable)\s+(?:a|an|the)?\s+(\w+(?:\s+\w+){0,5})/i,
  /(?:we|I)\s+(?:need|should|want)\s+(?:a|an|the)?\s+(\w+(?:\s+\w+){0,5})/i,
]

// Check if message contains planning intent
function detectPlanningIntent(message) {
  for (const pattern of planningPatterns) {
    const match = message.match(pattern)
    if (match) {
      return match[1].toLowerCase().replace(/\s+/g, '-')
    }
  }
  return null
}

// Extract feature name from message
function extractFeatureName(message) {
  // Remove common prefixes and clean up
  return message
    .replace(/^(?:let's|we should|I want to|we need to)\s+/i, '')
    .replace(/^(?:add|implement|create|build|design)\s+/i, '')
    .replace(/^(?:a|an|the)\s+/i, '')
    .replace(/[^\w\s-]/g, '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '-')
    .substring(0, 50)
}

// Sync OpenCode todo to beads task
async function syncTodoToBeads(todo, $) {
  const externalRef = `opencode-todo:${todo.id}`

  try {
    // Check if beads task already exists
    const searchResult = await $`bd list --json 2>/dev/null | grep ${externalRef} || echo ""`.text()

    if (searchResult.trim()) {
      // Task exists, update if needed
      const existing = JSON.parse(searchResult)
      const taskId = existing.id

      if (todo.completed && existing.status !== 'closed') {
        await $`bd close ${taskId}`
        console.log(`Closed beads task ${taskId} (todo completed)`)
      } else if (!todo.completed && existing.status === 'closed') {
        await $`bd reopen ${taskId}`
        console.log(`Reopened beads task ${taskId} (todo reopened)`)
      }
    } else {
      // Create new beads task
      const taskTitle = todo.text || todo.title || 'Untitled task'
      const result = await $`bd create ${taskTitle} --external-ref ${externalRef} --type task`.text()
      console.log(`Created beads task: ${result}`)
    }

    lastSync.set(todo.id, Date.now())
  } catch (error) {
    console.error('Failed to sync todo to beads:', error)
  }
}

// Sync beads task to OpenCode todo
async function syncBeadsToOpenCode(task, client) {
  const match = task.externalRef?.match(/opencode-todo:(.+)/)
  if (!match) return

  const todoId = match[1]
  const taskModified = new Date(task.updatedAt || task.createdAt).getTime()
  const lastSynced = lastSync.get(todoId) || 0

  // Conflict resolution: last-write-wins
  if (taskModified < lastSynced) {
    return // Skip, OpenCode version is newer
  }

  try {
    // Update OpenCode todo via SDK
    await client.todo.update({
      id: todoId,
      text: task.title,
      completed: task.status === 'closed'
    })

    lastSync.set(todoId, Date.now())
    console.log(`Synced beads task to OpenCode todo: ${task.title}`)
  } catch (error) {
    console.error('Failed to sync beads to OpenCode:', error)
  }
}

// Watch beads database for changes
async function watchBeadsDatabase($, client, worktree) {
  const beadsDir = join(worktree, '.beads')

  // Check if beads directory exists before watching
  try {
    const fs = await import('fs')
    if (!fs.existsSync(beadsDir)) {
      console.log('Beads not initialized - skipping watcher')
      return null
    }
  } catch (error) {
    console.error('Failed to check beads directory:', error)
    return null
  }

  try {
    const watcher = watch(beadsDir, { recursive: true }, async (eventType, filename) => {
      if (filename?.endsWith('.jsonl')) {
        // Debounce: wait 500ms for batch changes
        await new Promise(resolve => setTimeout(resolve, 500))

        try {
          // Read latest tasks
          const result = await $`bd list --json 2>/dev/null || echo "[]"`.text()
          const tasks = JSON.parse(result)

          // Sync each task with external-ref
          for (const task of tasks) {
            if (task.externalRef?.startsWith('opencode-todo:')) {
              await syncBeadsToOpenCode(task, client)
            }
          }
        } catch (error) {
          console.error('Failed to watch beads database:', error)
        }
      }
    })

    console.log('Watching beads database for changes...')
    return watcher
  } catch (error) {
    console.error('Failed to setup beads watcher:', error)
    return null
  }
}

// Main plugin export
export default async function SysinitSpecPlugin({ client, $, worktree, directory }) {
  // Setup bidirectional sync
  const beadsWatcher = await watchBeadsDatabase($, client, worktree)

  return {
    // Auto-detect planning intent and create OpenSpec PRD
    "message.updated": async ({ message }) => {
      if (!message.text || message.role !== 'user') return

      const featureName = detectPlanningIntent(message.text)
      if (!featureName) return

      // Check if spec already exists
      const specPath = join(worktree, '.openspec', 'features', featureName, 'spec.md')
      try {
        await readFile(specPath)
        // Spec exists, skip
        return
      } catch {
        // Spec doesn't exist, create it
      }

      // Create OpenSpec feature
      try {
        await $`openspec create-feature ${featureName} --template standard`.quiet()
        console.log(`Created OpenSpec feature: ${featureName}`)

        // Open spec for user review
        await client.editor.openFile({
          filePath: specPath,
          create: true
        })

        // Notify user
        await client.app.notify({
          title: 'SysinitSpec',
          message: `Created PRD for "${extractFeatureName(message.text)}". Review and save to proceed.`
        })
      } catch (error) {
        console.error('Failed to create OpenSpec feature:', error)
      }
    },

    // Sync OpenCode todo changes to beads
    "todo.updated": async ({ todo }) => {
      if (!todo) return

      // Prevent loops
      const lastBeadsSync = lastSync.get(todo.id)
      if (lastBeadsSync && Date.now() - lastBeadsSync < 1000) {
        return
      }

      await syncTodoToBeads(todo, $)
    },

    "todo.created": async ({ todo }) => {
      if (!todo) return
      await syncTodoToBeads(todo, $)
    },

    "todo.deleted": async ({ todo }) => {
      if (!todo) return

      const externalRef = `opencode-todo:${todo.id}`
      try {
        // Soft delete: close beads task
        const result = await $`bd list --json 2>/dev/null | grep ${externalRef} || echo ""`.text()
        if (result.trim()) {
          const task = JSON.parse(result)
          await $`bd close ${task.id}`
          console.log(`Closed beads task ${task.id} (todo deleted)`)
        }
      } catch (error) {
        console.error('Failed to close beads task:', error)
      }
    },

    // Gentle scope reminders based on current beads task
    "tool.execute.before": async (input, output) => {
      if (input.tool !== 'Edit' && input.tool !== 'Write') return

      const filePath = input.tool_input?.filePath || input.tool_input?.path
      if (!filePath) return

      try {
        // Get current beads task
        const result = await $`bd ready --json 2>/dev/null || echo "[]"`.text()
        const tasks = JSON.parse(result)

        if (tasks.length === 0) return

        const currentTask = tasks[0]
        const taskId = currentTask.id

        // Check if we've already reminded about this file
        const remindedKey = `${taskId}:${filePath}`
        if (lastSync.get(remindedKey)) return

        // Get task scope from description or labels
        const scopeLabels = currentTask.labels?.filter(l => l.startsWith('scope:')) || []

        // Check if file is in scope
        const isInScope = scopeLabels.some(label => {
          const scopeName = label.replace('scope:', '')
          return filePath.includes(scopeName)
        })

        if (!isInScope && scopeLabels.length > 0) {
          // Show gentle reminder (non-blocking)
          await client.app.notify({
            title: 'Scope Reminder',
            message: `Current task: ${currentTask.title}. You're editing ${filePath} (outside scope: ${scopeLabels.join(', ')}).`
          })

          // Mark as reminded (don't spam)
          lastSync.set(remindedKey, Date.now())
        }
      } catch (error) {
        // Silent fail - don't block user workflow
        console.error('Scope check failed:', error)
      }
    },

    // Cleanup on plugin unload
    "plugin.unload": () => {
      if (beadsWatcher) {
        beadsWatcher.close()
      }
    },

    // Tools
    tool: {
      // /plan - Create OpenSpec PRD
      plan: async (args, context) => {
        const featureName = args?.featureName || args?.[0]
        
        if (!featureName) {
          return "Usage: /plan <feature-name>\nExample: /plan user-authentication"
        }
        
        try {
          // Check if beads is initialized, init if not
          const fs = await import('fs')
          const path = await import('path')
          const beadsDir = path.join(worktree, '.beads')
          
          if (!fs.existsSync(beadsDir)) {
            console.log('Beads not initialized, running bd init...')
            await $`bd init`.quiet()
            await client.app.notify({
              title: 'SysinitSpec',
              message: 'Beads initialized for this project'
            })
          }
          
          // Create OpenSpec feature
          await $`openspec create-feature ${featureName} --template standard`.quiet()
          
          const specPath = path.join(worktree, '.openspec', 'features', featureName, 'spec.md')
          
          // Open spec for user review
          await client.editor.openFile({
            filePath: specPath,
            create: true
          })
          
          await client.app.notify({
            title: 'SysinitSpec',
            message: `Created PRD for "${featureName}". Review and save to proceed.`
          })
          
          return `Created PRD at ${specPath}`
        } catch (error) {
          console.error('Failed to create PRD:', error)
          throw new Error(`Failed to create PRD: ${error.message}`)
        }
      }
    }
  }
}
