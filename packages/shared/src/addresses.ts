export const CONTRACT_ADDRESSES = {
  8453: "0x0000000000000000000000000000000000000000",
  84532: "0x0000000000000000000000000000000000000000"
} as const;

export const USDC_ADDRESSES = {
  8453: "0x0000000000000000000000000000000000000000",
  84532: "0x0000000000000000000000000000000000000000"
} as const;

export function getContractAddress(chainId: number): `0x${string}` {
  return (CONTRACT_ADDRESSES as Record<number, `0x${string}`>)[chainId];
}

export function getUsdcAddress(chainId: number): `0x${string}` {
  return (USDC_ADDRESSES as Record<number, `0x${string}`>)[chainId];
}
