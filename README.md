# Polkadot Skills

Agent skills that teach your coding agent to build Polkadot apps with
[`@parity/product-sdk`](https://github.com/paritytech/product-sdk). Ask it to "build me a Polkadot app"
and it scaffolds one end to end. The other skills cover chain connection, transactions and signers,
contracts on Asset Hub, Cloud Storage, the Statement Store, personhood and usernames, NFTs, Pocket cards,
address and token utilities, and migrating an existing codebase.

## Build on the Devnet

The Polkadot Products Devnet is the public sandbox for building and publishing products.

- Pass `"devnet"` as the environment in the SDK.
- Fund your account at the [Polkadot faucet](https://faucet.polkadot.io/paseo?parachain=1000)
  (Paseo Asset Hub). Don't pick the "Next" chains: they belong to a different network.
- Open your app at [dev-dot.li](https://dev-dot.li) or in the Polkadot app's devnet builds.

Step-by-step guide: [Get started as a developer](https://docs.polkadotcommunity.foundation/getting-started/developers/).

## Install

| Agent | Install |
|---|---|
| Cursor, Copilot, OpenCode and other agents ([skills CLI](https://skills.sh)) | `npx skills add Polkadot-Community-Foundation/polkadot-skills` |
| Claude Code | `/plugin marketplace add Polkadot-Community-Foundation/polkadot-skills` then `/plugin install polkadot-skills@polkadot-community-foundation` |
| Codex | `codex plugin marketplace add Polkadot-Community-Foundation/polkadot-skills` |

## Skills

<!-- skills:start -->
From [`@parity/product-sdk@0.44.0`](https://github.com/paritytech/product-sdk/tree/a182639326d884a7a2a6909817da5656383cc316/product-sdk/skills):

- [`migrating-to-product-sdk`](skills/migrating-to-product-sdk/SKILL.md)
- [`product-sdk-app-builder`](skills/product-sdk-app-builder/SKILL.md)
- [`product-sdk-chain-connection`](skills/product-sdk-chain-connection/SKILL.md)
- [`product-sdk-cloud-storage`](skills/product-sdk-cloud-storage/SKILL.md)
- [`product-sdk-contracts`](skills/product-sdk-contracts/SKILL.md)
- [`product-sdk-individuality`](skills/product-sdk-individuality/SKILL.md)
- [`product-sdk-nfts`](skills/product-sdk-nfts/SKILL.md)
- [`product-sdk-pocket-cards`](skills/product-sdk-pocket-cards/SKILL.md)
- [`product-sdk-statement-store`](skills/product-sdk-statement-store/SKILL.md)
- [`product-sdk-transactions`](skills/product-sdk-transactions/SKILL.md)
- [`product-sdk-utilities`](skills/product-sdk-utilities/SKILL.md)
<!-- skills:end -->

## Source and updates

The product-sdk skills are written by Parity Technologies in
[paritytech/product-sdk](https://github.com/paritytech/product-sdk) and copied here unchanged from its
release tags. `upstream.json` records the tag, the commit and which folders in `skills/` come from
upstream. A weekly workflow opens a pull request when a new release ships. To fix one of those skills,
open an issue or pull request upstream.

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
