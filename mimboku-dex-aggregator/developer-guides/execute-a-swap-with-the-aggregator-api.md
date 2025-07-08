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

// Your wagmi config for gas estimation
const config = {
  // Your wagmi configuration
};
```

## Helper Functions

```javascript
// Map pool types to numbers
function mapPoolType(type) {
  const poolTypeMap = {
    'v2': 0,
    'v3': 1,
    'v3s1': 2,
    'mixed': 3
  };
  return poolTypeMap[type] || 0;
}

// Format amount for display
function formatAmount(amount) {
  return parseFloat(amount).toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 6
  });
}

// Check if tokens are wrap/unwrap pair
function isWrapUnwrapPair(tokenIn, tokenOut) {
  return (tokenIn.symbol === "IP" && tokenOut.symbol === "WIP") ||
         (tokenIn.symbol === "WIP" && tokenOut.symbol === "IP");
}
```

## 1. Fetch Quote from API

```javascript
async function fetchQuote({
  tokenIn,
  tokenOut,
  amountIn,
  chainId = 1514,
  protocols = 'v2,v3,v3s1,mixed'
}) {
  const params = new URLSearchParams({
    tokenIn: tokenIn.address,
    tokenOut: tokenOut.address,
    amountIn: amountIn.toString(),
    chainId: chainId.toString(),
    protocols
  });

  const response = await fetch(`https://your-api-endpoint/quote?${params}`);
  
  if (!response.ok) {
    throw new Error(`Quote API failed: ${response.statusText}`);
  }
  
  const data = await response.json();
  return data.quote;
}
```

## 2. Token Approval (ERC20 Only)

```javascript
async function checkAndApproveToken(tokenAddress, spenderAddress, amount) {
  const userAddress = await signer.getAddress();
  const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, signer);
  
  // Check current allowance
  const allowance = await tokenContract.allowance(userAddress, spenderAddress);
  
  if (BigInt(allowance.toString()) >= BigInt(amount.toString())) {
    console.log('Token already approved');
    return true;
  }
  
  console.log('Approving token...');
  const tx = await tokenContract.approve(spenderAddress, maxUint256);
  console.log('Approval tx hash:', tx.hash);
  
  await tx.wait();
  console.log('Token approval successful!');
  return true;
}
```

## 3. Handle Wrap/Unwrap (IP ↔ WIP)

```javascript
async function handleWrapUnwrap(tokenIn, tokenOut, amountIn) {
  const wrapContract = new ethers.Contract(WRAP_CONTRACT_ADDRESS, abi1514, signer);
  const amountWithDecimals = ethers.parseUnits(amountIn.toString(), tokenIn.decimals);
  
  // Case: IP -> WIP (Wrap)
  if (tokenIn.symbol === "IP" && tokenOut.symbol === "WIP") {
    console.log('Wrapping IP to WIP...');
    const tx = await wrapContract.deposit({
      value: amountWithDecimals,
      gasLimit: 10000000
    });
    
    console.log('Wrap tx hash:', tx.hash);
    const receipt = await tx.wait();
    
    if (receipt.status === 1) {
      console.log('Wrap successful!');
      return { success: true, txHash: tx.hash };
    } else {
      throw new Error('Wrap transaction failed');
    }
  }
  
  // Case: WIP -> IP (Unwrap)
  if (tokenIn.symbol === "WIP" && tokenOut.symbol === "IP") {
    console.log('Unwrapping WIP to IP...');
    const tx = await wrapContract.withdraw(amountWithDecimals.toString(), {
      gasLimit: 10000000
    });
    
    console.log('Unwrap tx hash:', tx.hash);
    const receipt = await tx.wait();
    
    if (receipt.status === 1) {
      console.log('Unwrap successful!');
      return { success: true, txHash: tx.hash };
    } else {
      throw new Error('Unwrap transaction failed');
    }
  }
  
  throw new Error('Invalid wrap/unwrap pair');
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
  let gas;

  try {
    // Case 1: Native token (IP) as tokenIn
    if (tokenIn.symbol === "IP") {
      console.log('Executing native token swap...');
      
      // Estimate gas for native token swap
      try {
        const data = encodeFunctionData({
          abi: abiMimbokuRouter,
          functionName: 'swapMultiroutes',
          args: [allExecutionParams],
        });

        const request = await prepareTransactionRequest(config, {
          account: userAddress,
          to: ROUTER_ADDRESS,
          data,
          value: ethers.parseUnits(amountIn.toString(), tokenIn.decimals),
        });
        gas = await estimateGas(config, request);
      } catch (error) {
        console.warn('Gas estimation failed, using fallback');
      }

      // Execute swap with native token value
      const tx = await router.swapMultiroutes(allExecutionParams, {
        gasLimit: gas || BigInt(10000000),
        value: ethers.parseUnits(amountIn.toString(), tokenIn.decimals)
      });
      hash = tx.hash;
    }
    
    // Case 2: ERC20 tokens (default case)
    else {
      console.log('Executing ERC20 token swap...');
      
      // Estimate gas for ERC20 swap
      try {
        const data = encodeFunctionData({
          abi: abiMimbokuRouter,
          functionName: 'swapMultiroutes',
          args: [allExecutionParams],
        });

        const request = await prepareTransactionRequest(config, {
          account: userAddress,
          to: ROUTER_ADDRESS,
          data,
        });
        gas = await estimateGas(config, request);
      } catch (error) {
        console.warn('Gas estimation failed, using fallback');
      }

      // Execute ERC20 swap
      const tx = await router.swapMultiroutes(allExecutionParams, {
        gasLimit: gas || BigInt(10000000)
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
      amountIn: ethers.parseUnits(amountIn.toString(), tokenIn.decimals).toString(),
      chainId,
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

## 7. Usage Examples

### Basic Swap Example

```javascript
// Example token objects
const tokenIn = {
  address: "0x1234567890123456789012345678901234567890",
  symbol: "TOKEN1",
  decimals: 18,
  name: "Token 1"
};

const tokenOut = {
  address: "0x0987654321098765432109876543210987654321",
  symbol: "TOKEN2",
  decimals: 18,
  name: "Token 2"
};

// Perform swap
async function example() {
  try {
    const result = await performSwap({
      tokenIn,
      tokenOut,
      amountIn: "1.5", // 1.5 tokens
      slippage: "0.5", // 0.5% slippage
      timeLimit: "20", // 20 minutes
      chainId: 1514,
      protocols: 'v2,v3,v3s1,mixed'
    });
    
    console.log('Swap completed:', result);
  } catch (error) {
    console.error('Swap failed:', error);
  }
}

example();
```

### Native Token (IP) Swap Example

```javascript
const ipToken = {
  address: "0x0000000000000000000000000000000000000000",
  symbol: "IP",
  decimals: 18,
  name: "IP Token"
};

const usdcToken = {
  address: "0xa0b86a33e6441b8c6cd5c8b3c3c8b1d3a8c7f9e1",
  symbol: "USDC",
  decimals: 6,
  name: "USD Coin"
};

// Swap IP to USDC
async function swapIPToUSDC() {
  try {
    const result = await performSwap({
      tokenIn: ipToken,
      tokenOut: usdcToken,
      amountIn: "0.1", // 0.1 IP
      slippage: "1.0", // 1% slippage
      timeLimit: "30" // 30 minutes
    });
    
    console.log('IP to USDC swap completed:', result);
  } catch (error) {
    console.error('IP to USDC swap failed:', error);
  }
}

swapIPToUSDC();
```

### Wrap/Unwrap Example

```javascript
const ipToken = {
  address: "0x0000000000000000000000000000000000000000",
  symbol: "IP",
  decimals: 18,
  name: "IP Token"
};

const wipToken = {
  address: "0x1514000000000000000000000000000000000000",
  symbol: "WIP",
  decimals: 18,
  name: "Wrapped IP"
};

// Wrap IP to WIP
async function wrapIP() {
  try {
    const result = await performSwap({
      tokenIn: ipToken,
      tokenOut: wipToken,
      amountIn: "1.0" // 1 IP
    });
    
    console.log('Wrap completed:', result);
  } catch (error) {
    console.error('Wrap failed:', error);
  }
}

// Unwrap WIP to IP
async function unwrapWIP() {
  try {
    const result = await performSwap({
      tokenIn: wipToken,
      tokenOut: ipToken,
      amountIn: "1.0" // 1 WIP
    });
    
    console.log('Unwrap completed:', result);
  } catch (error) {
    console.error('Unwrap failed:', error);
  }
}

wrapIP();
// unwrapWIP();
```

## 8. Error Handling

```javascript
async function safeSwap(swapParams) {
  try {
    // Check wallet connection
    if (!signer) {
      throw new Error('Wallet not connected');
    }
    
    // Check network
    const network = await provider.getNetwork();
    if (network.chainId !== 1514) {
      throw new Error('Please switch to the correct network');
    }
    
    // Check balance
    const userAddress = await signer.getAddress();
    let balance;
    
    if (swapParams.tokenIn.symbol === "IP") {
      balance = await provider.getBalance(userAddress);
    } else {
      const tokenContract = new ethers.Contract(swapParams.tokenIn.address, erc20Abi, provider);
      balance = await tokenContract.balanceOf(userAddress);
    }
    
    const requiredAmount = ethers.parseUnits(swapParams.amountIn.toString(), swapParams.tokenIn.decimals);
    
    if (balance < requiredAmount) {
      throw new Error('Insufficient balance');
    }
    
    // Perform swap
    return await performSwap(swapParams);
    
  } catch (error) {
    console.error('Safe swap failed:', error);
    
    // Handle specific errors
    if (error.message.includes('user rejected')) {
      throw new Error('Transaction was rejected by user');
    } else if (error.message.includes('insufficient funds')) {
      throw new Error('Insufficient funds for gas');
    } else if (error.message.includes('slippage')) {
      throw new Error('Slippage tolerance exceeded');
    } else if (error.message.includes('expired')) {
      throw new Error('Transaction expired');
    } else {
      throw error;
    }
  }
}
```

## 9. Utility Functions

```javascript
// Calculate exchange rate
function calculateExchangeRate(amountIn, amountOut, tokenInDecimals, tokenOutDecimals) {
  const amountInFormatted = parseFloat(ethers.formatUnits(amountIn, tokenInDecimals));
  const amountOutFormatted = parseFloat(ethers.formatUnits(amountOut, tokenOutDecimals));
  
  if (amountInFormatted === 0) return "0";
  
  const rate = amountOutFormatted / amountInFormatted;
  return formatAmount(rate.toFixed(6));
}

// Calculate price impact
function calculatePriceImpact(quoteData) {
  return parseFloat(quoteData.priceImpact || "0");
}

// Format gas fee
function formatGasFee(gasEstimateUSD) {
  const fee = parseFloat(gasEstimateUSD || "0");
  return fee < 0.001 ? "< 0.001" : fee.toFixed(3);
}

// Get token balance
async function getTokenBalance(tokenAddress, userAddress) {
  if (tokenAddress === "0x0000000000000000000000000000000000000000") {
    // Native token
    const balance = await provider.getBalance(userAddress);
    return ethers.formatEther(balance);
  } else {
    // ERC20 token
    const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, provider);
    const balance = await tokenContract.balanceOf(userAddress);
    const decimals = await tokenContract.decimals();
    return ethers.formatUnits(balance, decimals);
  }
}
```

## 10. Best Practices

1. **Always check network**: Ensure user is on the correct network before performing swaps
2. **Handle slippage**: Set appropriate slippage tolerance based on market conditions
3. **Gas estimation**: Always estimate gas before executing transactions
4. **Error handling**: Implement comprehensive error handling for all failure scenarios
5. **Balance checks**: Verify user has sufficient balance before attempting swaps
6. **Approval optimization**: Check existing allowances before requesting new approvals
7. **Transaction monitoring**: Always wait for transaction confirmation
8. **Price impact warnings**: Warn users about high price impact trades
9. **Deadline management**: Set reasonable transaction deadlines
10. **Fee calculation**: Include gas fees in swap calculations

## API Response Format

```javascript
// Expected quote response format
{
  "quote": {
    "route": [
      [
        {
          "amountIn": "1000000000000000000",
          "amountOut": "950000000000000000",
          "tokenIn": {
            "address": "0x...",
            "symbol": "TOKEN1",
            "decimals": 18
          },
          "tokenOut": {
            "address": "0x...",
            "symbol": "TOKEN2",
            "decimals": 18
          },
          "routerAddress": "0x...",
          "type": "v3",
          "fee": "3000",
          "feeOnTransferToken": 0
        }
      ]
    ],
    "priceImpact": "0.05",
    "gasUseEstimateUSD": "0.25"
  }
}
```

This guide provides a complete JavaScript implementation for integrating with the Mimboku DEX Aggregator. Make sure to replace placeholder addresses and API endpoints with your actual values.
