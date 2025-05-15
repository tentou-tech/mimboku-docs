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

{% embed url="https://petstore.swagger.io/?url=https://raw.githubusercontent.com/tentou-tech/mimboku-docs/main/mimboku-dex-aggregator/developer-guides/swagger.yaml" %}
{% endembed %}

### Interactive Swagger Documentation

You can access our interactive Swagger documentation in three ways:

The Swagger UI allows you to:

- Explore all available endpoints
- Try out API calls directly in your browser
- View detailed request and response schemas
- Switch between testnet and mainnet environments

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
| chainId         | number | (Optional) The blockchain network ID to use for the swap                                       | 1315                                       |

#### Example Request

```sh
curl --request GET 'https://router-dev.mimboku.com/quote?tokenInAddress=0x1514000000000000000000000000000000000000&tokenInChainId=1315&tokenOutAddress=0xd1fa5456186758b84811b929b4d696178fb56ee3&tokenOutChainId=1315&amount=100000000000&type=exactIn&protocols=v2,v3,v3s1'
```

## Response Format

The API returns a JSON response with the following structure:

```json
{
  "blockNumber": "4172602",
  "amount": "10000000000000000000",
  "amountDecimals": "10",
  "quote": "23380751936294484817899",
  "quoteDecimals": "23380.751936294484817899",
  "quoteGasAdjusted": "23380750164225210864289",
  "quoteGasAdjustedDecimals": "23380.750164225210864289",
  "gasUseEstimateQuote": "1772069273953609",
  "gasUseEstimateQuoteDecimals": "0.001772069273953609",
  "gasUseEstimate": "783000",
  "gasUseEstimateUSD": "0.000003",
  "simulationStatus": "UNATTEMPTED",
  "simulationError": false,
  "gasPriceWei": "1000090",
  "route": [
    [
      {
        "type": "v3-pool",
        "address": "0x0bB8Df520A2c1Bf8B50D0a7b326a0Df295069431",
        "routerAddress": "0x1062916B1Be3c034C1dC6C26f682Daf1861A3909",
        "dexName": "Storyhunt V3",
        "tokenIn": {
          "chainId": 1514,
          "decimals": "18",
          "address": "0x1514000000000000000000000000000000000000",
          "symbol": "WIP"
        },
        "tokenOut": {
          "chainId": 1514,
          "decimals": "6",
          "address": "0xF1815bd50389c46847f0Bda824eC8da914045D14",
          "symbol": "USDC.e"
        },
        "fee": "500",
        "liquidity": "135625982168192",
        "sqrtRatioX96": "169947854912589181635456",
        "tickCurrent": "-261061",
        "amountIn": "10000000000000000000"
      },
      {
        "type": "v3-pool",
        "address": "0xFD061584f1F88F24fe11Dfa12B9D283afe2FC9F8",
        "routerAddress": "0x1062916B1Be3c034C1dC6C26f682Daf1861A3909",
        "dexName": "Storyhunt V3",
        "tokenIn": {
          "chainId": 1514,
          "decimals": "6",
          "address": "0xF1815bd50389c46847f0Bda824eC8da914045D14",
          "symbol": "USDC.e"
        },
        "tokenOut": {
          "chainId": 1514,
          "decimals": "18",
          "address": "0x25F9c9715d1D700A50B2a9A06D80FE9f98CcB549",
          "symbol": "BENJI"
        },
        "fee": "3000",
        "liquidity": "2343433408753810919",
        "sqrtRatioX96": "2173771765105307832558",
        "tickCurrent": "-348245",
        "amountOut": "23380751936294484817899"
      }
    ]
  ],
  "routeString": "[V3] 100.00% = WIP -- 0.05% [0x0bB8Df520A2c1Bf8B50D0a7b326a0Df295069431]USDC.e -- 0.3% [0xFD061584f1F88F24fe11Dfa12B9D283afe2FC9F8]BENJI",
  "quoteId": "2674a",
  "hitsCachedRoutes": false,
  "priceImpact": "61.75"
}
```

### Response Fields

| Field                       | Type    | Description                                                           |
| --------------------------- | ------- | --------------------------------------------------------------------- |
| blockNumber                 | string  | Current block number when quote was generated                         |
| amount                      | string  | Amount of tokens to be swapped (in base units)                        |
| amountDecimals              | string  | Amount with proper decimal formatting                                 |
| quote                       | string  | The quoted amount for the swap (in base units)                        |
| quoteDecimals               | string  | Quote with proper decimal formatting                                  |
| quoteGasAdjusted            | string  | Quote adjusted for gas costs (in base units)                          |
| quoteGasAdjustedDecimals    | string  | Gas-adjusted quote with proper decimal formatting                     |
| gasUseEstimate              | string  | Estimated gas usage for the swap                                      |
| gasUseEstimateQuote         | string  | Cost of gas in quote currency (in base units)                         |
| gasUseEstimateQuoteDecimals | string  | Gas cost with proper decimal formatting                               |
| gasUseEstimateUSD           | string  | Cost of gas in USD                                                    |
| simulationStatus            | string  | Status of the transaction simulation (UNATTEMPTED, SUCCEEDED, FAILED) |
| simulationError             | boolean | Whether there was an error during simulation                          |
| gasPriceWei                 | string  | Current gas price in wei                                              |
| route                       | array   | The route(s) for the swap, containing pools and tokens                |
| routeString                 | string  | Human-readable representation of the route                            |
| quoteId                     | string  | Unique identifier for this quote                                      |
| hitsCachedRoutes            | boolean | Whether the quote used cached route data                              |
| priceImpact                 | string  | Price impact of the swap as a percentage                              |
