# Deployed Contracts

The information of MimbokuRouter Aggregator contracts and their respective explorers can be found below:

## Mimboku Router

`MimbokuRouter` is a smart contract that facilitates token swaps, handling both ERC20 tokens and native token on multi-dexs. It acts as an intermediary that routes swap requests through an executor contract which performs the actual swaps.

### Contract deployed address

| **Network** |                                                               **Address**                                                              |
| :---------: | :------------------------------------------------------------------------------------------------------------------------------------: |
|    Aeneid   | [0x6205da3e7f7233AaE627CaB247A39829a28A73Fb](https://www.storyscan.io/address/0x5d23a4639f8f72A7bF4a33Fd74351cCfFF08C191?tab=contract) |
|    Story    |        [0x5d23a4639f8f72A7bF4a33Fd74351cCfFF08C191](https://www.storyscan.io/address/0x5d23a4639f8f72A7bF4a33Fd74351cCfFF08C191)       |

### Description

The contract provides 2 main functions:

* `swapMultiroutes`:
  * Executes swaps across multiple paths in a single transaction
  * Handles both ERC20 and native token swaps
  * Returns output amounts for each swap
* `swap`:
  * Executes a single path swap
  * Handles token transfers from the user to the executor
  * Supports both native and ERC20 token inputs

The data structure for the parameters for the `swapMultiroutes` and `swap` functions is as follows:

```solidity
    enum PoolType {
        V2Pool,
        V3Pool
    }

    struct SwapRoute {
        address routerAddress;
        PoolType poolType;
        address tokenIn;
        address tokenOut;
        uint24 fee;
    }

    struct ExactInputParams {
        SwapRoute[] swapRoutes;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
```
