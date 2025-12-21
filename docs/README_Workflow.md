# Detailed Use Case: Minting and Applying Spell Transactions with workflow.sh

## Actors

- **Developer:** Mints spell transactions (NFTs/tokens) and manages workflows.
- **User:** Applies minted transactions on the Bitcoin network.

---

## Preconditions

- Developer has access to TokenBitcoinOS CLI, spell YAML templates, and workflow.sh.
- User has a Bitcoin wallet and access to minted transaction data.

---

## Main Flow

### 1. Developer: Minting a Spell Transaction

#### Action 1: Create Spell Configuration
- **User Action:** Developer writes a spell configuration in a YAML file (e.g., `mint-nft.yaml`).
- **System Response:** System saves the YAML file and makes it available for validation and minting.

#### Action 2: Validate Spell Configuration
- **User Action:** Developer runs the linting script (`lint.sh`) to check the YAML file.
- **System Response:** System parses the YAML, checks for errors, and returns validation results (success or error details).

#### Action 3: Mint Spell Transaction
- **User Action:** Developer executes the mint command via CLI, specifying the YAML file.
- **System Response:** System reads the configuration, constructs the transaction payload, and returns a summary (transaction ID, asset details).

#### Action 4: Export or Broadcast Transaction
- **User Action:** Developer chooses to export the transaction file or broadcast it directly to the Bitcoin network.
- **System Response:** 
  - If exported: System saves the transaction payload for user access.
  - If broadcast: System attempts to send the transaction to the Bitcoin network and returns broadcast status (success, failure, or error message).

---

### 2. User: Applying the Minted Transaction

#### Action 1: Receive Transaction Payload
- **User Action:** User obtains the transaction payload (file or direct broadcast).
- **System Response:** System provides the transaction details (asset type, amount, sender, receiver).

#### Action 2: Verify Transaction
- **User Action:** User reviews the transaction details for accuracy and legitimacy.
- **System Response:** System displays transaction metadata and validation status.

#### Action 3: Apply/Broadcast Transaction
- **User Action:** User uses their Bitcoin wallet or CLI to broadcast the transaction to the network.
- **System Response:** System submits the transaction, returns network response (confirmation, rejection, or pending status).

#### Action 4: Confirm Asset Ownership
- **User Action:** User checks their wallet or asset explorer for the new NFT/token.
- **System Response:** System updates the wallet balance and asset list, confirming ownership.

#### Action 5: Interact with Asset
- **User Action:** User transfers, trades, or utilizes the asset as desired.
- **System Response:** System processes further transactions and updates asset status accordingly.

---

## Special Workflow: Using workflow.sh

### Purpose

`workflow.sh` is a shell script designed to automate and orchestrate the main steps of minting and applying spell transactions. It streamlines the developer experience by chaining together validation, minting, and broadcasting actions.

### Detailed Interaction

#### Step 1: Initiate Workflow
- **User Action:** Developer runs `./workflow.sh` from the project root.
- **System Response:** Script starts, displays initial instructions or options.

#### Step 2: Validate Spell Files
- **User Action:** Developer selects or confirms the spell YAML file to use.
- **System Response:** Script calls `lint.sh` to validate the YAML file, displays validation results (success or error details).

#### Step 3: Mint Transaction
- **User Action:** Developer confirms to proceed with minting if validation passes.
- **System Response:** Script invokes the minting CLI command, processes the YAML, and outputs transaction details (ID, asset type, amount).

#### Step 4: Broadcast or Export Transaction
- **User Action:** Developer chooses to broadcast the transaction or export it for manual application.
- **System Response:** 
  - If broadcast: Script sends the transaction to the Bitcoin network, displays broadcast status (success, failure, or error).
  - If export: Script saves the transaction payload to a file, displays file location.

#### Step 5: Completion and Next Steps
- **User Action:** Developer reviews the final output and instructions for user application.
- **System Response:** Script summarizes the workflow, provides guidance for users to apply the transaction (e.g., file location, next CLI command).

---

## Example workflow.sh Session

1. **Run Script:**  
   `./workflow.sh`
2. **System:**  
   "Welcome to TokenBitcoinOS workflow. Please enter the spell YAML file to process:"
3. **User:**  
   `spells/mint-nft.yaml`
4. **System:**  
   "Validating mint-nft.yaml..."  
   "Validation successful."
5. **System:**  
   "Minting transaction..."  
   "Transaction minted: txid=abc123, asset=NFT, amount=1"
6. **System:**  
   "Do you want to broadcast this transaction? (y/n)"
7. **User:**  
   `y`
8. **System:**  
   "Broadcasting transaction..."  
   "Transaction broadcasted successfully. txid=abc123"
9. **System:**  
   "Workflow complete. User can now apply or verify the transaction on the Bitcoin network."

---

## Alternate Flows

- **Invalid YAML:** System returns error details; developer must correct and retry.
- **Broadcast Failure:** System returns error message; user may retry or seek support.
- **Asset Not Received:** System provides troubleshooting steps or support contact.

---

## Postconditions

- Spell transaction is minted and applied on the Bitcoin network.
- User owns and can interact with the new asset.
- workflow.sh provides a streamlined, automated process for developers.
