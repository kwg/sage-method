# Learn From This - Self-Improvement Instructions

<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {project-root}/sage/workflows/software/learn-from-this/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>

<critical>PURPOSE: This workflow helps agents learn from mistakes by capturing PROBLEM-SOLUTION pairs and modifying agent files and SOPs to prevent repetition. Focus on PREVENTION, not optimization.</critical>

<workflow>

<step n="1" goal="Identify Problem and Solution">
  <action>Check if user provided explicit text input with the LearnFromThis trigger</action>
  
  <check if="user provided text input">
    <action>User text is treated as pointing to the SOLUTION</action>
    <action>Review recent conversation history to identify the PROBLEM that led to this solution</action>
    <ask>I see you've identified a solution. Can you confirm what PROBLEM this addresses? Or should I analyze recent conversation to identify it?</ask>
    <action>Wait for user confirmation or clarification</action>
  </check>
  
  <check if="no text input provided">
    <action>Analyze recent conversation history (last 10-20 exchanges) for PROBLEM-SOLUTION pattern</action>
    <action>Look for indicators:</action>
      - Error messages or failures that were then resolved
      - User corrections or clarifications that fixed misunderstandings
      - Repeated attempts that finally succeeded
      - Explicit statements like "that worked" or "problem solved"
    
    <action if="PROBLEM-SOLUTION found">
      <action>Present identified PROBLEM and SOLUTION to user</action>
      <ask>I identified this learning opportunity:
      
      PROBLEM: [describe the issue that occurred]
      SOLUTION: [describe what fixed it]
      
      Is this correct? [y/n/clarify]</ask>
      <action>Wait for user confirmation</action>
    </action>
    
    <action if="no PROBLEM-SOLUTION found">
      <ask>I couldn't identify a recent PROBLEM-SOLUTION pair in our conversation. Can you describe:
      1. What PROBLEM occurred?
      2. What SOLUTION worked?</ask>
      <action>Wait for user input</action>
    </action>
  </check>
  
  <action>Once confirmed, document:
    - PROBLEM: Clear description of what went wrong
    - SOLUTION: Specific approach that resolved it
    - CONTEXT: When/where this occurred (which agent, which workflow, which task)
    - TRIGGER: What conditions led to the problem</action>

<action if="user declines or says no problem exists">HALT: "No learning recorded. Ready for next task."</action>
</step>

<step n="2" goal="Analyze Root Cause and Prevention Strategy">
  <action>Determine root cause category:</action>
    - **Instruction Gap**: Agent/workflow instructions were unclear or missing
    - **Validation Missing**: No check existed to catch the error before it occurred
    - **Assumption Error**: Agent made incorrect assumptions due to ambiguous guidance
    - **Tool Misuse**: Incorrect tool usage or missing tool-use guidance
    - **Context Loss**: Agent didn't maintain or retrieve critical context
    - **Sequencing Error**: Steps executed in wrong order or prerequisites skipped
    - **Communication Failure**: Agent didn't ask for clarification when needed
    - **Pattern Not Recognized**: Known scenario that agent should have recognized
  
  <action>Identify which files need modification:</action>
    - Current agent file (the one experiencing the problem)
    - Related SOPs or workflows that were being executed
    - Other agent files if problem could affect them too
    - Core task files if the issue is systemic
  
  <action>Formulate prevention strategy:</action>
    - What instruction/check/validation should be ADDED?
    - Where exactly should it be inserted?
    - What should trigger this new behavior?
    - How will the agent know to apply this learning?
  
  <action>Present analysis to user</action>
  <ask>ROOT CAUSE: [category]
  
  FILES TO MODIFY:
  - [list files]
  
  PREVENTION STRATEGY:
  - [describe what will be added/changed]
  
  Does this capture the right prevention approach? [y/n/adjust]</ask>
  
  <action>Iterate with user until prevention strategy is approved</action>
</step>

