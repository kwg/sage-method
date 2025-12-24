# Protocol: Scan Project

**Purpose**: Deep scan a project to infer structure, state, and configuration. Reusable by import, status, and other protocols.

**JIT Loading**: This protocol is loaded on-demand by other protocols, not directly by users.

---

## Scan Phases

Execute scans in order, stopping when confidence is sufficient for the calling protocol's needs.

### Phase 1: Quick Scan (always runs)

Fast checks that don't read file contents:

```
1.1 Git State
    - Is git repo? (git rev-parse --git-dir)
    - Current branch? (git branch --show-current)
    - Has remote? (git remote -v)
    - Uncommitted changes? (git status --porcelain | wc -l)
    - Recent branches (git branch --list | head -10)

1.2 SAGE State
    - project-sage/config.yaml exists?
    - .sage/state/checkpoint.json exists?
    - .sage/ directory exists?

1.3 File Structure (existence only)
    - docs/ or documentation/
    - specs/ or specifications/
    - stories/ or backlog/
    - {sprint_artifacts}/ (from config or default docs/sprint-artifacts/)
    - README.md
    - Package files: package.json, Cargo.toml, pyproject.toml, go.mod, etc.
```

### Phase 2: Structure Scan (if needed)

Deeper file system analysis:

```
2.1 Epic Detection
    - Glob: {sprint_artifacts}/epic-*/
    - For each: check for epic-context.yaml
    - Classify: SAGE_EPIC (has context) or ORPHAN_EPIC (no context)

2.2 Documentation Detection
    - Glob: docs/**/*.md, specs/**/*.md
    - List files with sizes (don't read yet)
    - Look for common patterns: prd.md, architecture.md, api-spec.md

2.3 Story/Task Detection
    - Glob: stories/**/*.md, backlog/**/*.md, {sprint_artifacts}/**/*.md
    - Count files, note naming patterns
```

### Phase 3: Content Scan (if needed)

Read file contents for deeper inference:

```
3.1 Package File Analysis
    - Read package.json → name, description, scripts
    - Read Cargo.toml → name, description
    - Read pyproject.toml → name, description
    - Read go.mod → module name

3.2 README Analysis
    - Read README.md (first 100 lines)
    - Extract project description
    - Look for setup instructions, architecture notes

3.3 Git History Analysis
    - Recent commits (git log --oneline -20)
    - Extract work context from commit messages
    - Identify active development patterns

3.4 Config Analysis
    - Read project-sage/config.yaml if exists
    - Extract: project_name, sprint_artifacts path, user settings
```

### Phase 4: External Scan (if available and needed)

External service integration:

```
4.1 GitHub API (requires: remote detected + gh auth status succeeds)
    - Open issues (gh issue list --state open --limit 20)
    - Open PRs (gh pr list --state open --limit 10)
    - Labels in use
    - Project boards (if accessible)

4.2 CI/CD Detection
    - .github/workflows/*.yml exists?
    - .gitlab-ci.yml exists?
    - Jenkinsfile exists?
```

---

## Output Format

Return structured scan results:

```yaml
scan_results:
  timestamp: "{ISO8601}"
  scan_depth: "{quick|structure|content|external}"

  git:
    is_repo: true|false
    branch: "{branch_name}"
    remote_url: "{url}" | null
    uncommitted_count: {n}
    recent_branches: [...]
    evidence: "git rev-parse, git remote -v"

  sage_state:
    configured: true|false
    has_checkpoint: true|false
    checkpoint_data: {...} | null
    config_path: "{path}" | null
    evidence: "file existence checks"

  project:
    name: "{inferred_name}"
    name_source: "package.json|Cargo.toml|directory|config"
    description: "{inferred_description}" | null
    description_source: "{source}"
    evidence: "{how we determined this}"

  epics:
    sage_epics: [{id, path, status}]
    orphan_epics: [{path}]
    evidence: "glob {sprint_artifacts}/epic-*/"

  documentation:
    locations: [{path, file_count, total_size_kb}]
    notable_files: [{path, size_kb, type_guess}]
    evidence: "glob patterns"

  work_tracking:
    method: "github_issues|local_files|unknown"
    issue_count: {n} | null
    pr_count: {n} | null
    evidence: "{how we determined this}"

  active_work:
    detected: true|false
    description: "{inferred_description}" | null
    phase_guess: "analysis|design|implementation|validation|unknown"
    confidence: "high|medium|low"
    evidence: ["{reason1}", "{reason2}"]

  github:
    available: true|false
    authenticated: true|false
    issues: [{number, title, state}] | null
    prs: [{number, title, state}] | null
```

---

## Confidence Levels

### High Confidence
- Direct evidence (file exists, config value present)
- Multiple corroborating sources

### Medium Confidence
- Single indirect evidence (e.g., branch name suggests feature)
- Pattern matching without content verification

### Low Confidence
- Heuristic guess (e.g., "probably implementation phase because code changed recently")
- No direct evidence, only inference

---

## Usage by Other Protocols

### detect-state.md
Calls scan with: `depth: structure`
Uses: sage_state, epics to determine menu state

### import-project.md
Calls scan with: `depth: content` (or `external` if GitHub available)
Uses: all fields to pre-fill interview

### show-status.md
Calls scan with: `depth: quick`
Uses: git, sage_state, active_work for status display

---

## Error Handling

| Error | Action |
|-------|--------|
| Git not installed | Set git.is_repo = false, continue |
| gh not authenticated | Set github.authenticated = false, skip external scan |
| Permission denied on file | Skip file, note in evidence |
| Timeout on external API | Set available = false, continue |

---

## Performance Notes

- Quick scan should complete in <2 seconds
- Structure scan should complete in <5 seconds
- Content scan should complete in <10 seconds
- External scan may take up to 30 seconds (network dependent)

Stop scanning when sufficient data is gathered for the calling protocol's needs.
