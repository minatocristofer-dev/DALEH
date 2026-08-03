import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://glgdiymnhmcvzhtmbqqb.supabase.co';
// Chave "anon" — pública por design, segura de expor no cliente.
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsZ2RpeW1uaG1jdnpodG1icXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2MTAzNTYsImV4cCI6MjEwMTE4NjM1Nn0.XAacR5Uk9dXya_Eh9Ol20HZ6bP3_uXnQo7WViT7zIDs';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
