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

## Working with Protected Branches

### Branch Protection

- The `staging` and `main` branches are protected. Direct pushes are only allowed for admins.
- Non-admins must create pull requests and get approval before merging to protected branches.

### Pre-Push Hook

- This repo uses a pre-push hook (`.git-hooks/pre-push`) for additional safety:
  - Blocks direct pushes to protected branches for non-admins.
  - Runs the test suite when pushing code changes to protected branches.
  - Allows skipping tests with: `SKIP_TESTS=1 git push origin <branch>`
  - Admins listed in `.git-hooks/admins.txt` can push directly.

### Admins

- To allow a user to push directly, add their Git username or email to `.git-hooks/admins.txt`.

### Common Errors

- **Direct pushes to staging are not allowed. Please create a pull request.**
  - Solution: Open a pull request instead of pushing directly.
- **Tests failed. Push aborted.**
  - Solution: Fix test failures before pushing.

### Contributing Workflow

1. Make changes on a feature branch.
2. Open a pull request to `staging` or `main`.
3. Wait for required approvals and test suite to pass.
4. Admins may push directly if necessary.

---

For more details, see `.git-hooks/pre-push` and `.git-hooks/admins.txt`.
