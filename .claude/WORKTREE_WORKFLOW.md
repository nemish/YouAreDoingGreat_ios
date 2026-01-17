# Git Worktree Workflow for Parallel Task Development

## Overview

This workflow allows you to work on multiple Linear tasks in parallel by creating separate worktrees for each task. Each worktree is an isolated workspace with its own branch, preventing conflicts when switching between tasks.

## Quick Start

### 1. Create Worktree for a Task (Automated)

From within this Claude Code session:

```bash
# Create worktree for YADG-37
.claude/worktree-helper.sh create YADG-37
```

This will:
- Create a new branch `yadg-37` from `main`
- Create worktree at `../worktrees/yadg-37/`
- Print the absolute path for opening in a new session

### 2. Open Worktree in New Claude Code Session

**Option A: From Terminal**
```bash
# Copy the path printed by the helper script
claude-code /Users/yara5000/projects/my/you_are_doing_great/worktrees/yadg-37
```

**Option B: Use the Helper**
```bash
# Get the path
WORKTREE_PATH=$(.claude/worktree-helper.sh open YADG-37)
# Open in new session
claude-code "$WORKTREE_PATH"
```

**Option C: Ask Claude Code**
In this session, say:
```
Create a worktree for YADG-37 and give me the command to open it in a new session
```

### 3. Work on Task in New Session

In the new Claude Code session (in the worktree):
- You're on branch `yadg-37`
- All changes are isolated
- Can commit and push independently
- Other sessions are unaffected

### 4. Complete Task & Merge

When done in the worktree session:
```bash
# Commit your work
git add .
git commit -m "feat: implement core haptic infrastructure (YADG-37)"

# Push to remote
git push -u origin yadg-37

# Create PR (in worktree session)
gh pr create --title "Core Infrastructure - HapticManager Service (YADG-37)" \
  --body "Resolves YADG-37"
```

### 5. Clean Up Worktree

After PR is merged, from the main session:
```bash
# Remove the worktree
.claude/worktree-helper.sh remove YADG-37

# Or clean up all merged worktrees
.claude/worktree-helper.sh cleanup
```

## Workflow for Multiple Tasks

### Sequential Approach (One Task at a Time)

```bash
# Task 1: Core Infrastructure
.claude/worktree-helper.sh create YADG-37
claude-code $(worktree-helper.sh open YADG-37)
# ... work on YADG-37 in new session ...
# ... merge PR, then back to main session ...
.claude/worktree-helper.sh remove YADG-37

# Task 2: Signature Pattern
.claude/worktree-helper.sh create YADG-38
claude-code $(.claude/worktree-helper.sh open YADG-38)
# ... work on YADG-38 in new session ...
```

### Parallel Approach (Multiple Tasks Simultaneously)

```bash
# Create worktrees for multiple tasks
.claude/worktree-helper.sh create YADG-37
.claude/worktree-helper.sh create YADG-38
.claude/worktree-helper.sh create YADG-39

# Open each in separate Claude Code sessions
claude-code /path/to/worktrees/yadg-37  # Terminal 1
claude-code /path/to/worktrees/yadg-38  # Terminal 2
claude-code /path/to/worktrees/yadg-39  # Terminal 3

# Work on all three simultaneously
# Each session is isolated
```

## Helper Script Commands

### Create Worktree
```bash
.claude/worktree-helper.sh create YADG-37
```
- Creates branch `yadg-37` from `main`
- Creates worktree at `../worktrees/yadg-37/`
- Prints path for opening

### List Worktrees
```bash
.claude/worktree-helper.sh list
```
Shows all active worktrees with their branches and paths