<step n="3" goal="Generate File Modifications">
  <action>For each identified file, read current content</action>
  <action>Determine optimal insertion point for new instruction/check/validation</action>
  
  <action>For agent files:</action>
    - Add to activation steps if it's a startup/initialization concern
    - Add to rules section if it's a general behavior guideline
    - Add to menu-handlers if it affects workflow execution
    - Consider adding a new section if this is a new category of guidance
  
  <action>For workflow/SOP files:</action>
    - Add new step if it's a major new validation
    - Add action/check within existing step if it's a refinement
    - Add to critical section at top if it's a showstopper
    - Update checklist if validation is needed
  
  <action>Generate specific modifications using exact old/new string format:</action>
  
  ```
  FILE: [filepath]
  LOCATION: [step/section where change occurs]
  REASON: [why this prevents the problem]
  
  OLD:
  [exact text with context lines before/after]
  
  NEW:
  [exact replacement text with context lines before/after]
  ```
  
  <action>For each modification, include:</action>
    - Reference to the PROBLEM being prevented
    - Brief comment explaining the check/instruction
    - Clear trigger condition if applicable
  
  <action>Present all proposed modifications to user</action>
  <ask>Review proposed file changes. Each change is designed to prevent: [PROBLEM]
  
  [show all modifications]
  
  Approve all [a], Edit specific changes [e], Skip some [s]?</ask>
  
  <action>Refine based on user feedback</action>
</step>

<step n="4" goal="Execute File Modifications">
  <action>Apply approved modifications to each file using replace_string_in_file or multi_replace_string_in_file</action>
  <action>Verify each modification was successful</action>
  <action>If any modification fails:</action>
    - Report which file/change failed
    - Explain why it failed
    - Propose alternative approach
    - Retry with user approval
  
  <action>Track all successful modifications</action>
  <action>Report summary of changes made</action>
</step>

<step n="5" goal="Create Learning Record">
  <action>Generate comprehensive learning record document with sections:</action>
  
  <section name="Learning Summary">
    - Date and agent context
    - PROBLEM description
    - SOLUTION description  
    - Root cause category
  </section>
  
  <section name="Files Modified">
    - List each file changed
    - Brief description of what was added/modified
    - Line numbers or section references
  </section>
  
  <section name="Prevention Mechanism">
    - Explain how the changes prevent problem recurrence
    - Describe trigger conditions
    - Note any dependencies or prerequisites
  </section>
  
  <section name="Verification">
    - How to verify the learning is working
    - What to watch for in future sessions
    - Suggested test scenarios if applicable
  </section>
  
  <section name="Related Patterns">
    - Link to similar problems if they exist
    - Suggest related areas that might benefit from similar changes
    - Note any edge cases or limitations
  </section>
  
  <action>Save learning record to {default_output_file}</action>
  <action>Show location of saved learning record to user</action>
</step>

<step n="6" goal="Verify and Commit">
  <action>Ask user if they want to review the modified files before committing</action>
  
  <check if="user wants to review">
    <action>Show each modified file section</action>
    <action>Allow user to request further adjustments</action>
  </check>
  
  <action>Prepare commit message:</action>
  ```
  learn: [brief problem description]
  
  Captured learning from problem-solution pair to prevent recurrence.
  
  Problem: [one-line problem summary]
  Solution: [one-line solution summary]
  
  Modified files:
  - [file1]: [what was added]
  - [file2]: [what was added]
  
  Learning record: {default_output_file}
  ```
  
  <ask>Ready to commit these learning modifications? 
  - Commit with generated message [c]
  - Edit commit message [e]
  - Don't commit yet [n]</ask>
  
  <action if="user approves commit">
    <action>Use git add for all modified files</action>
    <action>Execute commit with message</action>
    <action>Confirm commit successful</action>
  </action>
  
  <action>Report completion:</action>
  ```
  ✓ Learning captured and applied
  ✓ [N] files modified
  ✓ Learning record saved: {default_output_file}
  ✓ Changes committed [if applicable]
  
  This problem should not recur. The agent(s) now have specific guidance to prevent it.
  ```
</step>

</workflow>

<post-workflow>
  <note>Learning records accumulate over time, creating a knowledge base of solved problems</note>
  <note>Periodically review learning records to identify patterns that need higher-level architectural changes</note>
  <note>Consider creating a separate optimization workflow to consolidate multiple learnings into streamlined guidance</note>
</post-workflow>
