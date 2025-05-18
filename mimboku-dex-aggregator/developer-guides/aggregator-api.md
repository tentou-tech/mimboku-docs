---
description: Query Superior Swap Rates
---

# Aggregator API

Mimboku Aggregator exposes a set of APIs that allows developers to easily query favourable rates for a swap. This includes additional swap data such as the exact swap route, swap routing parameters, as well as the encoded data to be submitted to the Aggregator [smart contract.](contracts/) Please refer to [Execute A Swap With The Aggregator API](execute-a-swap-with-the-aggregator-api.md) for examples on how to integrate with our APIs.

## Public API

<table><thead><tr><th width="202.9296875">Environment</th><th>URL</th></tr></thead><tbody><tr><td>Story mainnet</td><td><a href="https://router.mimboku.com/">https://router.mimboku.com</a></td></tr><tr><td>Story testnet (Aeneid)</td><td><a href="https://router-dev.mimboku.com">https://router-dev.mimboku.com</a></td></tr></tbody></table>

## Supported Networks

| Chain ID | Network              |
| -------- | -------------------- |
| 1315     | Aeneid Story Testnet |
| 1514     | Story Mainnet        |

## API Documentation

{% openapi-operation spec="mimboku-api" path="/quote" method="get" %}
[Broken link](broken-reference)
{% endopenapi-operation %}

### Example Request

{% code overflow="wrap" %}
```sh
curl --request GET 'https://router-dev.mimboku.com/quote?tokenInAddress=0x1514000000000000000000000000000000000000&tokenInChainId=1315&tokenOutAddress=0xd1fa5456186758b84811b929b4d696178fb56ee3&tokenOutChainId=1315&amount=100000000000&type=exactIn&protocols=v2,v3,v3s1'
```
{% endcode %}
