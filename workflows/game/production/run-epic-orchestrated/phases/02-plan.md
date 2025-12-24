# Phase 02: Plan Story (PLANNER Subagent)

```xml
<phase id="02-plan" name="Plan Story Chunks">

  <purpose>
    Spawn PLANNER subagent to decompose story into small, focused chunks.
    Each chunk is implementable by a stateless subagent with minimal context.
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
      <action>Set planner_start_time = current timestamp (ms)</action>
    </step>

    <step n="2" name="spawn-planner">
      <output>📋 **Spawning PLANNER Subagent...**</output>

      <action>Use Task tool with subagent_type="general-purpose"</action>

      <subagent-prompt>
You are a STORY DECOMPOSITION SPECIALIST. Your job is to break down a story into small, focused implementation chunks.

## Story File
Read this file completely: {{story_path}}

## Project Context
Read architecture patterns from: docs/project-context-agent.md (if exists)

## Your Goal
Analyze the story and create an execution plan with SMALL, FOCUSED chunks that:
- Can each be implemented by a stateless subagent with minimal context
- Have clear boundaries (specific tasks, specific files)
- Respect dependencies (chunk B needs chunk A's output)
- Identify shared patterns that all chunks should follow

## Chunking Guidelines
- Each chunk should create/modify 1-3 files maximum
- Each chunk should cover 1-5 related tasks
- Group tasks that work on the same file together
- Put foundation work (resources, types, constants) in early chunks
- Put dependent work (systems using those resources) in later chunks
- Consider: "Could a developer implement this chunk in 30 minutes with clear instructions?"

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
      "task_descriptions": ["Create MathProblem resource", "Add MathType enum", "Add class_name"],
      "files_to_create": ["resources/math_problem.gd"],
      "files_to_modify": [],
      "files_to_read": [],
      "depends_on": [],
      "estimated_complexity": "small"
    },
    {
      "id": "chunk-2",
      "name": "Generator core implementation",
      "description": "Create MathProblemGenerator with base structure",
      "tasks": ["3.1", "3.2"],
      "task_descriptions": ["Create generator class", "Add static generate method"],
      "files_to_create": ["systems/math/math_problem_generator.gd"],
      "files_to_modify": [],
      "files_to_read": ["resources/math_problem.gd"],
      "depends_on": ["chunk-1"],
      "estimated_complexity": "medium"
    }
  ],
  "shared_patterns": [
    "Use static methods for stateless utilities",
    "Extend Resource for data classes",
    "Use class_name for all new classes"
  ],
  "execution_order": ["chunk-1", "chunk-2", "chunk-3"],
  "notes": "Any special considerations for implementation"
}
```
      </subagent-prompt>
    </step>

    <step n="3" name="parse-response">
      <action>Record planner_end_time = current timestamp (ms)</action>
      <action>Calculate planner_duration_ms = planner_end_time - planner_start_time</action>

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

    <step n="4" name="validate-chunks">
      <check if="chunks array is empty">
        <output>⚠️ PLANNER returned no chunks - story may have structural issues</output>
        <action>Update story metrics: final_status = "failed"</action>
        <action>Add to failed_stories: { story_id, reason: "no_chunks_planned" }</action>
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

    <step n="5" name="update-metrics">
      <action>Update current story metrics:
        - planner_duration_ms = {{planner_duration_ms}}
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

Proceeding to implementation...
  </output>

  <return>
    {
      "next_phase": "03-implement-chunk",
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
