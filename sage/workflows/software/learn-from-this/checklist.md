# Learn From This - Validation Checklist

Use this checklist when executing the Learn From This workflow to ensure thorough problem capture and prevention implementation.

## Problem Identification
- [ ] **Problem Clearly Defined**: Can state the problem in one clear sentence
- [ ] **Problem Actually Occurred**: Evidence exists in conversation/logs/files
- [ ] **Problem is Repeatable**: Could happen again under similar conditions
- [ ] **Problem Worth Preventing**: Impact justifies the effort to prevent

## Solution Verification
- [ ] **Solution Confirmed Working**: Problem was actually resolved, not just papered over
- [ ] **Solution is Specific**: Clear steps or changes that fixed the problem
- [ ] **Solution is Applicable**: Can be codified into instructions/checks
- [ ] **Solution Doesn't Create New Problems**: No negative side effects identified

## Root Cause Analysis
- [ ] **Root Cause Identified**: Know WHY the problem occurred, not just what happened
- [ ] **Root Cause Category Assigned**: Matches one of the defined categories
- [ ] **Trigger Conditions Known**: Understand what circumstances lead to the problem
- [ ] **Scope Understood**: Know if this affects one agent or multiple

## Prevention Strategy
- [ ] **Prevention is Proactive**: Catches problem before it occurs, not just after
- [ ] **Prevention is Specific**: Clear trigger conditions for when to apply
- [ ] **Prevention is Minimal**: Doesn't over-constrain or add unnecessary complexity
- [ ] **Prevention is Testable**: Can verify whether it's working

## File Modification Planning
- [ ] **Target Files Identified**: Know exactly which files need changes
- [ ] **Insertion Points Located**: Know where in each file to add content
- [ ] **Modification Type Clear**: Addition, replacement, or new section
- [ ] **Related Files Considered**: Other files that might need similar changes

## Modification Quality
- [ ] **Instructions are Clear**: Agent will understand what to do differently
- [ ] **Instructions are Actionable**: Specific enough to execute
- [ ] **Instructions are Contextual**: Include when/why to apply them
- [ ] **Instructions Preserve Intent**: Don't conflict with existing guidance

## Agent File Changes (if applicable)
- [ ] **Activation Steps Updated**: If problem occurs during startup/initialization
- [ ] **Rules Section Updated**: If problem is a general behavior issue
- [ ] **Handler Logic Updated**: If problem occurs during workflow execution
- [ ] **Menu Updated**: If new workflow or option is needed
- [ ] **Comments Added**: Explain why the change prevents the problem

## SOP/Workflow Changes (if applicable)
- [ ] **Step Added/Modified**: Clear integration with existing flow
- [ ] **Validation Added**: Check prevents problem before continuing
- [ ] **Critical Section Updated**: If showstopper issue
- [ ] **Checklist Updated**: If new validation point needed
- [ ] **Error Handling Added**: If problem requires specific handling

## Learning Record
- [ ] **Problem Well Documented**: Future readers will understand what happened
- [ ] **Solution Well Documented**: Clear explanation of what fixed it
- [ ] **Changes Well Documented**: List of all modifications made
- [ ] **Verification Steps Included**: How to test if learning is working
- [ ] **Context Preserved**: Enough detail to understand why decisions were made

## Implementation Verification
- [ ] **All Files Modified Successfully**: No failed replacements
- [ ] **Syntax Preserved**: No XML/YAML/Markdown syntax broken
- [ ] **Context Maintained**: Changes don't disrupt surrounding content
- [ ] **File Structure Intact**: Overall document organization preserved

## Commit Readiness
- [ ] **Changes Reviewed**: User has approved all modifications
- [ ] **Commit Message Clear**: Explains what was learned and changed
- [ ] **Related Files Included**: All modified files staged for commit
- [ ] **Learning Record Saved**: Output file created and referenced

## Post-Implementation
- [ ] **User Understands Changes**: Can explain what was modified and why
- [ ] **Verification Plan Exists**: Know how to test if learning prevents recurrence
- [ ] **Future Considerations Noted**: Edge cases or related areas documented
- [ ] **Success Criteria Defined**: Clear on what "working" means

## Quality Gates

### HALT if:
- Problem cannot be clearly defined or verified
- Solution didn't actually fix the problem
- Root cause is unknown or purely speculative
- Prevention strategy would break existing functionality
- File modifications would create conflicts or errors
- User does not approve the approach

### WARN if:
- Problem seems too minor to warrant file changes
- Solution is overly complex or hard to maintain
- Changes affect multiple agents in different ways
- Modification requires changes to core SAGE files
- Similar learning might already exist

## Notes for Agent
- Focus on PREVENTION not optimization
- Keep changes minimal and targeted
- Preserve existing functionality and flow
- Document reasoning clearly
- When in doubt, ask the user
- Better to under-fix than over-fix
