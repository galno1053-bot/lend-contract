import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const artifactPath = join(
  __dirname,
  "..",
  "artifacts",
  "contracts",
  "HybridLoanManager.sol",
  "HybridLoanManager.json"
);

const outputDir = join(__dirname, "..", "..", "shared", "src", "abis");
const outputPath = join(outputDir, "HybridLoanManager.json");

const artifact = JSON.parse(readFileSync(artifactPath, "utf8"));
mkdirSync(outputDir, { recursive: true });
writeFileSync(outputPath, JSON.stringify(artifact.abi, null, 2));

console.log("ABI exported to", outputPath);
