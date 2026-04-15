<?php

namespace App\Http\Controllers\Concerns;

/**
 * Provides a consistent storage disk selector across all controllers.
 *
 * Priority:
 *   1. Cloudflare R2  — when CLOUDFLARE_R2_ENDPOINT is set (production)
 *   2. public disk    — local development fallback
 *
 * Usage in controllers:
 *   $images[] = $request->file('image')->store('categories', $this->disk());
 *   Storage::disk($this->disk())->delete($path);
 */
trait UsesStorageDisk
{
    /**
     * Return the active storage disk name.
     */
    protected function disk(): string
    {
        return config('filesystems.disks.r2.endpoint') ? 'r2' : 'public';
    }
}
