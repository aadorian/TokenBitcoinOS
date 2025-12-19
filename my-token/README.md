This is a [Charms](https://charms.dev) app.

It is a simple fungible token managed by a reference NFT. The NFT has a state that specifies the remaining total supply of the tokens available to mint. If you control the NFT, you can mint new tokens.

## Documentation

The codebase includes comprehensive rustdoc documentation covering:
- Module-level overview of the NFT and token contract system
- Detailed function documentation with arguments, returns, and validation rules
- Examples and usage patterns
- Contract features and supply management mechanisms

To generate and view the documentation:

```sh
cargo doc --open
```

This will build the HTML documentation and open it in your default browser, providing detailed information about all public APIs, internal functions, and the contract logic.

### Documentation Commands

| Command | Action |
|---------|--------|
| `cargo doc` | Generates documentation for your project and all dependencies. |
| `cargo doc --open` | Generates the docs and immediately opens them in your default browser. |
| `cargo doc --no-deps` | Generates docs only for your local crate, skipping dependencies (faster). |
| `cargo test --doc` | Runs the code examples inside your documentation to ensure they actually work! |

## Installation

NOTE: you may need to install Wasm WASI P1 support:


```sh
rustup target add wasm32-wasip1
```

## Building

Build with:
```sh
cargo update
app_bin=$(charms app build)
```

The resulting Wasm binary will show up at `./target/wasm32-wasip1/release/my-token.wasm`.

Get the verification key for the app with:
```sh
charms app vk $app_bin
```

## Testing

### Unit Tests

The project includes comprehensive unit tests covering:
- Hash function correctness and consistency
- NftContent serialization/deserialization
- Edge cases (zero supply, max supply, empty tickers)
- Data structure integrity (Clone, Debug traits)

Tests are organized in the `tests/` directory:
- `tests/integration_tests.rs` - Integration tests for public API

Run the tests with:

```sh
cargo test
```

Run specific test file:

```sh
cargo test --test integration_tests
```

For verbose output:

```sh
cargo test -- --nocapture
```

### Integration Testing

Test the app with a simple NFT mint example:

```sh
export app_vk=$(charms app vk)

# set to a UTXO you're spending (you can see what you have by running `b listunspent`)
export in_utxo_0="d8fa4cdade7ac3dff64047dc73b58591ebe638579881b200d4fea68fc84521f0:0"

export app_id=$(echo -n "${in_utxo_0}" | sha256sum | cut -d' ' -f1)
export addr_0="tb1p3w06fgh64axkj3uphn4t258ehweccm367vkdhkvz8qzdagjctm8qaw2xyv"

prev_txs=02000000000101a3a4c09a03f771e863517b8169ad6c08784d419e6421015e8c360db5231871eb0200000000fdffffff024331070000000000160014555a971f96c15bd5ef181a140138e3d3c960d6e1204e0000000000002251207c4bb238ab772a2000906f3958ca5f15d3a80d563f17eb4123c5b7c135b128dc0140e3d5a2a8c658ea8a47de425f1d45e429fbd84e68d9f3c7ff9cd36f1968260fa558fe15c39ac2c0096fe076b707625e1ae129e642a53081b177294251b002ddf600000000

cat ./spells/mint-nft.yaml | envsubst | charms spell check --prev-txs=${prev_txs} --app-bins=${app_bin}
```
