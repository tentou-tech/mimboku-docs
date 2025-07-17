---
description: Interacting With Mimboku Aggregator Router Contract
---

# Execute A Swap With The Aggregator API

## Sequence diagram

<figure><img src="../../.gitbook/assets/Aggregator_API.png" alt=""><figcaption><p>API sequence diagram</p></figcaption></figure>

To execute a swap, the router (`MimbokuRouter`) contract requires the encoded swap data to be included as part of the transaction. This encoded swap data as well as other swap metadata are returned as part of the API response. As such, developers are expected to call the swap API prior to sending a transaction to the router contract.

# JavaScript API Integration Guide

This guide shows how to integrate with the Mimboku DEX Aggregator using vanilla JavaScript and ethers.js.

## Prerequisites

```bash
npm install ethers viem @wagmi/core
```

## Setup

```javascript
import { ethers } from "ethers";
import { encodeFunctionData, erc20Abi, maxUint256 } from "viem";
import { estimateGas, prepareTransactionRequest, waitForTransactionReceipt } from '@wagmi/core';
import abiMimbokuRouter from "./abis/abi.json";
import abi1514 from "./abis/0x1514000000000000000000000000000000000000.json";

// Contract addresses
const ROUTER_ADDRESS = "0x..."; // Replace with MimbokuRouter address
const WRAP_CONTRACT_ADDRESS = "0x1514000000000000000000000000000000000000";

// Initialize provider and signer
const provider = new ethers.JsonRpcProvider("https://your-rpc-url");
const signer = provider.getSigner();

## Helper Functions

```javascript
// Map pool types to numbers
function mapPoolType(type) {
  if (type.includes('v2')) {
    return 1;
  }
  // if (type.includes('v3')) {
  return 2;
}

## 1. Fetch Quote from API

```javascript
async function fetchQuote({
  tokenIn,
  tokenOut,
  amountIn,
  chainId = 1514,
  tradeType = 'exactIn',
  protocols = 'v2,v3,v3s1'
}) {

  const amountInWithDecimals = ethers.parseUnits(
                amountIn,
                Number(tokenIn?.decimals) || 18
            );

  const params = new URLSearchParams({
    tokenInAddress: tokenIn.address,
    tokenInChainId: chainId.toString(),
    tokenOutAddress: tokenOut.address,
    tokenOutChainId: chainId.toString(),
    amount: amountInWithDecimals.toString(),
    type: tradeType,
    protocols: protocols
  });

  const response = await fetch(`https://router-dev.mimboku.com/quote?${params}`);
  /* ex: 
 https://router-dev.mimboku.com/quote?  tokenInAddress=0x0000000000000000000000000000000000000000&tokenInChainId=1315&tokenOutAddress=0x3d05fd5240e30525b7dcf38683084195b68be848&tokenOutChainId=1315&amount=1413657184000000000000&type=exactIn&protocols=v2%2Cv3%2Cv3s1%2Cmixed */

  const data = await response.json();
  return data.quote;
}
```

## 2. Token Approval (ERC20 Only)

```javascript
Using erc20Abi to check approval

import { ethers } from 'ethers'
import { erc20Abi } from './abis/erc20' // your ABI import

const provider = new ethers.JsonRpcProvider('https://rpc-url')
const token = new ethers.Contract('0xTokenAddress', erc20Abi, provider)

