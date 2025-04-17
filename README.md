## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Deployed Contract Addresses

### Testnets

| Network | PivotTopic                                 | TopicSBT                                   | TopicERC20                                 |
| ------- | ------------------------------------------ | ------------------------------------------ | ------------------------------------------ |
| Sepolia | 0xED26c1cb913A7E99936F69E76B569DD5eFa3b475 | 0x90Fe42b223Fa33Ae136A2ca0eE8db213756e5104 | 0x83F3c5020Ef0f44C8Ef4993124740D3fe8D1470C |

### Mainnets

| Network  | PivotTopic | TopicSBT |
| -------- | ---------- | -------- |
| Ethereum |            |          |
| Base     |            |          |
| Etica    |            |          |

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Topic.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
