# Protocol: Import Project

**Purpose**: Adopt an existing (brownfield) project into SAGE management through a thorough, evidence-based interview process.

**Critical**: This process must be careful and accurate. Importing incorrectly creates problems that are difficult to undo.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Import Flow                                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: Deep Scan                                          │
│    - Run scan-project.md with depth: content/external       │
│    - Gather all available evidence                          │
│    - Show progress to user                                  │
│                                                             │
│  Step 2: Present Findings                                   │
│    - Show pre-filled interview with evidence                │
│    - User confirms or corrects each inference               │
│    - Offer batch confirm for obvious items                  │
│                                                             │
│  Step 3: Summary & Confirmation                             │
│    - Show what SAGE will do                                 │
│    - Explicit confirmation required                         │
│                                                             │
│  Step 4: Execute Import                                     │
│    - Create necessary files                                 │
│    - Initialize checkpoint                                  │
│    - Do NOT modify existing project files                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Deep Scan

### Display Progress

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Scanning Project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 [✓] Git repository state
 [✓] SAGE configuration
 [✓] File structure
 [✓] Package files
 [ ] Documentation...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Execute Scan

Load `scan-project.md` with depth based on availability:
- If `gh auth status` succeeds AND remote detected: depth = `external`
- Otherwise: depth = `content`

Store results in `scan_results` for use in interview.

---

## Step 2: Present Findings (Interview)

### Header

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Project Import - Review Findings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 Please confirm or correct each item. Items marked [inferred]
 were detected automatically. Items marked [?] need your input.

 Tip: If all inferences look correct, you can type 'confirm all'
 to accept them and only answer the [?] items.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Section 1: Project Basics

```
 SECTION 1: Project Basics
 ─────────────────────────

 1.1 Project name
     {{IF scan_results.project.name}}
     [inferred] {{scan_results.project.name}}
     Source: {{scan_results.project.name_source}}
     {{ELSE}}
     [?] Could not determine - please enter project name:
     {{ENDIF}}
     ───
     Correct? [Y/n] or enter new value: _____

 1.2 Description
     {{IF scan_results.project.description}}
     [inferred] "{{scan_results.project.description}}"
     Source: {{scan_results.project.description_source}}
     {{ELSE}}
     [?] No description found
     {{ENDIF}}
     ───
     Correct? [Y/n] or enter description: _____

 1.3 Git repository
     {{IF scan_results.git.is_repo}}
     [inferred] Yes
     {{IF scan_results.git.remote_url}}
     Remote: {{scan_results.git.remote_url}}
     {{ELSE}}
     Remote: None configured
     {{ENDIF}}
     Branch: {{scan_results.git.branch}}
     {{ELSE}}
     [inferred] Not a git repository
     {{ENDIF}}
     ───
     Correct? [Y]
```

### Section 2: Current Work State

```
 SECTION 2: Current Work State
 ─────────────────────────────

 2.1 Active work in progress?
     {{IF scan_results.active_work.detected}}
     [inferred] Yes
     Evidence:
     {{FOR evidence IN scan_results.active_work.evidence}}
       - {{evidence}}
     {{ENDFOR}}
     {{ELSE}}
     [inferred] No active work detected
     Evidence: No uncommitted changes, no recent feature branches
     {{ENDIF}}
     ───
     Correct? [Y/n]

 2.2 What's being worked on?
     {{IF scan_results.active_work.description}}
     [inferred] "{{scan_results.active_work.description}}"
     Source: Branch name / recent commits
     {{ELSE}}
     [?] Could not determine - please describe current work:
     {{ENDIF}}
     ───
     Correct? [Y/n] or describe: _____

 2.3 Current phase?
     {{IF scan_results.active_work.phase_guess != "unknown"}}
     [inferred] {{scan_results.active_work.phase_guess}}
     Confidence: {{scan_results.active_work.confidence}}
     Evidence: {{scan_results.active_work.evidence[0]}}
     {{ELSE}}
     [?] Could not determine phase
     {{ENDIF}}
     ───
     Correct? [Y/n] or select:
     [A] Analysis  [D] Design  [I] Implementation  [V] Validation
```

### Section 3: Work Tracking

```
 SECTION 3: Work Tracking
 ────────────────────────

 3.1 How are tasks tracked?
     {{IF scan_results.work_tracking.method == "github_issues"}}
     [inferred] GitHub Issues
     Evidence: {{scan_results.work_tracking.issue_count}} open issues found
     {{ELSEIF scan_results.work_tracking.method == "local_files"}}
     [inferred] Local files
     Evidence: Story/task files found in {{location}}
     {{ELSE}}
     [?] Could not determine tracking method
     {{ENDIF}}
     ───
     Correct? [Y/n] or select:
     [G] GitHub Issues  [F] Local files  [E] External tool  [N] None/informal

 3.2 Documentation location?
     {{IF scan_results.documentation.locations.length > 0}}
     [inferred] {{scan_results.documentation.locations[0].path}}
     Found: {{scan_results.documentation.locations[0].file_count}} files
     {{ELSE}}
     [?] No documentation directory detected
     {{ENDIF}}
     ───
     Correct? [Y/n] or enter path: _____

 3.3 Existing specs/PRDs?
     {{IF scan_results.documentation.notable_files.length > 0}}
     [inferred] Yes - {{scan_results.documentation.notable_files.length}} files detected:
     {{FOR file IN scan_results.documentation.notable_files LIMIT 5}}
       - {{file.path}} ({{file.size_kb}}KB)
     {{ENDFOR}}
     {{ELSE}}
     [inferred] None detected
     {{ENDIF}}
     ───
     Correct? [Y/n] or add paths: _____
```

