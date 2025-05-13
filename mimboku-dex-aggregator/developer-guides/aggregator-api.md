---
description: Query Superior Swap Rates
---

# Aggregator API

Mimboku Aggregator exposes a set of APIs that allows developers to easily query favourable rates for a swap. This includes additional swap data such as the exact swap route, swap routing parameters, as well as the encoded data to be submitted to the Aggregator [smart contract](../mimboku-aggregator/contracts/aggregator-contract-addresses.md). Please refer to [Execute A Swap With The Aggregator API ](../mimboku-aggregator/developer-guides/execute-a-swap-with-the-aggregator-api.md)for examples on how to integrate with our APIs.

## API Parameters

### GET /quote

Query parameters for getting swap quotes:

| Parameter       | Type   | Description                                                                                    | Example                                    |
| --------------- | ------ | ---------------------------------------------------------------------------------------------- | ------------------------------------------ |
| tokenInAddress  | string | Address of the input token                                                                     | 0x1514000000000000000000000000000000000000 |
| tokenInChainId  | number | Chain ID of the input token                                                                    | 1315                                       |
| tokenOutAddress | string | Address of the output token                                                                    | 0xd1fa5456186758b84811b929b4d696178fb56ee3 |
| tokenOutChainId | number | Chain ID of the output token                                                                   | 1315                                       |
| amount          | string | Amount of tokens to swap (in base units)                                                       | 100000000000                               |
| type            | string | Type of quote (exactIn or exactOut)                                                            | exactIn                                    |
| protocols       | string | Comma-separated list of protocols to include in the quote (v2, v3, v3s1, v4 don't support now) | v2,v3,v3s1                                 |

#### Example Request

```sh
curl --request GET 'https://router-dev.mimboku.com/quote?tokenInAddress=0x1514000000000000000000000000000000000000&tokenInChainId=1315&tokenOutAddress=0xd1fa5456186758b84811b929b4d696178fb56ee3&tokenOutChainId=1315&amount=100000000000&type=exactIn&protocols=v2,v3,v3s1'
```
