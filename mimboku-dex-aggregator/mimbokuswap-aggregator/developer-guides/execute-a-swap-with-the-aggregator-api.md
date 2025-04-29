---
description: Interacting With MimbokuSwap Aggregator Router Contract
---

# Execute A Swap With The Aggregator API

## Overview

MimbokuSwap maintains a single API specification for chains:

- [Swap API specs for chains](../aggregator-api/swaps.md)

{% hint style="info" %}
**MimbokuSwap Aggregator API**

Following feedback on the initial non-versioned API, MimbokuSwap has implemented a more performant `[V1]` API which improves the response time for getting a route via offloading encoding requirements to the post method.

## Sequence diagram

<figure><img src="../../../.gitbook/assets/Aggregator_API.png" alt=""><figcaption><p>API sequence diagram</p></figcaption></figure>

To execute a swap, the router (`MimbokuRouter`) contract requires the encoded swap data to be included as part of the transaction. This encoded swap data as well as other swap metadata are returned as part of the API response. As such, developers are expected to call the swap API prior to sending a transaction to the router contract.

## How to Call API for Quote and Swap Using JavaScript

Here is an example of how to call an API to get a quote and pass it to a smart contract for swapping:

1. **Fetch the Quote**: Use `fetch` or any HTTP client (e.g., Axios) to call the API endpoint for getting a quote.

2. **Prepare the Contract Interaction**: Use a library like `ethers.js` or `web3.js` to interact with the smart contract.

3. **Execute the Swap**: Pass the quote data to the contract's swap function.

### Example Code

```javascript
// Step 1: Fetch the quote
async function getQuote(apiUrl, params, additionalParams) {
  const queryParams = { ...params, ...additionalParams };
  const response = await fetch(`${apiUrl}?${new URLSearchParams(queryParams)}`);
  if (!response.ok) {
    throw new Error('Failed to fetch quote');
  }
  return response.json();
}

// Step 2: Prepare and execute the swap
async function executeSwap(contractAddress, abi, provider, signer, quoteData, tokenIn, tokenOut, slippage, address) {
  const contract = new ethers.Contract(contractAddress, abi, signer);

  const deadline = Math.floor(Date.now() / 1000) + parseInt(quoteData.timeLimit || '20') * 60; // Use time limit from quoteData
  const allExecutionParams = quoteData.route.map((path) => {
    const swapRoutes = path.map((step, index) => ({
      routerAddress: step.routerAddress,
      poolType: step.type,
      tokenIn: index === 0 ? tokenIn.address : step.tokenIn.address,
      tokenOut: step.tokenOut.address,
      fee: step.fee || BigInt(0),
    }));

    const amountInWithDecimals = BigInt(path[0]?.amountIn?.toString() || '0');
    const amountOutWithDecimals = BigInt(path[path.length - 1]?.amountOut || '0');
    const amountOutMinimum =
      (amountOutWithDecimals * BigInt(10000 - parseFloat(slippage) * 100)) / BigInt(10000);

    return {
      swapRoutes,
      recipient: address,
      deadline,
      amountIn: amountInWithDecimals,
      amountOutMinimum,
    };
  });

  let tx;
  if (tokenIn.symbol === 'IP') {
    // Case: tokenIn is IP
    tx = await contract.swapMultiroutes(allExecutionParams, {
      value: ethers.utils.parseUnits(quoteData.amountIn, tokenIn.decimals || 18),
      gasLimit: ethers.BigNumber.from(10000000),
    });
  } else if (tokenOut.symbol === 'IP') {
    // Case: tokenOut is IP
    tx = await contract.swapMultiroutes(allExecutionParams, {
      gasLimit: ethers.BigNumber.from(10000000),
    });
  } else {
    // Default case
    tx = await contract.swapMultiroutes(allExecutionParams, {
      gasLimit: ethers.BigNumber.from(10000000),
    });
  }

  console.log('Transaction sent:', tx.hash);
  await tx.wait();
  console.log('Transaction confirmed:', tx.hash);
}

// Example usage
(async () => {
  const apiUrl = 'https://api.example.com/getQuote';
  const params = {
    tokenIn: '0xTokenInAddress',
    tokenOut: '0xTokenOutAddress',
    amountIn: '1000000000000000000', // 1 token (in wei)
  };
  const additionalParams = {
    slippage: '0.5', // 0.5% slippage
    timeLimit: '20', // 20 minutes
  };

  try {
    const quoteData = await getQuote(apiUrl, params, additionalParams);
    console.log('Quote received:', quoteData);

    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contractAddress = '0xYourContractAddress';
    const abi = [/* Contract ABI */];
    const tokenIn = { address: '0xTokenInAddress', decimals: 18, symbol: 'IP' }; // Example: tokenIn is IP
    const tokenOut = { address: '0xTokenOutAddress', decimals: 18, symbol: 'USDT' };
    const address = await signer.getAddress();

    await executeSwap(contractAddress, abi, provider, signer, quoteData, tokenIn, tokenOut, additionalParams.slippage, address);
  } catch (error) {
    console.error('Error:', error);
  }
})();
```

### Notes
- The `getQuote` function now accepts `additionalParams` to include extra query parameters.
- Ensure the API supports the additional parameters being passed.
- Test the function with the updated parameters to verify correctness.
