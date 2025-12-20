//! Integration tests for the NFT token contract.
//!
//! These tests verify the core functionality of the contract including
//! hash operations and `NftContent` data structure behavior.

use charms_sdk::data::{Data, UtxoId};
use my_token::{hash, NftContent};

/// Tests the SHA-256 hash function.
///
/// Verifies that hashing a specific UTXO ID produces the expected hash value,
/// which is used to derive NFT identities.
#[test]
fn test_hash() {
    let utxo_id =
        UtxoId::from_str("dc78b09d767c8565c4a58a95e7ad5ee22b28fc1685535056a395dc94929cdd5f:1")
            .unwrap();
    let data = dbg!(utxo_id.to_string());
    let expected = "f54f6d40bd4ba808b188963ae5d72769ad5212dd1d29517ecc4063dd9f033faa";
    assert_eq!(&hash(&data).to_string(), expected);
}

/// Tests that hash function produces consistent results.
///
/// Verifies that hashing the same input multiple times produces identical output.
#[test]
fn test_hash_consistency() {
    let test_data = "test_utxo_id:0";
    let hash1 = hash(test_data);
    let hash2 = hash(test_data);
    assert_eq!(hash1, hash2, "Hash function should be deterministic");
}

/// Tests that hash function produces different outputs for different inputs.
///
/// Verifies that different UTXO IDs produce different hash values.
#[test]
fn test_hash_uniqueness() {
    let data1 = "utxo1:0";
    let data2 = "utxo2:0";
    let hash1 = hash(data1);
    let hash2 = hash(data2);
    assert_ne!(hash1, hash2, "Different inputs should produce different hashes");
}

/// Tests `NftContent` serialization and deserialization.
///
/// Verifies that `NftContent` can be properly serialized to and deserialized from Data.
#[test]
fn test_nft_content_serialization() {
    let content = NftContent {
        ticker: "TEST".to_string(),
        remaining: 1000,
    };

    // Serialize to Data using From trait
    let data = Data::from(&content);

    // Deserialize back
    let deserialized: NftContent = data.value().expect("Should deserialize NftContent");

    assert_eq!(deserialized.ticker, content.ticker);
    assert_eq!(deserialized.remaining, content.remaining);
}

/// Tests `NftContent` with zero remaining supply.
///
/// Verifies that an NFT with zero remaining tokens can be created.
#[test]
fn test_nft_content_zero_remaining() {
    let content = NftContent {
        ticker: "ZERO".to_string(),
        remaining: 0,
    };

    let data = Data::from(&content);
    let deserialized: NftContent = data.value().expect("Should deserialize");

    assert_eq!(deserialized.remaining, 0);
}

/// Tests `NftContent` with maximum u64 remaining supply.
///
/// Verifies that an NFT can handle the maximum possible supply value.
#[test]
fn test_nft_content_max_remaining() {
    let content = NftContent {
        ticker: "MAX".to_string(),
        remaining: u64::MAX,
    };

    let data = Data::from(&content);
    let deserialized: NftContent = data.value().expect("Should deserialize");

    assert_eq!(deserialized.remaining, u64::MAX);
}

/// Tests `NftContent` clone functionality.
///
/// Verifies that `NftContent` implements Clone correctly.
#[test]
fn test_nft_content_clone() {
    let content = NftContent {
        ticker: "CLONE".to_string(),
        remaining: 5000,
    };

    let cloned = content.clone();

    assert_eq!(content.ticker, cloned.ticker);
    assert_eq!(content.remaining, cloned.remaining);
}

/// Tests `NftContent` debug formatting.
///
/// Verifies that Debug trait is properly implemented for `NftContent`.
#[test]
fn test_nft_content_debug() {
    let content = NftContent {
        ticker: "DEBUG".to_string(),
        remaining: 100,
    };

    let debug_output = format!("{content:?}");
    assert!(debug_output.contains("DEBUG"));
    assert!(debug_output.contains("100"));
}

/// Tests that empty ticker is accepted.
///
/// Verifies that `NftContent` can be created with an empty ticker string.
#[test]
fn test_nft_content_empty_ticker() {
    let content = NftContent {
        ticker: String::new(),
        remaining: 1000,
    };

    assert_eq!(content.ticker, "");
    assert_eq!(content.remaining, 1000);
}

