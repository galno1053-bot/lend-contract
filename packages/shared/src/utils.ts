import { keccak256, stringToBytes } from "viem";

export function computeOffchainRefHash(draftId: string): `0x${string}` {
  return keccak256(stringToBytes(draftId));
}

export function buildBankDetailsMessage(params: {
  address: string;
  token: string;
  collateralAmount: string;
  requestedIdr: string;
  draftId: string;
  timestamp: string;
  chainId: string;
}) {
  return [
    "Pinjaman Bank Details Submission",
    `address: ${params.address}`,
    `token: ${params.token}`,
    `collateralAmount: ${params.collateralAmount}`,
    `requestedIdr: ${params.requestedIdr}`,
    `draftId: ${params.draftId}`,
    `timestamp: ${params.timestamp}`,
    `chainId: ${params.chainId}`
  ].join("\n");
}

export function buildAdminAccessMessage(params: {
  address: string;
  timestamp: string;
  chainId: string;
}) {
  return [
    "Pinjaman Admin Bank Details Access",
    `address: ${params.address}`,
    `timestamp: ${params.timestamp}`,
    `chainId: ${params.chainId}`
  ].join("\n");
}

export function formatIdr(value: bigint | number) {
  const num = typeof value === "bigint" ? Number(value) : value;
  return new Intl.NumberFormat("id-ID").format(num);
}

export function parseIdrToBigInt(value: string): bigint {
  const digits = value.replace(/[^\d]/g, "");
  return digits ? BigInt(digits) : 0n;
}
