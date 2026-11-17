export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export const badRequest = (m) => new HttpError(400, m);
export const forbidden = (m = 'You do not have permission to do this') => new HttpError(403, m);
export const notFound = (m = 'Not found') => new HttpError(404, m);
export const conflict = (m) => new HttpError(409, m);

/** Validate data with a zod schema, throwing a 400 with a readable message. */
export function parse(schema, data) {
  const r = schema.safeParse(data ?? {});
  if (!r.success) {
    const msg = r.error.issues
      .map((i) => (i.path.length ? `${i.path.join('.')}: ${i.message}` : i.message))
      .join('; ');
    throw badRequest(msg);
  }
  return r.data;
}

export function errorHandler(err, req, res, _next) {
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
  if (err?.code === '23505') return res.status(409).json({ error: 'That record already exists' });
  if (err?.code === '23503') return res.status(400).json({ error: 'It refers to a record that does not exist or is still in use' });
  if (err?.code === '23514') return res.status(400).json({ error: 'A value is not allowed' });
  if (err?.code === 'LIMIT_FILE_SIZE') return res.status(400).json({ error: 'Photo is too large (max 5 MB)' });
  console.error(err);
  res.status(500).json({ error: 'Something went wrong' });
}