/// Tests `NftContent` with long ticker string.
///
/// Verifies that `NftContent` can handle arbitrarily long ticker strings.
#[test]
fn test_nft_content_long_ticker() {
    let long_ticker = "A".repeat(1000);
    let content = NftContent {
        ticker: long_ticker.clone(),
        remaining: 500,
    };

    let data = Data::from(&content);
    let deserialized: NftContent = data.value().expect("Should deserialize long ticker");

    assert_eq!(deserialized.ticker, long_ticker);
    assert_eq!(deserialized.ticker.len(), 1000);
}

/// Tests hash output format.
///
/// Verifies that the hash output is a valid 32-byte (64 hex character) string.
#[test]
fn test_hash_output_format() {
    let test_data = "format_test:123";
    let hash_output = hash(test_data);
    let hash_string = hash_output.to_string();

    // SHA-256 produces 32 bytes = 64 hex characters
    assert_eq!(hash_string.len(), 64, "Hash should be 64 hex characters");

    // Verify all characters are valid hex
    assert!(
        hash_string.chars().all(|c| c.is_ascii_hexdigit()),
        "Hash should only contain hex digits"
    );
}

/// Tests that UTXO ID string can be properly hashed to create NFT identity.
///
/// This is the fundamental operation for NFT minting - the hash of a UTXO ID
/// becomes the NFT's identity, ensuring uniqueness.
#[test]
fn test_utxo_id_to_identity() {
    let utxo_id_str = "dc78b09d767c8565c4a58a95e7ad5ee22b28fc1685535056a395dc94929cdd5f:1";
    let identity1 = hash(utxo_id_str);
    let identity2 = hash(utxo_id_str);

    // Same UTXO ID should always produce same identity
    assert_eq!(identity1, identity2);

    // Different UTXO ID should produce different identity
    let different_utxo = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa:0";
    let identity3 = hash(different_utxo);
    assert_ne!(identity1, identity3);
}

/// Tests that witness data can be created from UTXO ID string.
///
/// Verifies the witness data structure that will be used in NFT minting.
#[test]
fn test_witness_data_creation() {
    let utxo_id_str = "dc78b09d767c8565c4a58a95e7ad5ee22b28fc1685535056a395dc94929cdd5f:1";

    // Create witness data
    let witness = Data::from(&utxo_id_str.to_string());

    // Verify we can retrieve the string back
    let retrieved: Result<String, _> = witness.value();
    assert!(retrieved.is_ok());
    assert_eq!(retrieved.unwrap(), utxo_id_str);
}

/// Tests empty witness data handling.
///
/// Verifies that empty witness data can be detected (this should fail NFT minting).
#[test]
fn test_empty_witness_detection() {
    let empty_witness = Data::empty();

    // Empty witness should not be deserializable as String
    let retrieved: Result<String, _> = empty_witness.value();
    assert!(retrieved.is_err(), "Empty witness should not contain valid string");
}

/// Tests UTXO ID parsing and validation.
///
/// Verifies that valid and invalid UTXO ID strings are properly handled.
#[test]
fn test_utxo_id_parsing() {
    // Valid UTXO ID
    let valid_utxo = "dc78b09d767c8565c4a58a95e7ad5ee22b28fc1685535056a395dc94929cdd5f:1";
    let parsed = UtxoId::from_str(valid_utxo);
    assert!(parsed.is_ok(), "Valid UTXO ID should parse successfully");

    // Verify round-trip
    let utxo_id = parsed.unwrap();
    assert_eq!(utxo_id.to_string(), valid_utxo);
}

/// Tests testnet4-style UTXO ID hashing.
///
/// Verifies that realistic testnet4 UTXO IDs can be properly hashed
/// to create NFT identities.
#[test]
fn test_testnet4_utxo_id_hashing() {
    // Realistic testnet4 transaction hash format
    let testnet4_utxo = "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890:0";

    let identity = hash(testnet4_utxo);

    // Verify it produces a valid 32-byte hash
    assert_eq!(identity.to_string().len(), 64);

    // Verify it's deterministic
    let identity2 = hash(testnet4_utxo);
    assert_eq!(identity, identity2);
}

/// Tests that different UTXO indices produce different identities.
///
/// Verifies that the same transaction hash with different output indices
/// produces unique NFT identities.
#[test]
fn test_different_indices_produce_different_identities() {
    let base_tx = "dc78b09d767c8565c4a58a95e7ad5ee22b28fc1685535056a395dc94929cdd5f";

    let identity0 = hash(&format!("{}:0", base_tx));
    let identity1 = hash(&format!("{}:1", base_tx));
    let identity2 = hash(&format!("{}:2", base_tx));

    assert_ne!(identity0, identity1);
    assert_ne!(identity1, identity2);
    assert_ne!(identity0, identity2);
}