const allowance = await token.allowance('0xOwnerAddress', '0xSpenderAddress')
console.log(ethers.formatUnits(allowance, 18)) // assuming token has 18 decimals
```

## 3. Handle Wrap/Unwrap (IP ↔ WIP)

```javascript
async function handleWrapUnwrap(tokenIn, tokenOut, amountIn) {
  const wrapContract = new ethers.Contract(WRAP_CONTRACT_ADDRESS, abi1514, signer);
  const amountWithDecimals = ethers.parseUnits(amountIn.toString(), tokenIn.decimals);
  
  // Case: IP -> WIP (Wrap)
  if (tokenIn.symbol === "IP" && tokenOut.symbol === "WIP") {
    const tx = await wrapContract.deposit({
      value: amountWithDecimals,
      gasLimit: 10000000
    });
    
    const receipt = await tx.wait();
  }
  
  // Case: WIP -> IP (Unwrap)
  if (tokenIn.symbol === "WIP" && tokenOut.symbol === "IP") {
    const tx = await wrapContract.withdraw(amountWithDecimals.toString(), {
      gasLimit: 10000000
    });
    
    const receipt = await tx.wait();
  }
}
```

## 4. Prepare Swap Parameters

```javascript
function prepareSwapParams(quoteData, userAddress, slippage = "0.5", timeLimit = "20") {
  const deadline = Math.floor(Date.now() / 1000) + parseInt(timeLimit, 10) * 60;
  
  return quoteData.route.map((path) => {
    // Map each step in the path to swap routes
    const swapRoutes = path.map((step) => ({
      routerAddress: step.routerAddress,
      poolType: mapPoolType(step.type),
      tokenIn: step.tokenIn.address,
      tokenOut: step.tokenOut.address,
      fee: step.fee || BigInt(0),
    }));

    const amountInWithDecimals = BigInt(path[0]?.amountIn?.toString() || '0');
    const amountOutWithDecimals = BigInt(path[path.length - 1]?.amountOut || '0');
    
    // Calculate minimum amount out with slippage protection
    const amountOutMinimum = 
      (amountOutWithDecimals * BigInt(10000 - parseFloat(slippage) * 100)) / BigInt(10000);

    // Apply fee-on-transfer token adjustments
    const totalPercent = path.reduce((acc, step) =>
      acc - (typeof step.feeOnTransferToken === 'number' && step.feeOnTransferToken > 0 ? step.feeOnTransferToken : 0), 100);
    const finalAmountOutMinimum = (amountOutMinimum * BigInt(totalPercent)) / BigInt(100);

    return {
      swapRoutes,
      recipient: userAddress,
      deadline,
      amountIn: amountInWithDecimals,
      amountOutMinimum: finalAmountOutMinimum,
    };
  });
}
```

## 5. Execute Swap

```javascript
async function executeSwap(allExecutionParams, tokenIn, amountIn) {
  const userAddress = await signer.getAddress();
  const router = new ethers.Contract(ROUTER_ADDRESS, abiMimbokuRouter, signer);
  
  let hash;
  try {
    // Case 1: Native token (IP) as tokenIn
    if (tokenIn.symbol === "IP") {

      // Execute swap with native token value
      const tx = await router.swapMultiroutes(allExecutionParams, {
        gasLimit: BigInt(10000000),
        value: ethers.parseUnits(amountIn.toString(), tokenIn.decimals)
      });
      hash = tx.hash;
    }
    
    // Case 2: ERC20 tokens (default case)
    else {

      // Execute ERC20 swap
      const tx = await router.swapMultiroutes(allExecutionParams, {
        gasLimit: BigInt(10000000)
      });
      hash = tx.hash;
    }

    // Wait for transaction confirmation
    if (!hash) {
      throw new Error('Transaction hash is undefined');
    }
    
    console.log('Swap tx hash:', hash);
    const receipt = await waitForTransactionReceipt(config, { hash });
    
    if (receipt.status === 'success') {
      console.log('Swap successful!');
      return { success: true, txHash: hash };
    } else {
      throw new Error('Transaction failed');
    }

  } catch (error) {
    console.error('Swap failed:', error);
    throw error;
  }
}
```

## 6. Complete Swap Workflow

```javascript
async function performSwap({
  tokenIn,
  tokenOut,
  amountIn,
  slippage = "0.5",
  timeLimit = "20",
  chainId = 1514,
  protocols = 'v2,v3,v3s1,mixed'
}) {
  try {
    const userAddress = await signer.getAddress();
    console.log('Starting swap workflow...');
    
    // Step 1: Check if it's a wrap/unwrap operation
    if (isWrapUnwrapPair(tokenIn, tokenOut)) {
      return await handleWrapUnwrap(tokenIn, tokenOut, amountIn);
    }
    
    // Step 2: Get quote from API
    console.log('Fetching quote...');
    const quoteData = await fetchQuote({
      tokenIn,
      tokenOut,
      amountIn
      chainId,
      tradeType
      protocols
    });
    
    if (!quoteData || !quoteData.route || quoteData.route.length === 0) {
      throw new Error('No route found for this swap');
    }
    
    // Step 3: Approve token if it's not native (IP)
    if (tokenIn.symbol !== "IP") {
      console.log('Checking token approval...');
      await checkAndApproveToken(
        tokenIn.address,
        ROUTER_ADDRESS,
        ethers.parseUnits(amountIn.toString(), tokenIn.decimals)
      );
    }
    
    // Step 4: Prepare swap parameters
    console.log('Preparing swap parameters...');
    const allExecutionParams = prepareSwapParams(quoteData, userAddress, slippage, timeLimit);
    
    // Step 5: Execute swap
    console.log('Executing swap...');
    const result = await executeSwap(allExecutionParams, tokenIn, amountIn);
    
    return result;
    
  } catch (error) {
    console.error('Swap workflow failed:', error);
    throw error;
  }
}
```

## interface
```javascript
interface QuoteResponse {
    blockNumber: string;
    amount: string;
    amountDecimals: string;
    quote: string;
    quoteDecimals: string;
    quoteGasAdjusted: string;
    quoteGasAdjustedDecimals: string;
    gasUseEstimateQuote: string;
    gasUseEstimateQuoteDecimals: string;
    gasUseEstimate: string;
    gasUseEstimateUSD: string;
    simulationStatus: string;
    simulationError: boolean;
    gasPriceWei: string;
    route: Array<Array<{
        type: string;
        address: string;
        routerAddress: string;
        feeOnTransferToken?: number;
        dexName: string;
        tokenIn: {
            chainId: number;
            decimals: string;
            address: string;
            symbol: string;
        };
        tokenOut: {
            chainId: number;
            decimals: string;
            address: string;
            symbol: string;
        };
        fee: string;
        liquidity: string;
        sqrtRatioX96: string;
        tickCurrent: string;
        amountIn?: string;
        amountOut?: string;
    }>>;
    routeString: string;
    quoteId: string;
    hitsCachedRoutes: boolean;
    priceImpact: string;
}

 interface IToken {
    id: string
    chainId?: number
    address: string
    name: string
    symbol: string
    decimals: number
    logoURI: string
}
```
This guide provides a complete JavaScript implementation for integrating with the Mimboku DEX Aggregator. Make sure to replace placeholder addresses and API endpoints with your actual values.
