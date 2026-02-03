create extension if not exists "uuid-ossp";

create table if not exists public.bank_details (
  id uuid primary key default uuid_generate_v4(),
  draft_id text unique not null,
  offchain_ref_hash text unique not null,
  wallet_address text not null,
  recipient_name text not null,
  bank_name text not null,
  account_number text not null,
  created_at timestamptz default now()
);

create index if not exists bank_details_wallet_idx on public.bank_details (wallet_address);
