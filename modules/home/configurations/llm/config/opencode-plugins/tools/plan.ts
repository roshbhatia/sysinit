// Tool: plan - Create OpenSpec PRD for a feature
// Usage: plan <feature-name>
// Example: plan user-authentication

import { tool } from "@opencode-ai/plugin"
import { join } from "path"

export default tool({
  description: "Create OpenSpec PRD for a feature (initializes beads/openspec if needed). Usage: plan <feature-name>",
  args: {
    featureName: tool.schema.string().describe("Name of the feature to plan (e.g., 'user-authentication')")
  },
  async execute(args, context) {
    const { $, worktree, client } = context
    const { featureName } = args
    
    // Path to shell script (same directory as this tool)
    const scriptPath = join(worktree, ".opencode", "tools", "plan.sh")
    
    try {
      // Execute shell script
      const result = await $`bash ${scriptPath} ${featureName} ${worktree}`.text()
      
      // Extract spec path from output (last line)
      const lines = result.trim().split('\n')
      const specPath = lines[lines.length - 1]
      
      if (!specPath || !specPath.includes('.openspec')) {
        throw new Error("Failed to create PRD: " + result)
      }
      
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
})
