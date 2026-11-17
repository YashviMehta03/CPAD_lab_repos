import 'dotenv/config';

const dbUrl = process.env.DATABASE_URL || '';

export const config = {
  port: Number(process.env.PORT || 4000),
  databaseUrl: dbUrl,
  dbSsl: process.env.DATABASE_SSL
    ? process.env.DATABASE_SSL === 'true'
    : !/localhost|127\.0\.0\.1/.test(dbUrl),
  jwtSecret: process.env.JWT_SECRET || '',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  supabaseUrl: process.env.SUPABASE_URL || '',
  supabaseKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  bucket: process.env.SUPABASE_BUCKET || 'helpdesk',
  demoNow: (process.env.DEMO_NOW || '').trim(),
};

export function assertConfig() {
  const missing = [];
  if (!config.databaseUrl) missing.push('DATABASE_URL');
  if (!config.jwtSecret) missing.push('JWT_SECRET');
  // Supabase Auth handles sign up / login, so these are required now.
  if (!config.supabaseUrl) missing.push('SUPABASE_URL');
  if (!config.supabaseKey) missing.push('SUPABASE_SERVICE_ROLE_KEY');
  if (missing.length) {
    console.error(`Missing required env vars: ${missing.join(', ')}. Copy .env.example to .env and fill them in.`);
    process.exit(1);
  }
}
