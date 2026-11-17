import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { query } from '../db.js';
import { HttpError } from '../lib/http.js';

export function signToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
}

/** Verifies the Bearer token and loads the user so a deleted or re-roled account loses access at once. */
export async function authenticate(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw new HttpError(401, 'Please log in');
  let payload;
  try {
    payload = jwt.verify(token, config.jwtSecret);
  } catch {
    throw new HttpError(401, 'Your session has expired, please log in again');
  }
  const { rows } = await query('SELECT id, role, name, email FROM users WHERE id = $1', [payload.sub]);
  if (!rows[0]) throw new HttpError(401, 'Account no longer exists');
  req.user = rows[0];
  next();
}

/** Allows only the given roles. Always used on the backend: the UI hiding a button is not security. */
export const requireRole = (...roles) => (req, _res, next) => {
  if (!roles.includes(req.user?.role)) {
    throw new HttpError(403, `Only ${roles.join(' or ')} accounts can do this`);
  }
  next();
};
