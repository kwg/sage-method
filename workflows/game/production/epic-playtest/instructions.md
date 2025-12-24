# Epic Playtest Workflow Instructions

<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {project-root}/sage/workflows/game/production/epic-playtest/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>

<critical>
PLAYTESTING PRINCIPLES (from Schultz/Bryant "Game Testing: All in One"):
- "If you're not recording, you're not testing"
- Structured testing verifies acceptance criteria systematically
- Free testing (exploratory) finds edge cases and unexpected behaviors
- Gameplay testing evaluates balance, difficulty, and fun
- Separate facts from opinions in feedback
- Lead with feeling, follow with reason: "I felt [emotion] when [situation] because [reason]"
- Bug severity: A (Critical), B (Major), C (Minor)
- Repro rate: X out of Y attempts
</critical>

<workflow>

<step n="1" goal="Epic Discovery and Setup">

<action>Greet {user_name} and explain the playtest workflow</action>

<output>
**Epic Playtest Session**

{user_name}, I'll guide you through a structured playtest of the completed epic. This workflow includes:
1. **Structured Testing** - Verify each story's acceptance criteria
2. **Free Testing** - Explore edge cases and try to break things
3. **Gameplay Testing** - Evaluate fun, balance, and overall experience

Let me identify which epic we're playtesting.
</output>

<action>Load {sprint_status_file} and find the highest epic with all stories marked "done"</action>
<action>Extract epic number and verify completion status</action>

<check if="epic found with all stories done">
  <output>
Found Epic {{epic_num}} ready for playtest. All stories are marked done.

Is this the epic you want to playtest, {user_name}?
  </output>
  <action>WAIT for {user_name} to confirm</action>
</check>

<check if="no complete epic found">
  <output>
I couldn't find a fully completed epic in the sprint status. Which epic would you like to playtest?
  </output>
  <action>WAIT for {user_name} to provide epic number</action>
</check>

<action>Set {{epic_num}} based on user confirmation</action>

</step>

<step n="2" goal="Generate Playtest Checklist">

<action>Load the epic document for Epic {{epic_num}}</action>
<action>Extract all stories and their acceptance criteria</action>

<output>
**Generating Playtest Checklist for Epic {{epic_num}}**

Loading stories and acceptance criteria...
</output>

<action>For each story in the epic:</action>
- Extract story number and title
- Extract all acceptance criteria (AC)
- Format into structured test table

<action>Generate checklist using {playtest_checklist} template</action>

<output>
**Epic {{epic_num}} Playtest Checklist**

| Story | AC | Description | Pass | Fail | Notes |
|-------|----|-----------| -----|------|-------|
{{for each story and AC, list the test items}}

**Total ACs to verify**: {{total_ac_count}}
</output>

<action>Save generated checklist to {sprint_artifacts}/epic-{{epic_num}}-playtest-checklist.md</action>

<output>
Checklist saved to: {sprint_artifacts}/epic-{{epic_num}}-playtest-checklist.md

{user_name}, you can use this checklist during testing. Ready to begin the playtest session?
</output>

<action>WAIT for {user_name} to indicate readiness</action>

</step>

<step n="3" goal="Structured Testing - AC Verification">

<output>
**Phase 1: Structured Testing**

Goal: Verify each acceptance criterion passes.

Instructions:
1. Launch the game/test scene
2. For each AC, perform the required action
3. Mark Pass or Fail
4. Add notes for any observations

Let's go through each story systematically.
</output>

<action>For each story in Epic {{epic_num}}:</action>

<output>
**Story {{story_num}}: {{story_title}}**

| AC | Description | Result |
|----|-------------|--------|
{{list ACs for this story}}

{user_name}, test each AC and let me know the results:
- Which ACs passed?
- Which ACs failed?
- Any notes or observations?
</output>

<action>WAIT for {user_name} to provide test results</action>

<action>Record results in the checklist</action>

<check if="any AC failed">
  <output>
**Failed AC Detected**

AC{{ac_num}} failed: {{ac_description}}

Would you like to:
1. File a bug report now
2. Continue testing and file bugs later
3. Investigate the failure further
  </output>
  <action>WAIT for {user_name} decision</action>

  <check if="user wants to file bug">
    <action>Use {bug_report} template</action>
    <action>Guide user through bug report fields</action>
    <action>Save bug report to {bugs_folder}/epic-{{epic_num}}-bug-{{bug_num}}.md</action>
  </check>
</check>

<action>Continue until all stories are tested</action>

<output>
**Structured Testing Complete**

Results:
- Stories tested: {{stories_tested}}/{{total_stories}}
- ACs passed: {{passed_count}}/{{total_ac_count}}
- ACs failed: {{failed_count}}/{{total_ac_count}}
- Bugs filed: {{bugs_filed}}

