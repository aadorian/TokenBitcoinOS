Detected testnet4 network

==> Setting up temporary cargo target directory...
[1] CARGO_TARGET_DIR set to: /var/folders/6t/k7lwfnkx5ps6ts_rzr9535w00000gn/T/tmp.OmBA4Om6av/target

==> Checking if charms CLI is installed...
[2] charms is already installed

==> Checking for spell template (my-token)...
[3] Spell template my-token already exists

==> Navigating to my-token directory...
[4] Changed directory to my-token

==> Unsetting CARGO_TARGET_DIR...
[5] CARGO_TARGET_DIR unset

==> Updating cargo dependencies...
    Updating crates.io index
     Locking 0 packages to latest compatible versions
note: pass `--verbose` to see 1 unchanged dependencies behind latest

==> Building app and generating verification key...
    Finished `release` profile [optimized] target(s) in 0.05s
[7] Verification key:
175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649

==> Exporting verification key...
[8] app_vk exported: 175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649

==> Checking if bitcoind is running...
[9] bitcoind is already running

==> Checking for wallet (nftcharm_wallet)...
[10] Wallet 'nftcharm_wallet' is already loaded

==> Checking wallet balance...
[11] Wallet balance: 0.00050000 BTC

==> Checking for unspent outputs (UTXOs)...
[12] Found unspent outputs:
[
  {
    "txid": "f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941",
    "vout": 0,
    "address": "tb1pyry0g642yr7qlhe82qd342lr0aztywhth62lnjttxgks8wmgsc9svf9xx2",
    "label": "",
    "scriptPubKey": "512020c8f46aaa20fc0fdf27501b1aabe37f44b23aebbe95f9c96b322d03bb68860b",
    "amount": 0.00050000,
    "confirmations": 1,
    "spendable": true,
    "solvable": true,
    "desc": "tr([4a6148a4/86h/1h/0h/0/1]bd733fc28c319fad75e483f05e736fb220145ea29a0ef1e9ad9f51fbad322bad)#tux50xfx",
    "parent_descs": [
      "tr([4a6148a4/86h/1h/0h]tpubDCfbmpwgTaYAFT79PJgTF13HjugQgCLqDdqJajLiVcai9jguYqXii4reXjh5GGkDi6MY45PP6z9jHcpgFtEbZapMGVUQ2HiFKioPqSntB4s/0/*)#evnmk9mm"
    ],
    "safe": true
  }
]

==> Extracting UTXO values and computing app_id...
[13] in_utxo_0: f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0
[13] app_id: 2ed3939eceafa9cdd5495e224c64f20b17e517bb7629153f1d5b5b0e3e87d2f5
[13] addr_0: tb1pyry0g642yr7qlhe82qd342lr0aztywhth62lnjttxgks8wmgsc9svf9xx2

==> Getting raw transaction data...
[14] prev_txs (txid): f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941
[14] prev_txs (raw): 02000000000101ade04b805baf4ebd087c28063502e508867e2925441f82c3fc...

==> Exporting variables for spell template substitution...

==> Showing substituted YAML spell configuration...
[16] Substituted YAML:
version: 8

apps:
  $00: n/2ed3939eceafa9cdd5495e224c64f20b17e517bb7629153f1d5b5b0e3e87d2f5/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649

private_inputs:
  $00: "f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0"

ins:
  - utxo_id: f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0
    charms: {}

outs:
  - address: tb1pyry0g642yr7qlhe82qd342lr0aztywhth62lnjttxgks8wmgsc9svf9xx2
    charms:
      $00:
        ticker: MY-TOKEN
        remaining: 100000
==> Running spell check to validate configuration...
[17] Spell check result:
Minting NFT with witness UTXO: f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0
Transaction Input #0: UtxoId(f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0)
✅  app contract satisfied: n/2ed3939eceafa9cdd5495e224c64f20b17e517bb7629153f1d5b5b0e3e87d2f5/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649
cycles spent: [1382134]

==> Setting funding UTXO for transaction fees...
[18] Warning: Only one UTXO available, using the same one for funding
[18] funding_utxo: f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0
[18] funding_utxo_value: 50000 satoshis (0.00050000 BTC)

==> Getting change address for transaction outputs...
[19] change_address: tb1pfev6ppyv7lela6flykctj2rpa8sls2tm7zk8ccaug85g6dxvmdrsa5s9dq

==> Setting RUST_LOG environment variable...
[20] RUST_LOG set to: info

