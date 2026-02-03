# Lend Contract (Core)

Repo core untuk kontrak + shared types + db schema.

## Struktur

- `packages/contracts` Hardhat contracts
- `packages/shared` ABI + utils (dipakai web/admin)
- `packages/db` Supabase client + schema

## Setup

```bash
pnpm install
```

## Deploy Base Sepolia

1. Copy env:

```bash
cp .env.example .env
```

2. Isi env:
- `PRIVATE_KEY`
- `BASE_SEPOLIA_RPC_URL`
- `TREASURY_ADDRESS`
- `USDC_ADDRESS`
- `ETH_USD_ORACLE`
- `USD_IDR_RATE`
- `APR_BPS`
- `PAYOUT_DEADLINE_SECONDS`

3. Deploy:

```bash
pnpm deploy:base-sepolia
```

## Export ABI

```bash
pnpm export-abi
```
