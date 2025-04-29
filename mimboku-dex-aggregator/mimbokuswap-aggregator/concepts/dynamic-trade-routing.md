---
description: Sourcing Optimal Liquidity For Your Trade
---

# Dynamic Trade Routing

<figure><img src="../../../.gitbook/assets/Route.png" alt=""><figcaption><p>Sourcing superior routes for your trade</p></figcaption></figure>

MimbokuSwap Aggregator has Dynamic Trade Routing, which aggregates fractured liquidity across DEXs thereby enabling users to source more capitally efficient liquidity to support their trades. Through integration with a myriad of DEX smart contracts, MimbokuSwap Aggregator is able to function as an optimisation layer between the DEXes smart contract and incoming trade requests. This ensures that users always get more optimal rates for any token swap, on any of the MimbokuSwap Aggregator supported networks.

MimbokuSwap trades are split and routed through different DEXs for the best prices within the same chain/network. Users can trade tokens that may not be in MimbokuSwap pools but are available on other DEXs. You can see exactly which DEXs were involved in the trade and the % split between them.

MimbokuSwap's DEX aggregator also provides the following benefits:

- **MimbokuSwap Ecosystem Gas Savings**: The MimbokuSwap Aggregator is able to generate additional gas savings for trades which are wholly routed via MimbokuSwap pools by optimizing the trade route internally.&#x20;
- **Fee on Transfer Savings**: MimbokuSwap Aggregator can also be configured to minimize the number of transfers. As a result, the gas fees associated with trading Fee on Transfer (FoT) tokens are also reduced. _In Fee on Transfer tokens, generally, a small portion of every transfer is either burnt or diverted to another wallet (i.e. tax). FoT tokens are common on the BSC chain._
