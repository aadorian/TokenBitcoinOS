# Linting and Code Quality Guide

This document describes the linting setup and code quality standards for the my-token project.

## Overview

The project uses multiple tools to ensure code quality, consistency, and security:

- **rustfmt** - Code formatting
- **clippy** - Rust linter for common mistakes and improvements
- **cargo-audit** - Security vulnerability scanner
- **cargo-udeps** - Unused dependency detection
- **Custom lint script** - Comprehensive automated checks

## Quick Start

### Run All Lints

```bash
./lint.sh
```

This runs the complete linting suite including formatting, clippy, tests, documentation, and security checks.

### Individual Tools

```bash
# Format code
cargo fmt

# Check formatting without modifying files
cargo fmt --check

# Run clippy
cargo clippy --all-targets --all-features

# Run clippy with strict warnings as errors
cargo clippy --all-targets --all-features -- -D warnings

# Build documentation
cargo doc --no-deps --all-features

# Run security audit
cargo audit

# Check for unused dependencies
cargo +nightly udeps
```

## Configuration Files

### `.rustfmt.toml`

Controls code formatting rules:
- Max line width: 100 characters
- 4 spaces for indentation
- Unix line endings
- Automatic import grouping and sorting
- Comment wrapping at 80 characters

### `.clippy.toml`

Configures clippy behavior:
- Cognitive complexity threshold: 30
- Type complexity threshold: 250
- Function parameter limit: 7
- Disallowed variable names: foo, bar, baz, quux

### `Cargo.toml` [lints] Section

Defines project-wide lint levels:

**Rust Lints:**
- `unsafe_code = "forbid"` - No unsafe code allowed
- `missing_docs = "warn"` - Warn on missing documentation
- `unused_import_braces = "warn"` - Warn on unnecessary import braces

**Clippy Lint Groups:**
- `pedantic = "warn"` - Strict code quality checks
- `cargo = "warn"` - Cargo-specific best practices
- `nursery = "warn"` - Experimental lints
- `correctness = "deny"` - Critical correctness issues
- `perf = "warn"` - Performance improvements
- `style = "warn"` - Style consistency
- `complexity = "warn"` - Code complexity warnings

**Specific Restrictions:**
- `unwrap_used = "warn"` - Discourage unwrap()
- `expect_used = "warn"` - Discourage expect()
- `panic = "warn"` - Discourage panic!()
- `todo = "warn"` - Flag TODO items
- `unreachable = "warn"` - Flag unreachable!()

## Pre-commit Hooks

A git pre-commit hook is available to run basic checks before each commit:

### Setup

```bash
# Link the hook to your git config
git config core.hooksPath .git-hooks

# Or copy to .git/hooks/
cp .git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

The pre-commit hook runs:
1. Code formatting check
2. Clippy with warnings as errors
3. All tests

### Bypass Hook (Not Recommended)

```bash
git commit --no-verify
```

Only use `--no-verify` in exceptional circumstances.

## Continuous Integration

The GitHub Actions workflow (`.github/workflows/my-token-ci.yml`) runs comprehensive linting:

1. **Lint Job** - Formatting and clippy
2. **Test Job** - All tests including doc tests
3. **Security Job** - cargo-audit
4. **Coverage Job** - Code coverage analysis

All jobs must pass before merging to main.

## Common Issues and Fixes

### Formatting Issues

```bash
# Fix all formatting issues automatically
cargo fmt
```

### Clippy Warnings

```bash
# See detailed clippy output
cargo clippy --all-targets --all-features -- -W clippy::all

# Fix automatically where possible
cargo clippy --fix --all-targets --all-features
```

### Allow Specific Lints

For necessary exceptions, use inline attributes:

```rust
#[allow(clippy::unwrap_used)]
fn example() {
    let value = some_option.unwrap(); // Justified because...
}
```

Always add a comment explaining why the lint is allowed.

### Documentation Warnings

```rust
/// Documents the function
///
/// # Arguments
///
/// * `param` - Description
///
/// # Returns
///
/// Description of return value
pub fn example(param: i32) -> bool {
    // ...
}
```

## Installing Additional Tools

### cargo-audit

```bash
cargo install cargo-audit
```

### cargo-udeps

```bash
cargo install cargo-udeps
```

Requires nightly Rust:
```bash
rustup toolchain install nightly
```

### cargo-tarpaulin (Coverage)

```bash
cargo install cargo-tarpaulin
```

## Best Practices

1. **Run lints before committing**
   ```bash
   ./lint.sh
   ```

2. **Keep code formatted**
   - Configure your editor to run `cargo fmt` on save
   - VSCode: Install rust-analyzer extension
   - Vim: Use rustfmt.vim

3. **Address clippy warnings**
   - Don't ignore warnings without good reason
   - Document why you're allowing a lint
   - Prefer refactoring over allowing lints

4. **Write documentation**
   - Document all public APIs
   - Include examples in doc comments
   - Explain "why" not just "what"

5. **Avoid panic in production code**
   - Use `Result<T, E>` for fallible operations
   - Handle errors explicitly
   - Only use `unwrap()` when you can prove it's safe

6. **Keep dependencies up to date**
   - Run `cargo update` regularly
   - Review `cargo audit` output
   - Remove unused dependencies

## IDE Integration

### VSCode

Install extensions:
- **rust-analyzer** - Rust language support
- **Error Lens** - Inline error display
- **Better TOML** - TOML syntax support

Settings (`.vscode/settings.json`):
```json
{
  "rust-analyzer.check.command": "clippy",
  "editor.formatOnSave": true,
  "[rust]": {
    "editor.defaultFormatter": "rust-lang.rust-analyzer"
  }
}
```

### IntelliJ IDEA / CLion

1. Install Rust plugin
2. Settings → Languages → Rust
3. Enable "Run clippy on save"
4. Enable "Run rustfmt on save"

## Metrics and Goals

Current project metrics:
- ✅ 0 clippy warnings
- ✅ 100% formatted code
- ✅ 11/11 tests passing
- ✅ 0 security vulnerabilities
- ✅ All public APIs documented

Goals:
- Maintain zero clippy warnings
- Keep test coverage above 80%
- Fix security issues within 24 hours
- Document all new public APIs

## Resources

- [Rustfmt Documentation](https://rust-lang.github.io/rustfmt/)
- [Clippy Lint List](https://rust-lang.github.io/rust-clippy/master/)
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
