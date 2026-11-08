/**
 * dsh-billing-badge, host half.
 *
 * Serves the DeepSeek account balance to the chip. One read-only route:
 *
 *   GET /plugins/billing-badge/balance
 *
 * Design notes:
 *  - The API key is resolved from the credentials seam and never leaves this
 *    process. The browser receives balance numbers only.
 *  - Nothing is written to disk and no other endpoint is touched.
 *  - Requests carry a plugin header and a cross-origin caller is rejected. A
 *    cross-origin page cannot set a custom header without a preflight the
 *    server never grants, which is the same guard the file explorer uses.
 *  - Every failure degrades to a state the chip can render, never to a throw.
 *
 * @module dsh-billing-badge
 */

export const name = 'billing-badge'

/** Web server for the route, credentials for the API key. */
export const inject = ['webServer', 'credentials']

/**
 * Identity the Platform balance call reports. dsh 0.2.x requires it; the
 * account seam itself is resolved softly, so a build without DeepSeek-account
 * sign-in keeps working through the API-key path.
 */
const accountClient = () => ({
  version: '0.1.3',
  locale: 'zh-CN',
  // Seconds east of UTC, the sign the Platform UI uses.
  timezoneOffsetSeconds: -new Date().getTimezoneOffset() * 60,
})

/**
 * Shape an account wallet reading into the response the chip consumes.
 *
 * The account seam carries no `is_available` flag: a funded wallet is the only
 * availability signal it has, so a zero total is reported as unavailable.
 *
 * @param {object} balance - `AccountDetails['balance']` from the account seam.
 * @returns {object|undefined} Response body, or undefined when unreadable.
 */
function readAccountBalance(balance) {
  if (balance === null || typeof balance !== 'object' || balance.status !== 'ready') return undefined
  const recharge = Array.isArray(balance.value) ? balance.value : []
  const bonus = Array.isArray(balance.bonusWallets) ? balance.bonusWallets : []
  if (recharge.length === 0 && bonus.length === 0) return undefined
  const sum = (wallets) => wallets.reduce((total, wallet) => total + Number(wallet?.balance ?? 0), 0)
  const currency = String((recharge[0] ?? bonus[0])?.currency ?? '')
  const toppedUp = sum(recharge)
  const granted = sum(bonus)
  const total = toppedUp + granted
  return {
    ok: true,
    state: 'ok',
    source: 'account',
    at: new Date().toISOString(),
    currency,
    isAvailable: total > 0,
    total,
    granted,
    toppedUp,
  }
}

/** Balance endpoint, the only network destination of this plugin. */
const BALANCE_ENDPOINT = 'https://api.deepseek.com/user/balance'

/** Route path. */
const ROUTE = '/plugins/billing-badge/balance'

/** Header every request must carry. */
const HEADER = 'x-dsh-billing-badge'

/** How long a balance reading is reused. */
const TTL_MS = 60_000

/** Request timeout. */
const TIMEOUT_MS = 15_000

/**
 * Shape one balance reading into the response the chip consumes.
 *
 * @param {object} parsed - Parsed API response.
 * @returns {object} Response body.
 */
function readBalance(parsed) {
  const info = Array.isArray(parsed?.balance_infos) ? parsed.balance_infos[0] : undefined
  if (info === undefined) {
    return { ok: false, state: 'empty', error: '余额响应中没有 balance_infos 条目' }
  }
  return {
    ok: true,
    state: 'ok',
    at: new Date().toISOString(),
    // The API decides the currency. Never assume one: a USD account labelled
    // with a CNY sign is worse than no number at all.
    currency: String(info.currency ?? ''),
    // `is_available` is a TOP-LEVEL field of the response, a sibling of
    // `balance_infos`, not a member of the entry. Reading it off `info` always
    // produced false, so the chip would have cried wolf forever.
    isAvailable: parsed?.is_available === true,
    total: Number(info.total_balance ?? 0),
    granted: Number(info.granted_balance ?? 0),
    toppedUp: Number(info.topped_up_balance ?? 0),
  }
}

export function apply(ctx) {
  let cached = null
  let inflight = null

  const message = (err) => String((err && err.message) || err)

  const sameOrigin = (req) => {
    const headers = req.headers ?? {}
    const origin = headers.origin
    if (origin === undefined) return true
    try {
      return new URL(origin).host === String(headers.host ?? '')
    } catch {
      return false
    }
  }

  const send = (res, status, body) => {
    res.writeHead(status, {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    })
    res.end(JSON.stringify(body))
  }

  /** Resolve the key through the credentials seam, then the process environment. */
  const resolveKey = async () => {
    try {
      const resolved = await ctx.credentials?.resolve?.('DEEPSEEK_API_KEY')
      if (resolved?.value) return resolved.value
    } catch {
      /* fall through to the environment */
    }
    return process.env.DEEPSEEK_API_KEY || undefined
  }

  /**
   * Read the balance from the signed-in DeepSeek account first.
   *
   * dsh 0.2.x desktop and web profiles sign in with a Platform account and may
   * carry no API key at all, which is why the account seam is the primary
   * source here; an undefined result simply falls back to the key path.
   *
   * @returns {Promise<object|undefined>} Reading, or undefined when unusable.
   */
  const loadFromAccount = async () => {
    const account = typeof ctx.get === 'function' ? ctx.get('deepseekAccount') : ctx.deepseekAccount
    if (!account) return undefined
    try {
      const view = await account.getState()
      if (view?.status !== 'credential-stored') return undefined
      const reading = readAccountBalance(await account.getBalance(accountClient()))
      return reading
    } catch {
      return undefined
    }
  }

  const load = async () => {
    const accountReading = await loadFromAccount()
    if (accountReading !== undefined) return accountReading
    const key = await resolveKey()
    if (!key) return { ok: false, state: 'no-credential', error: '未登录 DeepSeek 账号，也未配置 DEEPSEEK_API_KEY' }
    try {
      const response = await fetch(BALANCE_ENDPOINT, {
        headers: { authorization: `Bearer ${key}`, accept: 'application/json' },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      })
      const text = await response.text()
      if (!response.ok) {
        return { ok: false, state: 'error', error: `HTTP ${response.status}: ${text.slice(0, 200)}` }
      }
      return readBalance(JSON.parse(text))
    } catch (err) {
      return { ok: false, state: 'error', error: message(err) }
    }
  }

  const balance = async (force) => {
    if (!force && cached !== null && Date.now() - Date.parse(cached.at) < TTL_MS) return cached
    if (inflight !== null) return inflight
    inflight = load()
      .then((result) => {
        cached = result.at === undefined ? { at: new Date().toISOString(), ...result } : result
        return cached
      })
      .catch((err) => ({ ok: false, state: 'error', error: message(err) }))
      .finally(() => {
        inflight = null
      })
    return inflight
  }

  ctx.inject(['webServer'], (httpCtx) => {
    httpCtx.effect(
      () =>
        httpCtx.webServer.register({
          kind: 'exact',
          path: ROUTE,
          handler: async (req, res) => {
            if (String((req.headers ?? {})[HEADER] ?? '') !== '1') {
              send(res, 403, { ok: false, state: 'forbidden', error: '缺少插件请求头' })
              return
            }
            if (!sameOrigin(req)) {
              send(res, 403, { ok: false, state: 'forbidden', error: '已拒绝跨站请求' })
              return
            }
            const url = new URL(req.url ?? ROUTE, 'http://x')
            send(res, 200, await balance(url.searchParams.get('refresh') === '1'))
          },
        }),
      'billing-badge: balance route',
    )
  })
}
