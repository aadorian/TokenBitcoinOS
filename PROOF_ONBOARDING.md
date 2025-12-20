**Onboarding: Minting Workflow Explanation**

- **Overview:** Concise explanation of what the run did and why it matters.

**What happened (quick summary)**
- **Timestamp:** 2025-12-20T21:34:10.792341Z — an information log during the workflow run.
- **Command run:** `./workflow.sh` — orchestrates building, key generation, local Bitcoin checks, and a minting "spell".
- **Result:** A proof-building and a pair of signed raw transaction hex outputs were produced for a mint operation.

**Prerequisites**
- **Rust toolchain:** `cargo` installed and in PATH.
- **bitcoind:** Running and accessible (testnet/regtest as configured).
- **Wallet loaded:** `nftcharm_wallet` should be loaded in bitcoind.
- **Charms tooling:** Local `charms` binaries and spell templates available (repository includes `my-token/`).

**How to reproduce**
- Ensure `bitcoind` is running and `nftcharm_wallet` is loaded.
- From the repo root run:

```bash
./workflow.sh
```

The script will pause for 2 seconds between each step and display clear progress messages showing what action is being performed.

**Workflow steps**
1. Build the app and generate verification key
2. Setup Bitcoin environment (bitcoind + wallet)
3. Extract witness and funding UTXOs
4. Prepare and validate the spell with `charms spell check`
5. Generate proof and transactions with:
```bash
charms spell prove --funding-utxo <FUNDING_UTXO> --funding-utxo-value <FUNDING_UTXO_VALUE> --change-address <CHANGE_ADDRESS>
```
6. Sign the transactions with wallet:
```bash
bitcoin-cli signrawtransactionwithwallet "<TX_HEX>"
```
7. Submit the signed transaction package to Bitcoin network:
```bash
bitcoin-cli submitpackage '["<SIGNED_TX_HEX_1>", "<SIGNED_TX_HEX_2>"]'
```
8. Extract transaction IDs and display mempool URLs for verification on testnet4

**Key log entries explained**
- **CARGO_TARGET_DIR set/unset:** Controls where cargo builds; workflow temporarily sets it for the build.
- **charms is already installed / Spell template my-token already exists:** Confirms CLI tooling and template presence.
- **Building app and generating verification key... / app_vk exported:** The rust program (app) is built and its verification key (app_vk) is generated for the on-chain contract.
- **Checking if bitcoind is running / Wallet 'nftcharm_wallet' is already loaded:** Ensures node and wallet readiness.
- **Found unspent outputs:** Lists UTXOs available to use as witness and funding inputs — crucial for constructing transactions.
- **Exporting variables for envsubst / Substituted YAML:** The workflow composes a YAML spell describing apps, inputs, and outputs used by the minting spell.
- **Minting NFT with witness UTXO:** The mint operation uses a specific UTXO as the witness for the app contract.
- **app contract satisfied:** Confirms the app contract (identified by its app id and app_vk) was successfully satisfied; cycles spent indicate prover/resource usage.
- **Setting funding UTXO / change_address:** Funding UTXO chosen and change address computed for fees/change.
- **Running spell prove / prove_spell_tx logs:** The prove step generates the actual Bitcoin transaction(s) (two hex outputs shown). The long hex strings are signed raw transactions that can be broadcast.

**What the two hex objects are**
- They are JSON array items labeled `bitcoin` — each string is a serialized raw transaction hex. One may be a single-input provisional TX and the other the final combined transaction(s). They are safe to inspect locally with `bitcoin-cli -rpcwallet=nftcharm_wallet decoderawtransaction <hex>`.

**Transaction verification on Testnet4**
- After successful submission, the workflow displays transaction IDs and mempool.space URLs
- Example output:
```
Transaction 1 ID: abc123...
Mempool URL: https://mempool.space/testnet4/tx/abc123...

Transaction 2 ID: def456...
Mempool URL: https://mempool.space/testnet4/tx/def456...
```
- Use these URLs to track transaction confirmation status on the testnet4 blockchain explorer

**Checklist for a new user**
- **Confirm bitcoind:** `bitcoin-cli getblockchaininfo` returns status.
- **Confirm wallet:** `bitcoin-cli listwallets` includes `nftcharm_wallet`.
- **Inspect UTXOs:** `bitcoin-cli listunspent` to find available UTXOs used by the script.
- **Decode TXs:** Use `bitcoin-cli decoderawtransaction <hex>` to inspect outputs and scripts.
- **Track on mempool:** Visit the mempool.space URLs printed at the end to verify transaction propagation.

**Troubleshooting**
- If `bitcoind` isn't running: start it and ensure RPC credentials match repository config.
- If wallet missing: create and fund `nftcharm_wallet`, or update the workflow to point at a loaded wallet.
- If build fails: run `cargo build --release` inside `my-token/` to see compilation errors.
- If proofs fail due to network calls: check network connectivity and charms API URL in environment variables.

**Next steps**
- Decode and review the raw transactions for the mint outputs.
- Broadcast a test transaction on regtest/testnet if you want to complete the mint.
- If you'd like, I can copy this document into `PROOF.md` or add a brief step-by-step tutorial with exact `bitcoin-cli` commands for your environment.

---
Created to help a newcomer understand the workflow run and the important log entries. If you want this merged into `PROOF.md`, tell me and I'll patch it there.