==> Running spell prove to generate proof and transactions...
[2m2025-12-21T01:27:03.048212Z[0m [32m INFO[0m [3mcharms_prove_api_url[0m[2m=[0m"https://v8.charms.dev/spells/prove"
[2m2025-12-21T01:27:03.061810Z[0m [32m INFO[0m [1mprove_spell_tx[0m: new
Minting NFT with witness UTXO: f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0
Transaction Input #0: UtxoId(f62d75e7c52c1929c63033b797947d8af0f4e720cc5d67be5198e24491818941:0)
✅  app contract satisfied: n/2ed3939eceafa9cdd5495e224c64f20b17e517bb7629153f1d5b5b0e3e87d2f5/175affa66db36da14c819c6e7396e5bc21d5315a878b4f6800f980e646c9e649
[2m2025-12-21T01:27:03.067585Z[0m [32m INFO[0m [1mprove_spell_tx[0m: [3mtotal_sats_in[0m[2m=[0m50000 [3mfunding_utxo_sats[0m[2m=[0m50000 [3mtotal_sats_out[0m[2m=[0m547 [3mcharms_fee[0m[2m=[0m0 [3mestimated_bitcoin_fee[0m[2m=[0m926
[2m2025-12-21T01:27:59.918840Z[0m [32m INFO[0m [1mprove_spell_tx[0m: close [3mtime.busy[0m[2m=[0m24.1ms [3mtime.idle[0m[2m=[0m56.8s
[21] Prove output:
[{"bitcoin":"02000000014189819144e29851be675dcc20e7f4f08a7d9497b73330c629192cc5e7752df60000000000ffffffff0172c20000000000002251200d532150603099f9f0e49a474d1b41ca4ef0ad839de4059c7fe6860397096ca200000000"},{"bitcoin":"020000000001024189819144e29851be675dcc20e7f4f08a7d9497b73330c629192cc5e7752df60000000000ffffffff5c351289a3fda7fac1153eca8cec6b46dcdf1c8708eedf7f861b24fc198f108d0000000000ffffffff03230200000000000022512020c8f46aaa20fc0fdf27501b1aabe37f44b23aebbe95f9c96b322d03bb68860bac050000000000001600141db4ded10fa155036bfb40717ea68022be899fbb837a0100000000002251204e59a0848cf7f3fee93f25b0b92861e9e1f8297bf0ac7c63bc41e88d34ccdb47000341548077f928072b50967f4b6e9e3e9307729cd5f3216ef9ef96aa59120c9583bf69b1e980e3a97eab41334b9835831b1ca5c11824ed0529596de82860df04885b81fdf0020063057370656c6c4d080282a36776657273696f6e08627478a1646f75747381a100a2667469636b6572684d592d544f4b454e6972656d61696e696e671a000186a0716170705f7075626c69635f696e70757473a183616e9820182e18d31893189e18ce18af18a918cd18d51849185e1822184c186418f20b1718e51718bb1876182915183f181d185b185b0e183e188718d218f5982017185a18ff18a6186d18b3186d18a1184c1881189c186e1873189618e518bc182118d51831185a1887188b184f18680018f9188018e6184618c918e61849f699010418a41859184c1859182d188218b60e18dc0e183f185418441888187e18e4182f020a18181873189f18da18e5183d18631889185e18e3184b1834185818ee18861880182a16184c18cf18bd189318ac18b618b20b18d6185c1863184618d018ce18801894183b18e8181f18ca189318bb18ac185618d718d218fe1821189f188d18ac06189b18cb18db189518c41118c1185f1894184d18e518e318cd18d718dc1823189a188f185418ff1824181818cb18a218aa1888182b18f3185e18fe18331618541821184c18c8188818b918b318bd18e6188f18a818891418bb18fe187318220018a018c6186418ff18a8181b18221856184618c218ae1852187d181f18831118450a187318331853188f1833186d183c185a12188c18dd183d189e182218a4187217184a18fb185518bd18cc188f18d1189d18b71861054cb8186e121829181e1861189018f1188a182f183718c618451861186b183c18d5182b18ca18de18d018891854183f1858189418a6188918bc18da18df18cd182118d218f418b31860189218d7182c18b118821858188c188618fe18a304188e18ba1844184118aa188218211318fa1828187118dd1869187818c205182d18fe18f318e0188f18c818a518d918b61819185a18c90b18f8185d18bf185118c81833186a182f183618261822182718a5183f18f9031824182718b66820bc9337e4dd9fd5c5407e5f784261e2f32497c6e08088ab75c1f6b0a177f6d609ac21c1bc9337e4dd9fd5c5407e5f784261e2f32497c6e08088ab75c1f6b0a177f6d60900000000"}]

==> Extracting transaction hexes from prove output...
[22] First transaction hex (first 64 chars): 02000000014189819144e29851be675dcc20e7f4f08a7d9497b73330c629192c...
[22] Second transaction hex (first 64 chars): 020000000001024189819144e29851be675dcc20e7f4f08a7d9497b73330c629...

==> Signing first transaction with wallet...
[23] Transaction 1 signing complete: true
[23] ✓ Transaction 1 signed successfully

==> Testing transaction 1 with mempool acceptance...
[23.5] Test result:
[
  {
    "txid": "8d108f19fc241b867fdfee08871cdfdc466bec8cca3e15c1faa7fda38912355c",
    "wtxid": "27948dcdcb7527ec7707c2e8e766fc55abd7732545dc4764905704d3cfdafb4b",
    "allowed": true,
    "vsize": 111,
    "fees": {
      "base": 0.00000222,
      "effective-feerate": 0.00002000,
      "effective-includes": [
        "27948dcdcb7527ec7707c2e8e766fc55abd7732545dc4764905704d3cfdafb4b"
      ]
    }
  }
]
[23.5] ✓ Transaction 1 passed mempool acceptance test

==> Submitting first transaction to Bitcoin network...
[24] Attempting to broadcast first transaction...
[24] ✓ First transaction submitted successfully: 8d108f19fc241b867fdfee08871cdfdc466bec8cca3e15c1faa7fda38912355c

==> Signing second transaction with wallet...
99c87e74dfb50db7fac0ed41ed640dd62ec4d97e77aca70a60ed57edcd89485b