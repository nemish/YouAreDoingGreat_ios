#!/bin/bash
# Claude Code Worktree Helper
# Automates git worktree creation for Linear tasks

set -e

WORKTREES_DIR="../worktrees"
MAIN_BRANCH="main"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function show_usage() {
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  create <issue-id>           Create worktree for Linear issue (e.g., YADG-37)"
    echo "  list                        List all worktrees"
    echo "  remove <issue-id>           Remove worktree for issue"
    echo "  cleanup                     Remove all merged worktrees"
    echo "  open <issue-id>             Print path to worktree (for opening in new session)"
    echo ""
    echo "Examples:"
    echo "  $0 create YADG-37"
    echo "  $0 list"
    echo "  $0 remove YADG-37"
    echo "  $0 open YADG-37"
}

function create_worktree() {
    local issue_id=$1

    if [ -z "$issue_id" ]; then
        echo "Error: Issue ID required"
        show_usage
        exit 1
    fi

    # Convert to lowercase and format branch name
    local branch_name=$(echo "$issue_id" | tr '[:upper:]' '[:lower:]')
    local worktree_path="$WORKTREES_DIR/$branch_name"

    echo -e "${BLUE}Creating worktree for $issue_id...${NC}"

    # Check if worktree already exists
    if [ -d "$worktree_path" ]; then
        echo -e "${YELLOW}Worktree already exists at $worktree_path${NC}"
        echo -e "${GREEN}Path: $(cd "$worktree_path" && pwd)${NC}"
        exit 0
    fi

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo -e "${YELLOW}Branch $branch_name already exists, creating worktree from existing branch${NC}"
        git worktree add "$worktree_path" "$branch_name"
    else
        echo -e "${BLUE}Creating new branch $branch_name from $MAIN_BRANCH${NC}"
        git worktree add -b "$branch_name" "$worktree_path" "$MAIN_BRANCH"
    fi

    echo -e "${GREEN}✓ Worktree created successfully!${NC}"
    echo -e "${GREEN}Path: $(cd "$worktree_path" && pwd)${NC}"
    echo ""
    echo -e "${BLUE}To open in new Claude Code session:${NC}"
    echo "  claude-code $(cd "$worktree_path" && pwd)"
}

function list_worktrees() {
    echo -e "${BLUE}Current worktrees:${NC}"
    git worktree list
}

function remove_worktree() {
    local issue_id=$1

    if [ -z "$issue_id" ]; then
        echo "Error: Issue ID required"
        show_usage
        exit 1
    fi

    local branch_name=$(echo "$issue_id" | tr '[:upper:]' '[:lower:]')
    local worktree_path="$WORKTREES_DIR/$branch_name"

    if [ ! -d "$worktree_path" ]; then
        echo -e "${YELLOW}Worktree not found at $worktree_path${NC}"
        exit 1
    fi

    echo -e "${BLUE}Removing worktree for $issue_id...${NC}"
    git worktree remove "$worktree_path"

    echo -e "${GREEN}✓ Worktree removed${NC}"
    echo ""
    echo -e "${YELLOW}Note: Branch '$branch_name' still exists. To delete it:${NC}"
    echo "  git branch -D $branch_name"
}

function cleanup_worktrees() {
    echo -e "${BLUE}Checking for merged branches...${NC}"

    # Get list of merged branches (excluding main and current)
    local merged_branches=$(git branch --merged "$MAIN_BRANCH" | grep -v "\*" | grep -v "$MAIN_BRANCH" | tr -d ' ')

    if [ -z "$merged_branches" ]; then
        echo -e "${GREEN}No merged branches to clean up${NC}"
        exit 0
    fi

    echo -e "${YELLOW}Merged branches:${NC}"
    echo "$merged_branches"
    echo ""

    read -p "Remove worktrees for these branches? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$merged_branches" | while read branch; do
            if [ -n "$branch" ]; then
                local worktree_path="$WORKTREES_DIR/$branch"
                if [ -d "$worktree_path" ]; then
                    echo -e "${BLUE}Removing worktree: $branch${NC}"
                    git worktree remove "$worktree_path" || true
                fi
            fi
        done
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    else
        echo "Cleanup cancelled"
    fi
}

function open_worktree() {
    local issue_id=$1

    if [ -z "$issue_id" ]; then
        echo "Error: Issue ID required"
        show_usage
        exit 1
    fi

    local branch_name=$(echo "$issue_id" | tr '[:upper:]' '[:lower:]')
    local worktree_path="$WORKTREES_DIR/$branch_name"

    if [ ! -d "$worktree_path" ]; then
        echo -e "${YELLOW}Worktree not found. Creating it first...${NC}"
        create_worktree "$issue_id"
        worktree_path="$WORKTREES_DIR/$branch_name"
    fi

    # Print absolute path
    echo "$(cd "$worktree_path" && pwd)"
}

# Main command router
case "${1:-}" in
    create)
        create_worktree "$2"
        ;;
    list)
        list_worktrees
        ;;
    remove)
        remove_worktree "$2"
        ;;
    cleanup)
        cleanup_worktrees
        ;;
    open)
        open_worktree "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
