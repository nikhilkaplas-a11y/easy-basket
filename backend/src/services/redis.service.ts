import { createClient, type RedisClientType } from 'redis';

/**
 * Centralized Redis access. The HTTP server requires a working Redis (see [pingRequired] in bootstrap).
 *
 * Configure via environment (never commit secrets):
 *
 * Option A — URL:
 *   REDIS_URL=redis://default:PASSWORD@HOST:PORT
 *
 * Option B — discrete fields (Redis Cloud–style):
 *   REDIS_HOST=...
 *   REDIS_PORT=14810
 *   REDIS_USERNAME=default
 *   REDIS_PASSWORD=...
 *
 * Optional: REDIS_TLS=true if your provider requires TLS on the socket.
 */
export class RedisService {
  private static client: RedisClientType | null = null;
  private static connectPromise: Promise<RedisClientType> | null = null;

  /** True when URL or host+port+password are present. */
  static isConfigured(): boolean {
    if (process.env.REDIS_URL?.trim()) return true;
    const host = process.env.REDIS_HOST?.trim();
    const password = process.env.REDIS_PASSWORD;
    const port = process.env.REDIS_PORT;
    return !!(host && password && port);
  }

  private static createRedisClient(): RedisClientType | null {
    const url = process.env.REDIS_URL?.trim();
    if (url) {
      return createClient({
        url,
        socket: {
          reconnectStrategy: (retries) => Math.min(retries * 100, 3000),
        },
      });
    }

    const host = process.env.REDIS_HOST?.trim();
    const password = process.env.REDIS_PASSWORD;
    const portRaw = process.env.REDIS_PORT;
    if (!host || !password || !portRaw) return null;

    const port = Number(portRaw);
    if (!Number.isFinite(port)) return null;

    const username = process.env.REDIS_USERNAME?.trim() || 'default';
    const useTls = process.env.REDIS_TLS === 'true';

    const reconnectStrategy = (retries: number) => Math.min(retries * 100, 3000);

    return createClient({
      username,
      password,
      socket: useTls
        ? { host, port, tls: true, reconnectStrategy }
        : { host, port, reconnectStrategy },
    });
  }

  /**
   * Shared client; connects lazily on first use. Throws if Redis env is incomplete.
   */
  static async getClient(): Promise<RedisClientType> {
    if (this.client?.isOpen) return this.client;
    if (this.connectPromise) return this.connectPromise;

    const created = this.createRedisClient();
    if (!created) {
      throw new Error(
        'Redis is not configured. Set REDIS_URL or REDIS_HOST, REDIS_PORT, and REDIS_PASSWORD.'
      );
    }

    created.on('error', (err) => console.error('Redis Client Error', err));

    this.connectPromise = created
      .connect()
      .then(() => {
        this.client = created;
        this.connectPromise = null;
        console.log('✅ Redis connected');
        return created;
      })
      .catch((err) => {
        this.connectPromise = null;
        throw err;
      });

    return this.connectPromise;
  }

  /** Verify connectivity (e.g. at process start). Throws like [getClient] if misconfigured or unreachable. */
  static async pingRequired(): Promise<void> {
    const c = await this.getClient();
    await c.ping();
  }

  static async quit(): Promise<void> {
    if (this.client?.isOpen) {
      await this.client.quit();
    }
    this.client = null;
  }

  // --- Common string commands ---

  static async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    const c = await this.getClient();
    if (ttlSeconds != null) {
      await c.set(key, value, { EX: ttlSeconds });
    } else {
      await c.set(key, value);
    }
  }

  static async get(key: string): Promise<string | null> {
    const c = await this.getClient();
    return c.get(key);
  }

  static async del(...keys: string[]): Promise<number> {
    const c = await this.getClient();
    if (keys.length === 0) return 0;
    return c.del(keys);
  }

  static async exists(key: string): Promise<boolean> {
    const c = await this.getClient();
    return (await c.exists(key)) === 1;
  }

  static async expire(key: string, seconds: number): Promise<boolean> {
    const c = await this.getClient();
    return (await c.expire(key, seconds)) === 1;
  }

  static async ttl(key: string): Promise<number> {
    const c = await this.getClient();
    return c.ttl(key);
  }

  static async incr(key: string): Promise<number> {
    const c = await this.getClient();
    return c.incr(key);
  }

  static async decr(key: string): Promise<number> {
    const c = await this.getClient();
    return c.decr(key);
  }

  static async mGet(keys: string[]): Promise<(string | null)[]> {
    const c = await this.getClient();
    if (keys.length === 0) return [];
    return c.mGet(keys);
  }

  static async ping(): Promise<string> {
    const c = await this.getClient();
    return c.ping();
  }

  // --- JSON helpers ---

  static async setJson(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    await this.set(key, JSON.stringify(value), ttlSeconds);
  }

  static async getJson<T>(key: string): Promise<T | null> {
    const raw = await this.get(key);
    if (raw == null) return null;
    try {
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  // --- Hash (optional) ---

  static async hSet(key: string, field: string, value: string): Promise<number> {
    const c = await this.getClient();
    return c.hSet(key, field, value);
  }

  static async hGet(key: string, field: string): Promise<string | undefined> {
    const c = await this.getClient();
    const v = await c.hGet(key, field);
    return v ?? undefined;
  }

  static async hDel(key: string, ...fields: string[]): Promise<number> {
    if (fields.length === 0) return 0;
    const c = await this.getClient();
    return c.hDel(key, fields);
  }
}