{{#if failed_count > 0}}
**Failed ACs require attention before epic can be marked complete.**
{{else}}
All acceptance criteria verified!
{{/if}}
</output>

</step>

<step n="4" goal="Free Testing - Exploratory">

<output>
**Phase 2: Free Testing (Exploratory)**

Goal: Try to break things! Find edge cases, unexpected behaviors, and undocumented issues.

Before testing, define 3-5 goals. Examples:
- "What happens if I spam-click the execute button?"
- "Can I play cards with 0 plays remaining?"
- "What happens if all enemies die mid-stack resolution?"
- "Does the UI handle very long card names?"
</output>

<action>WAIT for {user_name} to define testing goals</action>

<output>
Your testing goals:
1. {{goal_1}}
2. {{goal_2}}
3. {{goal_3}}

Now spend 15-30 minutes exploring these scenarios. I'll wait for your findings.

**Remember**: If you find something unexpected, document:
- What you tried
- What you expected
- What actually happened
- How often it happens (repro rate)
</output>

<action>WAIT for {user_name} to complete exploratory testing</action>

<output>
**Free Testing Results**

{user_name}, share your findings:
- What issues did you discover?
- Which goals revealed problems?
- Any edge cases worth documenting?
</output>

<action>WAIT for {user_name} to provide findings</action>

<action>For each issue found, determine severity (A/B/C) and create bug report if needed</action>

<output>
**Free Testing Summary**

- Goals tested: {{goals_count}}
- Issues found: {{issues_count}}
- Bugs filed: {{bugs_filed}}

{{#if issues_count > 0}}
Issues identified:
{{list issues with severity}}
{{else}}
No issues found during exploratory testing.
{{/if}}
</output>

</step>

<step n="5" goal="Gameplay Testing">

<output>
**Phase 3: Gameplay Testing**

Goal: Evaluate the fun factor, balance, and overall experience.

Play through the game normally for 3+ combat sessions. Track:
- Turns to complete combat
- Cards played per turn
- Damage dealt vs taken
- Which cards you use most/least
- Your emotional responses

Use the "I felt [emotion] when [situation] because [reason]" format for feedback.
</output>

<action>WAIT for {user_name} to complete gameplay sessions</action>

<output>
**Gameplay Session Log**

{user_name}, please share your session data:

For each combat:
- How many turns?
- Win or loss?
- Any notable moments?

And your overall impressions:
- What was most fun?
- What was least fun?
- What felt too strong/weak?
- Any balance concerns?
</output>

<action>WAIT for {user_name} to provide gameplay feedback</action>

<action>Record feedback using {gameplay_feedback} template</action>

<output>
**Gameplay Testing Summary**

Sessions played: {{session_count}}
Average turns to win: {{avg_turns}}

**Emotional Responses:**
{{list emotional_responses}}

**Balance Observations:**
{{list balance_observations}}

**Fun Assessment:**
- Overall: {{overall_rating}}/5
- Most fun: {{most_fun}}
- Least fun: {{least_fun}}
</output>

</step>

<step n="6" goal="Compile Results and Sign-Off">

<output>
**Playtest Complete - Sign-Off Checklist**

All criteria must be met to mark epic playtest complete:

- [ ] All structured tests passed (or bugs filed)
- [ ] At least 3 exploratory goals tested
- [ ] At least 3 gameplay sessions logged
- [ ] All Severity A/B bugs filed
- [ ] Gameplay feedback template completed

{user_name}, let's verify each criterion.
</output>

<action>Walk through each sign-off criterion with {user_name}</action>

<check if="all criteria met">
  <output>
**All sign-off criteria met!**

Recommendation: [ ] Ready for release

Epic {{epic_num}} has passed playtesting.
  </output>
</check>

<check if="blocking issues exist">
  <output>
**Blocking Issues Detected**

The following must be resolved before epic completion:
{{list blocking_issues}}

Recommendation: [ ] Needs fixes

Epic {{epic_num}} cannot be marked complete until blocking issues are resolved.
  </output>
</check>

</step>

<step n="7" goal="Generate Playtest Report">

<action>Compile all results into final playtest report</action>

<output>
**Epic {{epic_num}} Playtest Report**

**Tester**: {user_name}
**Date**: {date}
**Version**: {{git_commit}}

---

## Structured Testing
- ACs Verified: {{passed_count}}/{{total_ac_count}}
- Pass Rate: {{pass_percentage}}%

## Free Testing
- Goals Tested: {{goals_count}}
- Issues Found: {{issues_count}}

## Gameplay Testing
- Sessions: {{session_count}}
- Average Turns: {{avg_turns}}
- Fun Rating: {{overall_rating}}/5

## Bugs Filed
{{list bugs with severity}}

## Recommendation
{{recommendation}}

---

Playtest completed: {date}
</output>

<action>Save report to {default_output_file}</action>

<output>
Playtest report saved to: {default_output_file}

{user_name}, the playtest session is complete.

**Next Steps:**
{{#if blocking_issues}}
1. Fix blocking bugs before marking epic complete
2. Run targeted regression test after fixes
3. Re-verify failed ACs
{{else}}
1. Review playtest report
2. Address any non-blocking feedback
3. Proceed to epic completion workflow
{{/if}}
</output>

</step>

</workflow>

<facilitation-guidelines>
<guideline>Guide testers through structured process, but allow flexibility</guideline>
<guideline>Encourage thorough documentation of all findings</guideline>
<guideline>Help categorize bugs by severity (A/B/C)</guideline>
<guideline>Separate facts from opinions in gameplay feedback</guideline>
<guideline>Use emotional response format for gameplay feedback</guideline>
<guideline>Ensure all blocking issues are documented before sign-off</guideline>
<guideline>Generate actionable bug reports with repro steps</guideline>
<guideline>Track playtest metrics for future reference</guideline>
</facilitation-guidelines>
