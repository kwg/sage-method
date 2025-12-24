# Context Clearing Workflow Pattern

## Overview

This workflow pattern demonstrates how to intentionally clear context between workflow steps to achieve:

- **Fresh perspective** - Review work without bias from previous discussion
- **Token optimization** - Start new steps with minimal context
- **Independent validation** - Verify decisions without prior assumptions
- **Quality assurance** - Code review in clean context

## How It Works

### Step 1: Normal Context
Execute with full conversation history and context available.

### Step 2: Clear Context (🧹 Fresh Start)
**To execute Step 2 with cleared context:**

1. **User Action Required**: Open a new chat/conversation window or clear context
2. **Agent starts fresh**: No memory of Step 1 conversation
3. **Load only essentials**: Read Step 1 output file explicitly
4. **Execute independently**: Follow clear_instructions without assumptions

### Step 3: Integration
Return to normal context mode, synthesize both perspectives.

## Implementation Methods

### Method 1: New Chat Window (Recommended)
```
Step 1: Execute in current chat → outputs file
Step 2: User opens NEW chat → agent reads Step 1 output → executes fresh
Step 3: Continue in either chat → read both outputs
```

### Method 2: Context Reset Command
```
Step 1: Execute → outputs file
User: "/clear" or equivalent context reset
Step 2: Agent treats as new conversation → reads Step 1 output
Step 3: Continue → synthesize
```

### Method 3: Agent Handoff
```
Step 1: Dev Agent → outputs file
Step 2: Launch Tea Agent (review) → reads Step 1 output → fresh review
Step 3: Original agent → synthesize both perspectives
```

## Workflow YAML Structure

```yaml
steps:
  - id: step-1
    name: "Analysis"
    context_mode: "normal"
    actions:
      - type: "output"
        filename: "{output_folder}/step-1-output.md"
  
  - id: step-2
    name: "Fresh Review"
    context_mode: "clear"  # 🔑 Key setting
    clear_instructions: |
      🧹 CONTEXT CLEARED
      You are starting fresh. Load only:
      - {output_folder}/step-1-output.md
    actions:
      - type: "read"
        files: ["{output_folder}/step-1-output.md"]
      - type: "review"
```

## Use Cases

### 1. Code Review After Implementation
```
Step 1 (dev): Implement feature → commit code
Step 2 (clear): Review code quality without implementation bias
Step 3: Address findings
```

### 2. Independent Validation
```
Step 1: Design architecture → document decisions
Step 2 (clear): Validate design against requirements only
Step 3: Finalize architecture
```

### 3. Token Optimization
```
Step 1: Deep analysis (uses 50k tokens) → summary output
Step 2 (clear): Execute action based on summary (uses 5k tokens)
Step 3: Validate results
```

## Best Practices

### ✅ DO
- Save all critical information to files before clearing context
- Use explicit file paths in clear_instructions
- Document assumptions in output files
- Test that Step 2 has everything needed

### ❌ DON'T
- Assume agent remembers previous steps after context clear
- Reference variables from previous conversation
- Skip writing intermediate outputs
- Use vague instructions after context clear

## Example Execution

**User starts workflow:**
```
User: Execute example-context-clear-workflow.yaml
Agent: [Executes Step 1, saves analysis to file]
Agent: ✅ Step 1 complete. 
       🧹 Step 2 requires context clear.
       Please start a new chat and say: "Execute Step 2 of context-clear-example"
```

**User opens new chat:**
```
User: Execute Step 2 of context-clear-example
New Agent: [Reads Step 1 output file only]
New Agent: [Executes fresh review]
New Agent: ✅ Step 2 complete with clean context
```

**User returns to original chat OR continues:**
```
User: Execute Step 3
Agent: [Reads both Step 1 and Step 2 outputs]
Agent: [Synthesizes final result]
```

## Integration with SAGE Workflows

Add to your agent menu:
```xml
<item cmd="*my-workflow" 
      workflow="{project-root}/sage/workflows/example-context-clear-workflow.yaml">
  Execute workflow with context clearing
</item>
```

The workflow handler will guide the user when context clearing is needed.

## Notes

- Context clearing is **manual** - requires user to start new conversation
- Agents cannot clear their own context programmatically
- Always verify Step 2 has access to required files
- Consider using subagents (runSubagent tool) for true isolation
