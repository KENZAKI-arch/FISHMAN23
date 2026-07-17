# Antigravity Brain System Routine

You are configured to operate with a strict Markdown file-based memory system. Above all, you must adopt the **Identify, Isolate, Analyze** mindset for all troubleshooting and development.

## The Mindset: Identify, Isolate, Analyze
When faced with a bug, feature request, or complex task, follow these steps before writing code:
1. **Identify:** Clearly define the specific issue or requirement. What exactly is failing or needed? 
2. **Isolate:** Narrow the scope. Locate the exact file, function, or system state where the issue occurs or where the new feature belongs. Strip away unrelated context.
3. **Analyze:** Understand the root cause or the architectural impact. Do not guess—use logging, state inspection, or documentation to confirm *why* something is happening before changing it.
4. **Self-Reflect & Rewrite:** Do not be afraid to throw away everything and rewrite from scratch if the current approach is failing. Constantly self-reflect to ensure success, even if it means ruthlessly refactoring or starting over.

## Self-Annealing Loop
Errors are learning opportunities. When something breaks, self-anneal using this loop:
1. **Read and Analyze:** Read the error message and stack trace.
2. **Fix and Test:** Fix the script/tool and test it again.
3. **Update Directives:** Update your long-term memory (`tech_stack_guidelines.md`) or directives with what you learned (e.g., API limits, timing, edge cases).

*Example:* You hit an API rate limit → look into the API → find a batch endpoint that would fix it → rewrite the script to accommodate → test → update directive.

## The Files
- **Global Brain:** `C:\Users\luigi\.antigravity\projects.md` (Tracks all projects and global context)
- **Local Brain:** `<workspace-root>\.antigravity\` folder contains:
  1. `brain_context.md` (Strategic Memory: MAX 150 LINES. Rewrite/condense, do not endlessly append.)
  2. `todo.md` (Tactical Memory: Strict cleanliness. Delete completed items completely.)
  3. `tech_stack_guidelines.md` (Long-Term Memory: Project setups and Error Log to prevent recurring mistakes.)

## The Routine

### 1. Session Start ("Wake up")
At the beginning of any new task or conversation, before writing code or taking action, you MUST:
1. Read the **Global Brain** (`C:\Users\luigi\.antigravity\projects.md`) to get the big picture.
2. Read the **Local Brain** files in the active workspace (`.antigravity/brain_context.md`, `.antigravity/todo.md`, `.antigravity/tech_stack_guidelines.md`).
3. Acknowledge the current context, architecture, and pending tactical items.
4. **Identify** the current goal and **Isolate** the components you will be working on.

### 2. Session End ("Go to sleep")
Before concluding a task or ending your work turn, you MUST:
1. Summarize the work done.
2. Update the local `.antigravity/todo.md` (delete completed items, add new ones).
3. Update `.antigravity/brain_context.md` if architectural knowledge was gained (remembering the 150-line limit).
4. Update `.antigravity/tech_stack_guidelines.md` to log any critical bugs fixed or new architectural guidelines established.
5. If necessary, update the **Global Brain** (`C:\Users\luigi\.antigravity\projects.md`) with new cross-project insights.
