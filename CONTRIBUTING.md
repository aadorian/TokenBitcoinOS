# Contributing to NFTCharm

Thank you for your interest in contributing to NFTCharm! This document provides guidelines and instructions for contributing.

## Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification. All commit messages must follow this format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Commit Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes that affect the build system or external dependencies
- `ci`: Changes to our CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

### Scope (Optional)

The scope should specify the place of the commit change. Examples:
- `my-token` - Changes to the Solana token program
- `core` - Changes to core library functionality
- `ci` - Changes to CI/CD configuration
- `docs` - Documentation changes

### Subject

- Use imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No period (.) at the end
- Maximum 100 characters

### Examples

```
feat(my-token): add token minting functionality

Implement the mint instruction for creating new tokens.
This includes parameter validation and proper error handling.

Fixes #42
```

```
fix(ci): resolve clippy warnings in workflow

Update clippy configuration to properly handle all warnings
and auto-fix where possible.
```

```
docs: update README with installation instructions
```

```
chore: update dependencies to latest versions
```

### Breaking Changes

Breaking changes must be indicated in the footer:

```
feat(my-token): change token metadata structure

BREAKING CHANGE: Token metadata now uses a different serialization format.
Existing tokens will need migration.
```

## Setting Up Commit Template

To use the provided commit message template:

```bash
git config commit.template .gitmessage
```

This will automatically open your editor with the template when you commit.

## Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-new-feature`
3. Make your changes
4. Write tests for your changes
5. Ensure all tests pass: `cargo test`
6. Ensure code passes linting: `cargo clippy -- -D warnings`
7. Format your code: `cargo fmt`
8. Commit using conventional commits format
9. Push to your fork
10. Create a Pull Request

## Code Quality

All code must:
- Pass `cargo test`
- Pass `cargo clippy -- -D warnings`
- Be formatted with `cargo fmt`
- Include appropriate documentation
- Follow Rust best practices

## Pull Request Process

1. Update the README.md or relevant documentation with details of changes
2. Update tests to cover your changes
3. The PR title should follow the conventional commits format
4. Ensure CI checks pass
5. Request review from maintainers

## Questions?

Feel free to open an issue for questions or use GitHub Discussions for broader topics.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
