//! Binary entry point for the my-token Charms application.
//!
//! This executable serves as the main entry point for the NFT token contract,
//! using the Charms SDK to initialize and run the [`app_contract`](my_token::app_contract)
//! function which validates NFT and token minting transactions.
//!
//! # Overview
//!
//! The binary uses the `charms_sdk::main!` macro to bootstrap the application
//! and connect it to the Charms blockchain infrastructure. The contract implements
//! a dual-token system where:
//!
//! - **NFTs** can be minted tied to specific UTXO identities
//! - **Fungible tokens** are controlled by NFT supply reserves
//! - **Supply management** enforces token limits through NFT state
//!
//! # Usage
//!
//! Build the WASM binary with:
//! ```sh
//! cargo build --release --target wasm32-wasip1
//! ```
//!
//! The resulting binary can be deployed to the Charms network for transaction validation.

charms_sdk::main!(my_token::app_contract);
