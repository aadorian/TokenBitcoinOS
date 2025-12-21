
## How the Final Mint Works

Since your previous transaction left you with an NFT Change UTXO containing 30,580 tokens, your next "Spell" would look like this:

Input: The UTXO from your last transaction (785723...:0).

Action: Mint the final 30,580.

Result: * New Token UTXO: 30,580 MY-TOKEN.

NFT State: 0 remaining.

# Point to the UTXO that currently holds the 30,580 remaining supply
export in_utxo_1="785723a522be1dfcd3cf0efe7c878d010d8ac792da4f98e6bb1a6e8fabf70042:0"

# This remains the same as your original setup
export original_witness_utxo="b8471ec2c860a12e78a97409e8c43e5498456799a379e86f61af63c7a766044d:2"

# Execute the mint
./mint-tokens.sh
Step 2: What to expect in the outputWhen the "Spell" is generated this time, pay close attention to the outs: section in the log. It should look like this:Address 1 (Your Wallet): charms: $01: 30580 (The final tokens arrive).Address 2 (The NFT Change): charms: $00: remaining: 0 (The factory is now empty).Step 3: Verifying the "Death" of the MintOnce this transaction clears:The Master NFT UTXO is spent.If you try to run ./mint-tokens.sh again, the script will fail with an error like UTXO already spent or Insufficient supply.The ZK-Proof will no longer validate because $0 - 1$ (trying to mint more) would result in a negative number, which the "App VK" logic forbids.

---------

user@192 NFTCharm % export in_utxo_1="785723a522be1dfcd3cf0efe7c878d010d8ac792da4f98e6bb1a6e8fabf70042:0"
user@192 NFTCharm % export original_witness_utxo="b8471ec2c860a12e78a97409e8c43e5498456799a379e86f61af63c7a766044d:2"
user@192 NFTCharm % ./mint-tokens.sh
==========================================
NFTCharm Token Minting
==========================================

Checking Bitcoin Core status...
✓ Bitcoin Core is running
Network: testnet4

Loading wallet...
✓ Wallet already loaded

Getting app details...
    Finished `release` profile [optimized] target(s) in 0.11s
App ID: 22e56e28b9b2c48dd0292d7f2d546fd651aa741aacdd863f0f5161d6a214fa4e
App VK: 175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649

NFT UTXO: b8471ec2c860a12e78a97409e8c43e5498456799a379e86f61af63c7a766044d:0
Token output address: tb1px6jrge3dynx9tjp6vwp7xrq9a3gm9dqpz9jts4jezhvlulayvrqq9rcrz3
NFT change address: tb1p40c5eywchazxa4t3jdytnc39c3g8l2tzegzk7zgrzcdm324xce3qww4eud

Fetching NFT transaction...
✓ NFT transaction fetched

Mint Spell:
============================================
version: 8

apps:
  $00: n/22e56e28b9b2c48dd0292d7f2d546fd651aa741aacdd863f0f5161d6a214fa4e/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649
  $01: t/22e56e28b9b2c48dd0292d7f2d546fd651aa741aacdd863f0f5161d6a214fa4e/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649

ins:
  - utxo_id: b8471ec2c860a12e78a97409e8c43e5498456799a379e86f61af63c7a766044d:0
    charms:
      $00:
        ticker: MY-TOKEN
        remaining: 100000

outs:
  - address: tb1px6jrge3dynx9tjp6vwp7xrq9a3gm9dqpz9jts4jezhvlulayvrqq9rcrz3
    charms:
      $01: 69420
  - address: tb1p40c5eywchazxa4t3jdytnc39c3g8l2tzegzk7zgrzcdm324xce3qww4eud
    charms:
      $00:
        ticker: MY-TOKEN
        remaining: 30580============================================

Validating spell...
condition does not hold: w_str.is_some()
✅  app contract satisfied: n/22e56e28b9b2c48dd0292d7f2d546fd651aa741aacdd863f0f5161d6a214fa4e/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649
✅  app contract satisfied: t/22e56e28b9b2c48dd0292d7f2d546fd651aa741aacdd863f0f5161d6a214fa4e/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649
cycles spent: [1624150, 1529863]
✓ Spell valid

Getting funding UTXO...
Funding: 785723a522be1dfcd3cf0efe7c878d010d8ac792da4f98e6bb1a6e8fabf70042:2 (0.01286757 BTC)
Change address: tb1prkp4jkz8vg3ewkufp3uh7ka7ge0rqdtjt8ntx3azz9s33t79k42s244qrp

Generating proof and transactions...
2025-12-21T19:03:08.343708Z  INFO charms_prove_api_url="https://v8.charms.dev/spells/prove"
2025-12-21T19:03:08.350291Z  INFO prove_spell_tx: new
condition does not hold: w_str.is_some()
✅  app contract satisfied: n/22e56e28b9b2c48dd0292d7f2d546fd651aa741aacdd863f0f5161d6a214fa4e/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649
✅  app contract satisfied: t/22e56e28b9b2c48dd0292d7f2d546fd651aa741aacdd863f0f5161d6a214fa4e/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649
2025-12-21T19:03:08.552215Z  INFO prove_spell_tx: total_sats_in=547 funding_utxo_sats=1286757 total_sats_out=1094 charms_fee=0 estimated_bitcoin_fee=1122
2025-12-21T19:04:48.922525Z  INFO prove_spell_tx: close time.busy=218ms time.idle=100s

Signing transaction 1...
Broadcasting transaction 1...
✓ TX1: e20572b13dc900ebbf7b42fda56b156377f01153a4b505d9dc9594c439fd93fd

Signing transaction 2...
Broadcasting transaction 2...
✓ TX2: d6e5f0212be34134ae51e0a595aa573e68a948f79d634175430888183bdf92c5

==========================================
✓ Token Minting Complete!
==========================================
Commit TX: e20572b13dc900ebbf7b42fda56b156377f01153a4b505d9dc9594c439fd93fd
Spell TX:  d6e5f0212be34134ae51e0a595aa573e68a948f79d634175430888183bdf92c5

Minted 69,420 tokens to: tb1px6jrge3dynx9tjp6vwp7xrq9a3gm9dqpz9jts4jezhvlulayvrqq9rcrz3
NFT with 30,580 remaining to: tb1p40c5eywchazxa4t3jdytnc39c3g8l2tzegzk7zgrzcdm324xce3qww4eud

To find your token UTXO, run:
  bitcoin-cli -testnet4 -rpcwallet="nftcharm_wallet" listunspent

The token UTXO will be: d6e5f0212be34134ae51e0a595aa573e68a948f79d634175430888183bdf92c5:0
Use this UTXO in transfer-tokens.sh
==========================================
user@192 NFTCharm % 