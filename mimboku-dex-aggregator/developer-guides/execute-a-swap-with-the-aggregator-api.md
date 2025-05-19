---
description: Interacting With Mimboku Aggregator Router Contract
---

# Execute A Swap With The Aggregator API

## Sequence diagram

<figure><img src="../../.gitbook/assets/Aggregator_API.png" alt=""><figcaption><p>API sequence diagram</p></figcaption></figure>

To execute a swap, the router (`MimbokuRouter`) contract requires the encoded swap data to be included as part of the transaction. This encoded swap data as well as other swap metadata are returned as part of the API response. As such, developers are expected to call the swap API prior to sending a transaction to the router contract.

## How to Call API for Quote and Swap Using JavaScript

Here is an example of how to call an API to get a quote and pass it to a smart contract for swapping:

1. **Fetch the Quote**: Use `fetch` or any HTTP client (e.g., Axios) to call the API endpoint for getting a quote.
2. **Prepare the Contract Interaction**: Use a library like `ethers.js` or `web3.js` to interact with the smart contract.
3. **Execute the Swap**: Pass the quote data to the contract's swap function.

### Example Code

```javascript
// Example: How to get a quote and perform a swap using ethers.js

import { ethers } from "ethers";
import abiMimbokuRouter from "@/abis/abi.json";

// 1. Get a quote from your backend or quote API
async function fetchQuote({
  tokenIn,
  tokenOut,
  amountIn,
  chainId,
  protocols
}) {
  // Replace with your actual quote API endpoint
  const res = await fetch(
    `https://your-quote-api/quote?tokenIn=${tokenIn}&tokenOut=${tokenOut}&amountIn=${amountIn}&chainId=${chainId}&protocols=${protocols}`
  );
  if (!res.ok) throw new Error("Failed to fetch quote");
  return await res.json();
}

// 2. Prepare ethers.js
const provider = new ethers.JsonRpcProvider("https://rpc-url");
const signer = provider.getSigner(); // Make sure wallet is connected
const routerAddress = "0x..."; // MimbokuRouter contract address

// Example tokens (replace with real addresses)
const tokenInAddress = "0x..."; // Token you want to sell
const tokenOutAddress = "0x..."; // Token you want to buy
const decimalsIn = 18; // Decimals for tokenIn
const decimalsOut = 18; // Decimals for tokenOut
const amountIn = ethers.parseUnits("1.0", decimalsIn); // Amount to swap

// 3. Get quote data
async function main() {
  // Get quote from API
  const quote = await fetchQuote({
    tokenIn: tokenInAddress,
    tokenOut: tokenOutAddress,
    amountIn: amountIn.toString(),
    chainId: 1514, // Replace with your chainId
    protocols: 'v2,v3,v3s1,mixed'
  });

  // Prepare swap params from quote
  // This assumes quote.route is an array of swap paths, similar to your dApp logic
  const swapParams = quote.route.map((path) => {
    const swapRoutes = path.map((step, idx) => {
      // --- Logic same as form-swap.tsx ---
      // Case 1: tokenIn is IP (native)
      if (quote.tokenInSymbol === "IP") {
        return {
          routerAddress: step.routerAddress,
          poolType: step.type,
          tokenIn: idx === 0 ? "0x0000000000000000000000000000000000000000" : step.tokenIn.address,
          tokenOut: step.tokenOut.address,
          fee: step.fee || 0
        };
      }
      // Case 2: tokenOut is IP (native)
      if (quote.tokenOutSymbol === "IP") {
        return {
          routerAddress: step.routerAddress,
          poolType: step.type,
          tokenIn: step.tokenIn.address,
          tokenOut: idx === path.length - 1 ? "0x0000000000000000000000000000000000000000" : step.tokenOut.address,
          fee: step.fee || 0
        };
      }
      // Default: ERC20 -> ERC20
      return {
        routerAddress: step.routerAddress,
        poolType: step.type,
        tokenIn: step.tokenIn.address,
        tokenOut: step.tokenOut.address,
        fee: step.fee || 0
      };
    });
    const amountInWithDecimals = ethers.BigNumber.from(path[0]?.amountIn?.toString() || "0");
    const amountOutWithDecimals = ethers.BigNumber.from(path[path.length - 1]?.amountOut || "0");
    // Calculate minimum amount out based on slippage (e.g. 0.5%)
    const slippage = 0.5;
    const amountOutMinimum = amountOutWithDecimals.mul(10000 - slippage * 100).div(10000);

    return {
      swapRoutes,
      recipient: quote.recipient, // or await signer.getAddress()
      deadline: Math.floor(Date.now() / 1000) + 60 * 20,
      amountIn: amountInWithDecimals,
      amountOutMinimum
    };
  });

  // 4. Handle swap cases
  const router = new ethers.Contract(routerAddress, abiMimbokuRouter, signer);

  // Case 1: Native token (IP) as tokenIn (send value)
  if (quote.tokenInSymbol === "IP") {
    const tx = await router.swapMultiroutes(swapParams, {
      gasLimit: 10000000,
      value: amountIn // Send value for native token
    });
    console.log("Tx hash:", tx.hash);
    await tx.wait();
    console.log("Swap Native(IP)->ERC20 successful!");
    return;
  }

  // Case 3: ERC 20-> Native token (IP) or ERC20 -> ERC20 (no value)
  if (quote.tokenInSymbol !== "IP" && quote.tokenOutSymbol !== "IP") {
    const tx = await router.swapMultiroutes(swapParams, {
      gasLimit: 10000000
      // No value needed
    });
    console.log("Tx hash:", tx.hash);
    await tx.wait();
    console.log("Swap ERC20->ERC20 successful!");
    return;
  }

  // Optionally, handle wrap/unwrap if needed (not shown here)
}

main().catch(console.error);

// Note:
// - For ERC20 swaps, make sure you have approved the router contract to spend your tokenIn before calling swapMultiroutes.
// - For native token swaps, pass the value field in the transaction options.
// - Always check the quote API and contract ABI for the latest parameter structure.
