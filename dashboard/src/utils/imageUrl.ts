const ABSOLUTE_URL_RE = /^https?:\/\//i;
const LOCAL_PREVIEW_URL_RE = /^(blob:|data:|file:)/i;

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
  const normalizedPath = path.trim();
  if (!normalizedPath) return '';
  // Keep browser-local preview URLs untouched (selected file before save).
  if (LOCAL_PREVIEW_URL_RE.test(normalizedPath)) return normalizedPath;
  if (ABSOLUTE_URL_RE.test(normalizedPath)) return normalizedPath;

  const base = resolveImageBase();
  const clean = normalizedPath.replace(/^\/+/, '');
  const storagePath = clean.startsWith('storage/') ? clean : `storage/${clean}`;
  return `${base}/${storagePath}`;
}
