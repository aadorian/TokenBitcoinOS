//! NFT and Token Contract Implementation
//!
//! This library provides a smart contract implementation for managing NFTs and fungible tokens
//! on the Charms SDK platform. It implements a dual-token system where NFTs can control the
//! minting of associated fungible tokens based on remaining supply tracked in the NFT state.
//!
//! # Contract Features
//!
//! - **NFT Minting**: Create unique NFTs tied to specific UTXO identities
//! - **Token Minting**: Mint fungible tokens controlled by corresponding NFT supply
//! - **Supply Management**: Track and enforce token supply limits through NFT state
//!
//! # Example
//!
//! ```ignore
//! use my_token::{app_contract, NftContent};
//! use charms_sdk::data::{App, Transaction, Data};
//!
//! // The contract validates transactions through app_contract function
//! let valid = app_contract(&app, &tx, &x, &w);
//! ```

use charms_sdk::data::{
    charm_values, check, sum_token_amount, App, Data, Transaction, UtxoId, B32, NFT, TOKEN,
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// Represents the content stored within an NFT.
///
/// This structure tracks the token ticker and the remaining supply available
/// for minting fungible tokens associated with this NFT.
///
/// # Fields
///
/// * `ticker` - The token symbol/ticker string
/// * `remaining` - The remaining supply of tokens that can be minted
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NftContent {
    /// The token ticker symbol
    pub ticker: String,
    /// Remaining supply of tokens available for minting
    pub remaining: u64,
}

/// Main contract validation function.
///
/// This function serves as the entry point for contract validation, routing to
/// appropriate validation logic based on the application tag (NFT or TOKEN).
///
/// # Arguments
///
/// * `app` - The application context containing tag, identity, and verification key
/// * `tx` - The transaction to validate
/// * `x` - Additional data (must be empty for this contract)
/// * `w` - Witness data used for NFT minting validation
///
/// # Returns
///
/// Returns `true` if the contract is satisfied, panics otherwise via the `check!` macro.
///
/// # Panics
///
/// Panics if `x` is not empty or if contract validation fails.
pub fn app_contract(app: &App, tx: &Transaction, x: &Data, w: &Data) -> bool {
    let empty = Data::empty();
    assert_eq!(x, &empty);
    match app.tag {
        NFT => {
            check!(nft_contract_satisfied(app, tx, w))
        }
        TOKEN => {
            check!(token_contract_satisfied(app, tx))
        }
        _ => unreachable!(),
    }
    true
}

/// Validates NFT contract satisfaction.
///
/// Checks whether the transaction satisfies the NFT contract by verifying that
/// either a new NFT can be minted or associated tokens can be minted.
///
/// # Arguments
///
/// * `app` - The NFT application context
/// * `tx` - The transaction to validate
/// * `w` - Witness data containing the UTXO ID for NFT minting
///
/// # Returns
///
/// Returns `true` if either NFT or token minting conditions are satisfied.
///
/// # Note
///
/// TODO: Replace with your own logic
fn nft_contract_satisfied(app: &App, tx: &Transaction, w: &Data) -> bool {
    let token_app = &App {
        tag: TOKEN,
        identity: app.identity.clone(),
        vk: app.vk.clone(),
    };
    check!(can_mint_nft(app, tx, w) || can_mint_token(&token_app, tx));
    true
}

/// Validates whether an NFT can be minted in the transaction.
///
/// This function enforces the NFT minting rules:
/// 1. The witness data must contain a valid UTXO ID string
/// 2. The hash of the witness must match the NFT's identity
/// 3. The transaction must spend the UTXO referenced in the witness
/// 4. Exactly one NFT must be created in the outputs
/// 5. The NFT must contain valid `NftContent` data
///
/// # Arguments
///
/// * `nft_app` - The NFT application context
/// * `tx` - The transaction attempting to mint the NFT
/// * `w` - Witness data containing the UTXO ID string
///
/// # Returns
///
/// Returns `true` if all NFT minting conditions are satisfied, `false` otherwise.
fn can_mint_nft(nft_app: &App, tx: &Transaction, w: &Data) -> bool {
    let w_str: Option<String> = w.value().ok();

    check!(w_str.is_some());
    let w_str = w_str.unwrap();

    // can only mint an NFT with this contract if the hash of `w` is the identity of the NFT.
    check!(hash(&w_str) == nft_app.identity);

    // can only mint an NFT with this contract if spending a UTXO with the same ID as passed in `w`.
    let w_utxo_id = UtxoId::from_str(&w_str).unwrap();
    check!(tx.ins.iter().any(|(utxo_id, _)| utxo_id == &w_utxo_id));

    let nft_charms = charm_values(nft_app, tx.outs.iter()).collect::<Vec<_>>();

    // can mint exactly one NFT.
    check!(nft_charms.len() == 1);
    // the NFT has the correct structure.
    check!(nft_charms[0].value::<NftContent>().is_ok());
    true
}

/// Computes the SHA-256 hash of input data.
///
/// This function is used to derive NFT identities from UTXO IDs by computing
/// their SHA-256 hash.
///
/// # Arguments
///
/// * `data` - The string data to hash
///
/// # Returns
///
/// Returns a `B32` (32-byte) hash of the input data.
///
/// # Example
///
/// ```ignore
/// let utxo_id = "dc78b09d767c8565c4a58a95e7ad5ee22b28fc1685535056a395dc94929cdd5f:1";
/// let identity = hash(utxo_id);
/// ```
pub fn hash(data: &str) -> B32 {
    let hash = Sha256::digest(data);
    B32(hash.into())
}

/// Validates token contract satisfaction.
///
/// Checks whether the transaction satisfies the token contract by verifying
/// that tokens can be minted according to the rules enforced by the managing NFT.
///
/// # Arguments
///
/// * `token_app` - The token application context
/// * `tx` - The transaction to validate
///
/// # Returns
///
/// Returns `true` if token minting conditions are satisfied.
///
/// # Note
///
/// TODO: Replace with your own logic
fn token_contract_satisfied(token_app: &App, tx: &Transaction) -> bool {
    check!(can_mint_token(token_app, tx));
    true
}

/// Validates whether tokens can be minted in the transaction.
///
/// This function enforces supply-controlled token minting by:
/// 1. Reading the NFT's remaining supply from transaction inputs
/// 2. Reading the NFT's remaining supply from transaction outputs
/// 3. Ensuring the supply only decreases (incoming >= outgoing)
/// 4. Calculating the difference in token amounts between inputs and outputs
/// 5. Verifying that minted tokens exactly match the decrease in NFT supply
///
/// This creates a mechanism where the NFT acts as a "reserve" that controls
/// how many tokens can be minted - as tokens are minted, the NFT's remaining
/// supply decreases by the same amount.
///
/// # Arguments
///
/// * `token_app` - The token application context
/// * `tx` - The transaction attempting to mint tokens
///
/// # Returns
///
/// Returns `true` if tokens can be minted according to NFT supply constraints,
/// `false` otherwise.
///
/// # Validation Rules
///
/// - The managing NFT must be present in both inputs and outputs
/// - NFT remaining supply must not increase (incoming >= outgoing)
/// - Tokens minted must equal the decrease in NFT supply:
///   `(output_tokens - input_tokens) == (incoming_supply - outgoing_supply)`
fn can_mint_token(token_app: &App, tx: &Transaction) -> bool {
    let nft_app = App {
        tag: NFT,
        identity: token_app.identity.clone(),
        vk: token_app.vk.clone(),
    };

    let Some(nft_content): Option<NftContent> =
        charm_values(&nft_app, tx.ins.iter().map(|(_, v)| v)).find_map(|data| data.value().ok())
    else {
        eprintln!("could not determine incoming remaining supply");
        return false;
    };
    let incoming_supply = nft_content.remaining;

    let Some(nft_content): Option<NftContent> =
        charm_values(&nft_app, tx.outs.iter()).find_map(|data| data.value().ok())
    else {
        eprintln!("could not determine outgoing remaining supply");
        return false;
    };
    let outgoing_supply = nft_content.remaining;

    if !(incoming_supply >= outgoing_supply) {
        eprintln!("incoming remaining supply must be >= outgoing remaining supply");
        return false;
    }

    let Some(input_token_amount) = sum_token_amount(&token_app, tx.ins.iter().map(|(_, v)| v)).ok()
    else {
        eprintln!("could not determine input total token amount");
        return false;
    };
    let Some(output_token_amount) = sum_token_amount(&token_app, tx.outs.iter()).ok() else {
        eprintln!("could not determine output total token amount");
        return false;
    };

    // can mint no more than what's allowed by the managing NFT state change.
    output_token_amount - input_token_amount == incoming_supply - outgoing_supply
}
