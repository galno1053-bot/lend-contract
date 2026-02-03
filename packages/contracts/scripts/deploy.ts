import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
  const treasury = process.env.TREASURY_ADDRESS ?? "";
  const usdc =
    process.env.USDC_ADDRESS ??
    process.env.NEXT_PUBLIC_USDC_ADDRESS ??
    "";
  const oracle = process.env.ETH_USD_ORACLE ?? "";
  const aprBps = Number(process.env.APR_BPS ?? "2400");
  const payoutDeadlineSeconds = Number(process.env.PAYOUT_DEADLINE_SECONDS ?? "7200");
  const usdIdrRate = BigInt(process.env.USD_IDR_RATE ?? "0");

  if (!treasury || !usdc || !oracle) {
    throw new Error("Missing TREASURY_ADDRESS, USDC_ADDRESS, or ETH_USD_ORACLE");
  }

  const factory = await ethers.getContractFactory("HybridLoanManager");
  const contract = await factory.deploy(
    treasury,
    usdc,
    oracle,
    aprBps,
    payoutDeadlineSeconds,
    usdIdrRate
  );
  await contract.waitForDeployment();
  console.log("HybridLoanManager deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
