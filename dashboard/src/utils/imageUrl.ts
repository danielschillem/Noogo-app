const ABSOLUTE_URL_RE = /^https?:\/\//i;

function resolveImageBase(): string {
  const explicit = (import.meta.env.VITE_IMAGE_BASE_URL || '').trim();
  if (explicit) return explicit.replace(/\/$/, '');

  const apiUrl = (import.meta.env.VITE_API_URL || '').trim();
  if (ABSOLUTE_URL_RE.test(apiUrl)) {
    try {
      return new URL(apiUrl).origin;
    } catch {
      // ignore invalid URL and fallback below
    }
  }

  return window.location.origin;
}

export function toImageUrl(path?: string | null): string {
  if (!path) return '';
  if (ABSOLUTE_URL_RE.test(path)) return path;

  const base = resolveImageBase();
  const clean = path.replace(/^\/+/, '');
  const storagePath = clean.startsWith('storage/') ? clean : `storage/${clean}`;
  return `${base}/${storagePath}`;
}