### Section 4: What You Need

```
 SECTION 4: What You Need
 ────────────────────────

 4.1 What should SAGE help with first?
     [?] Please select:

     [1] Continue implementing current work
         → Creates checkpoint at current state, ready to run

     [2] Create stories from existing specs
         → Spawns SM to decompose your docs into stories

     [3] Plan the next piece of work
         → Starts new epic flow with analysis phase

     [4] Just establish checkpoint for future use
         → Minimal setup, no immediate action

     Select: _____
```

### Navigation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 [C] Continue to summary
 [R] Rescan project
 [X] Cancel import

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 3: Summary & Confirmation

### Display Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Import Summary - Please Confirm
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 Project: {{confirmed.project_name}}
 {{IF confirmed.git_remote}}
 Git: {{confirmed.git_remote}}
 {{ELSE}}
 Git: Local repository (no remote)
 {{ENDIF}}

 Current State:
   Active work: {{confirmed.active_work ? "Yes" : "No"}}
   {{IF confirmed.work_description}}
   Description: "{{confirmed.work_description}}"
   {{ENDIF}}
   Phase: {{confirmed.phase}}
   Tracking: {{confirmed.tracking_method}}

 {{IF confirmed.docs_location}}
 Documentation: {{confirmed.docs_location}}
 {{ENDIF}}

 SAGE Will:
   {{IF !sage_config_exists}}
   1. Create project-sage/config.yaml
   {{ENDIF}}
   {{IF !sage_dir_exists}}
   2. Create .sage/ directory structure
   {{ENDIF}}
   3. Create initial checkpoint
   {{IF confirmed.first_action == "continue"}}
   4. Prepare to continue implementation
   {{ELSEIF confirmed.first_action == "create_stories"}}
   4. Queue SM agent for story creation
   {{ELSEIF confirmed.first_action == "plan"}}
   4. Queue analysis phase for new epic
   {{ELSE}}
   4. No immediate action (ready for manual control)
   {{ENDIF}}

 Will NOT modify:
   - Any existing project files
   - Git history or branches
   - External systems (GitHub, etc.)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 Is this correct?
 [Y] Yes, proceed with import
 [E] Edit answers
 [X] Cancel

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 4: Execute Import

### 4.1 Create Configuration (if needed)

If `project-sage/config.yaml` does not exist:

```yaml
# Project SAGE Configuration
# Generated by SAGE import on {{date}}

# User Configuration
user_name: "{{confirmed.user_name || "User"}}"
communication_language: "English"

# Project Configuration
project_name: "{{confirmed.project_name}}"
project_root: "{{cwd}}"
output_folder: "{{confirmed.docs_location || "docs"}}"
sprint_artifacts: "{{confirmed.docs_location || "docs"}}/sprint-artifacts"

# Development Configuration
default_branch: "{{scan_results.git.branch || "main"}}"
feature_branch_pattern: "feature/{story-key}"

# Import metadata
imported: true
import_date: "{{date}}"
import_source: "brownfield"
```

### 4.2 Create SAGE Directory

```bash
mkdir -p .sage/state/
mkdir -p .sage/logs/
```

### 4.3 Create Initial Checkpoint

```json
{
  "version": "1.0",
  "created": "{{ISO8601}}",
  "imported": true,
  "import_context": {
    "source": "brownfield_import",
    "work_description": "{{confirmed.work_description}}",
    "phase_at_import": "{{confirmed.phase}}",
    "tracking_method": "{{confirmed.tracking_method}}"
  },
  "current_state": {
    "phase": "{{confirmed.phase}}",
    "status": "ready",
    "commit_hash": "{{git_head_hash}}"
  },
  "next_action": "{{confirmed.first_action}}"
}
```

### 4.4 Completion Message

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Import Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 {{confirmed.project_name}} is now SAGE-managed.

 Created:
   {{IF created_config}}✓ project-sage/config.yaml{{ENDIF}}
   ✓ .sage/state/checkpoint.json

 Next: {{next_action_description}}

 Run '*status' to see your project state, or select from the menu.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Handling

| Error | Action |
|-------|--------|
| Cannot write to project-sage/ | Ask user to create directory or check permissions |
| Cannot write to .sage/ | Ask user to check permissions |
| Git state unclear | Warn user, proceed with caution flag in checkpoint |
| User cancels | Clean exit, no files created |

---

## Rollback

If import fails partway through:
1. Delete any files created during import
2. Report what was cleaned up
3. Return to menu

Files that may need cleanup:
- `project-sage/config.yaml` (if created)
- `.sage/` directory (if created)
