# Project Type Detection Protocol

## Purpose
Detect project type (game, software, brownfield) to delegate to appropriate workflow module.

## Detection Logic

### Step 1: Check project-sage/config.yaml

```yaml
# project-sage/config.yaml
project_type: "game" | "software" | "brownfield"
```

If `project_type` is set, use that value.

### Step 2: File-based Detection

If `project_type` is not set or ambiguous:

**Game Project Indicators:**
- `project.godot` exists in project root
- `.godot/` directory exists
- `*.tscn` files present

**Software Project Indicators:**
- `package.json` exists (Node.js)
- `Cargo.toml` exists (Rust)
- `pom.xml` exists (Java)
- `requirements.txt` or `pyproject.toml` (Python)
- `go.mod` exists (Go)

**Brownfield Project Indicators:**
- Large existing codebase (>100 files)
- No clear project structure
- Mix of technologies

### Step 3: Interactive Fallback

If detection is ambiguous or fails:

```
Unable to automatically detect project type.

Please select:
1. Game (Godot/Unity/Unreal)
2. Software (Web/CLI/Backend)
3. Brownfield (Existing codebase)

Your choice (1/2/3):
```

## Output

Returns one of:
- `game` → Delegate to `sage/workflows/game/`
- `software` → Delegate to `sage/workflows/software/`
- `brownfield` → Use core workflows with brownfield adaptations

## Usage

```xml
<action>Run project-type-detection protocol</action>
<action>Set {{project_type}} from detection result</action>
```
