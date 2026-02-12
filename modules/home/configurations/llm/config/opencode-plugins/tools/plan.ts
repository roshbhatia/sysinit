// Tool: /plan - Create OpenSpec PRD (initializes beads and openspec if needed)
// Simple version without Zod schema - args passed directly

export default async function plan(args, context) {
  const { $, worktree } = context
  
  // Handle both object args and positional args
  const featureName = typeof args === 'object' ? args.featureName : args
  
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
      await context.client.app.notify({
        title: 'SysinitSpec',
        message: 'Beads initialized for this project'
      })
    }
    
    // Create OpenSpec feature
    await $`openspec create-feature ${featureName} --template standard`.quiet()
    
    const specPath = path.join(worktree, '.openspec', 'features', featureName, 'spec.md')
    
    // Open spec for user review
    await context.client.editor.openFile({
      filePath: specPath,
      create: true
    })
    
    await context.client.app.notify({
      title: 'SysinitSpec',
      message: `Created PRD for "${featureName}". Review and save to proceed.`
    })
    
    return `Created PRD at ${specPath}`
  } catch (error) {
    console.error('Failed to create PRD:', error)
    throw new Error(`Failed to create PRD: ${error.message}`)
  }
}
