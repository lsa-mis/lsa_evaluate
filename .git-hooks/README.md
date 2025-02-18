# Git Hooks

This directory contains project-specific git hooks that help maintain code quality and prevent common issues.

## Current Hooks

### pre-push

The pre-push hook runs automatically when you try to push code to protected branches (staging or main). It:

1. Prevents direct pushes to protected branches (staging/main)
2. Runs the full test suite when pushing to protected branches
3. Stashes any uncommitted changes before running tests
4. Aborts the push if any tests fail
5. Restores any stashed changes after running tests

## How it Works

The hooks are automatically used because we've configured the project's git config to use the `.git-hooks` directory. You don't need to do any manual setup.

## Adding New Hooks

To add a new hook:

1. Create the hook file in this directory (e.g., `pre-commit`, `post-merge`, etc.)
2. Make it executable (`chmod +x .git-hooks/your-hook-name`)
3. Update this README to document the new hook

## Skipping Hooks

In emergency situations, you can skip the pre-push hook by using:

```bash
git push --no-verify
```

However, this should be used sparingly and only in exceptional circumstances.
