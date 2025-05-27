# Deployed Contracts

The information of MimbokuRouter Aggregator contracts and their respective explorers can be found below:

## Mimboku Router

`MimbokuRouter` is a smart contract that facilitates token swaps, handling both ERC20 tokens and native token on multi-dexs. It acts as an intermediary that routes swap requests through an executor contract which performs the actual swaps.

### Contract deployed address

| **Network** |                                                               **Address**                                                              |
| :---------: | :------------------------------------------------------------------------------------------------------------------------------------: |
|    Aeneid   |      [0x8Cc67A90074277E59aaB2927089F1D324D5E1b0a](https://aeneid.storyscan.io/address/0x8Cc67A90074277E59aaB2927089F1D324D5E1b0a)      |
|    Story    | [0x852143a47Ac710a851B5117Cbb927bdcd3744e64](https://www.storyscan.io/address/0x852143a47Ac710a851B5117Cbb927bdcd3744e64?tab=contract) |

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
