# Detailed Build Commands Explanation

## Building Your Charms Application

When building a Charms application, you'll typically use these two commands:

```bash
cargo update
app_bin=$(charms app build)
```

## `cargo update`

This command updates all dependencies in your Rust project to their latest compatible versions.

### What it does:
- Reads the `Cargo.toml` file which specifies dependency version requirements
- Checks crates.io (Rust's package registry) for the newest versions that match those requirements
- Updates the `Cargo.lock` file with the specific versions to use
- Ensures all dependencies are compatible with each other
- Does NOT change the version requirements in `Cargo.toml`, only updates within the specified ranges

### Example:
If `Cargo.toml` specifies `serde = "1.0"`, cargo update will fetch the latest 1.x version (like 1.0.210) but won't upgrade to 2.0.

### Why it's important:
- Gets the latest bug fixes and security patches
- Ensures reproducible builds through the `Cargo.lock` file
- Maintains compatibility with your specified version constraints

## `app_bin=$(charms app build)`

This is a shell command that performs two operations:

### 1. `charms app build` - Builds your Charms application

**What it does:**
- Compiles the Rust code to WebAssembly (Wasm) format
- Uses the `wasm32-wasip1` target (WebAssembly System Interface Preview 1)
- Applies release optimizations defined in `Cargo.toml`:
  - **LTO (Link Time Optimization)**: `lto = "fat"` - Optimizes across all crates
  - **Codegen units**: `codegen-units = 1` - Better optimization at cost of compile time
  - **Strip symbols**: `strip = "symbols"` - Removes debugging symbols to reduce size
  - **Panic behavior**: `panic = "abort"` - Aborts on panic instead of unwinding
- Outputs the binary to `./target/wasm32-wasip1/release/my-token.wasm`
- Returns the full path to the compiled Wasm binary

### 2. `app_bin=$(...)` - Captures the output

**What it does:**
- Stores the path to the compiled Wasm binary in the `app_bin` shell variable
- Allows you to use `$app_bin` in subsequent commands without retyping the path
- Makes your build scripts more maintainable and less error-prone

### Usage examples:

```bash
# Get the verification key for your app
charms app vk $app_bin

# Use in spell checking
charms spell check --app-bins=${app_bin}

# Multiple apps can be stored in different variables
app_bin_1=$(cd project1 && charms app build)
app_bin_2=$(cd project2 && charms app build)
```

## Complete Build Workflow

Here's the typical workflow when developing a Charms application:

```bash
# 1. Navigate to your project directory
cd my-token

# 2. Ensure you have the WebAssembly target installed (first time only)
rustup target add wasm32-wasip1

# 3. Update dependencies to latest compatible versions
cargo update

# 4. Build the application and store the binary path
app_bin=$(charms app build)

# 5. Get the verification key for your app
export app_vk=$(charms app vk $app_bin)

# 6. Now you can use $app_bin and $app_vk in your spells and tests
```

## Output Location

After building, your compiled Wasm binary will be located at:
```
./target/wasm32-wasip1/release/my-token.wasm
```

This binary:
- Is optimized for production use
- Contains your complete application logic
- Can be verified using the verification key
- Is used when executing spells and transactions

## Why WebAssembly (Wasm)?

Charms uses WebAssembly because it provides:
- **Deterministic execution**: Same code produces same results everywhere
- **Sandboxed environment**: Secure execution isolation
- **Platform independence**: Runs on any system with a Wasm runtime
- **Efficient verification**: Cryptographic proofs of correct execution
- **Small binary sizes**: Optimized builds are compact and fast to distribute
