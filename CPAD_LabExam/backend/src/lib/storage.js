// Helpdesk photo storage: Supabase Storage when configured, local backend/uploads otherwise (dev fallback).
import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createClient } from '@supabase/supabase-js';
import { config } from '../config.js';

export const uploadsDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'uploads');
const supabase = config.supabaseUrl && config.supabaseKey
  ? createClient(config.supabaseUrl, config.supabaseKey, { auth: { persistSession: false } })
  : null;

export const storageMode = supabase ? 'supabase' : 'local';

const EXT = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/heic': 'heic' };

/** Saves the file and returns its storage path (what goes in the database). */
export async function savePhoto(file) {
  const ext = EXT[file.mimetype] || 'jpg';
  const key = `tickets/${new Date().toISOString().slice(0, 10)}/${crypto.randomUUID()}.${ext}`;
  if (supabase) {
    const { error } = await supabase.storage.from(config.bucket).upload(key, file.buffer, {
      contentType: file.mimetype, upsert: false,
    });
    if (error) throw new Error(`Photo upload failed: ${error.message}`);
    return `supabase:${key}`;
  }
  const dest = path.join(uploadsDir, key);
  await fs.mkdir(path.dirname(dest), { recursive: true });
  await fs.writeFile(dest, file.buffer);
  return `local:${key}`;
}

/** A URL the app can load. Supabase photos get a short-lived signed URL; local ones a path on this server. */
export async function photoUrl(stored) {
  if (!stored) return null;
  if (stored.startsWith('supabase:') && supabase) {
    const { data, error } = await supabase.storage.from(config.bucket).createSignedUrl(stored.slice(9), 3600);
    return error ? null : data.signedUrl;
  }
  if (stored.startsWith('local:')) return `/uploads/${stored.slice(6)}`;
  return null;
}
