# Phase 02: Plan Story (PLANNER Subagent)

```xml
<phase id="02-plan" name="Plan Story Chunks">

  <purpose>
    Spawn PLANNER subagent to decompose story into small, focused chunks.
    Each chunk is implementable by a stateless subagent with minimal context.
    Software-specific: Include test files in chunk planning for TDD.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_path: path to story file
    - story_branch: current git branch
  </input>

  <preconditions>
    - Story file exists and is readable
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="record-start-time">
      <action>
        metrics_collector:
          action: record_start
          operation: "planner"
          story_id: {{current_story}}
      </action>
    </step>

    <step n="2" name="spawn-planner">
      <output>📋 **Spawning PLANNER Subagent...**</output>

      <action>
        subagent_spawner:
          action: spawn
          subagent_type: "PLANNER"
          context:
            story_path: {{story_path}}
            project_context: "docs/project-context-agent.md"
          output_schema:
            type: "chunk_plan"
      </action>

      <subagent-prompt>
You are a STORY DECOMPOSITION SPECIALIST for a software project. Your job is to break down a story into small, focused implementation chunks with TDD (Test-Driven Development) in mind.

## Story File
Read this file completely: {{story_path}}

## Project Context
Read architecture patterns from: docs/project-context-agent.md (if exists)

## Your Goal
Analyze the story and create an execution plan with SMALL, FOCUSED chunks that:
- Can each be implemented by a stateless subagent with minimal context
- Have clear boundaries (specific tasks, specific files)
- Include TEST FILES for each chunk (TDD approach)
- Respect dependencies (chunk B needs chunk A's output)
- Identify shared patterns that all chunks should follow

## Chunking Guidelines
- Each chunk should create/modify 1-3 source files maximum
- Each chunk should include corresponding test files
- Each chunk should cover 1-5 related tasks
- Group tasks that work on the same file together
- Put foundation work (types, interfaces, utilities) in early chunks
- Put dependent work (services using those utilities) in later chunks
- Consider: "Could a developer implement this chunk in 30 minutes with clear instructions?"

## TDD Requirements
- Every chunk with source code MUST include tests_to_create
- Tests should be written BEFORE implementation (enforced by implementer)
- Test files follow project conventions (e.g., __tests__/, *.test.ts, test_*.py)

## Output Format

Return JSON ONLY (no markdown, no explanation outside the JSON):
```json
{
  "story_summary": "Brief description of what this story delivers",
  "total_tasks": 10,
  "chunks": [
    {
      "id": "chunk-1",
      "name": "Human-readable chunk name",
      "description": "What this chunk accomplishes",
      "tasks": ["1.1", "1.2", "2.1"],
      "task_descriptions": ["Create User interface", "Add validation logic", "Add class_name"],
      "files_to_create": ["src/models/user.ts"],
      "files_to_modify": [],
      "files_to_read": [],
      "tests_to_create": ["src/models/__tests__/user.test.ts"],
      "depends_on": [],
      "estimated_complexity": "small"
    },
    {
      "id": "chunk-2",
      "name": "User service implementation",
      "description": "Create UserService with base structure",
      "tasks": ["3.1", "3.2"],
      "task_descriptions": ["Create service class", "Add CRUD methods"],
      "files_to_create": ["src/services/user-service.ts"],
      "files_to_modify": [],
      "files_to_read": ["src/models/user.ts"],
      "tests_to_create": ["src/services/__tests__/user-service.test.ts"],
      "depends_on": ["chunk-1"],
      "estimated_complexity": "medium"
    }
  ],
  "shared_patterns": [
    "Use interfaces for data contracts",
    "Use dependency injection for services",
    "Follow existing error handling patterns"
  ],
  "execution_order": ["chunk-1", "chunk-2", "chunk-3"],
  "notes": "Any special considerations for implementation"
}
```
      </subagent-prompt>
    </step>

    <step n="3" name="parse-response">
      <action>
        metrics_collector:
          action: record_end
          operation: "planner"
          story_id: {{current_story}}
      </action>

      <action>Parse PLANNER response as JSON</action>

      <check if="response is invalid JSON or missing required fields">
        <output>❌ PLANNER response invalid - creating fallback single chunk</output>
        <action>Create fallback chunk_plan:
          {
            "story_summary": "Fallback: implement entire story",
            "total_tasks": "unknown",
            "chunks": [{
              "id": "chunk-1",
              "name": "Full story implementation",
              "description": "Implement all tasks (fallback mode)",
              "tasks": ["all"],
              "task_descriptions": ["Implement complete story"],
              "files_to_create": [],
              "files_to_modify": [],
              "files_to_read": [],
              "tests_to_create": [],
              "depends_on": [],
              "estimated_complexity": "large"
            }],
            "shared_patterns": [],
            "execution_order": ["chunk-1"],
            "notes": "Fallback due to PLANNER failure"
          }
        </action>
      </check>
    </step>

    <step n="4" name="validate-tdd">
      <action>For each chunk in chunks:
        - Check if files_to_create is non-empty
        - If yes, verify tests_to_create is also non-empty
        - Warn if tests missing (TDD violation)
      </action>

      <check if="any chunk missing tests">
        <output>⚠️ TDD Warning: Some chunks missing test specifications</output>
        <action>Record in tdd_metrics: tests_written_after++</action>
      </check>
    </step>

    <step n="5" name="validate-chunks">
      <check if="chunks array is empty">
        <output>⚠️ PLANNER returned no chunks - story may have structural issues</output>
        <action>Update story metrics: final_status = "failed"</action>
        <action>Add to failed_stories: { story_id, reason: "no_chunks_planned" }</action>
        <action>
          learning_recorder:
            action: record_failure
            failure:
              type: "implementation"
              context:
                phase: "02-plan"
                story_id: {{current_story}}
                error: "PLANNER returned no chunks"
        </action>
        <return>
          {
            "next_phase": "01-story-start",
            "state_updates": {
              "current_story_index": {{current_story_index + 1}},
              "failed_stories": {{updated_failed_stories}},
              "metrics": {{updated_metrics}}
            },
            "output": "PLANNER returned no chunks for {{current_story}}. Skipping."
          }
        </return>
      </check>
    </step>

    <step n="6" name="update-metrics">
      <action>Update current story metrics:
        - chunks_planned = length(chunks)
      </action>
    </step>

  </execution>

  <output>
✅ **PLANNER Complete**

Story: {{current_story}}
Summary: {{chunk_plan.story_summary}}
Chunks: {{chunk_plan.chunks.length}}
Execution order: {{chunk_plan.execution_order | join(" → ")}}

Shared patterns:
{{for pattern in chunk_plan.shared_patterns}}
- {{pattern}}
{{endfor}}

TDD Status: {{tdd_status}}

Proceeding to implementation...
  </output>

  <return>
    {
      "next_phase": "03-implement",
      "state_updates": {
        "chunk_plan": {{chunk_plan}},
        "chunk_queue": {{chunk_plan.execution_order}},
        "current_chunk_index": 0,
        "completed_chunks": [],
        "failed_chunks": [],
        "chunk_retry_count": 0,
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
