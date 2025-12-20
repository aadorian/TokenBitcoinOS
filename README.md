# NFTCharm

## Installation

To install the charms package, run the following command:

```bash
cargo install charms --version=0.10.0
```

This will install version 0.10.0 of the charms package using Cargo, Rust's package manager.

## Prerequisites

Make sure you have Rust and Cargo installed on your system. If you don't have them installed, you can get them from [rustup.rs](https://rustup.rs/).

### Bitcoin Core (Optional)

If you need to interact with Bitcoin, install Bitcoin Core:

**macOS:**
```bash
brew install bitcoin
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install bitcoind
```

**From source:**
Visit [bitcoincore.org](https://bitcoincore.org/en/download/) to download the latest release.

### Running Bitcoin Daemon

Start Bitcoin daemon on testnet4:
```bash
bitcoind -testnet4 -daemon
```

Common options:
- `-testnet4`: Use testnet4 network for testing
- `-daemon`: Run in background
- `-regtest`: Run in regression test mode for local development
- `-datadir=<path>`: Specify custom data directory

Check daemon status:
```bash
bitcoin-cli -testnet4 getblockchaininfo
```

Stop daemon:
```bash
bitcoin-cli -testnet4 stop
```

## Creating a New Token Project

After installing charms, you can create a new token project using:

```bash
charms app new my-token
```

This command will:
- Create a new directory called `my-token`
- Generate a new Charms application with the necessary project structure
- Set up the boilerplate code for your token project
- Initialize configuration files needed for token development

Replace `my-token` with your desired project name.

## Charms App Commands

### Create a New App

```bash
charms app new <NAME>
```

Creates a new Charms application with the specified name. A directory with the given name will be created containing the project structure.

### Build the App

```bash
charms app build
```

Builds your Charms application. Run this command from within your app directory.

### Show Verification Key

```bash
charms app vk [PATH]
```

Displays the verification key for an app. You can optionally specify the path to the app's Wasm binary.

**Arguments:**
- `[PATH]` - Optional path to the app's Wasm binary

### Help

```bash
charms app --help
charms app <COMMAND> --help
```

Display help information for the charms app commands or specific subcommands.

## Project Structure

The NFTCharm repository structure:

```
NFTCharm/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml       # Bug report issue template
│   │   ├── feature_request.yml  # Feature request template
│   │   └── config.yml           # Issue template configuration
│   └── workflows/
│       ├── commitlint.yml       # Commit message validation
│       └── my-token-ci.yml      # CI/CD pipeline for my-token
├── my-token/                    # Token project directory
│   ├── .clippy.toml            # Clippy linting configuration
│   ├── .gitignore              # Git ignore rules for my-token
│   ├── .rustfmt.toml           # Rust formatting configuration
│   ├── Cargo.toml              # Rust package configuration
│   ├── LICENSE                 # MIT license file
│   ├── LINTING.md              # Linting documentation
│   ├── README.md               # Token project documentation
│   ├── lint.sh                 # Linting script
│   ├── src/
│   │   ├── lib.rs              # Main application logic and contract code
│   │   └── main.rs             # Entry point that invokes the app contract
│   ├── spells/
│   │   ├── mint-nft.yaml       # Spell to mint the reference NFT
│   │   ├── mint-token.yaml     # Spell to mint fungible tokens
│   │   └── send.yaml           # Spell to send tokens
│   └── tests/
│       └── integration_tests.rs # Integration tests
├── .commitlintrc.json          # Conventional commits configuration
├── .gitmessage                 # Git commit message template
├── .gitignore                  # Git ignore rules for repository
├── CONTRIBUTING.md             # Contribution guidelines
├── README.md                   # Main project documentation
└── README_DETAIL.md            # Detailed project information
```

### File Descriptions

#### Repository Configuration

**[.commitlintrc.json](.commitlintrc.json)**
- Commitlint configuration enforcing conventional commits
- Defines allowed commit types and formatting rules
- Ensures consistent commit message format across the project

**[.gitmessage](.gitmessage)**
- Git commit message template with conventional commits format
- Provides guidelines and examples for writing commit messages
- Activate with: `git config commit.template .gitmessage`

**[CONTRIBUTING.md](CONTRIBUTING.md)**
- Comprehensive contribution guidelines
- Explains conventional commits specification
- Development workflow and code quality requirements

**[.github/ISSUE_TEMPLATE/](.github/ISSUE_TEMPLATE/)**
- GitHub issue templates for bug reports and feature requests
- Standardizes issue reporting with structured forms
- Improves issue quality and maintainability

**[.github/workflows/](.github/workflows/)**
- `commitlint.yml`: Validates commit messages and PR titles
- `my-token-ci.yml`: CI/CD pipeline for building and testing

#### Token Project (my-token/)

**[my-token/Cargo.toml](my-token/Cargo.toml)**
The Rust package manifest that defines:
- Package metadata (name, version, description, license)
- Dependencies:
  - `charms-sdk` (v0.10.0) - The Charms SDK for building applications
  - `serde` (v1.0) - Serialization/deserialization framework
  - `sha2` (v0.10.9) - SHA-2 cryptographic hash functions
- Release profile optimizations (LTO, code generation settings, stripping)

**[my-token/src/lib.rs](my-token/src/lib.rs)**
Contains the main application logic implementing a fungible token system:
- Token contract implementation
- State management for token supply
- Business logic for minting and transferring tokens
- Integration with the Charms SDK

**[my-token/src/main.rs](my-token/src/main.rs)**
The application entry point that:
- Invokes the app contract using `charms_sdk::main!` macro
- Connects the library contract to the Charms runtime

**[my-token/spells/](my-token/spells/)** Directory
Contains YAML spell files that define transactions:

- **mint-nft.yaml**: Creates the reference NFT that controls token minting
  - Defines the initial state with ticker symbol and total supply
  - Sets up private inputs for the transaction
  - Example: Creates an NFT with ticker "MY-TOKEN" and 100,000 remaining supply

- **mint-token.yaml**: Mints new fungible tokens from the reference NFT
  - Requires control of the reference NFT to execute
  - Decreases the remaining supply in the NFT state
  - Outputs new tokens to specified addresses
  - Example: Mints 69,420 tokens and updates remaining supply to 30,580

- **send.yaml**: Transfers fungible tokens between addresses
  - Takes token inputs and creates token outputs
  - Does not require the reference NFT
  - Example: Sends 420 tokens to one address and 69,000 to another

**[my-token/tests/](my-token/tests/)**
- Integration tests for the token contract
- Validates token minting and transfer functionality

**Linting Configuration**
- **[.clippy.toml](my-token/.clippy.toml)**: Clippy linter settings
- **[.rustfmt.toml](my-token/.rustfmt.toml)**: Rust code formatting rules
- **[lint.sh](my-token/lint.sh)**: Automated linting script

### Token System Overview

This is a simple fungible token managed by a reference NFT:
- The NFT has a state specifying the remaining total supply available to mint
- Only the NFT controller can mint new tokens
- Once minted, tokens can be freely transferred without the NFT
- The system uses Charms' app contract model with verification keys

## Contributing

We welcome contributions! Please follow these guidelines:

### Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification. All commit messages must follow this format:

```
<type>(<scope>): <subject>
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Formatting changes (no code change)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI configuration
- `chore`: Other changes that don't modify src or test files

**Examples:**
```bash
feat(my-token): add token minting functionality
fix(ci): resolve clippy warnings in workflow
docs: update README with installation instructions
```

### Setting Up Commit Template

To use the provided commit message template:

```bash
git config commit.template .gitmessage
```

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-new-feature`
3. Make your changes and ensure tests pass: `cargo test`
4. Ensure code passes linting: `cargo clippy -- -D warnings`
5. Format your code: `cargo fmt`
6. Commit using conventional commits format
7. Push and create a Pull Request

For detailed contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md)
