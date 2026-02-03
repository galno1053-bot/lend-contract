import { createClient } from "@supabase/supabase-js";

export type BankDetailsRecord = {
  id: string;
  draft_id: string;
  offchain_ref_hash: string;
  wallet_address: string;
  recipient_name: string;
  bank_name: string;
  account_number: string;
  created_at: string;
};

export function getSupabaseServerClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    throw new Error("Missing Supabase server environment variables");
  }

  return createClient(url, key, {
    auth: {
      persistSession: false
    }
  });
}
