# Git Hooks

This directory contains git hooks for the YouAreDoingGreat iOS project.

## Installation

To install the hooks, run:

```bash
./hooks/install.sh
```

This will copy the hooks to your local `.git/hooks` directory.

## Available Hooks

### pre-commit

Runs the test suite before each commit to ensure all tests pass.

- **What it does**: Executes `xcodebuild test` with the project's test scheme
- **When it runs**: Before each `git commit`
- **Skip it**: Use `git commit --no-verify` to bypass the hook if needed

## Requirements

- Xcode installed with command line tools
- iPhone SE (3rd generation) simulator available
- All test dependencies properly configured

## Testing the Hook

After installation, try making a commit. The tests will run automatically before the commit is created.
