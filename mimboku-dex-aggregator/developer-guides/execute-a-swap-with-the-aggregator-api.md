---
description: Interacting With Mimboku Aggregator Router Contract
---

# Execute A Swap With The Aggregator API

## Sequence diagram

<figure><img src="../../.gitbook/assets/Aggregator_API.png" alt=""><figcaption><p>API sequence diagram</p></figcaption></figure>

To execute a swap, the router (`MimbokuRouter`) contract requires the encoded swap data to be included as part of the transaction. This encoded swap data as well as other swap metadata are returned as part of the API response. As such, developers are expected to call the swap API prior to sending a transaction to the router contract.

## How to Call API for Quote and Swap Using JavaScript

// Example: How to get a quote and perform a swap using ethers.js

import { ethers } from "ethers";
import { encodeFunctionData, erc20Abi, maxUint256 } from "viem";
import { estimateGas, prepareTransactionRequest, waitForTransactionReceipt } from '@wagmi/core';
import abiMimbokuRouter from "@/abis/abi.json";

// Helper function to map pool types (from utils/index.ts)
function mapPoolType(type) {
  const poolTypeMap = {
    'v2': 0,
    'v3': 1,
    'v3s1': 2,
    'mixed': 3
  };
  return poolTypeMap[type] || 0;
}

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
const config = {/* your wagmi config */}; // For gas estimation

// Example tokens (replace with real addresses)
const tokenInAddress = "0x..."; // Token you want to sell
const tokenOutAddress = "0x..."; // Token you want to buy
const decimalsIn = 18; // Decimals for tokenIn
const decimalsOut = 18; // Decimals for tokenOut
const amountIn = ethers.parseUnits("1.0", decimalsIn); // Amount to swap

// 3. Get quote data and perform swap
async function main() {
  const userAddress = await signer.getAddress();
  
  // Get quote from API
  const quote = await fetchQuote({
    tokenIn: tokenInAddress,
    tokenOut: tokenOutAddress,
    amountIn: amountIn.toString(),
    chainId: 1514, // Replace with your chainId
    protocols: 'v2,v3,v3s1,mixed' // Available protocols
  });

  // Prepare swap execution parameters from quote
  const slippage = "0.5"; // 0.5% slippage
  const timeLimit = "20"; // 20 minutes
  const deadline = Math.floor(Date.now() / 1000) + parseInt(timeLimit, 10) * 60;

  const allExecutionParams = quote.route.map((path) => {
    // Map each step in the path to swap routes
    const swapRoutes = path.map((step, index) => ({
      routerAddress: step.routerAddress,
      poolType: mapPoolType(step.type), // Map string type to number
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

  // 4. Handle different swap cases
  const router = new ethers.Contract(routerAddress, abiMimbokuRouter, signer);

  try {
    let hash;
    let gas;

    // Case 1: Native token (IP) as tokenIn
    if (quote.tokenInSymbol === "IP") {
      try {
        // Estimate gas with value for native token
        const data = encodeFunctionData({
          abi: abiMimbokuRouter,
          functionName: 'swapMultiroutes',
          args: [allExecutionParams],
        });

        const request = await prepareTransactionRequest(config, {
          account: userAddress,
          to: routerAddress,
          data,
          value: ethers.parseUnits(amountIn.toString(), decimalsIn),
        });
        gas = await estimateGas(config, request);
      } catch (error) {
        console.warn('Gas estimation failed, using fallback');
      }

      // Execute swap with native token value
      const tx = await router.swapMultiroutes(allExecutionParams, {
        gasLimit: gas || BigInt(10000000), // Use estimated gas or fallback
        value: ethers.parseUnits(amountIn.toString(), decimalsIn) // Send value for native token
      });
      hash = tx.hash;
      console.log("Native token swap tx hash:", hash);
    }
    
    // Case 2: ERC20 tokens (default case)
    else {
      try {
        // Estimate gas for ERC20 swap
        const data = encodeFunctionData({
          abi: abiMimbokuRouter,
          functionName: 'swapMultiroutes',
          args: [allExecutionParams],
        });

        const request = await prepareTransactionRequest(config, {
          account: userAddress,
          to: routerAddress,
          data,
        });
        gas = await estimateGas(config, request);
      } catch (error) {
        console.warn('Gas estimation failed, using fallback');
      }

      // Execute ERC20 swap
      const tx = await router.swapMultiroutes(allExecutionParams, {
        gasLimit: gas || BigInt(10000000), // Use estimated gas or fallback
        // No value needed for ERC20
      });
      hash = tx.hash;
      console.log("ERC20 swap tx hash:", hash);
    }

    // Wait for transaction confirmation
    if (!hash) {
      throw new Error('Transaction hash is undefined');
    }
    
    const receipt = await waitForTransactionReceipt(config, { hash });
    
    if (receipt.status === 'success') {
      console.log('Swap successful! TxHash:', hash);
    } else {
      throw new Error('Transaction failed');
    }

  } catch (error) {
    console.error('Swap failed:', error);
    throw error;
  }
}

// 5. Handle token approval (for ERC20 tokens only)
async function approveToken(tokenAddress, spenderAddress, amount) {
  const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, signer);
  const userAddress = await signer.getAddress();
  
  // Check current allowance
  const allowance = await tokenContract.allowance(userAddress, spenderAddress);
  
  if (BigInt(allowance.toString()) >= BigInt(amount.toString())) {
    console.log('Token already approved');
    return;
  }
  
  // Approve token
  const tx = await tokenContract.approve(spenderAddress, maxUint256);
  console.log('Approval tx hash:', tx.hash);
  await tx.wait();
  console.log('Token approval successful!');
}

// 6. Complete workflow example
async function performSwap() {
  try {
    // Step 1: Approve token if it's not native (IP)
    if (tokenInAddress !== "0x0000000000000000000000000000000000000000") { // Not native token
      await approveToken(tokenInAddress, routerAddress, amountIn);
    }
    
    // Step 2: Perform the swap
    await main();
    
  } catch (error) {
    console.error('Swap workflow failed:', error);
  }
}

// 7. Handle wrap/unwrap cases (IP <-> WIP)
async function handleWrapUnwrap(tokenIn, tokenOut, amount) {
  const wrapContractAddress = "0x1514000000000000000000000000000000000000"; // From ContractAddresses.OX1514Address
  const wrapContract = new ethers.Contract(wrapContractAddress, abi1514, signer);
  
  // Case: IP -> WIP (Wrap)
  if (tokenIn.symbol === "IP" && tokenOut.symbol === "WIP") {
    const tx = await wrapContract.deposit({
      value: ethers.parseUnits(amount, tokenIn.decimals),
      gasLimit: 10000000
    });
    console.log('Wrap tx hash:', tx.hash);
    await tx.wait();
    console.log('Wrap successful!');
    return;
  }
  
  // Case: WIP -> IP (Unwrap)
  if (tokenIn.symbol === "WIP" && tokenOut.symbol === "IP") {
    const amountWithDecimals = ethers.parseUnits(amount, tokenIn.decimals);
    const tx = await wrapContract.withdraw(amountWithDecimals.toString(), {
      gasLimit: 10000000
    });
    console.log('Unwrap tx hash:', tx.hash);
    await tx.wait();
    console.log('Unwrap successful!');
    return;
  }
  
  // Regular swap
  await performSwap();
}

// Run the example
performSwap().catch(console.error);
