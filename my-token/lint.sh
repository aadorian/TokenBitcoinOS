#!/bin/bash
# Comprehensive Linting Script for my-token
# Runs all code quality checks

set -e

echo "🔍 Running Linting Suite for my-token..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Track overall status
FAILED=0

# 1. Check formatting
print_section "Checking code formatting (rustfmt)"
if cargo fmt --all -- --check; then
    print_success "Code formatting is correct"
else
    print_error "Code formatting issues found. Run 'cargo fmt' to fix."
    FAILED=1
fi

# 2. Run clippy
print_section "Running clippy lints"
if cargo clippy --all-targets --all-features -- -D warnings; then
    print_success "No clippy warnings"
else
    print_error "Clippy found issues"
    FAILED=1
fi

# 3. Check for common mistakes
print_section "Checking for common mistakes"
if cargo clippy --all-targets --all-features -- \
    -W clippy::unwrap_used \
    -W clippy::expect_used \
    -W clippy::panic \
    -W clippy::todo \
    -W clippy::unimplemented; then
    print_success "No common mistakes found"
else
    print_warning "Found some common mistakes (not blocking)"
fi

# 4. Run tests
print_section "Running tests"
if cargo test --all-features; then
    print_success "All tests passed"
else
    print_error "Tests failed"
    FAILED=1
fi

# 5. Check documentation
print_section "Checking documentation"
if cargo doc --no-deps --all-features --document-private-items; then
    print_success "Documentation builds successfully"
else
    print_error "Documentation has errors"
    FAILED=1
fi

# 6. Check for unused dependencies
print_section "Checking for unused dependencies"
if command -v cargo-udeps &> /dev/null; then
    if cargo +nightly udeps; then
        print_success "No unused dependencies"
    else
        print_warning "Found unused dependencies (not blocking)"
    fi
else
    print_warning "cargo-udeps not installed. Install with: cargo install cargo-udeps"
fi

# 7. Security audit
print_section "Running security audit"
if command -v cargo-audit &> /dev/null; then
    if cargo audit; then
        print_success "No security vulnerabilities found"
    else
        print_error "Security vulnerabilities detected!"
        FAILED=1
    fi
else
    print_warning "cargo-audit not installed. Install with: cargo install cargo-audit"
fi

# 8. Check for TODO/FIXME comments
print_section "Checking for TODO/FIXME comments"
TODO_COUNT=$(grep -r "TODO\|FIXME" src/ tests/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
    print_warning "Found $TODO_COUNT TODO/FIXME comments"
    grep -rn "TODO\|FIXME" src/ tests/ 2>/dev/null || true
else
    print_success "No TODO/FIXME comments found"
fi

# 9. Check line length
print_section "Checking line lengths"
LONG_LINES=$(find src/ tests/ -name "*.rs" -exec awk 'length > 100' {} + 2>/dev/null | wc -l | tr -d ' ')
if [ "$LONG_LINES" -gt 0 ]; then
    print_warning "Found $LONG_LINES lines longer than 100 characters"
else
    print_success "All lines within 100 character limit"
fi

# 10. Final summary
print_section "Lint Summary"
if [ $FAILED -eq 0 ]; then
    echo ""
    print_success "All critical checks passed! ✨"
    echo ""
    exit 0
else
    echo ""
    print_error "Some checks failed. Please fix the issues above."
    echo ""
    exit 1
fi
