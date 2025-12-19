# NFTCharm

## Installation

To install the charms package, run the following command:

```bash
cargo install charms --version=0.10.0
```

This will install version 0.10.0 of the charms package using Cargo, Rust's package manager.

## Prerequisites

Make sure you have Rust and Cargo installed on your system. If you don't have them installed, you can get them from [rustup.rs](https://rustup.rs/).

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

When you create a new token project with `charms app new my-token`, the following structure is generated:

```
my-token/
├── Cargo.toml           # Rust package configuration
├── LICENSE              # MIT license file
├── README.md            # Project documentation
├── .gitignore          # Git ignore rules
├── src/
│   ├── lib.rs          # Main application logic and contract code
│   └── main.rs         # Entry point that invokes the app contract
└── spells/
    ├── mint-nft.yaml   # Spell to mint the reference NFT
    ├── mint-token.yaml # Spell to mint fungible tokens
    └── send.yaml       # Spell to send tokens
```

### File Descriptions

#### Cargo.toml
The Rust package manifest that defines:
- Package metadata (name, version, description, license)
- Dependencies:
  - `charms-sdk` (v0.10.0) - The Charms SDK for building applications
  - `serde` (v1.0) - Serialization/deserialization framework
  - `sha2` (v0.10.9) - SHA-2 cryptographic hash functions
- Release profile optimizations (LTO, code generation settings, stripping)

#### src/lib.rs
Contains the main application logic implementing a fungible token system:
- Token contract implementation
- State management for token supply
- Business logic for minting and transferring tokens
- Integration with the Charms SDK

#### src/main.rs
The application entry point that:
- Invokes the app contract using `charms_sdk::main!` macro
- Connects the library contract to the Charms runtime

#### spells/ Directory
Contains YAML spell files that define transactions:

**mint-nft.yaml**
- Creates the reference NFT that controls token minting
- Defines the initial state with ticker symbol and total supply
- Sets up private inputs for the transaction
- Example: Creates an NFT with ticker "MY-TOKEN" and 100,000 remaining supply

**mint-token.yaml**
- Mints new fungible tokens from the reference NFT
- Requires control of the reference NFT to execute
- Decreases the remaining supply in the NFT state
- Outputs new tokens to specified addresses
- Example: Mints 69,420 tokens and updates remaining supply to 30,580

**send.yaml**
- Transfers fungible tokens between addresses
- Takes token inputs and creates token outputs
- Does not require the reference NFT
- Example: Sends 420 tokens to one address and 69,000 to another

### Token System Overview

This is a simple fungible token managed by a reference NFT:
- The NFT has a state specifying the remaining total supply available to mint
- Only the NFT controller can mint new tokens
- Once minted, tokens can be freely transferred without the NFT
- The system uses Charms' app contract model with verification keys
