export type LoanStatus =
  | "PAYOUT_PENDING"
  | "ACTIVE"
  | "REPAY_REQUESTED"
  | "CLOSED"
  | "LIQUIDATED";

export type Position = {
  positionId: bigint;
  borrower: `0x${string}`;
  collateralToken: `0x${string}`;
  collateralAmount: bigint;
  principalIDR: bigint;
  aprBps: number;
  startTimestamp: number;
  status: number;
  payoutDeadline: number;
  payoutRefHash: `0x${string}`;
  repayRefHash: `0x${string}`;
  offchainRefHash: `0x${string}`;
};