### Open Worktree (Get Path)
```bash
.claude/worktree-helper.sh open YADG-37
```
Prints absolute path (creates worktree if doesn't exist)

### Remove Worktree
```bash
.claude/worktree-helper.sh remove YADG-37
```
Removes worktree (branch remains, can delete separately)

### Cleanup Merged Worktrees
```bash
.claude/worktree-helper.sh cleanup
```
Interactive cleanup of worktrees for merged branches

## Asking Claude Code to Automate

You can ask Claude Code in this session to automate the entire workflow:

### Example 1: Start Single Task
```
Create a worktree for YADG-37 and show me how to open it
```

Claude will:
1. Run `.claude/worktree-helper.sh create YADG-37`
2. Show you the command to open in new session

### Example 2: Start Multiple Tasks
```
Create worktrees for YADG-37, YADG-38, and YADG-39.
Give me the commands to open each in a new session.
```

Claude will:
1. Create all three worktrees
2. Provide commands for opening each

### Example 3: Full Automation
```
I want to work on task YADG-37. Create the worktree,
and tell me what to do next.
```

Claude will:
1. Create worktree
2. Provide step-by-step instructions
3. Give you the `claude-code` command

## Directory Structure

```
you_are_doing_great/
├── YouAreDoingGreat_ios/          # Main workspace (current)
│   ├── .git/                       # Git directory
│   ├── .claude/
│   │   ├── worktree-helper.sh     # Helper script
│   │   └── WORKTREE_WORKFLOW.md   # This file
│   └── YouAreDoingGreat/          # Source code
└── worktrees/                      # Worktrees directory
    ├── yadg-37/                    # Task YADG-37 worktree
    ├── yadg-38/                    # Task YADG-38 worktree
    └── yadg-ios-debug-switch-user-id/  # Existing worktree
```

## Best Practices

### 1. Always Work from Main Session for Setup
- Use this main session to create/remove worktrees
- Don't create worktrees from within other worktrees

### 2. One Branch Per Task
- Each Linear task gets its own branch and worktree
- Branch naming: `yadg-XX` (lowercase issue number)

### 3. Keep Worktrees Clean
- Remove worktrees after PR is merged
- Run cleanup regularly: `.claude/worktree-helper.sh cleanup`

### 4. Use Descriptive Commits
- Include issue number in commit messages
- Follow conventional commits format

### 5. Sync Regularly
- Pull latest `main` in main session: `git pull origin main`
- Rebase feature branches if needed: `git rebase main` (in worktree)

## Manual Worktree Commands (If Needed)

If you prefer manual control:

```bash
# Create worktree manually
git worktree add -b yadg-37 ../worktrees/yadg-37 main

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../worktrees/yadg-37

# Prune stale worktrees
git worktree prune
```

## Troubleshooting

### Worktree Already Exists
```bash
# Check if it exists
git worktree list

# Remove if needed
git worktree remove ../worktrees/yadg-37
```

### Branch Already Exists
```bash
# Delete branch if needed
git branch -D yadg-37

# Or create worktree from existing branch
git worktree add ../worktrees/yadg-37 yadg-37
```

### Can't Remove Worktree (Uncommitted Changes)
```bash
# Force remove
git worktree remove --force ../worktrees/yadg-37
```

### Main Repo Out of Sync
```bash
# In main session
git pull origin main

# In worktree
cd ../worktrees/yadg-37
git rebase main
```

## Example: Complete Workflow for YADG-37

```bash
# 1. In main session: Create worktree
.claude/worktree-helper.sh create YADG-37

# Output:
# Creating worktree for YADG-37...
# Creating new branch yadg-37 from main
# ✓ Worktree created successfully!
# Path: /Users/yara5000/projects/my/you_are_doing_great/worktrees/yadg-37

# 2. Open in new terminal
claude-code /Users/yara5000/projects/my/you_are_doing_great/worktrees/yadg-37

# 3. In new Claude Code session (worktree):
# Say: "I want to implement YADG-37 - Core Infrastructure HapticManager Service"
# Claude will start implementing in the worktree

# 4. When done (in worktree session):
git add .
git commit -m "feat: implement core haptic infrastructure (YADG-37)"
git push -u origin yadg-37
gh pr create --title "Core Infrastructure - HapticManager Service (YADG-37)"

# 5. After PR merged (back in main session):
git pull origin main
.claude/worktree-helper.sh remove YADG-37
```

## Summary

**Key Insight**: You can ask Claude Code in this session to automate worktree creation and management. Just say what you want, like:

- "Create a worktree for YADG-37"
- "Set up worktrees for tasks YADG-37 through YADG-43"
- "Show me how to work on multiple tasks in parallel"

Claude will use the helper script and guide you through the entire workflow.
