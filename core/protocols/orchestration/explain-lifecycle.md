# Protocol: Explain Lifecycle

**Purpose**: Explain the SAGE lifecycle to the user.

## SAGE Lifecycle Overview

The SAGE (Standard Operating Procedures System) lifecycle consists of these phases:

### 1. Analysis Phase
- **Product Brief** - Initial concept and vision
- **Research** - Market, competitive, technical research
- **Brainstorming** - Ideation and exploration

### 2. Planning Phase
- **PRD** - Product Requirements Document
- **UX Design** - User experience specification
- **Architecture** - Technical architecture document

### 3. Solutioning Phase
- **Epics & Stories** - Break down into implementable units
- **Sprint Planning** - Organize stories into sprints
- **Implementation Readiness** - Validate alignment

### 4. Implementation Phase
- **Story Drafting** - SM prepares developer-ready stories
- **Development** - Dev agent implements with TDD
- **Code Review** - Quality and standards validation
- **Story Completion** - Mark done, update sprint status

### 5. Delivery Phase
- **Epic Retrospective** - Team learnings
- **Documentation** - Final docs and guides
- **Deployment** - Release to production

## Orchestration Modes

1. **Interactive** - User drives each step
2. **Autonomous** - Agent progresses automatically with HitL checkpoints
3. **Hybrid** - Autonomous with user approval gates

## Key Concepts

- **Checkpoints**: Saved state for resumption
- **HitL (Human-in-the-Loop)**: GitHub issues for async decisions
- **Subagents**: Specialized agents spawned for tasks
- **Protocols**: Reusable procedure definitions

## TODO

- [ ] Add visual diagrams
- [ ] Link to detailed phase documentation
