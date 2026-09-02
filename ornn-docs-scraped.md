# Ornn — Scraped docs

## Source: https://data.ornn.com/docs/llms-full.txt

# Access tiers
Source: https://data.ornn.com/docs/access-tiers

What Index, Premium, and Full can read on the platform, the REST API, and MCP — including payments, key prefixes, and grain.

Ornn Data has three customer-facing plans. Trial is Premium with a 72-hour clock and no bill. Access is enforced on the REST API by the key prefix, on MCP by the account's own grant, and on the website by the live platform tier.

| Plan                        | Payment                                                                      | API key    | Grain            | History                           |
| --------------------------- | ---------------------------------------------------------------------------- | ---------- | ---------------- | --------------------------------- |
| **Index**                   | Free. No account.                                                            | None       | Daily            | Trailing window only              |
| **Premium** (and **Trial**) | **\$500 / month**, self-serve on Stripe. Trial is 72 hours, granted by Ornn. | `sk_prem_` | **Daily only**   | **Complete — no trailing window** |
| **Full**                    | Custom. Organization-grained, billed through Rillet.                         | `sk_live_` | Daily and hourly | Complete, every grain             |

<Note>
  A Premium key asking for `granularity=hourly` or `auto` is **served at daily**, not refused. Read the `granularity` and `access` fields on the response. The endpoints that exist only to serve sub-daily data — `/api/gpu/{gpuName}/hourly` and `/api/gpu/{gpuName}/rolling-24h-average` — return `403` for a Premium key. Daily history at `/api/gpu/{gpuName}/rolling-24h-average/history` remains Premium. The real-time GPU route is under maintenance and returns `404` for every caller.
</Note>

Compare plans on the website at [data.ornn.com/pricing](https://data.ornn.com/pricing). Field-level coverage is in the [data dictionary](/docs/data-dictionary). A gating or billing change must update both pages and the internal Word file (`backend/tests/data-dictionary-gating.test.js`).

## What each plan can read

| Dataset                                     | Index                                                        | Premium / Trial                                                    | Full                                                                                                                                     |
| ------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Compute Price Index (OCPI)                  | 5 GPUs, trailing 3 months, daily                             | All 6 GPUs, all-time, daily                                        | All 6 GPUs, all grains, all-time                                                                                                         |
| Compute analytics (volatility, utilization) | None                                                         | Daily, all-time                                                    | All grains, all-time                                                                                                                     |
| Forward curves                              | Nine published types (no marks API)                          | Published marks and suppressed coverage for nine tracked curves    | Same — current marks only; historical marks are not on the customer API                                                                  |
| Memory Price Index                          | Catalog only                                                 | All 14 types, full history                                         | Same                                                                                                                                     |
| Token Price Index (OTPI)                    | 4 labs, trailing 1 month                                     | All 11 labs, all-time                                              | Same                                                                                                                                     |
| Token Volume Index                          | None                                                         | Included                                                           | Included                                                                                                                                 |
| Workload Cost Index                         | None                                                         | Included                                                           | Included                                                                                                                                 |
| Model Frontier                              | None                                                         | Included                                                           | Included                                                                                                                                 |
| LLM Coding Analytics                        | Product catalog only                                         | Values and history                                                 | Same                                                                                                                                     |
| Power Markets                               | None                                                         | Daily market prices via REST (`/api/power/markets`) + price charts | Daily market prices plus hourly load and fuel mix via REST (`/api/power/markets`, `/api/power/load`, `/api/power/fuel-mix`) + all charts |
| Datacenter Sites                            | Public points (coordinates only)                             | Public points only                                                 | Full site payload and API                                                                                                                |
| Compute Buyers                              | None                                                         | Included                                                           | Included                                                                                                                                 |
| News                                        | Public headlines and excerpts, linking to sources — no login | Same                                                               | Same                                                                                                                                     |
| Chat (`POST /api/chat`)                     | No                                                           | No — a `sk_prem_` key returns `403`                                | API access with `sk_live_`                                                                                                               |
| Dataset exports (CSV / XLSX)                | Free-window CSV on the public Index page only                | Same — in-app chart exports need Full                              | Yes                                                                                                                                      |
| Organization seats                          | No                                                           | No — individual grant                                              | Yes                                                                                                                                      |

Power Markets is a Premium-included analytics dataset served on the REST API at `GET /api/power/markets` (daily wholesale prices, traded volume, and system load, history from 2017-01-03) and rendered on the platform charts at [data.ornn.com/analytics/power](https://data.ornn.com/analytics/power). The hourly grid-operations routes — `GET /api/power/load` for actual and forecast demand, and `GET /api/power/fuel-mix` for generation by fuel — are Full-only. None of these routes has a free/Index tier. Every other Premium-included analytics dataset has a REST route too: the Token Volume Index at [`GET /api/token-volume`](/docs/api-reference/token-volume/get-the-token-volume-index-by-day), Model Frontier at [`GET /api/model-frontier`](/docs/api-reference/model-frontier/get-the-model-frontier-dataset), Compute Buyers at [`GET /api/compute-buyers`](/docs/api-reference/compute-buyers/list-tracked-compute-buyers), and the forward curve at [`GET /api/forward`](/docs/api-reference/forward/get-the-forward-curve), alongside the existing Workload Cost (`GET /api/workload`) and LLM Coding (`GET /api/llm-coding/*`) routes. The Token Volume Index page covers all 11 OTPI labs (selectable share, a shared growth baseline, and an open/closed split); the REST route publishes the closed-lab series. See [The Token Volume Index](/docs/token-volume-index). On MCP, Token Volume has its own tool; Model Frontier and Compute Buyers are REST-only (Model Frontier and Compute Buyers because their full-snapshot payloads exceed the MCP result-size cap).

### Public GPU window (Index)

`H100 SXM` · `H200` · `B200` · `A100 SXM4` · `RTX 5090`

`RTX PRO 6000 WS` is Premium and Full only.

### Public OTPI window (Index)

`anthropic` · `openai` · `google` · `deepseek`

The other seven labs — `minimax`, `xiaomi`, `qwen`, `moonshotai`, `z-ai`, `mistralai`, `meta-llama` — are Premium and Full only.

## API keys

Keys are created in [Settings → API Keys](https://data.ornn.com/settings?tab=api-keys). The prefix **is** the tier: the backend identifies a key from the secret itself, not from the owner's current database row.

| Who can mint                                                                   | Prefix     | What it unlocks                                                                                                                                    |
| ------------------------------------------------------------------------------ | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Own **trial** or **premium** grant                                             | `sk_prem_` | Every index family at daily grain, all-time. Forward curve. Memory, coding, workload, volume, frontier, buyers. **Not** hourly, neocloud, or chat. |
| Own **full** grant, or membership in a **Full** organization with no own grant | `sk_live_` | Unrestricted. Floor-dependent Full keys are revoked if the organization ceiling drops.                                                             |
| Index, or a trial/premium organization floor with no own grant                 | —          | Cannot mint.                                                                                                                                       |

<Warning>
  A `sk_prem_` key is Premium even if the permissions stamp is missing or the owner is later upgraded. A `sk_live_` key minted before Premium existed stays Full. Downgrading an account revokes its keys; mint again on the new tier.
</Warning>

See [Manage API keys](/docs/manage-api-keys) and [Authentication](/docs/authentication).

## Payments

* **Index** — no invoice.
* **Trial** — no invoice. 72 hours, starting on first visit. Request from [data.ornn.com/pricing](https://data.ornn.com/pricing) or [data@ornn.com](mailto:data@ornn.com). The clock is the cost.
* **Premium** — \$500 per month, server-pinned. Self-serve: Settings → Billing, or the subscribe button on `/pricing`. A saved card is charged automatically; otherwise Stripe emails a hosted invoice. Cancel by writing to [data@ornn.com](mailto:data@ornn.com). Bound by the [Premium Data Use Addendum](https://data.ornn.com/premium-data-use).
* **Full** — custom, organization-grained, billed through Rillet. Talk to [data@ornn.com](mailto:data@ornn.com).

## MCP

Access follows the same ladder. Paid tools need an **own** grant: a Full organization floor covers the product, not the unscoped MCP service key.

| Account                            | Tools                                                                                                                                                                                             |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Signed in, no paid grant           | Public tools, shaped to the Index window                                                                                                                                                          |
| Trial or Premium (own grant)       | Paid index-family tools plus `get_token_volume`, **daily grain**, complete daily history. Neocloud tools and `get_gpu_price_at` are not included; Model Frontier and Compute Buyers are REST-only |
| Full (own grant)                   | Every tool, full depth                                                                                                                                                                            |
| API key (`sk_prem_` or `sk_live_`) | Same as that key on the REST API                                                                                                                                                                  |

See [Ornn MCP](/docs/mcp-server).

## Rate limits

Public Index and catalog routes that use the public limiter are **60 requests / minute / IP**. Sending a key does not replace that limiter. `POST /api/chat` is the exception: **20 messages / minute / key**, because each call spends model tokens. See [Rate limits](/docs/rate-limits).


# Analytics
Source: https://data.ornn.com/docs/analytics

Annualized volatility and market utilization derived from the GPU price index.

Beyond raw prices, the API derives two analytics from the index history: price volatility and market utilization. Both need an API key and use the same GPU names and `startDate` / `endDate` parameters as the [history endpoints](/docs/price-index).

<CardGroup>
  <Card title="Volatility" href="/docs/api-reference/analytics/get-annualized-price-volatility">
    How much the price swings.
  </Card>

  <Card title="Utilization" href="/docs/api-reference/analytics/get-market-utilization">
    How much capacity is rented.
  </Card>
</CardGroup>

## Annualized volatility

`rolling_volatility` is the standard deviation of log returns over a rolling window, annualized. It is a decimal fraction, so `0.80` means roughly 80% annualized volatility. A higher number means the price moves more.

Two parameters shape the result:

* `windowDays` (default `30`, range `1` to `365`): the lookback for each point. A shorter window reacts faster, a longer one is smoother.
* `startDate` and `endDate` (both required): the span to return.

<CodeGroup>
  ```bash cURL theme={null}
  curl "https://api.ornnai.com/api/gpu/H100%20SXM/volatility?startDate=2026-03-01&endDate=2026-05-31&windowDays=30" \
    -H "Authorization: Bearer YOUR_API_KEY"
  ```

  ```python Python theme={null}
  import requests

  resp = requests.get(
      "https://api.ornnai.com/api/gpu/H100 SXM/volatility",
      params={"startDate": "2026-03-01", "endDate": "2026-05-31", "windowDays": 30},
      headers={"Authorization": "Bearer YOUR_API_KEY"},
  )
  series = resp.json()["data"]  # most recent first
  ```
</CodeGroup>

Each row pairs the index value with its volatility:

```json theme={null}
{
  "recorded_at": "2026-01-01T00:00:00.000Z",
  "gpu_type": "H100 SXM",
  "region": "global",
  "index_value": 2.00,
  "rolling_volatility": 0.20,
  "window_days": 30
}
```

See [Get annualized price volatility](/docs/api-reference/analytics/get-annualized-price-volatility) for all seven language examples.

## Market utilization

`utilization_ratio` is the share of tracked capacity that is currently rented, as a decimal fraction. `0.70` means about 70% utilized. Utilization often moves ahead of price, since tight supply tends to precede a price rise.

`GET /api/gpu/{gpuName}/volume-metrics?startDate=...&endDate=...` returns a series:

```json theme={null}
{
  "recorded_at": "2026-01-01T00:00:00.000Z",
  "utilization_ratio": 0.70
}
```

## Notes

* Every analytics endpoint needs an API key. See [Authentication](/docs/authentication).
* Series come back most-recent-first. Sort ascending before you plot or compute returns.
* Ranged analytics default to daily granularity. Hourly is available via the `granularity` parameter on a **Full** (`sk_live_`) key. A Premium key is served at daily even if it asks for hourly. See [Access tiers](/docs/access-tiers) and [The Price Index](/docs/price-index).


# Get annualized price volatility
Source: https://data.ornn.com/docs/api-reference/analytics/get-annualized-price-volatility

openapi.yaml GET /api/gpu/{gpuName}/volatility
Standard deviation of daily log returns over a rolling window, annualized. Results are most-recent-first.

## Overview

Standard deviation of daily log returns over a rolling window, annualized. Results are most-recent-first.


# Get current utilization for all GPUs
Source: https://data.ornn.com/docs/api-reference/analytics/get-current-utilization-for-all-gpus

openapi.yaml GET /api/gpu-utilization
The latest utilization reading for every tracked GPU in one call, with the
7- and 30-day means behind it. Takes no parameters.

Use this for a cross-section across GPUs. For one GPU's series over time,
use `/api/gpu/{gpuName}/volume-metrics`.

`utilization_ratio` is the share of tracked capacity rented, between 0 and 1,
and is bounded to the last 48 hours: a GPU whose feed has stopped returns
`null` rather than a stale figure. `avg_7d` and `avg_30d` are explicitly
windowed and still populate in that case. A GPU with no readings at all in
the 30-day window is absent from `data` rather than present with nulls.

Pinned to `region: "global"`.


## Overview

The latest utilization reading for every tracked GPU in one call, with the 7- and
30-day means behind it. Takes no parameters.

Use this for a cross-section across GPUs. For one GPU's series over time, use
[Get market utilization](/docs/api-reference/analytics/get-market-utilization).

## Reading the response

`utilization_ratio` is the share of tracked capacity rented, between 0 and 1, and is
bounded to the last 48 hours — a GPU whose feed has stopped returns `null` rather than
a stale figure. `avg_7d` and `avg_30d` are explicitly windowed and still populate in
that case, so neither can be misread as current.

A GPU with no readings at all in the 30-day window is absent from `data` rather than
present with nulls.

Results are pinned to `region: "global"`.


# Get market utilization
Source: https://data.ornn.com/docs/api-reference/analytics/get-market-utilization

openapi.yaml GET /api/gpu/{gpuName}/volume-metrics
The share of tracked capacity that is rented, between 0 and 1.

## Overview

The share of tracked capacity that is rented, between 0 and 1.


# List tracked compute buyers
Source: https://data.ornn.com/docs/api-reference/compute-buyers/list-tracked-compute-buyers

openapi.yaml GET /api/compute-buyers
Compute Buyers: AI-native startups that raised 10 million dollars or more in a single event, classified by the workload their compute is for (`tier` T1 trains models, T2 heavy inference or AI infrastructure, T3 GPU-adjacent HPC). Built from SEC Form D filings and announced rounds. A snapshot rather than a daily series - the list moves as new raises are verified. Requires an API key - there is no free tier.


## Overview

Compute Buyers: AI-native startups that raised \$10M or more in a single event, classified by the workload their compute is for - `tier` T1 trains models, T2 runs heavy inference or AI infrastructure, T3 is GPU-adjacent HPC. Built from SEC Form D filings and announced rounds. This is a snapshot rather than a daily series: the list moves as new raises are verified, and `count` carries the current size. Requires an API key - there is no free tier.


# Get current price for one GPU
Source: https://data.ornn.com/docs/api-reference/current-prices/get-current-price-for-one-gpu

openapi.yaml GET /api/gpu/{gpuName}
The current price index for a single GPU model, in USD per GPU-hour.

## Overview

The current price index for a single GPU model, in USD per GPU-hour.


# Get latest daily index for all GPUs
Source: https://data.ornn.com/docs/api-reference/current-prices/get-latest-daily-index-for-all-gpus

openapi.yaml GET /api/daily-index/all
The latest daily index for every tracked GPU in one call. Public, no key required.

## Overview

The latest daily index for every tracked GPU in one call. Public, no key required.


# Get latest daily index for one GPU
Source: https://data.ornn.com/docs/api-reference/current-prices/get-latest-daily-index-for-one-gpu

openapi.yaml GET /api/daily-index
The latest daily index value for one GPU. Public, no key required.

## Overview

The latest daily index value for one GPU. Public, no key required.


# Get previous day's daily index
Source: https://data.ornn.com/docs/api-reference/current-prices/get-previous-days-daily-index

openapi.yaml GET /api/daily-index/{gpuName}/previous
The previous day's daily index for a GPU. Useful for day-over-day comparisons.

## Overview

The previous day's daily index for a GPU. Useful for day-over-day comparisons.


# Get today's daily index
Source: https://data.ornn.com/docs/api-reference/current-prices/get-todays-daily-index

openapi.yaml GET /api/day-index
**Deprecated — use `/api/daily-index` instead**, which returns the same most-recent daily index value for one GPU. This alias is kept for backward compatibility and may be removed in a future version. For the current (hourly) price use `/api/gpu/{gpuName}`; for every GPU at once use `/api/daily-index/all`. Public, no key required.


## Overview

**Deprecated - use `/api/daily-index` instead**, which returns the same most-recent daily index value for one GPU. This alias is kept for backward compatibility and may be removed in a future version. For the current (hourly) price use `/api/gpu/{gpuName}`; for every GPU at once use `/api/daily-index/all`. Public, no key required.


# Get the published forward curve
Source: https://data.ornn.com/docs/api-reference/forward/get-the-forward-curve

openapi.yaml GET /api/forward
The published GPU forward curve: current marks only, for every paying key (`sk_prem_` and `sk_live_`). `data` carries the curves with at least one published mark; `suppressed` carries fully unmarked curves, whose points have a null `price` and a machine-readable `insufficient_data` reason. Each published point includes provenance and its mark edit or publish time, and `asOf` is the most recent mark timestamp in the response. Marks are hand-published rather than settled on a cadence, so responses change only when a mark does. Historical marks are not available on the customer API.


## Overview

The published GPU forward curve: current marks only, for every paying key (`sk_prem_` and `sk_live_`). `data` carries the curves with at least one published mark; `suppressed` carries the fully unmarked curves, whose points have a null `price` and a machine-readable `insufficient_data` reason - the service never interpolates, carries forward, or fills a missing mark with a default. Each published point includes provenance and its mark edit or publish time, and `asOf` is the most recent mark timestamp in the response.

Marks are hand-published rather than settled on a cadence, so responses change only when a mark does. Historical marks are not available on the customer API. Requires an API key - there is no free tier; the website catalog shows the curve products without a marks API.


# Get a clean daily/hourly series
Source: https://data.ornn.com/docs/api-reference/historical-prices/get-a-clean-dailyhourly-series

openapi.yaml GET /api/gpu/{gpuName}/history-simple
A clean timestamp / index_value series, ideal for charts and DataFrames. Points are most-recent-first.

## Overview

A clean timestamp / index\_value series, ideal for charts and DataFrames. Points are most-recent-first.


# Get a public daily series
Source: https://data.ornn.com/docs/api-reference/historical-prices/get-a-public-daily-series

openapi.yaml GET /api/gpu/{gpuName}/index-history
Daily index series for a public GPU. Without a key, the free tier covers 5 GPUs — `H100 SXM`, `H200`, `B200`, `A100 SXM4`, `RTX 5090` — for the trailing 3 months (the same window charted for free on index.ornn.com); any other GPU (e.g. `RTX PRO 6000 WS`) requires a key. Pass your API key to unlock the full history back to the earliest available data. The response includes `access: "public-3mo" | "premium" | "full"`. Rate-limited per IP for anonymous callers.


## Overview

Daily index series for a public GPU. Without a key, the free tier covers 5 GPUs - `H100 SXM`, `H200`, `B200`, `A100 SXM4`, `RTX 5090` - for the trailing 3 months (the same window charted for free on index.ornn.com); any other GPU (e.g. `RTX PRO 6000 WS`) requires a key. Pass your API key to unlock the full history back to the earliest available data. The response includes `access: "public-3mo" | "premium" | "full"`. Rate-limited per IP for anonymous callers.


# Get history rows with metadata
Source: https://data.ornn.com/docs/api-reference/historical-prices/get-history-rows-with-metadata

openapi.yaml GET /api/gpu/{gpuName}/history-range
Richer history rows over a date range, with per-row granularity.

## Overview

Richer history rows over a date range, with per-row granularity.


# Get index value nearest a timestamp
Source: https://data.ornn.com/docs/api-reference/historical-prices/get-index-value-nearest-a-timestamp

openapi.yaml GET /api/gpu/{gpuName}/history
Returns the index value of the record nearest the requested time, with the gap reported in time_difference.

## Overview

Returns the index value of the record nearest the requested time, with the gap reported in time\_difference.


# Get the full H100 daily series
Source: https://data.ornn.com/docs/api-reference/historical-prices/get-the-full-h100-daily-series

openapi.yaml GET /api/h100-history
The H100 SXM global daily index as a clean timestamp and value series. Without a key you get the trailing 3 months (the same free window on index.ornn.com); pass your API key to unlock the full history back to the earliest available data. The response includes `access: "public-3mo" | "premium" | "full"`.


## Overview

The H100 SXM global daily index as a clean timestamp and value series. Without a key you get the trailing 3 months (the same free window on index.ornn.com); pass your API key to unlock the full history back to the earliest available data. The response includes `access: "public-3mo" | "premium" | "full"`.


# Get the daily history for an LLM coding product
Source: https://data.ornn.com/docs/api-reference/llm-coding/get-the-daily-history-for-an-llm-coding-product

openapi.yaml GET /api/llm-coding/history
Daily history for an LLM coding-activity index, oldest first. Requires an API key — LLM coding analytics have no free tier. Note this is a coding-activity index, not one of the public token price indices (those are OTPI, under `/api/otpi`). Single-tool products return rows with a single `value`; compare products return rows with both `value` and `value2`, ordered to match `seriesLabels`. Pass `startDate` and `endDate` (`YYYY-MM-DD`, inclusive) to bound the window. `limit` caps the row count (default `2000`). An unknown `product` returns `400`; a valid product with no rows in the window returns `200` with an empty `data` array (this endpoint never returns `404`).


## Overview

Daily history for an LLM coding-activity index, oldest first. Requires an API key - LLM coding analytics have no free tier. Note this is a coding-activity index, not one of the public token price indices (those are OTPI, under `/api/otpi`). Single-tool products return rows with a single `value`; compare products return rows with both `value` and `value2`, ordered to match `seriesLabels`. Pass `startDate` and `endDate` (`YYYY-MM-DD`, inclusive) to bound the window. `limit` caps the row count (default `2000`). An unknown `product` returns `400`; a valid product with no rows in the window returns `200` with an empty `data` array (this endpoint never returns `404`).


# Get the latest value for an LLM coding product
Source: https://data.ornn.com/docs/api-reference/llm-coding/get-the-latest-value-for-an-llm-coding-product

openapi.yaml GET /api/llm-coding/index
The most recent daily value for a single (non-compare) LLM coding product, with the day-over-day percent change. Requires an API key — LLM coding analytics have no free tier. `changePct` is `null` when there is no previous day on file or the previous value was zero. Compare products such as `cc-vs-codex` are not valid here — use `/api/llm-coding/history` for those.


## Overview

The most recent daily value for a single (non-compare) LLM coding product, with the day-over-day percent change. Requires an API key - LLM coding analytics have no free tier. `changePct` is `null` when there is no previous day on file or the previous value was zero. Compare products such as `cc-vs-codex` are not valid here - use `/api/llm-coding/history` for those.


# List available LLM coding products
Source: https://data.ornn.com/docs/api-reference/llm-coding/list-available-llm-coding-products

openapi.yaml GET /api/llm-coding/products
The list of pre-built products exposed by the LLM coding endpoints. Each product pairs a tool with a metric (PRs, commits, or merge rate). Use this to drive a selector without hard-coding product IDs.


## Overview

The list of pre-built products exposed by the LLM coding endpoints. Each product pairs a tool with a metric (PRs, commits, or merge rate). Use this to drive a selector without hard-coding product IDs.


# Get current memory spot prices
Source: https://data.ornn.com/docs/api-reference/memory/get-current-memory-spot-prices

openapi.yaml GET /api/memory-index
Current memory spot prices. With no params, returns all types. Narrow with type or category.

## Overview

Current memory spot prices. With no params, returns all types. Narrow with `type` (frozen `id` or name) or `category`.


# Get memory price history
Source: https://data.ornn.com/docs/api-reference/memory/get-memory-price-history

openapi.yaml GET /api/memory/{memoryType}/history

## Overview

Historical spot prices for a single memory type, oldest-first. Pair this with `/api/memory-types` to discover valid `id` or `memoryType` values.


# List tracked memory types
Source: https://data.ornn.com/docs/api-reference/memory/list-tracked-memory-types

openapi.yaml GET /api/memory-types

## Overview

Returns every memory type Ornn tracks as `{ id, memory_type, category }`. `id` is the stable ≤32-character key (for example `mem_ddr4_16gb`); `memory_type` is the display name. Pass either `id` or `memory_type` as `type` on `/api/memory-index`.


# Get the Model Frontier dataset
Source: https://data.ornn.com/docs/api-reference/model-frontier/get-the-model-frontier-dataset

openapi.yaml GET /api/model-frontier
The Model Frontier dataset: benchmark capability against transacted price per task. `models` is the per-model scatter - Epoch Capabilities Index plus SWE-bench Verified / GPQA Diamond / AIME scores, priced with token-weighted OTPI dollars per million tokens as of the last benchmark refresh (`costPerTask` = `price` x `tpt` / 1e6). `tests` lists the tracked thinking-level benchmarks, `efforts` carries every (model x thinking level) run per test, and `releaseDates` maps model display names to first-release dates (YYYY-MM-DD) - join it against the `efforts` rows to reconstruct the frontier as of any past date. `history` carries real month-by-month prices where they exist (currently GPQA Diamond only); for the tracked benchmarks, past frontier states come from `efforts` + `releaseDates`. The dataset refreshes on benchmark refresh rather than daily, so responses are stable between refreshes. Requires an API key - there is no free tier.


## Overview

The Model Frontier dataset: benchmark capability against transacted price per task, for every model and thinking level. `models` is the per-model scatter - Epoch Capabilities Index and SWE-bench Verified / GPQA Diamond / AIME scores, priced with token-weighted OTPI dollars per million tokens as of the last benchmark refresh (`costPerTask` = `price` × `tpt` / 1e6). `tests` lists the tracked thinking-level benchmarks, `efforts` carries every (model × thinking level) run per test, and `releaseDates` maps model display names to first-release dates - join it against the `efforts` rows to reconstruct the frontier as it stood on any past date. `history` carries real month-by-month prices where they exist (currently GPQA Diamond only). A model with no real score on an axis is dropped from that view, never estimated. The dataset moves on benchmark refresh, not daily. Requires an API key - there is no free tier.


# Aggregate sites by country or GPU type
Source: https://data.ornn.com/docs/api-reference/neo-cloud-sites/aggregate-sites-by-country-or-gpu-type

openapi.yaml GET /api/neocloud/sites/aggregate
Aggregate power capacity, GPU quantity, and site counts grouped by country or by GPU type. Useful for regional/technology risk rollups. Defaults to neo-cloud sites; `scope=all` widens to the full set. For `by=gpu_type`, a site listing multiple chips (e.g. `H100/A100`) contributes to each of its chip-type buckets; sites with no recognized chip fall under `Other`.


## Overview

Aggregate power capacity, GPU quantity, and site counts grouped by country or by GPU type. Useful for regional/technology risk rollups. Defaults to neo-cloud sites; `scope=all` widens to the full set. For `by=gpu_type`, a site listing multiple chips (e.g. `H100/A100`) contributes to each of its chip-type buckets; sites with no recognized chip fall under `Other`. To drill a `by=country` bucket down to its sites, pass its `key` as `country` (with the same `scope`) to the [region query](/docs/api-reference/neo-cloud-sites/query-neo-cloud-sites-by-region).


# Query neo-cloud sites by region
Source: https://data.ornn.com/docs/api-reference/neo-cloud-sites/query-neo-cloud-sites-by-region

openapi.yaml GET /api/neocloud/sites
Return GPU data-center sites in a geographic region, looked up by city name, by coordinates with a radius, or by country name alone. Each site includes GPU types, quantity, power capacity, chip generation, business category, and key customer, along with its location. By default only neo-cloud sites (GPU-as-a-service providers) are returned. Pass `scope=all` to include the full site set (AI supercomputers and other GPU asset owners). A country-only query is the drill-down from `/api/neocloud/sites/aggregate?by=country`: pass a bucket's `key` as `country` (and the same `scope`) to list the sites behind it, including the `Unknown` bucket for sites with no country on file. A large country can exceed the default `limit=100` — page with `limit`/`offset` to reach the full bucket.


## Overview

Return GPU data-center sites in a geographic region, looked up by city name, by coordinates with a radius, or by country name alone. A country-only query is the drill-down from the [aggregate endpoint](/docs/api-reference/neo-cloud-sites/aggregate-sites-by-country-or-gpu-type): pass a `by=country` bucket's `key` as `country` (and the same `scope`) to list the sites behind it, including the `Unknown` bucket for sites with no country on file. A large country can exceed the default `limit=100` — page with `limit`/`offset` to reach the full bucket. Each site includes GPU types, quantity, power capacity, chip generation, business category, and key customer, along with its location. By default only neo-cloud sites (GPU-as-a-service providers) are returned. Pass `scope=all` to include the full site set (AI supercomputers and other GPU asset owners).


# Health check
Source: https://data.ornn.com/docs/api-reference/reference/health-check

openapi.yaml GET /health
Liveness and database check. Public, no key required.

## Overview

Liveness and database check. Public, no key required.


# List free-tier GPU models
Source: https://data.ornn.com/docs/api-reference/reference/list-free-tier-gpu-models

openapi.yaml GET /api/gpu-types-free
Returns the GPU indices available on the public (no-key) tier. Pair this with `/api/gpu-types` — the full catalog Ornn tracks — to render the free-vs-paid split. The response does not vary by caller tier, so a keyed caller can still ask "what is free?" to build pricing or upsell UI.


## Overview

Returns the GPU indices available on the public (no-key) tier. Pair this with `/api/gpu-types` - the full catalog Ornn tracks - to render the free-vs-paid split. The response does not vary by caller tier, so a keyed caller can still ask "what is free?" to build pricing or upsell UI.


# List supported GPU models
Source: https://data.ornn.com/docs/api-reference/reference/list-supported-gpu-models

openapi.yaml GET /api/gpu-types

## Overview

The full catalog of GPU models Ornn tracks, across both the free and paid tiers. Pair this with `/api/gpu-types-free` to render the free-vs-paid split.


# Get the latest token price index by lab
Source: https://data.ornn.com/docs/api-reference/token-prices/get-the-latest-token-price-index-by-lab

openapi.yaml GET /api/otpi
The Ornn Token Price Index (OTPI): a daily, volume-weighted blended price per million tokens for each major model lab. Returns the latest settled day by default, a specific `date`, or a `startDate`/`endDate` range. Use `lab` to filter to a single lab. Without a key, the free tier covers 4 labs — `anthropic`, `openai`, `google`, `deepseek` — for the trailing 1 month (the same free window on index.ornn.com); other labs and older history require an API key. The response includes `access: "public-1mo" | "premium" | "full"`.


## Overview

The Ornn Token Price Index (OTPI): a daily, volume-weighted blended price per million tokens for each major model lab. Returns the latest settled day by default, a specific `date`, or a `startDate`/`endDate` range. Use `lab` to filter to a single lab. Without a key, the free tier covers 4 labs - `anthropic`, `openai`, `google`, `deepseek` - for the trailing 1 month (the same free window on index.ornn.com); other labs and older history require an API key. The response includes `access: "public-1mo" | "premium" | "full"`.


# List free-tier OTPI labs
Source: https://data.ornn.com/docs/api-reference/token-prices/list-free-tier-otpi-labs

openapi.yaml GET /api/token-types-free
Returns the OTPI labs available on the public (no-key) tier as `{ lab, label }` pairs. Pair this with `/api/token-types` to render the free-vs-paid split. The response does not vary by caller tier.


## Overview

Returns the OTPI labs available on the public (no-key) tier as `{ lab, label }` pairs. Pair this with `/api/token-types` to render the free-vs-paid split. The response does not vary by caller tier.


# List tracked OTPI labs
Source: https://data.ornn.com/docs/api-reference/token-prices/list-tracked-otpi-labs

openapi.yaml GET /api/token-types
Returns every lab published by the Ornn Token Price Index (OTPI) as `{ lab, label }` pairs. Use this as the source of truth for valid `lab` values on `/api/otpi` and `/api/workload` instead of hard-coding them or discovering them from `400` errors.


## Overview

Returns every lab published by the Ornn Token Price Index (OTPI) as `{ lab, label }` pairs. Use this as the source of truth for valid `lab` values on `/api/otpi` and `/api/workload` instead of hard-coding them or discovering them from `400` errors.


# Get the Token Volume Index by day
Source: https://data.ornn.com/docs/api-reference/token-volume/get-the-token-volume-index-by-day

openapi.yaml GET /api/token-volume
The Token Volume Index: settled daily token volume for the closed frontier labs (`anthropic`, `openai`, `google`), with each lab indexed to 100 at its own first settled day (`growthIndex`), its share of the closed-lab daily total (`share`), and the combined total indexed to 100 (`totalGrowthIndex`). The index is fixed-base: baselines anchor to each lab's first settled day ever, not to the first day of the requested window, so overlapping windows return identical values for the same date. A lab absent for a day is left out of that day's `labs` array rather than carried as a zero. Daily grain only. Requires an API key - like the Workload Cost Index there is no free tier. The analytics page at data.ornn.com/analytics/models/volume covers all 11 labs behind a weight-class selector - closed source or open source, then the labs inside that class - with a shared growth baseline and an open/closed split, recomputed from the same settled volumes; those views are not extra fields on this endpoint.


## Overview

The Token Volume Index: settled daily token volume for the closed frontier labs (`anthropic`, `openai`, `google`). Each lab carries its volume indexed to 100 at **its own** first settled day (`growthIndex`) and its share of the closed-lab daily total (`share`); the combined total rides alongside as `totalGrowthIndex`. Both `startDate` and `endDate` are required - the series is read over an explicit window. The window selects which days come back; baselines stay anchored to each lab's first settled day in the full history, so overlapping windows return identical values for the same date. A lab that settled no volume on a day is left out of that day's `labs` array rather than reported as zero. Daily grain only. Requires an API key - like the Workload Cost Index, no part of this dataset has a free tier.

The analytics page at [data.ornn.com/analytics/models/volume](https://data.ornn.com/analytics/models/volume) offers all 11 OTPI labs with independent selectors, a shared growth baseline, and an open/closed split, recomputed from the same settled volumes. Those views are not extra fields on this endpoint. See [The Token Volume Index](/docs/token-volume-index).


# Get the Workload Cost Index by provider
Source: https://data.ornn.com/docs/api-reference/workload-cost/get-the-workload-cost-index-by-provider

openapi.yaml GET /api/workload
The Workload Cost Index: daily settled cents per request, a mix-purged like-for-like index, and tokens per request for each closed-lab provider (`anthropic`, `openai`, `google`). With no `startDate` or `endDate` this returns the entire settled history for every provider and model family, so pass a range unless you actually want the full series - the unfiltered payload grows with every settlement day. Use `lab` to filter to a single provider. Requires an API key - unlike the GPU and token indices, the Workload Cost Index has no free tier.


## Overview

The Workload Cost Index: daily settled cents per request, a mix-purged like-for-like index, and tokens per request for each closed-lab provider (`anthropic`, `openai`, `google`). With no `startDate` or `endDate` this returns the entire settled history for every provider and model family, so pass a range unless you actually want the full series - the unfiltered payload grows with every settlement day. Use `lab` to filter to a single provider. Requires an API key - unlike the GPU and token indices, the Workload Cost Index has no free tier.


# Authentication
Source: https://data.ornn.com/docs/authentication

How to authenticate with the Ornn Data API using a Bearer API key, and which endpoints require one.

The Ornn Data API authenticates requests with an **API key** passed as a Bearer token, and not every endpoint requires one.

## The Authorization header

Send your key in the `Authorization` header on every request to a protected endpoint:

```
Authorization: Bearer YOUR_API_KEY
```

<CodeGroup>
  ```bash cURL theme={null}
  curl "https://api.ornnai.com/api/gpu/H100%20SXM" \
    -H "Authorization: Bearer YOUR_API_KEY"
  ```

  ```python Python theme={null}
  import requests

  resp = requests.get(
      "https://api.ornnai.com/api/gpu/H100 SXM",
      headers={"Authorization": "Bearer YOUR_API_KEY"},
  )
  ```

  ```javascript JavaScript theme={null}
  const res = await fetch("https://api.ornnai.com/api/gpu/H100 SXM", {
    headers: { Authorization: "Bearer YOUR_API_KEY" },
  });
  ```

  ```php PHP theme={null}
  <?php
  $ch = curl_init("https://api.ornnai.com/api/gpu/" . rawurlencode("H100 SXM"));
  curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_HTTPHEADER => ["Authorization: Bearer YOUR_API_KEY"],
  ]);
  $data = json_decode(curl_exec($ch), true);
  ```

  ```go Go theme={null}
  package main

  import (
  	"net/http"
  	"net/url"
  )

  func main() {
  	endpoint := "https://api.ornnai.com/api/gpu/" + url.PathEscape("H100 SXM")
  	req, _ := http.NewRequest("GET", endpoint, nil)
  	req.Header.Set("Authorization", "Bearer YOUR_API_KEY")
  	resp, _ := http.DefaultClient.Do(req)
  	defer resp.Body.Close()
  }
  ```

  ```java Java theme={null}
  import java.net.URI;
  import java.net.http.HttpClient;
  import java.net.http.HttpRequest;
  import java.net.http.HttpResponse;

  HttpClient client = HttpClient.newHttpClient();
  HttpRequest request = HttpRequest.newBuilder(
          URI.create("https://api.ornnai.com/api/gpu/H100%20SXM"))
      .header("Authorization", "Bearer YOUR_API_KEY")
      .build();
  HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
  ```

  ```ruby Ruby theme={null}
  require "net/http"

  uri = URI("https://api.ornnai.com/api/gpu/H100%20SXM")
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer YOUR_API_KEY"
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  ```
</CodeGroup>

## Getting a key

API keys are created in the dashboard, not through the API. Sign in to [data.ornn.com](https://data.ornn.com), go to **Settings → API Keys**, and create one. See [Manage API keys](/docs/manage-api-keys) for details.

<Warning>
  Your full key (`sk_prem_...` on Trial/Premium, `sk_live_...` on Full) is shown **only once**, at creation. Store it somewhere safe. If you lose it, revoke it and create a new one. You cannot retrieve it later.
</Warning>

## Which endpoints need a key?

Ornn Data's access tiers are **Index** (free), **Premium** (\$500/month, or a 72-hour trial), and **Full** (custom). Index mirrors what you can already see on [index.ornn.com](https://index.ornn.com). A `sk_prem_` key unlocks every index family at daily grain with complete history. A `sk_live_` key unlocks hourly and neocloud site data. See [Access tiers](/docs/access-tiers) for the full matrix and [data.ornn.com/pricing](https://data.ornn.com/pricing) for prices.

### Granularity by tier

| Tier                     | Granularity      | History                           |
| ------------------------ | ---------------- | --------------------------------- |
| Free / anonymous         | Daily            | Trailing window only              |
| **Premium** (`sk_prem_`) | **Daily only**   | **Complete — no trailing window** |
| Full (`sk_live_`)        | Daily and hourly | Complete                          |

Premium is a daily-grain tier at every range: the 1-year view, the all-time view and API-key access are all served at daily. A request for `granularity=hourly` or `auto` is answered at daily rather than refused, so existing integrations keep working — read the `granularity` field on the response to see what you were served. The endpoints that exist only to serve sub-daily data — `/api/gpu/{gpuName}/hourly`, `/api/gpu/{gpuName}/rolling-24h-average`, `/api/power/load`, and `/api/power/fuel-mix` — return `403` for a Premium key; all are included with a Full subscription. Daily history at `/api/gpu/{gpuName}/rolling-24h-average/history` remains Premium.

**Public GPU indices** (current price + **trailing 3 months** of history, no key): `H100 SXM`, `H200`, `B200`, `A100 SXM4`, `RTX 5090`.

**Public token indices — OTPI** (current value + **trailing 1 month** of history, no key): `anthropic`, `openai`, `google`, `deepseek`.

| Access                                            | Endpoints                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Public — GPU, 3-month window**                  | `/api/gpu/{gpuName}` (current price), `/api/gpu/{gpuName}/index-history`, `/api/h100-history` — **free-5 GPUs only**                                                                                                                                                                                                                                                                                                                                                                                                       |
| **Public — GPU, trailing 7 settled days**         | `/api/daily-index`, `/api/daily-index/all`, `/api/day-index` (deprecated), `/api/daily-index/{gpuName}/previous` — the settled daily index reaches back **7 days**, not 3 months, for every caller; the 3-month series is `/api/gpu/{gpuName}/index-history`. **Free-5 GPUs only** without a key                                                                                                                                                                                                                           |
| **Public — token (OTPI), 1-month window**         | `/api/otpi` — **free-4 labs only**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **Public — no data windowing**                    | `/health`; catalogs `/api/gpu-types`, `/api/gpu-types-free`, `/api/token-types`, `/api/token-types-free`, `/api/memory-types`, `/api/llm-coding/products`                                                                                                                                                                                                                                                                                                                                                                  |
| **Premium or Full key (`sk_prem_` / `sk_live_`)** | Every other index: `RTX PRO 6000 WS`, OTPI labs outside the free-4, memory prices and history, Workload Cost (`/api/workload`), LLM coding values and history, the forward curve (`/api/forward`), Token Volume (`/api/token-volume`), Model Frontier (`/api/model-frontier`), Compute Buyers (`/api/compute-buyers`), daily Power Markets (`/api/power/markets`), volatility and volume analytics (`/api/gpu/{gpuName}/volume-metrics`, `/api/gpu-utilization`), and ranged GPU history. Premium is **daily grain only**. |
| **Full key only (`sk_live_`)**                    | GPU hourly route, the current-value rolling 24-hour average (`/api/gpu/{gpuName}/rolling-24h-average`), hourly power operations (`/api/power/load`, `/api/power/fuel-mix`), and neocloud site routes (`/api/neocloud/sites`, `/api/neocloud/map`, `/api/neocloud/sites/aggregate`). A Premium key returns `403`. Daily history at `/api/gpu/{gpuName}/rolling-24h-average/history` remains Premium.                                                                                                                        |

<Note>
  On the windowed endpoints, an anonymous request returns the free window and includes `"access": "public-3mo"` (GPU) or `"public-1mo"` (OTPI). Send your API key to reach the complete history — the response then returns `"access": "premium"` (Premium/`sk_prem_`) or `"access": "full"` (Full/`sk_live_`). A `startDate` earlier than the free window, a non-free GPU, or a non-free OTPI lab is only served with a key (otherwise `401`). The Workload Cost Index and LLM coding analytics do not have a free window: `/api/workload`, `/api/llm-coding/index`, and `/api/llm-coding/history` require a key on every request.
</Note>

<Tip>
  To discover the free-vs-paid split at runtime — for example to render a pricing table — pair the full catalog with its `-free` companion: `/api/gpu-types` with [`/api/gpu-types-free`](/docs/api-reference/reference/list-free-tier-gpu-models), and [`/api/token-types`](/docs/api-reference/token-prices/list-tracked-otpi-labs) with [`/api/token-types-free`](/docs/api-reference/token-prices/list-free-tier-otpi-labs). The `-free` routes return the same list regardless of caller tier.
</Tip>

<Note>
  Public index and catalog routes that use the public limiter are limited to 60 requests/minute per IP. Because the limiter runs before optional authentication, sending a valid API key does not switch those requests to a separate per-key limit. See [Rate limits](/docs/rate-limits).
</Note>

## Authentication errors

If the key is missing, malformed, or invalid, you get a `401`:

```json theme={null}
{
  "error": "Unauthorized",
  "message": "API key required. Use Authorization: Bearer YOUR_API_KEY"
}
```

```json theme={null}
{
  "error": "Unauthorized",
  "message": "Invalid API key"
}
```

A revoked key returns `{"error": "Unauthorized", "message": "API key is inactive"}`. See [Errors & status codes](/docs/errors) for the full list.


# Chart prices in JavaScript
Source: https://data.ornn.com/docs/chart-javascript

Fetch a GPU price series and render it in the browser.

This guide fetches an H100 SXM price series and prepares it for a chart in the browser.

## Prerequisites

* A browser origin allowed by the Ornn API's CORS configuration, or a server-side proxy you control.

<Warning>
  Public access means the free-tier [`/index-history`](/docs/api-reference/historical-prices/get-a-public-daily-series) data needs no key for server-to-server requests. It does not allow every website to call the API directly: browser CORS checks reject unlisted origins. Use your own backend for a third-party site, and never embed an API key in browser code.
</Warning>

## Fetch the series

The direct browser request below works only from an origin configured by Ornn. The dates are computed at runtime to remain inside the trailing 3-month public window:

```javascript theme={null}
const BASE = "https://api.ornnai.com";

function isoDate(daysAgo) {
  const value = new Date();
  value.setUTCDate(value.getUTCDate() - daysAgo);
  return value.toISOString().slice(0, 10);
}

async function getSeries(gpu, startDate, endDate) {
  const url = new URL(`${BASE}/api/gpu/${encodeURIComponent(gpu)}/index-history`);
  url.searchParams.set("startDate", startDate);
  url.searchParams.set("endDate", endDate);

  const res = await fetch(url);
  if (!res.ok) throw new Error(`Request failed: ${res.status}`);

  const { data } = await res.json();
  // Sort ascending and shape for a charting library
  return data
    .map((p) => ({ x: new Date(p.timestamp), y: p.index_value }))
    .sort((a, b) => a.x - b.x);
}

const startDate = isoDate(30);
const endDate = isoDate(0);
const series = await getSeries("H100 SXM", startDate, endDate);
console.log(series[0]); // { x: Date, y: index_value }
```

## Render with Chart.js

```javascript theme={null}
import Chart from "chart.js/auto";

const points = await getSeries("H100 SXM", startDate, endDate);

new Chart(document.getElementById("price-chart"), {
  type: "line",
  data: {
    datasets: [{ label: "H100 SXM (USD/hr)", data: points }],
  },
  options: {
    scales: { x: { type: "time" }, y: { title: { display: true, text: "USD per hour" } } },
  },
});
```

<Frame>
  <img alt="H100 SXM price index line chart over a trailing 30-day window" />

  <img alt="H100 SXM price index line chart over a trailing 30-day window" />
</Frame>

<Tip>
  For authenticated endpoints (analytics, full history), put the `Authorization: Bearer` request on your server and forward only the data to the browser.
</Tip>


# Data dictionary
Source: https://data.ornn.com/docs/data-dictionary

Every dataset and field a subscriber receives, with Index, Premium, and Full coverage. Version 4.0.

Every dataset and every field a subscriber receives, tagged by plan. Delivered through [data.ornn.com](https://data.ornn.com) and the REST API at `https://api.ornnai.com`, with CSV/XLSX export from in-app charts and tables on **Full** only. (The public Index page offers its own CSV of the free-window chart — that series is already public; Full-tier exports cover every dataset and the complete history.)

The Index window is served on the public Index pages and the public API routes; the signed-in `/analytics` workspace requires an approved account, and shows locked previews to everyone else.

This is version **4.0**, effective August 19, 2026. It supersedes the v3 dictionary (Public vs Full Data only) by adding **Premium** (\$500/month, daily grain) as a first-class column. Compare plans at [data.ornn.com/pricing](https://data.ornn.com/pricing). Grain and key rules are in [Access tiers](/docs/access-tiers). When those rules change, this page must change with them — `backend/tests/data-dictionary-gating.test.js` fails the PR otherwise.

Ornn Data LLC, 447 Broadway FL 4, New York, NY 10013.

<Info>
  `access` on a keyed response is `premium` or `full`. On the Index window it is `public-3mo` (GPU) or `public-1mo` (OTPI).
</Info>

## 1. Datasets

| #  | Dataset                    | What it measures                                                   | Unit                                                | Cadence                         | Index                                 | Premium / Trial                                       | Full                                                                                                                      |
| -- | -------------------------- | ------------------------------------------------------------------ | --------------------------------------------------- | ------------------------------- | ------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| 2  | Compute Price Index (OCPI) | Cost to rent GPU compute                                           | USD per GPU-hour                                    | Hourly prints, daily settlement | 5 of 6 GPUs, trailing 3 months, daily | All 6 GPUs, all-time, **daily only**                  | All 6 GPUs, all grains, all-time                                                                                          |
| 3  | Compute analytics          | Volatility and utilization on the GPU index                        | Decimal fraction                                    | Hourly or daily                 | None                                  | Daily, all-time                                       | All grains, all-time                                                                                                      |
| 4  | Forward Curves             | Published forward marks by tenor for tracked GPUs                  | USD per GPU-hour                                    | Mark edit/publish time          | Published types only                  | Published marks only                                  | Published marks only                                                                                                      |
| 5  | Memory Price Index         | Component and module spot prices                                   | USD per unit                                        | Each weekday                    | Catalog only                          | All 14 types, full history                            | Same                                                                                                                      |
| 6  | Token Price Index (OTPI)   | Lab-level blended token price                                      | USD per million tokens                              | Daily settlement                | 4 of 11 labs, trailing 1 month        | All 11 labs, all-time                                 | Same                                                                                                                      |
| 7  | Token Volume Index         | Daily token volume, share, growth, and open/closed split           | Index, base 100                                     | Daily settlement                | None                                  | Included                                              | Included                                                                                                                  |
| 8  | Workload Cost Index        | Cost per request, mix-purged unit cost, workload intensity         | Cents per request, index points, tokens per request | Daily settlement                | None                                  | Included                                              | Included                                                                                                                  |
| 9  | Model Frontier             | Benchmark capability against price per task                        | Score against USD per task                          | On benchmark refresh            | None                                  | Included                                              | Included                                                                                                                  |
| 10 | LLM Coding Analytics       | Public-GitHub PRs, merges, commits by coding tool                  | Counts and percent                                  | Daily                           | Product catalog only                  | Included                                              | Included                                                                                                                  |
| 11 | Power Markets              | Wholesale US power prices, volume, load, and grid operations       | USD per MWh, GWh, MW                                | Daily prices; hourly operations | None                                  | Daily prices via REST (`/api/power/markets`) + charts | Daily prices plus hourly load/fuel mix via REST (`/api/power/markets`, `/api/power/load`, `/api/power/fuel-mix`) + charts |
| 12 | Datacenter Sites           | Tracked AI datacenter sites, operators, power, hardware, timelines | Mixed                                               | Curated                         | Coordinates only                      | Coordinates only                                      | Full payload and API                                                                                                      |
| 13 | Compute Buyers             | Funded AI-native startups classified by workload                   | USD raised                                          | Snapshot                        | None                                  | Included                                              | Included                                                                                                                  |

Premium adds RTX PRO 6000 WS, the seven OTPI labs outside the Index four, unlimited **daily** history on both windowed series, and sections 3–11 and 13. Full adds hourly grain, hourly power operations, CSV/XLSX export, and the full datacenter-site payload. Trial is Premium with a 72-hour clock.

## 2. Compute Price Index (OCPI)

Per-GPU price series calculated from anonymized executed transactions. The index reflects transactions, not list prices. Published hourly on the hour and aggregated to a daily average. One region is populated, global.

**Tracked GPUs (6).** RTX PRO 6000 WS is Premium/Full only; the other five are on Index at a trailing 3 months, daily.

| GPU             | Index           | Premium         | Full                 |
| --------------- | --------------- | --------------- | -------------------- |
| H100 SXM        | 3 months, daily | All-time, daily | All grains, all-time |
| H200            | 3 months, daily | All-time, daily | All grains, all-time |
| A100 SXM4       | 3 months, daily | All-time, daily | All grains, all-time |
| B200            | 3 months, daily | All-time, daily | All grains, all-time |
| RTX 5090        | 3 months, daily | All-time, daily | All grains, all-time |
| RTX PRO 6000 WS | None            | All-time, daily | All grains, all-time |

| Field                       | Type             | Unit             | Description                                         | Example                  | Access                  |
| --------------------------- | ---------------- | ---------------- | --------------------------------------------------- | ------------------------ | ----------------------- |
| `gpu_type` / `gpu_name`     | string           | none             | The GPU model the series is for                     | H100 SXM                 | All                     |
| `region`                    | string           | none             | Geographic market, empty or `global`                | global                   | All                     |
| `date`                      | string, date     | none             | Settlement date of a daily index value              | 2026-07-17               | All                     |
| `timestamp` / `recorded_at` | string, ISO 8601 | UTC              | Date and time of a print or history point           | 2026-07-17T20:00:00.000Z | All                     |
| `index_value`               | number           | USD per GPU-hour | Published index value, rounded to a tenth of a cent | 2.00                     | All (windowed on Index) |
| `average_usd_per_hour`      | number           | USD per GPU-hour | Rolling 24-hour average price, published hourly     | 2.00                     | Full (hourly path)      |
| `last_updated`              | string, ISO 8601 | UTC              | When the value was computed                         | 2026-07-17T20:05:02.000Z | All                     |
| `access`                    | string           | none             | Tier served: `public-3mo`, `premium`, or `full`     | premium                  | All                     |
| `granularity`               | string           | none             | Grain actually served: `daily` or `hourly`          | daily                    | Keyed                   |

## 3. Compute analytics

Volatility and utilization derived from the GPU index history, per GPU. No Index window.

| Field                | Type             | Unit                        | Description                                                                                       | Example                  | Access                           |
| -------------------- | ---------------- | --------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------ | -------------------------------- |
| `recorded_at`        | string, ISO 8601 | UTC                         | Point timestamp                                                                                   | 2026-07-17T00:00:00.000Z | Premium+, daily; Full, any grain |
| `gpu_type`           | string           | none                        | GPU model                                                                                         | H100 SXM                 | Premium+                         |
| `region`             | string           | none                        | Market                                                                                            | global                   | Premium+                         |
| `index_value`        | number           | USD per GPU-hour            | Index value at that point                                                                         | 2.00                     | Premium+                         |
| `rolling_volatility` | number           | annualized decimal fraction | Standard deviation of log returns over the rolling window, annualized. 0.80 is roughly 80 percent | 0.20                     | Premium+                         |
| `window_days`        | number           | days                        | Lookback applied. Default 30, range 1 to 365                                                      | 30                       | Premium+                         |

Changes are in percentage points, not percent change: both ends are already percentages.

| Field               | Type             | Unit              | Description                                                          | Example                  | Access   |
| ------------------- | ---------------- | ----------------- | -------------------------------------------------------------------- | ------------------------ | -------- |
| `recorded_at`       | string, ISO 8601 | UTC               | Point timestamp                                                      | 2026-07-17T00:00:00.000Z | Premium+ |
| `utilization_ratio` | number           | decimal fraction  | Share of tracked capacity currently rented. 0.70 is about 70 percent | 0.70                     | Premium+ |
| `latestPct`         | number, nullable | percent           | Most recent day's mean utilization                                   | 70.4                     | Premium+ |
| `dayPoints`         | number, nullable | percentage points | Change against the prior day                                         | 1.2                      | Premium+ |
| `weekPoints`        | number, nullable | percentage points | Change against 7 days prior                                          | -0.8                     | Premium+ |
| `monthPoints`       | number, nullable | percentage points | Change against 30 days prior                                         | 4.1                      | Premium+ |

## 4. Forward Curves

Published forward marks by tenor for tracked GPUs.

The `data` array contains only curves with at least one persisted valid mark.

The `suppressed` array contains fully unmarked curves. Each suppressed point has a null price and a machine-readable reason.

The website catalog shows all nine curve products. It shows a dash for each missing mark.

A missing tenor remains a gap. The service never interpolates, carries forward, or fills a missing mark with a default.

The Index tier has no marks API.

**Tracked curves (9).** H100 SXM, H200, A100 SXM4, RTX 5090, B200, RTX PRO 6000 WS, B300, GB200, GB300.

**Tenors (5).** 1M (1 month), 6M (6), 1Y (12), 3Y (36), 5Y (60).

Curves read on a term basis (average cost to the tenor) or a forward basis (implied rate between two tenors), with the depreciation each curve implies.

| Field               | Type                       | Unit             | Description                                                                                                                    | Example                  | Access   |
| ------------------- | -------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------ | -------- |
| `data`              | array                      | none             | Curves with at least one published mark                                                                                        | H100 SXM curve           | Premium+ |
| `suppressed`        | array                      | none             | Tracked curves with no published marks                                                                                         | GB200 curve              | Premium+ |
| `name`              | string                     | none             | The GPU the curve is for                                                                                                       | H100 SXM                 | Premium+ |
| `label`             | string                     | none             | Tenor label                                                                                                                    | 1Y                       | Premium+ |
| `months`            | number                     | months           | Tenor in months                                                                                                                | 12                       | Premium+ |
| `price`             | number, nullable           | USD per GPU-hour | The forward mark at that tenor. `null` means no mark, never 0.00                                                               | 1.98                     | Premium+ |
| `has_mark`          | boolean                    | none             | Whether price is a real quote. `false` is a gap, never 0.00                                                                    | true                     | Premium+ |
| `provenance`        | object, nullable           | none             | Mark source, its `updated_at` edit/publish timestamp, and sample count when supplied. `null` for a gap                         | hand\_entered\_mark      | Premium+ |
| `as_of_date`        | string, ISO 8601, nullable | UTC              | Per-mark edit/publish timestamp; it is not the market observation time                                                         | 2026-08-12T00:00:00.000Z | Premium+ |
| `insufficient_data` | string, nullable           | none             | Gap reason. `no_observation` means that no valid stored mark exists. `insufficient_sample` is reserved for the suppression job | no\_observation          | Premium+ |
| `asOf`              | string, ISO 8601, nullable | UTC              | Latest mark edit/publish timestamp in the response; it is not a daily-settlement or observation timestamp                      | 2026-08-12T00:00:00.000Z | Premium+ |

## 5. Memory Price Index

Daily spot prices for 14 memory types in three categories, refreshed each weekday. No Index window on prices; the type catalog is public.

**Tracked memory types**

| Category | Memory types                                                                                                                                                          |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| dram     | DDR3 4Gb (512Mx8) 1600/1866, DDR4 8Gb (1Gx8) 3200, DDR4 8Gb (1Gx8) eTT, DDR4 16Gb (2Gx8) 3200, DDR4 16Gb (2Gx8) eTT, DDR5 16Gb (2Gx8) 4800/5600, DDR5 16Gb (2Gx8) eTT |
| flash    | MLC 32Gb (4Gx8), MLC 64Gb (8Gx8), SLC 1Gb (128Mx8), SLC 2Gb (256Mx8)                                                                                                  |
| module   | DDR4 UDIMM 16GB 3200, DDR5 RDIMM 32GB 4800/5600, DDR5 UDIMM 16GB 4800/5600                                                                                            |

| Field             | Type             | Unit    | Description                                  | Example                  | Access                           |
| ----------------- | ---------------- | ------- | -------------------------------------------- | ------------------------ | -------------------------------- |
| `memoryType`      | string           | none    | The tracked memory product                   | DDR4 16Gb (2Gx8) 3200    | Catalog: Index. Prices: Premium+ |
| `category`        | string           | none    | `dram`, `flash`, or `module`                 | dram                     | Catalog: Index. Prices: Premium+ |
| `price`           | number           | USD     | Latest daily spot price, the session average | 40.00                    | Premium+                         |
| `changePct`       | number           | percent | Change from the prior reading                | 0.00                     | Premium+                         |
| `weeklyHigh`      | number           | USD     | High over the trailing week                  | 50.00                    | Premium+                         |
| `weeklyLow`       | number           | USD     | Low over the trailing week                   | 30.00                    | Premium+                         |
| `date`            | string, ISO 8601 | UTC     | Price date                                   | 2026-07-17T00:00:00.000Z | Premium+                         |
| `timestamp`       | string, ISO 8601 | UTC     | Point timestamp on history rows              | 2026-07-17T00:00:00.000Z | Premium+                         |
| `sourceUpdatedAt` | string, ISO 8601 | UTC     | Upstream publication time                    | 2026-07-17T00:00:00.000Z | Premium+                         |
| `updatedAt`       | string, ISO 8601 | UTC     | When Ornn ingested the value                 | 2026-07-17T14:00:00.000Z | Premium+                         |

## 6. Token Price Index (OTPI)

A daily, volume-weighted blended price per million tokens for each lab, across its paid production models. Free tiers and open-weight self-hosting are excluded.

**Tracked labs (11).** The first four are Index at a trailing 1 month; the rest are Premium/Full only.

| Lab        | Label       | Index   | Premium / Full |
| ---------- | ----------- | ------- | -------------- |
| anthropic  | Anthropic   | 1 month | All-time       |
| openai     | OpenAI      | 1 month | All-time       |
| google     | Google      | 1 month | All-time       |
| deepseek   | DeepSeek    | 1 month | All-time       |
| minimax    | MiniMax     | None    | All-time       |
| xiaomi     | Xiaomi      | None    | All-time       |
| qwen       | Qwen        | None    | All-time       |
| moonshotai | Moonshot AI | None    | All-time       |
| z-ai       | Z.ai        | None    | All-time       |
| mistralai  | Mistral AI  | None    | All-time       |
| meta-llama | Meta Llama  | None    | All-time       |

| Field          | Type             | Unit                   | Description                                      | Example                  | Access                           |
| -------------- | ---------------- | ---------------------- | ------------------------------------------------ | ------------------------ | -------------------------------- |
| `date`         | string, date     | none                   | Settlement date the value covers                 | 2026-07-17               | All (windowed on Index)          |
| `lab`          | string           | none                   | Model provider identifier                        | anthropic                | All (lab list windowed on Index) |
| `indexPerMtok` | number           | USD per million tokens | Blended price per million tokens, full precision | 1.234567                 | All (windowed on Index)          |
| `computedAt`   | string, ISO 8601 | UTC                    | When the value was computed                      | 2026-07-18T12:00:00.000Z | All                              |
| `access`       | string           | none                   | Tier served, `public-1mo`, `premium`, or `full`  | premium                  | All                              |

## 7. Token Volume Index

Settled daily token volume OTPI has already counted. Daily granularity. No Index window. Open-weight models released by a closed lab and free variants are excluded before settlement.

**On the platform** ([data.ornn.com/analytics/models/volume](https://data.ornn.com/analytics/models/volume)): all 11 OTPI labs. Token Share and Volume Growth each have an independent selector (default: the closed frontier three). Share re-bases on the selection so the drawn lines always sum to 100%. Volume Growth indexes every plotted lab from one shared day — the first on which they all reported — and trims the window to start there. Frontier Token Volume stays the closed three combined, indexed to 100 at the first date. Open vs Closed Share splits the whole registry by model-weight class (three closed against eight open-weight) as a 100% band. See [The Token Volume Index](/docs/token-volume-index).

**On the REST API** at [`GET /api/token-volume`](/docs/api-reference/token-volume/get-the-token-volume-index-by-day): the closed-lab series only (`anthropic`, `openai`, `google`). Each lab's `growthIndex` is indexed to 100 at that lab's **own** first settled day, and `share` is of the closed-lab daily total. `startDate` and `endDate` required. The growth index is fixed-base: overlapping windows return identical values for the same date. The platform's shared baseline, selectable share, and open/closed split are recomputed from the same settled rows; they are not extra fields on this response.

| Field              | Type             | Unit             | Description                                                   | Access   |
| ------------------ | ---------------- | ---------------- | ------------------------------------------------------------- | -------- |
| `date`             | string, date     | none             | Settlement day                                                | Premium+ |
| `lab`              | string           | none             | Model provider identifier                                     | Premium+ |
| `totalTokens`      | number           | tokens           | Settled daily token volume for that lab                       | Premium+ |
| `growthIndex`      | number           | index points     | That lab's volume indexed to 100 at its own first settled day | Premium+ |
| `share`            | number           | decimal fraction | The lab's share of the closed-lab daily total                 | Premium+ |
| `totalGrowthIndex` | number, nullable | index points     | The closed-lab total, indexed to 100 at the total baseline    | Premium+ |
| `baselines`        | array            | mixed            | Per-lab `{ lab, date, totalTokens }` the index is based at    | Premium+ |
| `totalBaseline`    | object, nullable | mixed            | `{ date, totalTokens }` for the closed-lab total              | Premium+ |

## 8. Workload Cost Index

The OTPI companion that prices the request rather than the token, for the three closed labs. History from 2026-06-11. No Index window.

**Tracked providers and model classes.** Classes are exact partitions of a provider's daily rows, so class rows sum back to the aggregate.

| Series              | What it measures                                                                                                           | Unit                                                 |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| Cost per Request    | Settled spend over paid calls for the node's model mix that day. Includes mix, so it moves when users shift between models | cents per request, cents per image for image classes |
| Like-for-Like Index | Mix-purged unit cost. Separates true price and efficiency change from savings that come from routing to cheaper models     | index points, base 100                               |
| Workload Intensity  | How heavy a typical call is: tokens served per request across the node's mix                                               | tokens per request                                   |

| Provider  | Aggregate | Model classes                           |
| --------- | --------- | --------------------------------------- |
| anthropic | yes       | opus, sonnet, haiku, fable              |
| openai    | yes       | flagship, mini, nano, pro, codex, image |
| google    | yes       | flash, pro, lite, image                 |

| Field             | Type             | Unit                            | Description                                           | Example                  | Access   |
| ----------------- | ---------------- | ------------------------------- | ----------------------------------------------------- | ------------------------ | -------- |
| `date`            | string, date     | none                            | Settlement date                                       | 2026-07-13               | Premium+ |
| `lab`             | string           | none                            | anthropic, openai, or google                          | anthropic                | Premium+ |
| `family`          | string           | none                            | `all` for the provider aggregate, or a model class    | all                      | Premium+ |
| `cCents`          | number           | cents per request               | Cost per Request                                      | 4.82                     | Premium+ |
| `lfl`             | number           | index points                    | Like-for-Like Index                                   | 96.4                     | Premium+ |
| `qKtok`           | number           | thousands of tokens per request | Workload Intensity                                    | 1.82                     | Premium+ |
| `priceEffect`     | number           | percent contribution            | Same-model unit-cost contribution to the day's change | 0.4                      | Premium+ |
| `intensityEffect` | number           | percent contribution            | Tokens-per-request contribution                       | -1.1                     | Premium+ |
| `mixEffect`       | number, nullable | percent contribution            | Model-mix contribution                                | 0.2                      | Premium+ |
| `computedAt`      | string, ISO 8601 | UTC                             | When the row was computed                             | 2026-07-14T00:00:00.000Z | Premium+ |

## 9. Model Frontier

Benchmark capability against price per task, for every model and thinking level. Cost is priced off the index: the lab's OTPI dollars per million tokens multiplied by the model's tokens per task. No Index window. On the REST API at [`GET /api/model-frontier`](/docs/api-reference/model-frontier/get-the-model-frontier-dataset), which also carries `releaseDates` — model display name to first-release date, for reconstructing past frontier states — and `history`, real month-by-month prices where they exist (currently GPQA Diamond only): fractional `months` plus each model's `cap` and monthly `cost` series.

Capability axes: Overall (Epoch ECI), Coding (SWE-bench Verified), Reasoning (GPQA Diamond), Math (AIME 2024/25). A model with no real score on an axis is dropped from that view, never estimated.

| Field             | Type             | Unit                   | Description                                                                    | Access   |
| ----------------- | ---------------- | ---------------------- | ------------------------------------------------------------------------------ | -------- |
| `slug` / `name`   | string           | none                   | Model identifier and display name                                              | Premium+ |
| `lab`             | string           | none                   | The lab that serves the model                                                  | Premium+ |
| `cap`             | number           | ECI index points       | Epoch Capability Index composite score                                         | Premium+ |
| `tpt`             | number           | tokens                 | Tokens per task                                                                | Premium+ |
| `price`           | number           | USD per million tokens | Per-model price used for the cost axis                                         | Premium+ |
| `pIn` / `pOut`    | number           | USD per million tokens | Input and output prices                                                        | Premium+ |
| `totalTokens`     | number           | tokens                 | Volume behind the model                                                        | Premium+ |
| `costPerTask`     | number           | USD per task           | price × tpt / 1e6                                                              | Premium+ |
| `bench.coding`    | number           | percent                | SWE-bench Verified                                                             | Premium+ |
| `bench.reasoning` | number           | percent                | GPQA Diamond                                                                   | Premium+ |
| `bench.math`      | number           | percent                | AIME 2024/25                                                                   | Premium+ |
| `model`           | string           | none                   | Model identifier (thinking-level rows)                                         | Premium+ |
| `effort`          | string           | none                   | minimal, low, medium, high, xhigh, max, thinking, or default                   | Premium+ |
| `rank`            | number           | 0 to 5                 | Ordering from least to most thinking                                           | Premium+ |
| `cost`            | number           | USD per task           | OTPI-rebased where the lab has an OTPI price, else the measured provider price | Premium+ |
| `tokensEst`       | number, nullable | tokens per task        | Output tokens per task                                                         | Premium+ |
| `timeSec`         | number, nullable | seconds                | Time to solve                                                                  | Premium+ |
| `speedTps`        | number, nullable | tokens per second      | Output speed used for timeSec                                                  | Premium+ |
| `speedMeasured`   | boolean          | none                   | true if measured, false if a median fallback                                   | Premium+ |
| `costBasis`       | string           | none                   | `otpi` or `measured`                                                           | Premium+ |

**Tracked benchmarks (11).** WeirdML, Aider Polyglot, CursorBench, DeepSWE, ALE-Bench, ARC-AGI, ARC-AGI-2, ProofBench, Surface Evolver, CritPt, The Agent Company.

## 10. LLM Coding Analytics

Daily public-GitHub activity for the major AI coding tools. No Index window on values; the product catalog is public.

**Tracked tools (5).** claude (Claude Code), codex, copilot (GitHub Copilot), cursor, devin (Cognition). PRs and merge rates for all five; commits for claude only.

**Products (13).** A tool crossed with a metric. Each has an `id`, `label`, `category`, `kind` (count or pct), `compare` flag, and `seriesLabels`.

Public-GitHub signals only. Private repos, self-hosted instances, and IDE-side telemetry are out of scope.

| Field              | Type             | Unit                 | Description                                                             | Access                           |
| ------------------ | ---------------- | -------------------- | ----------------------------------------------------------------------- | -------------------------------- |
| `date`             | string, date     | UTC                  | The day the activity was observed                                       | Premium+                         |
| `tool`             | string           | none                 | One of the five tools                                                   | Catalog: Index. Values: Premium+ |
| `commits`          | number           | count                | Public-GitHub commits attributed to the tool that day, claude only      | Premium+                         |
| `prs`              | number           | count                | Pull requests opened from the tool's branch namespace                   | Premium+                         |
| `merged`           | number           | count                | Of those PRs, how many have merged so far                               | Premium+                         |
| `merge_rate`       | number           | percent, one decimal | 100 × merged / prs                                                      | Premium+                         |
| `value` / `value2` | number           | count or percent     | The series value; value2 carries the second series on a compare product | Premium+                         |
| `changePct`        | number, nullable | percent              | Day-over-day change                                                     | Premium+                         |
| `updatedAt`        | string, ISO 8601 | UTC                  | When the value was written                                              | Premium+                         |

## 11. Power Markets

Daily wholesale power prices across every US market, with history from 2017-01-03. Six markets are ICE exchange trades carrying the volume behind each print; ERCOT is its own day-ahead clearing price, shown against grid load. No Index window.

Power Markets is served on the REST API at `GET /api/power/markets` (daily prices, traded volume, and system load) and rendered on the platform charts at [data.ornn.com/analytics/power](https://data.ornn.com/analytics/power). The hourly operations routes are `GET /api/power/load` (actual and forecast demand) and `GET /api/power/fuel-mix` (generation by fuel). Daily prices are Premium+; the hourly operations routes are Full-only. There is no free/Index tier.

Traded volume and system load are separate fields and never share an axis: a clearing price has no traded volume, so ERCOT carries the energy the grid actually moved. Daily peak-block prices per hub, not hourly nodal.

**Tracked markets**

| Market         | Depth series                     | Hub(s)                                           | Source |
| -------------- | -------------------------------- | ------------------------------------------------ | ------ |
| WECC Northwest | Traded volume                    | Mid C Peak                                       | ICE    |
| PJM            | Traded volume                    | PJM WH Real Time Peak                            | ICE    |
| CAISO          | Traded volume                    | NP15 EZ Gen DA LMP Peak, SP15 EZ Gen DA LMP Peak | ICE    |
| ISO-NE         | Traded volume                    | Nepool MH DA LMP Peak                            | ICE    |
| WECC Southwest | Traded volume                    | Palo Verde Peak                                  | ICE    |
| MISO           | Traded volume                    | Indiana Hub RT Peak                              | ICE    |
| ERCOT          | System load, plus off-peak price | HB\_NORTH                                        | ERCOT  |

| Field | Type             | Unit        | Description                                                      | Access   |
| ----- | ---------------- | ----------- | ---------------------------------------------------------------- | -------- |
| `d`   | string, date     | none        | Trade or clearing date                                           | Premium+ |
| `p`   | number           | USD per MWh | Peak-block price, the headline series                            | Premium+ |
| `o`   | number, optional | USD per MWh | Off-peak price, hours ending 1 to 6 and 23 to 24 of the same day | Premium+ |
| `t`   | number, optional | GWh         | Traded volume, exchange-traded markets only                      | Premium+ |
| `l`   | number, optional | GWh         | System load delivered, clearing markets only                     | Premium+ |
| `g`   | number, optional | count       | Trade count behind the print                                     | Premium+ |

The operations routes use EIA regional data rather than ICE hub trades. Load is hourly actual demand and day-ahead forecast in MW. Fuel mix is hourly regional generation by fuel in MW. Both are operational context for the price series, not additional hub-level traded-price products, and both require Full access.

## 12. Datacenter Sites

Every tracked AI datacenter site worldwide, with the operator, power capacity, hardware, and build timeline behind each one. **Full only** for the payload. Index and Premium see coordinates on the map (points only) — not a locked overlay. Filters, site records, and the power overlay stay Full-only.

Sites can be rolled up by country or by GPU type into `site_count`, `total_power_mw`, and `total_gpu_qty`.

| Field                                          | Type       | Description                                                   | Access                                    |
| ---------------------------------------------- | ---------- | ------------------------------------------------------------- | ----------------------------------------- |
| `company`                                      | string     | The operator running the site                                 | Full                                      |
| `siteName`                                     | string     | The named facility or campus                                  | Full                                      |
| `streetAddress` / `city` / `state` / `country` | string     | Physical location                                             | Full                                      |
| `latitude` / `longitude`                       | number     | Coordinates                                                   | Index+ (points view); Full (with payload) |
| `dcTier`                                       | string     | Datacenter tier or classification, for example Tier III+      | Full                                      |
| `ownershipModel`                               | string     | Owned, leased, or colocation                                  | Full                                      |
| `coloPartner`                                  | string     | Colocation partner where the site is hosted rather than owned | Full                                      |
| `gpuTypes`                                     | string     | GPU models deployed or planned                                | Full                                      |
| `gpuQtyKnown`                                  | number     | Confirmed GPU count where reported                            | Full                                      |
| `gpuQtyEst`                                    | number     | Estimated GPU count where not reported                        | Full                                      |
| `chipGeneration`                               | string     | Hardware generation deployed or committed                     | Full                                      |
| `powerCapacity`                                | number, MW | The site's power envelope                                     | Full                                      |
| `category`                                     | string     | Business category, for example GPU-as-a-Service               | Full                                      |
| `isNeocloud`                                   | boolean    | Whether the site is a neo-cloud (GPU-as-a-service) operator   | Full                                      |
| `status`                                       | string     | Lifecycle stage: announced, under construction, operational   | Full                                      |
| `leaseTerm`                                    | string     | Lease length where the site is leased                         | Full                                      |
| `keyCustomer`                                  | string     | Anchor tenant or key customer where known                     | Full                                      |
| `contractAnnounced`                            | date       | Contract announcement                                         | Full                                      |
| `gpuOrderDate`                                 | date       | GPU order placed                                              | Full                                      |
| `constructionStart`                            | date       | Construction start                                            | Full                                      |
| `phase1LiveDate`                               | date       | First phase live                                              | Full                                      |
| `fullCapacityTarget`                           | date       | Full-capacity target                                          | Full                                      |
| `sourceNotes`                                  | string     | Provenance and caveats for the row                            | Full                                      |

## 13. Compute Buyers

AI-native startups that raised 10 million dollars or more in a single event, classified by the workload their compute is for. Built from SEC Form D filings and announced rounds, July 2024 to July 2026. No Index window. On the REST API at [`GET /api/compute-buyers`](/docs/api-reference/compute-buyers/list-tracked-compute-buyers).

| Field                  | Type             | Unit | Description                                                                    | Access   |
| ---------------------- | ---------------- | ---- | ------------------------------------------------------------------------------ | -------- |
| `name` / `displayName` | string           | none | Company legal name and display name                                            | Premium+ |
| `tier`                 | string           | none | T1 trains models, T2 heavy inference or AI infrastructure, T3 GPU-adjacent HPC | Premium+ |
| `workload`             | string           | none | The workload classification                                                    | Premium+ |
| `forWhat`              | string           | none | What the compute is for                                                        | Premium+ |
| `what`                 | string           | none | What the company does                                                          | Premium+ |
| `sold`                 | number, nullable | USD  | Amount raised in the event                                                     | Premium+ |
| `date`                 | string, date     | none | Event date                                                                     | Premium+ |
| `location`             | string           | none | Company location                                                               | Premium+ |
| `domain`               | string, nullable | none | Company domain                                                                 | Premium+ |
| `url`                  | string           | none | Source link for the raise                                                      | Premium+ |

## Keys, payments, and grain

|                    | Index                        | Premium / Trial                                       | Full                        |
| ------------------ | ---------------------------- | ----------------------------------------------------- | --------------------------- |
| Payment            | Free                         | **\$500/month** Stripe, or a 72-hour trial            | Custom, org-grained, Rillet |
| API key            | None                         | `sk_prem_`                                            | `sk_live_`                  |
| Hourly             | No                           | 403 on dedicated routes; other routes served at daily | Yes                         |
| Realtime GPU route | 404                          | 404                                                   | 404                         |
| Neocloud API       | No                           | 403                                                   | Yes                         |
| CSV / XLSX export  | Public Index page chart only | In-app exports need Full                              | Yes                         |

The key prefix is the tier. See [Access tiers](/docs/access-tiers). When API gating or Premium billing changes, update this page, Access tiers, and regenerate the internal Word file from `frontend/app/(shell)/internal/data-dictionary/build-docx.py`.


# Datacenter Sites
Source: https://data.ornn.com/docs/datacenter-map

What the neocloud datacenter map shows: GPU-site locations, operators, capacity, and buildout timelines.

The **Map** page on the platform plots the physical GPU supply behind the market: individual "neocloud" datacenter sites, who operates them, what hardware they run, and where each site is in its buildout. It's the geographic companion to the price indices, letting you see the capacity that price signals are moving against.

<Note>
  Index and Premium see coordinates on the map (points only). Filters, site records, and the power overlay are Full-only. `GET /api/neocloud/sites`, `/api/neocloud/map`, and `/api/neocloud/sites/aggregate` require a `sk_live_` key; a `sk_prem_` key returns `403`. See [Access tiers](/docs/access-tiers) and the [API reference](/docs/api-reference/neo-cloud-sites/query-neo-cloud-sites-by-region).
</Note>

## What each site shows

Every point on the map is a datacenter site. Fields below are **Full-only** unless noted. Index and Premium see coordinates on the map.

| Field                                                                                                | Meaning                                                                                                                    |
| ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `company`                                                                                            | The operator running the site.                                                                                             |
| `siteName`                                                                                           | The named facility or campus.                                                                                              |
| `streetAddress` / `city` / `state` / `country`                                                       | Physical location, used to place the point on the map.                                                                     |
| `latitude` / `longitude`                                                                             | Coordinates for the marker.                                                                                                |
| `dcTier`                                                                                             | Datacenter tier / classification of the facility.                                                                          |
| `ownershipModel`                                                                                     | Whether the operator owns the site, leases it, or runs in colocation.                                                      |
| `coloPartner`                                                                                        | The colocation partner, where the site is hosted rather than owned.                                                        |
| `gpuTypes`                                                                                           | The GPU models deployed or planned at the site.                                                                            |
| `gpuQtyKnown` / `gpuQtyEst`                                                                          | Confirmed GPU count where reported, and an estimate where it isn't.                                                        |
| `chipGeneration`                                                                                     | The hardware generation deployed or committed.                                                                             |
| `powerCapacity`                                                                                      | The site's power envelope, the practical ceiling on how much compute it can host.                                          |
| `status`                                                                                             | Where the site is in its lifecycle (announced, under construction, live, and so on).                                       |
| `leaseTerm`                                                                                          | Lease length, where the site is leased.                                                                                    |
| `keyCustomer`                                                                                        | The anchor tenant or key customer, where known.                                                                            |
| `contractAnnounced` / `gpuOrderDate` / `constructionStart` / `phase1LiveDate` / `fullCapacityTarget` | The buildout timeline, from contract and GPU order through construction start, first phase live, and full-capacity target. |
| `sourceNotes`                                                                                        | Provenance and caveats for the row.                                                                                        |

## How to read it

* **Capacity, not price.** The map answers "where is the compute, who runs it, and when does it come online" — it doesn't carry rental prices. Pair it with [The Price Index](/docs/price-index) to connect supply to rates.
* **Known vs. estimated.** GPU counts are split into a confirmed `gpuQtyKnown` and an `gpuQtyEst` estimate. Where only an estimate exists, treat the figure as directional.
* **Timelines are targets.** Buildout dates (`phase1LiveDate`, `fullCapacityTarget`, and so on) are announced or projected milestones and can move.

<Note>
  Because the dataset is curated, coverage is broad but not exhaustive, and individual fields can be blank where a detail hasn't been reported. Use `sourceNotes` for context on any specific row.
</Note>


# Errors & status codes
Source: https://data.ornn.com/docs/errors

The error format, HTTP status codes, and common error responses for the Ornn Data API.

## Error format

Errors return a JSON body with an `error` label and a human-readable `message`:

```json theme={null}
{
  "error": "Bad request",
  "message": "Invalid GPU type. Allowed: H100 SXM, H200, A100 SXM4, RTX 5090, B200, RTX PRO 6000 WS"
}
```

## Status codes

| Status | Meaning                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `200`  | Success.                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `400`  | Bad request: a missing or invalid parameter.                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `401`  | Unauthorized: missing, malformed, invalid, or revoked API key.                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `403`  | Forbidden: the request is authenticated but not allowed. A `sk_prem_` key gets this on GPU hourly, the current-value rolling 24-hour average (`/api/gpu/{gpuName}/rolling-24h-average`), hourly power operations (`/api/power/load` and `/api/power/fuel-mix`), and neocloud routes. Creating a key can also 403 if the account cannot mint (no own grant and not a member of a Full organization). Daily history at `/api/gpu/{gpuName}/rolling-24h-average/history` remains Premium. |
| `404`  | Not found: no data for the requested parameters.                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `429`  | Too many requests. See [Rate limits](/docs/rate-limits).                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `500`  | Internal server error.                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `503`  | Service unavailable (e.g. `/health` when the database is unreachable).                                                                                                                                                                                                                                                                                                                                                                                                                 |

## Common errors

### 401: Missing key

```json theme={null}
{
  "error": "Unauthorized",
  "message": "API key required. Use Authorization: Bearer YOUR_API_KEY"
}
```

### 401: Invalid or revoked key

```json theme={null}
{ "error": "Unauthorized", "message": "Invalid API key" }
```

```json theme={null}
{ "error": "Unauthorized", "message": "API key is inactive" }
```

### 403: Premium grain or dataset

A Premium (`sk_prem_`) key asking for a Full-only surface is refused rather than silently emptied:

```json theme={null}
{
  "error": "Forbidden",
  "message": "Premium access is daily-grain only. Hourly and real-time data require a full subscription."
}
```

```json theme={null}
{
  "error": "Forbidden",
  "message": "Neocloud site data is not included in premium access. A full subscription unlocks it."
}
```

See [Access tiers](/docs/access-tiers).

### 403: Cannot mint a key

Trial, Premium, and Full own grants can mint keys. A member of a Full organization with no own grant can mint an unstamped `sk_live_` key. A trial or Premium organization floor, with no own grant, cannot. `POST /api/create-api-key` then returns:

```json theme={null}
{ "success": false, "error": "API keys need an access grant of your own, or an organization on full access. Write to data@ornn.com for an individual grant." }
```

See [Manage API keys](/docs/manage-api-keys) for details.

### 400: Unknown GPU

```json theme={null}
{
  "error": "Bad request",
  "message": "Invalid GPU type. Allowed: H100 SXM, H200, A100 SXM4, RTX 5090, B200, RTX PRO 6000 WS"
}
```

### 400: Missing required parameter

```json theme={null}
{
  "error": "Bad request",
  "message": "datetime query parameter is required (format: YYYY-MM-DD HH:MM:SS or ISO 8601)"
}
```

### 404: No data

```json theme={null}
{ "error": "No data available", "message": "No daily index data found for H100 SXM" }
```

<Note>
  Endpoints that return the **nearest** record, such as [`/api/gpu/{gpuName}/history`](/docs/api-reference/historical-prices/get-index-value-nearest-a-timestamp), won't 404 for an out-of-range timestamp. They return the closest match and report the gap in `time_difference`.
</Note>

## Handling errors

Always check the HTTP status before reading the body.

```python theme={null}
import requests

resp = requests.get(
    "https://api.ornnai.com/api/gpu/H100 SXM",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
)
if not resp.ok:
    err = resp.json()
    raise RuntimeError(f"{resp.status_code}: {err.get('message', err.get('error'))}")

data = resp.json()["data"]
```


# Introduction
Source: https://data.ornn.com/docs/introduction

Documentation for the Ornn Data API, with read-only access to current prices, historical series, and market signals across GPU, memory, power, and AI markets.

<div>
  <section aria-label="Ornn Data API">
    <div>
      <img alt="" />
    </div>

    <div>
      <h2>Ornn Data API</h2>

      <p>
        Access GPU, memory, token, and AI-infrastructure signals through the Ornn Data API. Index data is public without a key. A Premium key (`sk_prem_`, \$500/month) unlocks every family at daily grain. A Full key (`sk_live_`) unlocks hourly and neocloud site data.
      </p>

      <div>
        <a href="/docs/quickstart">Get Started</a>
        <a href="https://data.ornn.com/settings?tab=api-keys">Create an API key</a>
      </div>

      <div>
        <p>BASE URL</p>

        ```text theme={null}
        https://api.ornnai.com
        ```
      </div>
    </div>
  </section>

  <section aria-label="Documentation sections">
    <div aria-label="Documentation sections">
      <a href="/docs/quickstart">
        <div>
          <p>Quickstart</p>
          <p>Get an API key and make your first request in under two minutes.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>

      <a href="/docs/access-tiers">
        <div>
          <p>Access Tiers</p>
          <p>Index, Premium, and Full — what each plan can read, and what it costs.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>

      <a href="/docs/data-dictionary">
        <div>
          <p>Data Dictionary</p>
          <p>Every dataset and field, tagged by Index, Premium, and Full.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>

      <a href="/docs/authentication">
        <div>
          <p>Authentication</p>
          <p>Learn how to use an API key and which data is Index, Premium, or Full.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>

      <a href="/docs/api-reference/current-prices/get-current-price-for-one-gpu">
        <div>
          <p>API Reference</p>
          <p>Browse endpoint schemas with request and response examples.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>

      <a href="/docs/pandas-dataframe">
        <div>
          <p>Working with Data</p>
          <p>Pull API series into pandas or chart them in JavaScript.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>

      <a href="/docs/supported-types">
        <div>
          <p>Supported Data</p>
          <p>See the GPU, memory, and token types tracked by the API.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>

      <a href="/docs/errors">
        <div>
          <p>Errors & Limits</p>
          <p>Diagnose failed requests and understand status codes and limits.</p>
        </div>

        <div>
          <img alt="" />
        </div>
      </a>
    </div>
  </section>

  <section aria-label="Market data lifecycle">
    <div>
      <div>
        <img alt="" />
      </div>

      <div>
        <h2>Market Data Lifecycle</h2>
        <p>From market inputs to usable signals</p>

        <p>
          Ornn combines verified compute transactions with upstream market and infrastructure data
          to produce signals across GPU, memory, token, and AI markets. Each dataset follows its own
          refresh cadence, with historical series available where supported.
        </p>

        <div>
          <a href="/docs/price-index">Explore the Price Index</a>
        </div>
      </div>
    </div>
  </section>

  <section>
    <div>
      <div>
        <p>CONCEPTS</p>
      </div>

      <a href="/docs/analytics">View GPU Analytics</a>
    </div>

    <div aria-label="Core data guides">
      <a href="/docs/price-index">
        <span>GPU Price Index</span><p>How compute prices are measured and refreshed hourly.</p><b>↗</b>
      </a>

      <a href="/docs/memory-index">
        <span>Memory Prices</span><p>Explore DRAM and Flash spot prices, refreshed each weekday.</p><b>↗</b>
      </a>

      <a href="/docs/power-markets">
        <span>Power Indices</span><p>Daily wholesale prices on REST at Premium; hourly load and fuel mix at Full. No MCP tool.</p><b>↗</b>
      </a>

      <a href="/docs/token-price-index">
        <span>Token and Workload Costs</span><p>Compare token prices and follow the companion cost-per-request index.</p><b>↗</b>
      </a>

      <a href="/docs/llm-coding-index">
        <span>LLM Coding Analytics</span><p>Follow public GitHub activity across leading coding products.</p><b>↗</b>
      </a>

      <a href="/docs/datacenter-map">
        <span>Datacenter Sites</span><p>Public map with site coordinates. Full unlocks operator, hardware, power, and timelines.</p><b>↗</b>
      </a>

      <a href="/docs/data-dictionary">
        <span>Data Dictionary</span><p>Every dataset and field, tagged by Index, Premium, and Full.</p><b>↗</b>
      </a>
    </div>
  </section>
</div>


# LLM Coding Analytics
Source: https://data.ornn.com/docs/llm-coding-index

Daily public-GitHub activity — PRs opened, merge rates, and commits — for Claude Code, Codex, Copilot, Cursor, and Devin.

**LLM Coding Analytics** tracks daily public-GitHub activity for the major AI coding tools. For each tool, Ornn measures pull requests opened, the share of those PRs that eventually merged, and (for Claude Code) commits attributed via co-author trailer. Use it to compare adoption and code-acceptance trends across tools over time.

## Tracked tools

The index covers five AI coding tools:

`claude` (Claude Code) · `codex` · `copilot` (GitHub Copilot) · `cursor` · `devin` (Cognition)

PRs and merge rates are tracked for all five. Commits are tracked for `claude` only, since it is the only tool that consistently attributes commits via a co-author trailer on public GitHub.

## Metrics

Each daily row in `llm_coding_daily_metrics` carries one set of values per tool:

| Field        | Meaning                                                               |
| ------------ | --------------------------------------------------------------------- |
| `date`       | The day the activity was observed (YYYY-MM-DD, UTC)                   |
| `tool`       | One of `claude`, `codex`, `copilot`, `cursor`, `devin`                |
| `commits`    | Public-GitHub commits attributed to the tool that day (`claude` only) |
| `prs`        | Pull requests opened that day from the tool's branch namespace        |
| `merged`     | Of those PRs, how many have merged so far                             |
| `merge_rate` | `100 × merged / prs`, as a percentage with one decimal                |

PR counts are stable once posted. `merged` and `merge_rate` for recent days continue to update as in-flight PRs land, then settle once activity tails off.

<Note>
  These are **public-GitHub** signals only. Private repos, self-hosted instances, and IDE-side telemetry are out of scope. Treat the values as a directional measure of open-source adoption, not total usage.
</Note>

## Products

The API exposes pre-built **products** — a tool plus a metric — so you can fetch one series at a time without picking columns by hand. Each product has an `id`, a human-readable `label`, and a `kind`:

* `kind: "count"` — a whole-number count (PRs or commits per day).
* `kind: "pct"` — a percentage (the daily merge rate).

| Product ID          | Label                 | Metric                  |
| ------------------- | --------------------- | ----------------------- |
| `cc-prs`            | Claude PRs            | PRs opened              |
| `codex-prs`         | Codex PRs             | PRs opened              |
| `copilot-prs`       | Copilot PRs           | PRs opened              |
| `cursor-prs`        | Cursor PRs            | PRs opened              |
| `devin-prs`         | Devin PRs             | PRs opened              |
| `cc-commits`        | Claude Commits        | Commits                 |
| `cc-merge`          | Claude Merge          | Merge rate              |
| `codex-merge`       | Codex Merge           | Merge rate              |
| `copilot-merge`     | Copilot Merge         | Merge rate              |
| `cursor-merge`      | Cursor Merge          | Merge rate              |
| `devin-merge`       | Devin Merge           | Merge rate              |
| `cc-vs-codex`       | Claude vs Codex       | PRs opened (two series) |
| `cc-vs-codex-merge` | Claude vs Codex Merge | Merge rate (two series) |

Products whose ID starts with a `vs` pairing (for example `cc-vs-codex`) return two series in a single response, ready to plot on one chart. They are only valid on `/api/llm-coding/history` — the single-day `/api/llm-coding/index` endpoint rejects them.

## Update frequency

Values are refreshed once per day after a backfill-and-catch-up scrape. New days appear within roughly 24 hours of UTC midnight. Re-fetching the same `date` later may return a higher `merged` count as previously open PRs land.

## Reading the latest value

`GET /api/llm-coding/index?product={id}` returns the most recent daily value for a single (non-compare) product, with the day-over-day percent change. The product catalog is public; values and history need a Premium or Full key. See [Access tiers](/docs/access-tiers):

```bash theme={null}
curl "https://api.ornnai.com/api/llm-coding/index?product=cc-prs" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```json theme={null}
{
  "success": true,
  "data": {
    "product": "cc-prs",
    "label": "Claude PRs",
    "kind": "count",
    "value": 1000,
    "changePct": 0.00,
    "date": "2026-01-01",
    "updatedAt": "2026-01-01T00:00:00.000Z"
  }
}
```

`changePct` is `null` when there is no previous day on file or the previous value was zero.

## Pulling a historical series

`GET /api/llm-coding/history?product={id}` returns the daily series for a product, oldest first. Pass `startDate` and `endDate` (both `YYYY-MM-DD`, inclusive) to bound the window, or `limit` to cap the row count (default `2000`).

This endpoint requires an API key — LLM coding analytics have no free tier. Anonymous requests return `401`.

For a single-tool product, each row carries one `value`:

```bash theme={null}
curl "https://api.ornnai.com/api/llm-coding/history?product=copilot-merge&startDate=2026-05-01&endDate=2026-06-21" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```json theme={null}
{
  "success": true,
  "product": "copilot-merge",
  "compare": false,
  "data": [
    { "date": "2026-01-01", "value": 70.0 },
    { "date": "2026-01-02", "value": 70.0 }
  ]
}
```

For a compare product, each row carries both tools side by side as `value` and `value2`, ordered to match `seriesLabels`:

```bash theme={null}
curl "https://api.ornnai.com/api/llm-coding/history?product=cc-vs-codex&startDate=2026-05-01&endDate=2026-06-21" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```json theme={null}
{
  "success": true,
  "product": "cc-vs-codex",
  "compare": true,
  "seriesLabels": ["Claude PRs", "Codex PRs"],
  "data": [
    { "date": "2026-01-01", "value": 1000, "value2": 1000 },
    { "date": "2026-01-02", "value": 1000, "value2": 1000 }
  ]
}
```

An unknown `product` returns `400`. A valid product with no rows in the requested window returns `200` with an empty `data` array — history never returns `404` (unlike [the index endpoint](#reading-the-latest-value), which returns `404` when a known product has no current value).

## Listing available products

If you want to drive a selector from the live product list rather than hard-coding IDs, call `GET /api/llm-coding/products`. This catalog endpoint is public — no API key required:

```bash theme={null}
curl "https://api.ornnai.com/api/llm-coding/products"
```

```json theme={null}
{
  "success": true,
  "data": [
    { "id": "cc-prs", "label": "Claude PRs", "category": "prs", "kind": "count", "compare": false, "seriesLabels": null },
    { "id": "cc-vs-codex", "label": "Claude vs Codex", "category": "prs", "kind": "count", "compare": true, "seriesLabels": ["Claude PRs", "Codex PRs"] }
  ]
}
```

See the [LLM Coding API reference](/docs/api-reference/llm-coding/get-the-latest-value-for-an-llm-coding-product) for the full schema and code samples in every supported language.

## Notes

* LLM coding analytics require an API key — the latest value (`/api/llm-coding/index`) and history (`/api/llm-coding/history`) both return `401` without one. Only the products catalog (`/api/llm-coding/products`) is public. See [Authentication](/docs/authentication).
* History rows come back **oldest first** — the opposite of the OTPI and GPU history endpoints. You can plot them directly without re-sorting.
* Merge rates and merged counts for the last few days will keep ticking up as PRs land. Pin to a settled date if you need a stable value.


# Manage API keys
Source: https://data.ornn.com/docs/manage-api-keys

Create, view, and delete your Ornn Data API keys from the dashboard.

API keys are managed in the [data.ornn.com](https://data.ornn.com) dashboard, under **Settings → API Keys**.

<Note>
  Trial and Premium accounts mint **`sk_prem_`** keys, capped at **daily granularity** with complete daily history — the same surface the MCP connector exposes. Hourly and neocloud site data stay Full-only. A **Full** account, or a member of a Full organization with no own grant, mints unrestricted **`sk_live_`** keys. A trial or Premium organization floor, with no own grant, cannot create keys.
</Note>

## Find your keys

Sign in to [data.ornn.com](https://data.ornn.com) and open **Settings → API Keys**. API Keys is a tab on the Settings page, so you can also deep-link to [data.ornn.com/settings?tab=api-keys](https://data.ornn.com/settings?tab=api-keys). The older `/api-keys` URL still works and redirects to the tab.

Each key you have issued is listed with:

| Column        | What it shows                                                                                                                                                                                                                                             |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Name**      | The label you gave the key when you created it                                                                                                                                                                                                            |
| **Key**       | A short identifier for the key, e.g. `sk_live_3f9a2b1c...`. The characters after the prefix come from a hash of the key, **not** from the key itself, so you cannot use this to reconstruct or recognise the original secret — match keys by name instead |
| **Created**   | The date the key was issued                                                                                                                                                                                                                               |
| **Last used** | The date of the most recent request authenticated with the key, or `Never`                                                                                                                                                                                |
| **Status**    | `Active`. Only active keys are listed, so a deleted key disappears from the table rather than showing as inactive                                                                                                                                         |

<Frame>
  <img alt="API keys table with Name, Key, Created, Last used and Status columns, a Create key button above it, and a delete icon on each row" />
</Frame>

If you have not created a key yet, the tab shows **No active API keys** with a **Create key** button in its place.

## Create a key

<Steps>
  <Step title="Open the API Keys tab">
    Sign in to [data.ornn.com](https://data.ornn.com) and go to **Settings → API Keys**.
  </Step>

  <Step title="Name the key">
    Click **Create key**, enter a descriptive name in **API key name** (e.g. `notebook-research`), and submit with **Create key**. A name is required — submitting an empty one shows *Please enter a name for your API key*.
  </Step>

  <Step title="Copy it now">
    Your full key is shown **once**, in the **API Key Created** dialog. Trial and Premium keys begin `sk_prem_`; Full keys begin `sk_live_`. Click **Copy & Close** to copy it to the clipboard; the button confirms with **Copied** and the dialog dismisses itself. Store the key in a secret manager or environment variable.
  </Step>
</Steps>

<Frame>
  <img alt="Create key dialog with an API key name field and Cancel and Create key buttons" />
</Frame>

<Frame>
  <img alt="API Key Created dialog showing the full sk_live key above a Copy and Close button" />
</Frame>

<Warning>
  The full key appears only in the **API Key Created** dialog and cannot be retrieved afterward. The **Key** column is derived from a hash, so it will not help you identify a key you have misplaced — give each key a name you will recognise. If you lose a key, delete it and create a new one.
</Warning>

If your browser blocks clipboard access, the dialog stays open and shows *Copy failed. Select the key text manually.* — select the key and copy it by hand before dismissing the dialog with `Esc`.

New keys are read-only against the index endpoints. There are no scopes, expiry dates, or environments to choose at creation; scope a key by what you use it for and delete it when that use ends.

## Use a key

Pass it as a Bearer token on every request to a protected endpoint:

```bash theme={null}
curl "https://api.ornnai.com/api/gpu/H100%20SXM" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

A good practice is to keep it in an environment variable:

```python theme={null}
import os, requests

resp = requests.get(
    "https://api.ornnai.com/api/gpu/H100 SXM",
    headers={"Authorization": f"Bearer {os.environ['ORNN_API_KEY']}"},
)
```

## Delete a key

In **Settings → API Keys**, click the trash icon at the end of the key's row, then confirm in the browser prompt. The row disappears from the table and the key immediately returns `401 { "error": "Unauthorized", "message": "API key is inactive" }`. Deletion cannot be undone, so issue a new key to replace it.

<Frame>
  <img alt="Browser confirmation dialog asking whether to delete the API key" />
</Frame>

## Best practices

* **One key per app or environment** so you can delete narrowly.
* **Never commit keys** to source control or ship them in browser code.
* **Rotate** periodically by creating a new key and deleting the old one.
* **Watch Last used** to spot keys nothing depends on any more, and delete them.


# Ornn MCP
Source: https://data.ornn.com/docs/mcp-server

Connect Claude, ChatGPT, and any other MCP client to live Ornn GPU, memory, token, and workload market data.

The Ornn MCP server exposes the Ornn Data API as tools an AI assistant can call directly. Once connected, you can ask for a GPU price index, a history series, volatility, memory prices, or the token price index in plain language, and your assistant queries Ornn for the answer instead of guessing.

It is a **read-only** server. Every tool fetches data; none of them write, change, or delete anything in your Ornn account.

<Note>
  Endpoint: `https://data.ornn.com/mcp` — streamable HTTP, OAuth 2.1 with browser sign-in.
</Note>

## What MCP can access

| Data                                                            | Available                                                                                             |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| GPU price indices, daily settled index, index history           | Yes                                                                                                   |
| Token price index (OTPI), tracked labs and memory types         | Yes                                                                                                   |
| Market index, price history, volatility, volume metrics         | Yes, on a paid plan                                                                                   |
| Memory prices, LLM coding index, workload cost, forward curve   | Yes, on a paid plan                                                                                   |
| Token volume index                                              | Yes, on a paid plan                                                                                   |
| Model Frontier and Compute Buyers                               | No — [REST API only](/docs/access-tiers): their full-snapshot payloads exceed the MCP result-size cap |
| Power markets                                                   | Yes, on a paid plan; hourly operations are REST API only and Full-only                                |
| Neocloud datacenter sites and aggregates                        | Full plans only                                                                                       |
| Anything in your account — keys, settings, billing, other users | No                                                                                                    |

Access follows the same tiers as the REST API:

| Account                                | What the tools return                                                                                                                                                                                                                  |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Any signed-in Ornn account**         | The public tools, shaped to the free tier — free-tier GPU types, the free OTPI labs, and trailing public windows                                                                                                                       |
| **Trial or premium**                   | The public tools plus the paid market-index tools, **capped at daily granularity** and reaching the complete daily history. An hourly or `auto` request is served at daily. Neocloud site data and `get_gpu_price_at` are not included |
| **Full**                               | Every tool, full depth, all tracked types                                                                                                                                                                                              |
| **API key** (`sk_live_` or `sk_prem_`) | Same as the key itself allows on the REST API — a `sk_prem_` key carries the daily cap with it                                                                                                                                         |

<Info>
  Tools resolve access at call time from the account you signed in with. If your access changes, the next tool call reflects it — there is nothing to reconnect.
</Info>

<Note>
  Paid tools need your **own** grant. Access you hold only through your organization covers the product and the public tools, but not programmatic access — write to [data@ornn.com](mailto:data@ornn.com) for an individual grant.
</Note>

## Set-up guide

**Before you start, you need:**

* An Ornn account at [data.ornn.com](https://data.ornn.com). Signing up is self-service.
* An AI tool that supports MCP, such as Claude or ChatGPT.
* A paid plan (trial, premium, or full), or an [API key](/docs/manage-api-keys), if you want the paid tools. The public tools work on any account.

<Note>
  Official Ornn connectors in Anthropic's connector directory and OpenAI's app directory are **coming soon**. Until they land, add Ornn yourself with the endpoint below — the steps take about a minute and give you the same tools.
</Note>

### How to connect

<AccordionGroup>
  <Accordion title="Claude">
    1. Open **Settings → Connectors** in Claude (web or desktop).
    2. Click **Add custom connector**.
    3. Name it `Ornn` and enter the URL `https://data.ornn.com/mcp`.
    4. Click **Connect**, sign in to Ornn in the browser window that opens, and approve access.
    5. Start a new chat and enable **Ornn** from the tools menu.
  </Accordion>

  <Accordion title="ChatGPT">
    1. Open **Settings → Connectors**.
    2. Click **Create** to add a custom connector.
    3. Name it `Ornn`, enter the URL `https://data.ornn.com/mcp`, and choose **OAuth** authentication.
    4. Click **Create**, then sign in to Ornn in the browser window that opens.
    5. In a chat, reference the connector with `@Ornn` or just ask a market-data question.
  </Accordion>

  <Accordion title="Claude Code">
    1. Run the following in your terminal:

       ```bash theme={null}
       claude mcp add ornn --transport http https://data.ornn.com/mcp
       ```

    2. Start Claude Code and run `/mcp`.

    3. Select **ornn** and choose **Authenticate**.

    4. Sign in to Ornn in the browser window that opens and approve access.

    5. Run `/mcp` again — **ornn** should read `connected`.
  </Accordion>

  <Accordion title="Other MCP clients">
    Any MCP client can connect to `https://data.ornn.com/mcp` as a custom or remote server. The client needs:

    * **Streamable HTTP** transport (the server is stateless and POST-only).
    * **OAuth 2.1** with authorization code + PKCE and dynamic client registration, using the browser to sign in.

    Clients that cannot do the OAuth flow but can send headers may authenticate with an API key instead — `sk_live_` on a full plan, `sk_prem_` on trial or premium:

    ```json theme={null}
    {
      "mcpServers": {
        "ornn": {
          "type": "http",
          "url": "https://data.ornn.com/mcp",
          "headers": { "Authorization": "Bearer YOUR_API_KEY" }
        }
      }
    }
    ```

    <Info>
      Prefer plain HTTP? Every tool here maps to a REST endpoint you can call yourself — see the [Quickstart](/docs/quickstart) and [API reference](/docs/api-reference/current-prices/get-current-price-for-one-gpu).
    </Info>
  </Accordion>
</AccordionGroup>

## Tools and descriptions

Tools marked **Paid** need a paid plan (trial, premium, or full) or an API key; on trial and premium they are served at daily granularity, across the complete history. Tools marked **Full only** need a full plan. The rest work on any signed-in account, returning free-tier data.

### GPU prices

| Tool                       | Description                                                                                                                            | Access                               |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `list_gpu_types`           | The GPU types with a published price index                                                                                             | Any                                  |
| `get_gpu_price`            | Latest \$/hr price index for one GPU type                                                                                              | Any                                  |
| `get_gpu_index_history`    | Daily price index series for one GPU type                                                                                              | Any                                  |
| `get_daily_index`          | Settled daily index over the trailing 7 settled days                                                                                   | Any                                  |
| `get_daily_index_snapshot` | Latest settled daily index for every tracked GPU, in one call                                                                          | Any                                  |
| `get_market_index`         | The live Ornn compute market index for one GPU type                                                                                    | Paid                                 |
| `get_gpu_price_history`    | Prices over a date range, daily or hourly                                                                                              | Paid                                 |
| `get_gpu_price_at`         | The price nearest a specific datetime                                                                                                  | Full only                            |
| `get_gpu_rolling_average`  | Rolling 24-hour average. Current value (no dates) is Full (hourly path); history with startDate and endDate is Premium+ at daily grain | Paid (history daily); Full (current) |
| `get_gpu_volatility`       | Rolling-window price volatility over a range                                                                                           | Paid                                 |
| `get_gpu_volume_metrics`   | Observed listing volume metrics over a range                                                                                           | Paid                                 |
| `get_forward_curve`        | Published forward curve marks for GPU compute                                                                                          | Paid                                 |

### Memory, tokens, and workloads

| Tool                       | Description                                                       | Access |
| -------------------------- | ----------------------------------------------------------------- | ------ |
| `list_memory_types`        | DRAM, flash, and module types with published prices               | Any    |
| `list_token_types`         | Labs and models covered by the token price index                  | Any    |
| `get_token_price_index`    | Settled \$/token by lab (OTPI)                                    | Any    |
| `list_llm_coding_products` | Product IDs in the LLM coding index                               | Any    |
| `get_memory_index`         | Current memory price index — one type, one category, or all       | Paid   |
| `get_memory_price_history` | Historical prices for one memory type                             | Paid   |
| `get_llm_coding_index`     | Current LLM coding index value for one product                    | Paid   |
| `get_llm_coding_history`   | Daily LLM coding index history for one product                    | Paid   |
| `get_workload_index`       | Daily workload cost: settled \$/request, index, intensity         | Paid   |
| `get_token_volume`         | Token Volume Index: daily volume, growth, and share by closed lab | Paid   |

### Datacenters and discovery

| Tool                     | Description                                     | Access    |
| ------------------------ | ----------------------------------------------- | --------- |
| `search`                 | Find Ornn data series by name and get their ids | Any       |
| `fetch`                  | Retrieve the current value of one series by id  | Any       |
| `get_neocloud_sites`     | Neocloud GPU datacenter sites in one region     | Full only |
| `get_neocloud_aggregate` | Site counts and capacity by country or GPU type | Full only |

### Example prompts

* *"What's the current H100 SXM price index?"*
* *"Chart the A100 daily index for the last six months."*
* *"How volatile has H200 pricing been this quarter, on a 30-day window?"*
* *"Compare today's settled index across every GPU type Ornn tracks."*
* *"What's the token price index for Anthropic and OpenAI right now?"*
* *"Where are the neocloud sites running H100s in Virginia?"*

## Troubleshooting

<AccordionGroup>
  <Accordion title="A tool says it needs your own grant">
    Paid tools require your account's **own** grant — the same rule that governs creating API keys. Access you hold only through your organization does not include programmatic access. Check your status at [data.ornn.com](https://data.ornn.com), write to [data@ornn.com](mailto:data@ornn.com) for an individual grant, or connect with an API key instead.
  </Accordion>

  <Accordion title="A tool says it is not included in my plan">
    Trial and premium plans cover the market indices, the token volume index tool, and the current forward curve — not the neocloud site data. `get_neocloud_sites` and `get_neocloud_aggregate` need a full plan, as does `get_gpu_price_at` — it answers with the nearest price print, which can be hourly, so it sits outside the daily-grain tier. Model Frontier and Compute Buyers have no MCP tool on any plan; read them over the [REST API](/docs/api-reference/model-frontier/get-the-model-frontier-dataset).
  </Accordion>

  <Accordion title="I asked for hourly and got daily">
    Expected on trial and premium: those plans are daily-grain at every range. The request is served rather than refused, and the response reports the granularity you were actually given — read that field rather than assuming you got what you asked for. In exchange there is no history window: daily reaches the complete record. Hourly data needs a full subscription.
  </Accordion>

  <Accordion title="Unauthorized, or the client keeps asking me to sign in">
    Remove the connector and add it again so the sign-in flow runs fresh. Confirm the URL is exactly `https://data.ornn.com/mcp` with no trailing slash or path, and that you signed in with the Ornn account that holds your access.
  </Accordion>

  <Accordion title="No tools available">
    The client connected but has not listed tools yet. Restart the client, or in Claude Code run `/mcp` and confirm **ornn** reads `connected`. If it reads `needs authentication`, choose **Authenticate** and finish the browser sign-in.
  </Accordion>

  <Accordion title="Rate limited">
    Calls are limited per account: 60 per minute on the public tools and 600 per minute on the paid tools. Batched or looping requests count individually. Wait a minute and retry, or pull large series through the [REST API](/docs/quickstart) instead of one tool call per row.
  </Accordion>

  <Accordion title="A date range came back shorter than I asked for">
    Tools that can return unbounded history clamp an open-ended request to a trailing window — 180 days on the GPU series, less on the workload index — and derive a missing bound from the one you gave. Pass both `startDate` and `endDate` for a specific window.
  </Accordion>

  <Accordion title="A price came back for the wrong moment">
    `get_gpu_price_at` returns the *nearest* available point rather than erroring on an out-of-range datetime. Read `time_difference` and `is_exact` in the response, and quote the timestamp it returned rather than the one you asked for.
  </Accordion>
</AccordionGroup>

## FAQ

<AccordionGroup>
  <Accordion title="Can the MCP server change anything?">
    No. Every tool is read-only and annotated as such, so assistants can run them without a confirmation prompt for each call. There are no write, update, or delete tools.
  </Accordion>

  <Accordion title="Do I need an API key?">
    Not for the connector flow — signing in with your Ornn account is enough, and your account's access decides what the tools return. A key is useful for clients that cannot run a browser sign-in, or when you want a credential you can revoke on its own. Either key shape works here: a `sk_prem_` key reaches the same daily-grain surface its plan does.
  </Accordion>

  <Accordion title="Is my API key sent to the assistant?">
    Only if you configure one yourself in the client, as in **Other MCP clients** above. The OAuth path never exposes a key; the server resolves your access from the signed-in account.
  </Accordion>

  <Accordion title="Does this cost extra?">
    No. MCP access is included with your Ornn plan and draws on the same data and access tiers as the REST API. Trial and premium plans reach the paid tools at daily granularity; a full plan reaches everything.
  </Accordion>

  <Accordion title="Which data does it cover?">
    The same market data documented on this site: GPU price and market indices, history and analytics, memory prices, the token price index, the token volume index, the LLM coding index, workload cost, forward curve marks, and — on a full plan — neocloud sites. Model Frontier and Compute Buyers are REST-only; Power Markets' hourly load and fuel-mix routes are Full-only.
  </Accordion>

  <Accordion title="Can I use it with my own agent or script?">
    Yes — point any MCP client at `https://data.ornn.com/mcp`. If you are writing the client yourself, calling the [REST API](/docs/quickstart) directly is usually simpler.
  </Accordion>
</AccordionGroup>

## Next steps

<CardGroup>
  <Card title="Manage API keys" href="/docs/manage-api-keys">
    Create a key for clients that cannot run a browser sign-in.
  </Card>

  <Card title="Browse all endpoints" href="/docs/api-reference/current-prices/get-current-price-for-one-gpu">
    The REST surface behind every tool on this page.
  </Card>
</CardGroup>


# Memory Price Index
Source: https://data.ornn.com/docs/memory-index

What the memory prices represent, the tracked memory types, and how they update.

Alongside GPUs, the Ornn Data API tracks **memory prices** for DRAM and Flash components.

## What it covers

Memory prices are spot prices for individual memory components, grouped into categories:

| Category (`category`) | Examples                                              |
| --------------------- | ----------------------------------------------------- |
| **`dram`**            | `DDR5 16Gb (2Gx8) 4800/5600`, `DDR4 16Gb (2Gx8) 3200` |
| **`flash`**           | `MLC 64Gb (8Gx8)`, `SLC 2Gb (256Mx8)`                 |
| **`module`**          | `DDR5 RDIMM 32GB 4800/5600`, `DDR4 UDIMM 16GB 3200`   |

Fetch the full live list from [`/api/memory-types`](/docs/api-reference/memory/list-tracked-memory-types) without an API key.

## Fields

Each memory price includes:

| Field                      | Meaning                                                                                  |
| -------------------------- | ---------------------------------------------------------------------------------------- |
| `id`                       | Frozen ≤32-character partner key (for example `mem_ddr4_16gb`). Never renamed or reused. |
| `price`                    | The current spot price (session average)                                                 |
| `changePct`                | Percent change versus the previous reading                                               |
| `weeklyHigh` / `weeklyLow` | The high and low over the trailing week                                                  |
| `sourceUpdatedAt`          | The upstream publication timestamp                                                       |
| `updatedAt`                | When Ornn ingested the value (ISO 8601, UTC)                                             |

## Update frequency

Memory prices are refreshed **once per trading day (weekdays)**. The `sourceUpdatedAt` string reflects the upstream publication time; `updatedAt` is the UTC ingestion time you should rely on programmatically.

<Note>
  Each part has a frozen `id` (≤32 characters, for example `mem_ddr4_16gb`) and a vendor-style `memory_type` name. Prefer `id` as a primary key. Lookups accept either: `/api/memory-index?type=mem_ddr4_16gb` or the URL-encoded name. Pull the mapping from `/api/memory-types`.
</Note>

## Reading current prices

Memory price endpoints require a **Premium or Full** key; only the `/api/memory-types` catalog is public on Index. With no parameters, `GET /api/memory-index` returns every tracked type:

```bash theme={null}
curl "https://api.ornnai.com/api/memory-index" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Narrow to one `category` (`dram`, `flash`, or `module`) to get an array, or to a single `type` (id or name) to get one object:

```bash theme={null}
# one category
curl "https://api.ornnai.com/api/memory-index?category=dram" \
  -H "Authorization: Bearer YOUR_API_KEY"

# one type by frozen id
curl "https://api.ornnai.com/api/memory-index?type=mem_ddr4_16gb" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```json theme={null}
{
  "success": true,
  "date": "2026-01-01T00:00:00.000Z",
  "count": 14,
  "data": [
    {
      "id": "mem_ddr4_16gb",
      "memoryType": "DDR4 16Gb (2Gx8) 3200",
      "category": "dram",
      "price": 40.00,
      "changePct": 0.00,
      "weeklyHigh": 50.00,
      "weeklyLow": 30.00,
      "sourceUpdatedAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

## Pulling price history

`GET /api/memory/{memoryType}/history` returns a single type's series. The path accepts the frozen `id` or the URL-encoded name. Bound the window with inclusive `startDate` and `endDate` (`YYYY-MM-DD`; a date-only `endDate` includes that day's 4 PM ET settlement), or cap rows with `limit` (default `1000`):

```bash theme={null}
curl "https://api.ornnai.com/api/memory/mem_ddr4_16gb/history?limit=5" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

```json theme={null}
{
  "success": true,
  "id": "mem_ddr4_16gb",
  "memoryType": "DDR4 16Gb (2Gx8) 3200",
  "count": 5,
  "data": [
    { "date": "2026-01-01T00:00:00.000Z", "id": "mem_ddr4_16gb", "memoryType": "DDR4 16Gb (2Gx8) 3200", "category": "dram", "price": 40.00, "weeklyHigh": 50.00, "weeklyLow": 30.00, "changePct": 0.00, "sourceUpdatedAt": "2026-01-01T00:00:00.000Z", "timestamp": "2026-01-01T00:00:00.000Z" }
  ]
}
```

See the [Memory API reference](/docs/api-reference/memory/get-current-memory-spot-prices) for the full schema and code samples in every supported language.


# Pull price history into pandas
Source: https://data.ornn.com/docs/pandas-dataframe

Load a GPU price series into a pandas DataFrame and plot it.

This guide loads an H100 SXM price history into a pandas DataFrame, ready for analysis or plotting.

## Prerequisites

* An [API key](/docs/manage-api-keys).
* `pip install requests pandas`

## Fetch and load

The [`/history-simple`](/docs/api-reference/historical-prices/get-a-clean-dailyhourly-series) endpoint returns a clean `timestamp` / `index_value` series, ideal for a DataFrame.

```python theme={null}
import requests
import pandas as pd

API_KEY = "YOUR_API_KEY"
BASE = "https://api.ornnai.com"

resp = requests.get(
    f"{BASE}/api/gpu/H100 SXM/history-simple",
    params={
        "startDate": "2026-05-01",
        "endDate": "2026-05-31",
        "granularity": "daily",  # one point per day
        "limit": 500,            # default is 100, raise it for long ranges
    },
    headers={"Authorization": f"Bearer {API_KEY}"},
)
resp.raise_for_status()

df = pd.DataFrame(resp.json()["data"])
df["timestamp"] = pd.to_datetime(df["timestamp"])
df = df.sort_values("timestamp").set_index("timestamp")

print(df.head())
```

```text Output theme={null}
                           index_value
timestamp
2026-01-01 00:00:00+00:00         2.00
2026-01-02 00:00:00+00:00         2.00
2026-01-03 00:00:00+00:00         2.00
2026-01-04 00:00:00+00:00         2.00
2026-01-05 00:00:00+00:00         2.00
```

<Tip>
  The API returns points most-recent-first. Sorting by `timestamp` (as above) puts them in chronological order before any rolling calculations or plotting.
</Tip>

## Plot it

```python theme={null}
import matplotlib.pyplot as plt

df["index_value"].plot(title="H100 SXM price index (USD/hr)")
plt.ylabel("USD per hour")
plt.show()
```

<Frame>
  <img alt="H100 SXM price index line chart for May 2026" />

  <img alt="H100 SXM price index line chart for May 2026" />
</Frame>

## Compare multiple GPUs

```python theme={null}
gpus = ["H100 SXM", "H200", "B200"]
frames = []

for gpu in gpus:
    r = requests.get(
        f"{BASE}/api/gpu/{gpu}/history-simple",
        params={"startDate": "2026-05-01", "endDate": "2026-05-31",
                "granularity": "daily", "limit": 500},
        headers={"Authorization": f"Bearer {API_KEY}"},
    )
    s = pd.DataFrame(r.json()["data"])
    s["timestamp"] = pd.to_datetime(s["timestamp"])
    frames.append(s.set_index("timestamp")["index_value"].rename(gpu))

prices = pd.concat(frames, axis=1).sort_index()
prices.plot(title="GPU price index comparison")
```

<Frame>
  <img alt="GPU price index comparison line chart" />

  <img alt="GPU price index comparison line chart" />
</Frame>


# Power Markets
Source: https://data.ornn.com/docs/power-markets

Wholesale US power prices and hourly grid-operations context.

The Power Markets pages on [data.ornn.com/analytics/power](https://data.ornn.com/analytics/power) plot daily wholesale prices across the seven tracked US hubs: six ICE exchange-traded peak products, plus ERCOT's day-ahead clearing price against grid load. History starts 2017-01-03. Premium and Full see the price charts; the hourly Load vs Forecast and Fuel Mix views require Full.

<Note>
  Power Markets has a REST API. Premium and Full keys can read daily prices at `GET /api/power/markets`. Full keys can also read hourly grid operations at `GET /api/power/load` and `GET /api/power/fuel-mix`; a Premium key receives `403` on those two routes. CSV/XLSX export from the charts is Full-only.
</Note>

The GPU [forward curve](/docs/access-tiers) is a separate product. Published GPU forward marks are served at `GET /api/forward` for paying keys and as the MCP tool `get_forward_curve`. They are not a power product. Do not look for power forwards on that route.

## What the charts show

| Field | Meaning                                               |
| ----- | ----------------------------------------------------- |
| `d`   | Trade or clearing date.                               |
| `p`   | Peak-block price in USD per MWh, the headline series. |
| `o`   | Off-peak price, ERCOT only.                           |
| `t`   | Traded volume in GWh, exchange-traded hubs only.      |
| `l`   | System load delivered, clearing hubs only.            |
| `g`   | Trade count behind the print.                         |

Tracked hubs: WECC Northwest (Mid C Peak), PJM, CAISO, ISO-NE, WECC Southwest (Palo Verde Peak), MISO, ERCOT (HB\_NORTH). See the [data dictionary](/docs/data-dictionary) §11 for the field list and access columns.

The series is maintained by scheduled ingestion into the live data store. ICE-published hub workbooks can lag the trade date by weeks, while EIA operations feeds are hourly. Each response includes source and freshness metadata; the page stamps the latest source observation, not "today".

MISO trades thinly on ICE. Interpret its price together with traded volume.


# The Price Index
Source: https://data.ornn.com/docs/price-index

What the GPU index value represents, its units, granularity, and how often it updates.

The core metric in the Ornn Data API is the **price index**: a number that tracks the on-demand rental price of a GPU model over time.

## What the index value means

`index_value` is the **going rate of compute** for a GPU model, measured in **US dollars per GPU-hour**. It is a **weighted average of all verified compute transactions across the market** for that model. For example, an H100 SXM index of `2.00` means the market rate for an H100 SXM is about **\$2.00 per GPU-hour**.

<Note>
  The index reflects actual transactions, not list prices. Treat `index_value` as a normalized market rate per GPU model rather than a quote from any single provider.
</Note>

## Hourly and daily

The API exposes the GPU index at two granularities:

| Granularity | What it is                                        | Where you see it                              |
| ----------- | ------------------------------------------------- | --------------------------------------------- |
| **Hourly**  | The index sampled on the hour                     | Point-in-time and ranged history endpoints    |
| **Daily**   | The aggregated daily average of the hourly values | Daily-index endpoints and long history ranges |

History endpoints automatically choose between hourly and daily: short ranges return hourly points, long ranges (more than \~30 days) return daily points. You can also force a granularity with the `granularity` parameter where supported.

<Note>
  **Premium** (`sk_prem_`) is daily-grain only. An hourly or `auto` request is served at daily; `/api/gpu/{gpuName}/hourly` returns `403`. **Index** (no key) is the trailing 3-month daily window on the five public GPUs. See [Access tiers](/docs/access-tiers).
</Note>

## Update frequency

* **GPU index (hourly / daily)**: refreshed **hourly**, on the hour.
* **Memory prices**: refreshed **once per trading day (weekdays)**. See [Memory Price Index](/docs/memory-index).

The `last_updated` (or `updatedAt`) field on each response tells you exactly when the value was computed.

## Regions

The index currently tracks a single **global** region. The optional `region` parameter exists on several endpoints, but the only populated region is global, and it's the default. You can omit it.

<Tip>
  In some responses `region` echoes back as an empty string (`""`) and in others as `"global"`. Both refer to the same global index. This is a cosmetic difference between endpoints, not different data.
</Tip>

## Supported GPUs

The index covers these models:

`H100 SXM` · `H200` · `A100 SXM4` · `B200` · `RTX 5090` · `RTX PRO 6000 WS`

GPU names are **case- and spelling-sensitive** and must match exactly. Fetch the live list any time from [`/api/gpu-types`](/docs/api-reference/reference/list-supported-gpu-models), or see [Supported GPUs & memory types](/docs/supported-types).

## Working with the endpoints

The GPU index is exposed through a family of endpoints. A few common starting points:

| You want…                         | Endpoint                                                                                                   | Key params                                          |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| The latest price for one GPU      | [`/api/daily-index`](/docs/api-reference/current-prices/get-latest-daily-index-for-one-gpu)                | `gpuType`                                           |
| A clean daily series for charting | [`/api/gpu/{gpuName}/history-range`](/docs/api-reference/historical-prices/get-history-rows-with-metadata) | `startDate`, `endDate`, `limit`                     |
| Annualized volatility             | [`/api/gpu/{gpuName}/volatility`](/docs/api-reference/analytics/get-annualized-price-volatility)           | `startDate`, `endDate`, `windowDays` (default `30`) |
| Utilization / volume metrics      | [`/api/gpu/{gpuName}/volume-metrics`](/docs/api-reference/analytics/get-market-utilization)                | `startDate`, `endDate`, `granularity`               |

A ranged daily history for the H100, oldest first:

```bash theme={null}
curl "https://api.ornnai.com/api/gpu/H100%20SXM/history-range?startDate=2026-05-01&endDate=2026-05-31" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

<Tip>
  GPU names go in the path and must be URL-encoded (`H100 SXM` becomes `H100%20SXM`). History ranges longer than \~30 days come back at daily resolution; shorter ranges come back hourly. Force a granularity with `granularity` where the endpoint supports it. See [Analytics](/docs/analytics) for what volatility and utilization mean.
</Tip>


# Quickstart
Source: https://data.ornn.com/docs/quickstart

Get an API key and make your first request to the Ornn Data API in under two minutes.

This guide takes you from zero to your first price in three steps.

<Steps>
  <Step title="Get an API key">
    Sign in to [data.ornn.com](https://data.ornn.com), open **Settings → API Keys**, and click **Create key**. Copy the key. Trial and Premium keys start with `sk_prem_`; Full keys start with `sk_live_`. The secret is shown only once.

    See [Manage API keys](/docs/manage-api-keys) for the full walkthrough.
  </Step>

  <Step title="Make your first request">
    Fetch the current price index for an H100 SXM. Replace `YOUR_API_KEY` with the key you created.

    <CodeGroup>
      ```bash cURL theme={null}
      curl "https://api.ornnai.com/api/gpu/H100%20SXM" \
        -H "Authorization: Bearer YOUR_API_KEY"
      ```

      ```python Python theme={null}
      import requests

      resp = requests.get(
          "https://api.ornnai.com/api/gpu/H100 SXM",
          headers={"Authorization": "Bearer YOUR_API_KEY"},
      )
      resp.raise_for_status()
      print(resp.json())
      ```

      ```javascript JavaScript theme={null}
      const res = await fetch("https://api.ornnai.com/api/gpu/H100 SXM", {
        headers: { Authorization: "Bearer YOUR_API_KEY" },
      });
      const data = await res.json();
      console.log(data);
      ```

      ```php PHP theme={null}
      <?php
      $ch = curl_init("https://api.ornnai.com/api/gpu/" . rawurlencode("H100 SXM"));
      curl_setopt_array($ch, [
          CURLOPT_RETURNTRANSFER => true,
          CURLOPT_HTTPHEADER => ["Authorization: Bearer YOUR_API_KEY"],
      ]);
      $data = json_decode(curl_exec($ch), true);
      print_r($data);
      ```

      ```go Go theme={null}
      package main

      import (
      	"fmt"
      	"io"
      	"net/http"
      	"net/url"
      )

      func main() {
      	endpoint := "https://api.ornnai.com/api/gpu/" + url.PathEscape("H100 SXM")
      	req, _ := http.NewRequest("GET", endpoint, nil)
      	req.Header.Set("Authorization", "Bearer YOUR_API_KEY")
      	resp, _ := http.DefaultClient.Do(req)
      	defer resp.Body.Close()
      	body, _ := io.ReadAll(resp.Body)
      	fmt.Println(string(body))
      }
      ```

      ```java Java theme={null}
      import java.net.URI;
      import java.net.http.HttpClient;
      import java.net.http.HttpRequest;
      import java.net.http.HttpResponse;

      HttpClient client = HttpClient.newHttpClient();
      HttpRequest request = HttpRequest.newBuilder(
              URI.create("https://api.ornnai.com/api/gpu/H100%20SXM"))
          .header("Authorization", "Bearer YOUR_API_KEY")
          .build();
      HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
      System.out.println(response.body());
      ```

      ```ruby Ruby theme={null}
      require "net/http"
      require "json"

      uri = URI("https://api.ornnai.com/api/gpu/H100%20SXM")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer YOUR_API_KEY"
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      puts JSON.parse(res.body)
      ```
    </CodeGroup>
  </Step>

  <Step title="Read the response">
    You get back the latest index value, in USD per hour:

    ```json theme={null}
    {
      "success": true,
      "data": {
        "gpu_name": "H100 SXM",
        "region": "",
        "index_value": 2.00,
        "last_updated": "2026-01-01T00:00:00.000Z"
      }
    }
    ```
  </Step>
</Steps>

## Next steps

<CardGroup>
  <Card title="Pull history into pandas" href="/docs/pandas-dataframe">
    Load a price series into a DataFrame and plot it.
  </Card>

  <Card title="Browse all endpoints" href="/docs/api-reference/current-prices/get-current-price-for-one-gpu">
    Current prices, history, analytics, and memory.
  </Card>
</CardGroup>

<Tip>
  The GPU name goes straight in the URL path. A literal space works (`H100 SXM`); your HTTP client URL-encodes it to `H100%20SXM` for you.
</Tip>


# Rate limits
Source: https://data.ornn.com/docs/rate-limits

How rate limiting works on the Ornn Data API and how to avoid it.

## How it works

Public index and catalog routes that use the public limiter allow **60 requests per minute per IP address**.

<Tip>
  The public limiter runs before optional API-key authentication, so sending a key does not replace this limit with a per-key tier. Requests from origins configured as trusted by Ornn bypass the public limiter; this is deployment configuration, not a general client entitlement. See [Authentication](/docs/authentication) for which endpoints are public.
</Tip>

## Chat

[`POST /api/chat`](/docs/access-tiers) is the exception, because each call spends model tokens rather than serving a stored row. It allows **20 messages per minute per key**, not per IP — so rotating addresses does not widen it, and a key is metered as one caller wherever it calls from. Its `429` body states the 20-message allowance and carries the same `Retry-After` header.

## When you exceed the limit

After the enforced allowance is exhausted, the limiter returns HTTP `429 Too Many Requests` with a JSON body stating the allowance it enforced — 60 requests per minute for the public limiter. Use the response's `Retry-After` header to determine how many seconds to wait before retrying.

<Note>
  Back off when you receive a `429`; repeated public polling should be cached client-side or moved to a server-side cache.
</Note>

## Avoiding rate limits

* **Cache** values you read repeatedly. The GPU index only updates hourly, so there's no benefit to polling faster than that.
* **Batch** where possible. For example, [`GET /api/daily-index/all`](/docs/api-reference/current-prices/get-latest-daily-index-for-all-gpus) returns every GPU in one request instead of one call per model.


# Supported GPUs & memory types
Source: https://data.ornn.com/docs/supported-types

The GPU models and memory types tracked by the Ornn Data API.

GPU and memory names are **exact strings**. They must match spelling, casing, and spacing. URL-encode spaces and slashes in paths and query values.

## GPU models

| GPU name          |
| ----------------- |
| `H100 SXM`        |
| `H200`            |
| `A100 SXM4`       |
| `B200`            |
| `RTX 5090`        |
| `RTX PRO 6000 WS` |

Fetch this list programmatically from [`GET /api/gpu-types`](/docs/api-reference/reference/list-supported-gpu-models) so your code stays current if models are added. Use [`GET /api/gpu-types-free`](/docs/api-reference/reference/list-free-tier-gpu-models) to get just the Index (free) subset — `H100 SXM`, `H200`, `A100 SXM4`, `B200`, `RTX 5090`. `RTX PRO 6000 WS` needs a Premium or Full key. See [Access tiers](/docs/access-tiers).

## Token (OTPI) labs

| Lab          | Label       |
| ------------ | ----------- |
| `anthropic`  | Anthropic   |
| `openai`     | OpenAI      |
| `google`     | Google      |
| `deepseek`   | DeepSeek    |
| `minimax`    | MiniMax     |
| `xiaomi`     | Xiaomi      |
| `qwen`       | Qwen        |
| `moonshotai` | Moonshot AI |
| `z-ai`       | Z.ai        |
| `mistralai`  | Mistral AI  |
| `meta-llama` | Meta Llama  |

Fetch this list programmatically from [`GET /api/token-types`](/docs/api-reference/token-prices/list-tracked-otpi-labs), and the Index subset from [`GET /api/token-types-free`](/docs/api-reference/token-prices/list-free-tier-otpi-labs) — `anthropic`, `openai`, `google`, `deepseek` at a trailing 1 month. The other seven labs need a Premium or Full key. These are the valid `lab` values for [`/api/otpi`](/docs/api-reference/token-prices/get-the-latest-token-price-index-by-lab) and [`/api/workload`](/docs/api-reference/workload-cost/get-the-workload-cost-index-by-provider).

## Memory types

Fetch the live list from [`GET /api/memory-types`](/docs/api-reference/memory/list-tracked-memory-types) (public, no key required).

Each type belongs to one of three categories: `dram`, `flash`, or `module`.

### DRAM

| Id                  | Memory type                   |
| ------------------- | ----------------------------- |
| `mem_ddr3_4gb`      | `DDR3 4Gb (512Mx8) 1600/1866` |
| `mem_ddr4_8gb`      | `DDR4 8Gb (1Gx8) 3200`        |
| `mem_ddr4_8gb_ett`  | `DDR4 8Gb (1Gx8) eTT`         |
| `mem_ddr4_16gb`     | `DDR4 16Gb (2Gx8) 3200`       |
| `mem_ddr4_16gb_ett` | `DDR4 16Gb (2Gx8) eTT`        |
| `mem_ddr5_16gb`     | `DDR5 16Gb (2Gx8) 4800/5600`  |
| `mem_ddr5_16gb_ett` | `DDR5 16Gb (2Gx8) eTT`        |

### Flash

| Id             | Memory type        |
| -------------- | ------------------ |
| `mem_mlc_32gb` | `MLC 32Gb (4Gx8)`  |
| `mem_mlc_64gb` | `MLC 64Gb (8Gx8)`  |
| `mem_slc_1gb`  | `SLC 1Gb (128Mx8)` |
| `mem_slc_2gb`  | `SLC 2Gb (256Mx8)` |

### Module

| Id                    | Memory type                 |
| --------------------- | --------------------------- |
| `mem_ddr4_udimm_16gb` | `DDR4 UDIMM 16GB 3200`      |
| `mem_ddr5_rdimm_32gb` | `DDR5 RDIMM 32GB 4800/5600` |
| `mem_ddr5_udimm_16gb` | `DDR5 UDIMM 16GB 4800/5600` |

<Note>
  This list reflects the types tracked at the time of writing. Always treat [`/api/memory-types`](/docs/api-reference/memory/list-tracked-memory-types) as the source of truth.
</Note>


# The Token Price Index
Source: https://data.ornn.com/docs/token-price-index

What the OTPI is, how it's computed per lab, how to read the daily settled values, and every parameter the endpoint accepts.

The **Ornn Token Price Index (OTPI)** is a daily, volume-weighted blended price per million tokens for each major AI model lab. It lets you track the effective cost of inference across a lab's mix of production models in one number, rather than tracking each model's list price by hand.

## What the OTPI value means

`indexPerMtok` is the **blended USD price per million tokens** for a lab on a given day. It is a volume-weighted blend across the lab's paid production models, so higher-volume models and providers influence the value more.

For example, an `anthropic` OTPI of `1.00` means \$1.00 per million tokens averaged across paid Anthropic inference for that day.

<Note>
  The OTPI uses paid inference activity and provider-weighted posted pricing, not a simple unweighted list price. Treat `indexPerMtok` as a market-blended cost of serving a lab's mix of paid models on a given day.
</Note>

## How it's computed

For each lab, on each settlement day, the index is a **volume-weighted** blend of posted per-token prices across that lab's paid production models — effectively the price of the average paid token served for that lab that day. Free tiers and open-weight self-hosting are excluded, and models served in higher volume move the index more than thinly-used ones.

<Note>
  The exact weighting scheme and provider-sampling methodology are maintained by the OTPI team and refined over time. This page describes the current published behavior; if you need the precise formula or a methodology version for research use, contact the team rather than inferring it from values.
</Note>

## Tracked labs

The index is published for these labs:

`anthropic` · `openai` · `google` · `deepseek` · `minimax` · `xiaomi` · `qwen` · `moonshotai` · `z-ai` · `mistralai` · `meta-llama`

Fetch this list programmatically from [`GET /api/token-types`](/docs/api-reference/token-prices/list-tracked-otpi-labs), or the free-tier subset from [`GET /api/token-types-free`](/docs/api-reference/token-prices/list-free-tier-otpi-labs).

Open-weight models (for example `gpt-oss`, `gemma`) and free tiers are excluded. Models without enough pricing coverage on the settlement day are also excluded, so a lab having a light-coverage day is dropped rather than published with a partial blend.

## Update frequency and settlement

OTPI values are **settled daily**, a short time after the day they cover. The lag is deliberate: it lets the day's activity finish landing before the day is blended and frozen. Once a day is settled its `indexPerMtok` is stable.

Each row includes:

| Field          | Meaning                                             |
| -------------- | --------------------------------------------------- |
| `date`         | The settlement date (`YYYY-MM-DD`) the value covers |
| `lab`          | One of the tracked labs above                       |
| `indexPerMtok` | Blended USD price per million tokens for that lab   |
| `computedAt`   | UTC timestamp the value was computed                |

<Note>
  `indexPerMtok` is returned at full floating-point precision (for example `1.234567`), not pre-rounded. Round in your own presentation layer to whatever precision you display.
</Note>

## Parameters

The OTPI is served from a single endpoint, `GET /api/otpi`. Without a key, **Index** covers the four public labs — `anthropic`, `openai`, `google`, `deepseek` — for the trailing 1 month. A **Premium** (`sk_prem_`) or **Full** (`sk_live_`) key unlocks all 11 labs with complete history. See [Access tiers](/docs/access-tiers).

| Parameter   | Type         | Description                                                                                                                          |
| ----------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `date`      | `YYYY-MM-DD` | Return that single settlement day. Defaults to the latest settled day when omitted. Ignored when `startDate`/`endDate` are supplied. |
| `startDate` | `YYYY-MM-DD` | Inclusive start of a settlement-date range. Use together with `endDate`.                                                             |
| `endDate`   | `YYYY-MM-DD` | Inclusive end of a settlement-date range. Use together with `startDate`.                                                             |
| `lab`       | enum         | Filter to a single lab. One of the tracked labs. An unrecognized value returns `400`.                                                |

Notes on combining parameters:

* **Latest vs. specific vs. range.** With no date parameters you get the latest settled day. Pass `date` for one historical day, or `startDate`+`endDate` for a window. Do not combine `date` with `startDate`/`endDate` — the API returns `400` if both are present.
* **`lab` is optional everywhere.** Omit it to get every lab you have access to (the free-4 without a key, or all tracked labs with one) for the selected day(s); include it to get one lab's series.

## Reading the latest values

Omit `date` to get the latest settled day across the labs you have access to (the free-4 without a key, or all tracked labs with one):

```bash theme={null}
curl "https://api.ornnai.com/api/otpi"
```

Add `lab` to get just one lab's latest value:

```bash theme={null}
curl "https://api.ornnai.com/api/otpi?lab=anthropic"
```

Pass a specific `date` to pull one historical day:

```bash theme={null}
DATE=$(python3 -c 'from datetime import date, timedelta; print((date.today() - timedelta(days=7)).isoformat())')
curl "https://api.ornnai.com/api/otpi?date=${DATE}"
```

## Pulling a historical range

To chart the index over time, pass `startDate` and `endDate` (both inclusive, `YYYY-MM-DD`) instead of `date`. Combine with `lab` to limit the response to a single lab. Anonymous callers are clamped to the trailing 1 month; pass an API key to reach further back. Compute dates when you make the request so a no-key example stays inside the moving window:

```python theme={null}
from datetime import date, timedelta
import requests

end_date = date.today()
start_date = end_date - timedelta(days=7)
resp = requests.get(
    "https://api.ornnai.com/api/otpi",
    params={
        "lab": "deepseek",
        "startDate": start_date.isoformat(),
        "endDate": end_date.isoformat(),
    },
)
resp.raise_for_status()
print(resp.json())
```

A ranged response echoes the requested window back as top-level `startDate`/`endDate` (not `date`), and `data` holds one row per settled day for the selected lab, oldest first.

A single-day query (`date`, or no date at all) instead echoes back a top-level `date`. The top-level `startDate`/`endDate` echo the window you requested, while the `data` rows begin at the first day the lab actually has coverage in that window, so the earliest row can be later than the `startDate` you asked for.

## Loading into pandas

The OTPI range response drops straight into a DataFrame for charting or analysis:

```python theme={null}
from datetime import date, timedelta

import pandas as pd
import requests

end_date = date.today()
start_date = end_date - timedelta(days=7)
resp = requests.get(
    "https://api.ornnai.com/api/otpi",
    params={
        "lab": "deepseek",
        "startDate": start_date.isoformat(),
        "endDate": end_date.isoformat(),
    },
)
df = pd.DataFrame(resp.json()["data"])
df["date"] = pd.to_datetime(df["date"])
df = df.set_index("date").sort_index()

# blended $/Mtok series for the lab, ready to plot
print(df["indexPerMtok"])
```

See the [pandas guide](/docs/pandas-dataframe) for the same pattern applied to the GPU index.

## Coverage and caveats

* **New labs backfill from their first settlement.** Newly added labs return rows only after their first public settlement. Historical ranges that start before that date will include only the labs already published then, so a range's per-day `count` can grow over time.
* **History begins 2025-07-04.** `anthropic`, `openai`, `google`, and `deepseek` publish from 2025-07-04; the labs added in June 2026 publish from their first settlements in mid-June 2026.
* **A coverage break spans 2026-04-04 to 2026-06-03.** History earlier than 2026-04-04 is a pre-launch reconstruction from archival source data that ends 2026-04-03, and live daily settlement begins 2026-06-04. No lab has values inside that window, and it cannot be recomputed after the fact; range queries spanning it return the days on either side. Backtests that cross the window should treat the two sides as separate segments with a known break.
* **Light-coverage days are omitted, not zeroed.** A lab with insufficient same-day pricing coverage is dropped from that day rather than published with a partial or misleading value.
* **Settled values are stable; the latest day can shift.** Because settlement lands a short time after the covered day, the "latest" day advances daily. Pin to a specific `date` if you need a fixed value.

See the [OTPI API reference](/docs/api-reference/token-prices/get-the-latest-token-price-index-by-lab) for the full schema and code samples in every supported language.

For the companion index that **counts** these tokens rather than pricing them, see the [Token Volume Index](/docs/token-volume-index). For the companion that prices the **request** rather than the token, see the [Workload Cost Index](/docs/workload-cost-index).


# The Token Volume Index
Source: https://data.ornn.com/docs/token-volume-index

Settled daily token volume across the 11 OTPI labs: share within a weight class, a shared growth baseline, an open/closed split, and the closed-lab REST series.

The **Token Volume Index** counts the tokens [OTPI](/docs/token-price-index) already prices. Nothing here is a new collection — the series are derived from the same settled daily volumes. Open-weight models released by a closed lab (`gpt-oss`, Gemma) and free variants are excluded before settlement, so a lab's totals sit below its published all-model figures.

Daily grain only. No Index window: every request needs a Premium or Full key. See [Access tiers](/docs/access-tiers).

## Four charts on the platform

The page at [data.ornn.com/analytics/models/volume](https://data.ornn.com/analytics/models/volume) draws four series from one feed. Token Share and Volume Growth each have an independent selector that gates on **weight class** first — closed source or open source — then the labs inside that class, and both open on the closed frontier three (`anthropic`, `openai`, `google`). The two classes are never drawn on one axis: these volumes settle from OpenRouter, whose traffic leans heavily toward open-weight models, so a share taken across both classes would mostly describe the routing venue rather than the market. Within a class that skew sits in every lab's denominator alike and cancels. Frontier Token Volume and Open vs Closed Share are fixed universes — a selector would make their titles wrong.

| Chart                     | Universe                        | What it answers                                                                                                                                                                                                        |
| ------------------------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Token Share**           | Labs you tick, within one class | Each selected lab as a share of the labs selected beside it. Ticking another lab re-bases the ones already on the chart, so the drawn lines always sum to 100%. Closed and open-weight labs never share a denominator. |
| **Volume Growth**         | Labs you tick                   | Each plotted lab indexed to 100 on the first day they all reported. The shared base moves with the selection; a lab that never settled in the window is struck through and left out of the base.                       |
| **Frontier Token Volume** | Closed three                    | The closed labs added together, indexed to 100 on the first date any of them reported. Shares cannot all rise; this is the chart that can.                                                                             |
| **Open vs Closed Share**  | All 11 labs                     | Proprietary vs open-weight as a filled 100% band, starting the day open-weight coverage begins. An open-weight model from a closed lab counts for neither side.                                                        |

Share is a per-day ratio, valid on every day the selected labs reported, so it is **not** trimmed to the shared growth base. Growth is: drawing days before the common start would put some labs below 100 while a late arrival had no line at all.

## Tracked labs

The same 11 as OTPI:

**Closed.** `anthropic` · `openai` · `google`

**Open-weight.** `deepseek` · `minimax` · `xiaomi` · `qwen` · `moonshotai` · `z-ai` · `mistralai` · `meta-llama`

## The REST series

[`GET /api/token-volume`](/docs/api-reference/token-volume/get-the-token-volume-index-by-day) publishes the **closed-lab** slice of the same volumes:

* `growthIndex` — each lab indexed to 100 at **its own** first settled day, not a shared day. Fixed-base: overlapping windows return identical values for the same date.
* `share` — of the closed-lab daily total.
* `totalGrowthIndex` — the three labs combined, indexed to 100 at the first date any of them reported.

`startDate` and `endDate` are required (`YYYY-MM-DD`). A lab that settled no volume on a day is left out of that day's `labs` array rather than reported as zero. There is no `lab` filter: share is defined over the closed-lab total, so a single-lab read would answer `share: 1` on every row.

The platform charts recompute share, the shared growth base, and the open/closed split **client-side** from the same settled rows. Those views are not extra fields on this endpoint. `commonBaselineDate` is absent from the REST response — a shared base is not a concept on the own-day series.

## Related

* [The Token Price Index](/docs/token-price-index) — the per-token prices these volumes weight.
* [The Workload Cost Index](/docs/workload-cost-index) — the OTPI companion that prices the request rather than the token.
* [Get the Token Volume Index by day](/docs/api-reference/token-volume/get-the-token-volume-index-by-day) — the REST schema and code samples.


# The Workload Cost Index
Source: https://data.ornn.com/docs/workload-cost-index

Daily realized dollars per request for the closed AI labs, plus a mix-purged like-for-like index and tokens-per-request intensity.

The **Workload Cost Index** is the [OTPI](/docs/token-price-index) companion for the price of a call. OTPI prices the token; this prices the request:

```
¢/request = $/MTok × tokens/request
```

Where OTPI blends posted per-token prices, the Workload Cost Index tracks the **settled dollars a lab's paid workload actually generated per request that day**, plus the two things that drive it: same-model unit cost (mix-purged) and tokens per request. It is published for the three closed labs — **Anthropic**, **OpenAI**, and **Google** — and refreshed on the same daily settle as OTPI.

## The three series

Every workload node (a provider or a model class within it) publishes three daily series:

| Series                  | What it measures                                                                                                                                               | Units                                                 |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| **Cost per Request**    | The real blended cost of one call: settled spend over paid calls for the node's model mix that day. Includes mix, so it moves when users shift between models. | cents per request (cents per image for image classes) |
| **Like-for-Like Index** | Mix-purged unit cost. Isolates true price and efficiency change from savings that come from routing to smaller or cheaper models.                              | index points (base = 100 on the seed day)             |
| **Workload Intensity**  | How heavy a typical call is — tokens served per request across the node's mix.                                                                                 | tokens per request                                    |

Read the three together: if Cost per Request falls while the Like-for-Like Index stays flat, the lab is getting cheaper by shifting workload to smaller models rather than because the same model got cheaper. If the Like-for-Like Index also falls, the same model actually got cheaper. Rising Workload Intensity — longer answers, more tool calls, deeper reasoning — can push Cost per Request up even while per-token prices fall.

<Note>
  "Settled" here means the index's official daily computation from venue-reported realized prices and volumes — the same epistemic status as OTPI. It is not audited payments.
</Note>

## Providers and model classes

Model classes are exact partitions of a provider's daily per-model rows, so class-level rows sum back to the provider aggregate. Class-level like-for-like removes only within-class mix.

| Provider    | Aggregate | Model classes                                       |
| ----------- | --------- | --------------------------------------------------- |
| `anthropic` | ✓         | `opus`, `sonnet`, `haiku`, `fable`                  |
| `openai`    | ✓         | `flagship`, `mini`, `nano`, `pro`, `codex`, `image` |
| `google`    | ✓         | `flash`, `pro`, `lite`, `image`                     |

Choose the **aggregate** for a whole-lab view, or a **class** to isolate a family (for example `sonnet` to strip out Opus/Haiku mix effects).

<Note>
  Thin classes (OpenAI `pro`, `codex`, `nano`, and the image families across labs) are accurate partitions but low-volume. Daily wiggles in those series are small-sample noise and should be read with wider windows.
</Note>

## How it's computed

The index rides the existing OTPI settle. For each provider on each settlement day:

1. **Per-model daily rows** are persisted with settled dollars, tokens, and request counts.
2. **Provider and class nodes** are built by summing the partition of models in each node.
3. **Cost per Request** is `settled_dollars ÷ requests` on that day.
4. **Workload Intensity** is `tokens ÷ requests` on that day.
5. **Like-for-Like Index** uses an LMDI decomposition between trailing 7-day windows to separate the same-model unit-cost change from the mix change, then chains the same-model component day over day. Inputs are smoothed, outputs are not, so daily chaining does not drift and model entry/exit lands in the mix term by construction.

Errors in the workload settle are isolated from the OTPI settle — OTPI rows are written first, then workload errors are collected and thrown as an `AggregateError` so the job exits with failure while preserving the token price index.

## Coverage window

* History starts **2026-06-11**. The 2026-06-04 to 2026-06-10 settlement block was backfilled with elevated Opus effective prices and is excluded from the seeded base.
* **2026-06-30 is missing** from settlement inputs for all labs — a one-day gap pending a settlement re-emit upstream.
* Newly settled days advance daily on the same \~36-hour lag as OTPI.

## Accessing the data

Query the index programmatically via [`GET /api/workload`](/docs/api-reference/workload-cost/get-the-workload-cost-index-by-provider). Unlike OTPI, this endpoint has **no Index window** — every request needs a Premium or Full key. See [Access tiers](/docs/access-tiers).

## Viewing in the dashboard

The **Workload Cost** page on [data.ornn.com/analytics/models/workload-cost](https://data.ornn.com/analytics/models/workload-cost) plots all three series, with dropdowns for provider and model class. Axes and hover tooltips are unit-aware — cents for cost per request, index points for like-for-like, thousands of tokens for intensity.

## Related

* [The Token Price Index](/docs/token-price-index) — the per-token OTPI this index composes with.
* [The Token Volume Index](/docs/token-volume-index) — settled daily token volume, share, and growth across the OTPI labs.
* [LLM coding activity](/docs/llm-coding-index) — daily public-GitHub PR and merge metrics for coding assistants.



---

## Source: https://docs.ornn.com/llms-full.txt

# Sign in to your Ornn account
Source: https://docs.ornn.com/authentication



Sign in to Ornn with a passwordless magic link, Google, GitHub, or Microsoft.

All methods create or resume the same account, so you can use whichever is most convenient. Learn what happens after authentication based on your account state.

### Sign in or create an account

The sign-in page has one email field and one primary action. The action reads “Sign In” or “Sign Up” based on the mode you are in.

First-time visitors start in sign-in mode. To create an account, use the Sign Up link under “Don't have an account?”. The page switches to create-account mode.

To switch back, use the Sign In link under “Already have an account?”.

<Info>
  The mode only changes the page label. Email sign-in and provider sign-in use the same account flow, so either mode can create a new account or resume an existing one.
</Info>

## Sign-in methods

<Tabs>
  <Tab title="Magic link">
    Magic link is the default. Ornn sends a one-time link to your email; no password required.

    <Steps>
      <Step title="Enter your email">
        Type your work email into the **Your email** field and submit the form.
      </Step>

      <Step title="Check your inbox">
        After you submit, this tab shows **Check your inbox** and confirms that we sent a sign-in link to your email. Open the email and click the link to finish signing in.

        If you need a new link, click **Resend link**.

        <Tip>
          If the email doesn't arrive within a minute, check your spam or junk folder. The link is single-use and expires after a short window.
        </Tip>
      </Step>

      <Step title="You're signed in">
        After clicking the link, Ornn routes you based on your account state. See the table below.
      </Step>
    </Steps>
  </Tab>

  <Tab title="Google">
    <Steps>
      <Step title="Click the Google tile">
        On the sign-in page, click the **Google** tile (labeled **Sign in with Google**).
      </Step>

      <Step title="Complete the Google OAuth flow">
        Sign in or pick the Google account you want to use. Google redirects you back to Ornn.
      </Step>

      <Step title="You're signed in">
        Ornn routes you based on your account state. See the table below.
      </Step>
    </Steps>
  </Tab>

  <Tab title="GitHub">
    <Steps>
      <Step title="Click the GitHub tile">
        On the sign-in page, click the **GitHub** tile (labeled **Sign in with GitHub**).
      </Step>

      <Step title="Complete the GitHub OAuth flow">
        Authorize the Ornn app in GitHub. GitHub redirects you back to Ornn.
      </Step>

      <Step title="You're signed in">
        Ornn routes you based on your account state. See the table below.
      </Step>
    </Steps>
  </Tab>
</Tabs>

## What happens after sign-in

Where you land depends on the state of your account:

| Account state                       | Where you go                                                         |
| ----------------------------------- | -------------------------------------------------------------------- |
| New user (no profile submitted)     | The onboarding form, to complete your company and contact details    |
| Profile submitted, pending approval | The onboarding schedule page, where your application is under review |
| Approved tenant                     | The reservation flow, ready to browse capacity and submit a bid      |

## Session persistence

Your session stays active across browser restarts. You won't need to sign in again on the same device unless you explicitly sign out or your session expires. Use **Sign out** in the Settings tab of the Account page to end a session at any time.


# Changelog
Source: https://docs.ornn.com/changelog



What's new and changed on Ornn. Product updates, lifecycle changes, and CLI releases.

Product updates, lifecycle changes, and CLI releases for Ornn. Newest first.

<Update label="2026-08-27">
  ## Interactive SSH only

  `ornn nodes console` and MCP `nodes_console` are removed. Open a shell with
  `ornn ssh <node-id>` (add `--identity-file` for your PEM). Observability
  verbs are unchanged.
</Update>

<Update label="2026-08-27">
  ## CLI 0.2.2 — observability latest and tail

  The [Ornn Compute CLI](/cli) and [MCP server](/mcp-server) share Observability
  verbs for reserved machines.

  * `ornn telemetry latest` / `ornn logs latest` read a one-shot window or log
    page. `ornn telemetry tail` / `ornn logs tail` follow the same live
    Observability subscribe feed as the console graphs. MCP exposes
    `telemetry_latest`, `telemetry_tail`, `logs_latest`, and `logs_tail`.
  * Interactive SSH is `ornn ssh <node-id>` (add `--identity-file` for your
    PEM). There is no host-snapshot or `nodes console` verb.

  See the [CLI](/cli) and [MCP server](/mcp-server) pages for the full command
  and tool lists.
</Update>

<Update label="2026-08-27">
  ## CLI 0.2.0 and MCP name lockstep

  The [Ornn Compute CLI](/cli) and [MCP server](/mcp-server) now share the same
  identity, node, and controller verbs.

  * `ornn update` installs the latest `@ornncompute/cli` from npm when a newer
    release is published.
  * Prefer `ornn slurm` and `ornn kubernetes` to launch or tear down those
    controllers. Launch is blocked only when the reservation's nodes already
    belong to the other controller.
  * MCP session tools are now `identity_whoami` and `identity_status` (replacing
    `ornn_whoami` and `ornn_status`). Reconnect the agent if your client cached
    the old names.

  See the [CLI](/cli) and [MCP server](/mcp-server) pages for the full command
  and tool lists.
</Update>

<Update label="2026-07-22">
  ## ACH (US bank account) checkout is live

  Checkout invoices now accept **ACH (US bank account)** in addition to card. Pick the ACH tab on the Stripe-hosted invoice, enter your US bank details, and Ornn advances your bid or reservation as soon as the transfer clears.

  * **Card** settles in seconds — your bid or reservation moves forward immediately.
  * **ACH** typically settles in **1–3 US business days**. Your invoice sits in a **processing** state until the transfer clears; you don't need to pay again.

  See [Completing your Ornn reservation checkout](/guides/checkout).
</Update>

<Update label="2026-07-14">
  ## Shorter Quick Connect SSH usernames

  The **User** shown in a reservation's Connect section (and in the copied **Quick Connect** command) is now a short, friendly name derived from your email or member name — no long identifier suffix. Copy the command and run it as-is:

  ```bash theme={null}
  ssh <name>@<ip>
  ```

  If two members on the same reservation resolve to the same name, Ornn appends a small numeric suffix to keep them distinct. Existing sessions and `~/.ssh/config` entries with the previous username keep working until the VM or Bare Metal host is relaunched.
</Update>

<Update label="2026-06-05">
  ## Docs visual overhaul

  * Banner artwork on every card, plus a lifecycle illustration on the [introduction](/introduction).
  * New diagrams: [bid lifecycle](/guides/bidding) and [access modes](/guides/access-overview).
  * Refreshed theme and content across all guides.
</Update>

<Update label="2026-05-27">
  ## Docs refresh

  * Repositioned Ornn as a **GPU omnicloud** across the docs.
  * Documented the full bid lifecycle: **Pending deposit → Active → Accepted → Reservation created**, plus **Rejected**, **Withdrawn**, and **Expired**.
  * Clarified that **checkout / down-payment happens before** a bid is reviewable.
  * Updated Account to reflect four tabs: **Profile**, **Billing**, **Settings**, and **SSH keys**.
  * Added an [Access](/guides/access-overview) guide with SSH config, port forwarding, data persistence, and troubleshooting.
  * Added [Manage SSH keys](/guides/ssh-keys) and [Resale market](/guides/resale) guides.
  * Added the [Ornn Compute CLI](/cli) reference.
</Update>


# Ornn Compute CLI
Source: https://docs.ornn.com/cli



Install and use the Ornn Compute CLI (ornn) to sign in from a terminal and run tenant-scoped reservation, access, and billing commands through the same web authorization layer as the browser app.

Use the Ornn Compute CLI (`ornn`) to sign in from a terminal and run tenant-scoped reservation, access, and billing commands through the same web authorization layer as the browser app.

## Easy Install

Install from the hosted web app:

```bash theme={null}
curl -fsSL https://compute.ornn.com/cli/install | sh
```

For local development:

```bash theme={null}
curl -fsSL http://localhost:3000/cli/install | sh
```

The installer:

* prints a short Ornn Compute welcome banner and login prompt
* requires Node.js 20 or newer and `npm`
* installs `@ornncompute/cli` globally
* installs the `ornn` command
* adds the npm global bin directory to your shell profile if needed
* records the host that served it as `authBaseUrl` in `~/.config/ornn/config.json`

Set `ORNN_INSTALL_BANNER=0` to skip the banner or `ORNN_INSTALL_ANIMATION=0` to keep the banner static in scripted installs.

After install, restart your shell or source the updated profile, then run:

```bash theme={null}
ornn login
ornn whoami
ornn update
```

## Browser login

`ornn login` uses a browser device flow:

1. The CLI asks the web app for a one-time device code.
2. The CLI opens a browser to `/cli/device/<code>` when possible.
3. You sign in with the normal Ornn web login flow.
4. Once the browser session is authenticated, the CLI device request is approved automatically.
5. The CLI stores the approved session in `~/.config/ornn/auth.json`.

If the browser cannot open automatically (for example, on a remote SSH machine), copy the printed URL into any browser, sign in there, and leave the terminal running. The terminal will keep polling until the browser login approves or the request expires.

```bash theme={null}
ornn login
```

Useful options:

```bash theme={null}
ornn login --no-browser
ornn login --auth-base https://compute.ornn.com
ornn login --timeout 600
```

## Commands

```bash theme={null}
ornn help [command]
ornn login [--auth-base <url>] [--no-browser] [--timeout <seconds>]
ornn update
ornn whoami [--json]
ornn status [--json]
ornn listings list [--gpu-type <type>] [--facility <name>] [--json]
ornn listings show <listing-id> [--open] [--json]
ornn buy <listing-id> [--no-open] [--json]
ornn exchange create <listing-id> --node-count <n> [--min-node-count <n>] --start-date <yyyy-mm-dd> --end-date <yyyy-mm-dd> --price <usd> [--no-open] [--json]
ornn exchange list [--limit <1-500>] [--cursor <last-id>] [--json]
ornn exchange show <exchange-id> [--open] [--json]
ornn exchange update <exchange-id> --node-count <n> --min-node-count <n> --start-date <yyyy-mm-dd> --end-date <yyyy-mm-dd> --price <usd>
ornn exchange withdraw <exchange-id>
ornn gpus list [--status <status>] [--limit <1-500>] [--cursor <last-id>] [--json]
ornn gpus show <gpu-id> [--open] [--json]
ornn gpus checkout <gpu-id> [--no-open] [--json]
ornn nodes list [--json]
ornn nodes show <node-id> [--json]
ornn telemetry latest <node-id> [--span 15m] [--start <iso>] [--end <iso>] [--max-points <n>] [--json]
ornn telemetry tail <node-id> [--duration <seconds>] [--json]
ornn logs latest <node-id> [--stream kernel] [--count <n>] [--before <iso>] [--cursor <token>] [--json]
ornn logs tail <node-id> [--stream kernel] [--duration <seconds>] [--json]
ornn nodes launch <reservation-id> --key <path|id|label> [--mode bare-metal|vm] [--username <name>] [--network public|private] [--storage-load-drive-id <id>] [--storage-save-drive-id <id>] [--wait] [--json]
ornn nodes switch <reservation-id> --network public|private --key <path|id|label> [--mode bare-metal|vm] [--username <name>] [--wait] [--json]
ornn nodes wait <node-or-reservation-id> [--timeout <seconds>] [--json]
ornn nodes reboot <node-id> [--json]
ornn nodes hard-reset <node-id> [--json]
ornn nodes ssh-command <node-or-reservation-id> [--json]
ornn nodes keys attach <node-id> --key <path|id|label> [--json]
ornn nodes keys list <node-id> [--json]
ornn ssh <node-or-reservation-id> [--print] [--identity-file <path>] [--user <name>] [--json]
ornn metrics nodes [--json]
ornn metrics node <node-id> [--json]
ornn metrics history <node-id> [--start <iso>] [--end <iso>] [--max-points <n>] [--json]
ornn metrics watch <node-id> [--interval <seconds>] [--count <n>] [--timeout <seconds>] [--json]
ornn clusters list [--json]
ornn clusters reservations [--json]
ornn clusters eligible-nodes <reservation-id> [--type kubernetes|slurm] [--network public|private] [--json]
ornn clusters create <reservation-id> --type kubernetes|slurm [--network public|private] [--node <node-id>] [--node-count <n>] [--wait] [--json]
ornn clusters show <reservation-id> [--type kubernetes|slurm] [--json]
ornn clusters wait <reservation-id> [--type kubernetes|slurm] [--timeout <seconds>] [--json]
ornn clusters credentials <reservation-id> [--type kubernetes|slurm] [--json]
ornn clusters kubeconfig <reservation-id> [--output <path>] [--json]
ornn clusters ssh-command <reservation-id> [--identity-file <path>] [--user <name>] [--json]
ornn clusters ssh <reservation-id> [--print] [--identity-file <path>] [--user <name>] [--json]
ornn clusters add-node <reservation-id> --node <node-id> [--json]
ornn clusters remove-node <reservation-id> --node <node-id> [--json]
ornn clusters teardown <reservation-id> [--type kubernetes|slurm] [--json]
ornn slurm launch <reservation-id> [--network public|private] [--node <node-id>] [--node-count <n>] [--wait] [--wait-timeout <seconds>] [--json]
ornn slurm teardown <reservation-id> [--json]
ornn slurm status <reservation-id> [--json]
ornn slurm credentials <reservation-id> [--json]
ornn slurm ssh <reservation-id> [--print] [--identity-file <path>] [--user <name>] [--json]
ornn kubernetes launch <reservation-id> [--network public|private] [--node <node-id>] [--node-count <n>] [--wait] [--wait-timeout <seconds>] [--json]
ornn kubernetes teardown <reservation-id> [--json]
ornn kubernetes status <reservation-id> [--json]
ornn kubernetes credentials <reservation-id> [--json]
ornn kubernetes kubeconfig <reservation-id> [--output <path>] [--json]
ornn networks list [--json]
ornn networks show <network-id> [--json]
ornn networks create --name <name> [--cidr <cidr>] [--description <text>] [--json]
ornn networks update <network-id> [--name <name>] [--description <text>] [--clear-description] [--json]
ornn networks delete <network-id> [--json]
ornn networks reservation <reservation-id> [--json]
ornn networks attach <reservation-id> --network <network-id> [--json]
ornn networks detach <reservation-id> [--json]
ornn storage volumes list [--json]
ornn storage volumes show <drive-id> [--json]
ornn storage volumes create --name <name> [--source <drive-id>] [--json]
ornn storage volumes refresh <drive-id> [--json]
ornn storage volumes clear <drive-id> [--json]
ornn storage volumes delete <drive-id> [--json]
ornn storage files ls <drive-id> [--prefix <path>] [--json]
ornn storage files upload <drive-id> <local-file> [--destination <path>] [--content-type <type>] [--json]
ornn storage files download <drive-id> <remote-path> [--output <path>] [--json]
ornn storage targets [--json]
ornn storage deploy <drive-id> --reservation <reservation-id> [--all-nodes] [--read-only|--read-write] [--json]
ornn storage detach --reservation <reservation-id> [--json]
ornn storage filesystem deploy --reservation <reservation-id> [--performance-tier <tier>] [--capacity-gib <gib>] [--json]
ornn storage filesystem status --reservation <reservation-id> [--json]
ornn storage filesystem delete --reservation <reservation-id> [--json]
ornn storage status --reservation <reservation-id> [--watch] [--interval <seconds>] [--timeout <seconds>] [--json]
ornn storage buckets list [--json]
ornn storage buckets show <drive-id> [--json]
ornn storage buckets connect gcs|s3|r2 --bucket <bucket>|--url <url> [--name <name>] [--prefix <prefix>] [--region <region>] [--account-id <id>|--endpoint-url <url>] [--access-key-id <id> --secret-access-key-file <path>] [--read-only|--read-write] [--verify] [--json]
ornn storage buckets update-credentials <drive-id> --access-key-id <id> --secret-access-key-file <path> [--json]
ornn storage buckets verify <drive-id> [--json]
ornn storage buckets disconnect <drive-id> [--json]
ornn keys list [--json]
ornn keys add [<public-key-file>] --label <label> [--public-key <key>] [--json]
ornn keys delete <key-id> [--json]
ornn access show <reservation-id> [--json]
ornn access activate <reservation-id> --key <path|id|label> [--mode bare-metal|vm] [--username <name>] [--network public|private] [--storage-load-drive-id <id>] [--storage-save-drive-id <id>] [--wait] [--no-open] [--json]
ornn access switch <reservation-id> --network public|private --key <path|id|label> [--mode bare-metal|vm] [--username <name>] [--wait] [--json]
ornn access keys list <reservation-id> [--json]
ornn access keys add <reservation-id> --public-key <key> --label <label> [--json]
ornn access keys add <reservation-id> --public-key-file <path> --label <label> [--json]
ornn access keys push <reservation-id> --ssh-key-id <id> [--json]
ornn access keys status <reservation-id> [--json]
ornn access push-keys <reservation-id> --ssh-key-id <id> [--json]
ornn ssh-keys list [--json]
ornn ssh-keys add --public-key <key> --label <label> [--json]
ornn ssh-keys add --public-key-file <path> --label <label> [--json]
ornn ssh-keys delete <key-id> [--json]
ornn billing summary [--json]
ornn billing invoices [--json]
ornn billing showback --start <yyyy-mm-dd> --end <yyyy-mm-dd> [--json]
ornn billing open [--no-open] [--json]
ornn api <get|post|patch|put|delete> <allowlisted-path> [--data <json>] [--raw]
ornn logout
```

UI-aligned names are canonical: `listings`, `exchange`, and `gpus`. Older names remain as aliases (`availability` → `listings`, `bid` → `exchange`, `reservations` → `gpus`).

Bid and reservation list commands return a bounded page (500 rows by default).
Use `--limit` and `--cursor` to traverse older history: pass the final row ID
from one page as the next page's cursor. Exact `show` and
reservation `checkout` commands work independently of the selected page.

```bash theme={null}
# Read the first page, then walk older rows with the last row's ID.
ornn reservations list --limit 100 --json
ornn reservations list --limit 100 --cursor <last-id-from-previous-page> --json
```

Commands print concise human-readable output by default. Use `--json` on read/show/list commands and transaction handoffs when you need structured stdout for scripts. Errors and login/browser progress go to stderr.

Run `ornn --help` or `<command> --help` for the full command list.

## Launch and connect

```bash theme={null}
ornn keys add ~/.ssh/id_ed25519.pub --label laptop
ornn nodes launch <reservation-id> --key laptop --mode bare-metal --username ubuntu --wait
ornn nodes launch <reservation-id> --key laptop --network private --storage-load-drive-id <drive-id>
ornn nodes list
ornn ssh <node-id> --identity-file ~/.ssh/id_ed25519
```

`ornn nodes launch` registers or reuses your SSH public key, selects VM or Bare
Metal access, queues the launch, and can wait until SSH is ready. Use
`--mode vm` for VM access and `--mode bare-metal` for direct host access. If you
pass a private key path by mistake and the matching `.pub` file exists, the CLI
uses the public key file and refuses to upload private key material.
Use `--network private`, `--storage-load-drive-id`, and
`--storage-save-drive-id` to select private networking and storage volume intent
for launches that already support those options in the web app.

Use `ornn ssh <node-id>` to open an interactive SSH session with your local
OpenSSH client. Passing a reservation id also works when exactly one active
node in that reservation is SSH-ready. Add `--identity-file` for your PEM
and `--print` to print the command without connecting. After you connect,
verify GPUs with `nvidia-smi` on NVIDIA hosts or `amd-smi list` on AMD Instinct.

## Reboot and hard reset

Cycle a live node without releasing the reservation:

```bash theme={null}
ornn nodes reboot <node-id>
ornn nodes hard-reset <node-id>
```

`ornn nodes reboot` cycles the operating system on the host and leaves the
tenant user, home directory, authorized SSH keys, and attached Ornn volumes
in place. `ornn nodes hard-reset` wipes tenant data on the host (user, home,
authorized keys, and `/tmp`, `/var/tmp`, `/dev/shm` residue), reboots, and
re-pushes the reservation's active SSH keys on reconnect. Use hard reset to
return a Bare Metal host to a clean state without giving up the reservation;
copy anything you want to keep off the host first.

## Monitor node health

```bash theme={null}
ornn telemetry latest <node-id>
ornn telemetry tail <node-id>
ornn logs latest <node-id>
ornn logs tail <node-id>
ornn metrics nodes
ornn metrics node <node-id>
ornn metrics history <node-id>
ornn metrics watch <node-id>
```

`ornn telemetry latest` reads a one-shot telemetry window (start/end or `--span`
plus `--max-points`) for a reserved machine. `ornn logs latest` pages newest
kernel or serial lines with `--count`, `--before`, and `--cursor`. `telemetry
tail` and `logs tail` attach to the same live Observability subscribe feed the
console graphs use. `ornn metrics` remains the compact GPU health view.

## Clusters from the CLI

```bash theme={null}
ornn clusters reservations
ornn clusters create <reservation-id> --type kubernetes --node <node-id> --wait
ornn clusters kubeconfig <reservation-id> --output kubeconfig.yaml

ornn clusters create <reservation-id> --type slurm --node <node-id> --wait
ornn clusters ssh-command <reservation-id>
ornn clusters ssh <reservation-id> --identity-file ~/.ssh/id_ed25519
```

Prefer the `ornn slurm` and `ornn kubernetes` shortcuts when you already know
the controller type. `ornn clusters` remains the combined form and still
mirrors the web Orchestration console. Use `eligible-nodes` to see same-island
nodes before launch, `add-node` or `remove-node` to manage a live cluster, and
`teardown` to release it. Kubernetes credentials are exported with
`kubeconfig`; Slurm credentials expose an SSH login command.

Launch is blocked only when those nodes already belong to the other
controller — for example, a reservation running Kubernetes cannot also launch
Slurm. In that case the CLI reports the nodes are already on a different
controller.

## Slurm and Kubernetes shortcuts

```bash theme={null}
ornn slurm launch <reservation-id>
ornn slurm status <reservation-id>
ornn slurm ssh <reservation-id> --identity-file ~/.ssh/id_ed25519

ornn kubernetes launch <reservation-id>
ornn kubernetes status <reservation-id>
ornn kubernetes kubeconfig <reservation-id> --output kubeconfig.yaml
```

`ornn slurm` and `ornn kubernetes` are the preferred verbs for those
controllers. They match `ornn clusters ... --type slurm` and
`ornn clusters ... --type kubernetes`. Use them when you already know which
cluster type a reservation runs so you can skip the `--type` flag. Both
groups accept `--json` on every subcommand.

* `launch` provisions the cluster on the reservation.
* `teardown` releases the cluster without releasing the reservation.
* `status` shows the current cluster state.
* `credentials` prints connection details for the cluster.
* `ornn slurm ssh` opens (or prints, with `--print`) an SSH session to the Slurm login node.
* `ornn kubernetes kubeconfig` writes a kubeconfig to `--output` (or stdout) for use with `kubectl`.

Every subcommand requires a reservation id; running `<command> --help` without
one prints usage and exits.

## Networks and storage

```bash theme={null}
ornn networks list
ornn networks create --name training --cidr 10.50.0.0/16
ornn networks attach <reservation-id> --network <network-id>
ornn networks detach <reservation-id>

ornn storage volumes list
ornn storage volumes create --name checkpoint
ornn storage volumes refresh <drive-id>
ornn storage files upload <drive-id> ./model.bin --destination checkpoints/model.bin
ornn storage deploy <drive-id> --reservation <reservation-id> --all-nodes
ornn storage status --reservation <reservation-id>
ornn storage buckets list
ornn storage buckets connect gcs --bucket gs://customer-data/datasets --region us-east1
ornn storage buckets connect s3 --bucket s3://customer-data/datasets --region us-east-2 --access-key-id <id> --secret-access-key-file <path> --verify
ornn storage buckets connect s3 --url "https://us-east-2.console.aws.amazon.com/s3/buckets/customer-data?region=us-east-2&prefix=datasets/"
ornn storage buckets verify <drive-id>
ornn storage buckets update-credentials <drive-id> --access-key-id <id> --secret-access-key-file <path>
ornn storage buckets disconnect <drive-id>
```

The mount path is always `/home/<user>/volume` on each node. It cannot be changed.

`ornn networks` mirrors the customer Network console for private networks and
reservation network attachment. `ornn storage volumes` manages storage drives
that can be selected at node launch. `ornn storage deploy` creates the
reservation-scoped colocated bucket/prefix placement and moves it into
pre-positioning. `ornn storage buckets connect s3|r2`
registers S3-compatible sources and scoped credentials for later deployment to a
reservation. `ornn storage buckets connect gcs` registers a customer-owned GCS
bucket for the same deploy flow through GCP Storage Transfer Service; the source
bucket must allow the Storage Transfer service account to read it. Use
`--url` to paste supported provider console URLs, and `--verify`
to check S3-compatible credentials during registration.
`ornn storage buckets verify` confirms Ornn can access the source
before deployment. Use `update-credentials` to repair stale S3-compatible keys,
and `disconnect` to remove the Ornn connection without deleting customer
bucket data. Customer image profiles are disabled on main, so image
commands are not exposed.

Use `ornn storage files upload` before or during a direct FUSE mount. Every
mounted node sees the file on its next lookup. You do not need to remount. A
direct FUSE drive attaches to one reservation by default; pass `--all-nodes`
when deploying to fan the same mount out across every compatible node in the
node group. Avoid concurrent writes to the same file path because object storage
is not a POSIX shared filesystem.

Deploy a connected bucket once before uploading. Ornn imports it into an
Ornn-managed colocated working copy. That copy remains durable across detach
and later mounts. Detach flushes every mounted node before releasing the
volume. Ornn does not write changes back to your original bucket.

## Environment variables

* `ORNN_AUTH_BASE_URL`: web/auth origin used by `ornn login`. Unset, it falls back to the `authBaseUrl` the installer recorded in `config.json`, then to `http://localhost:3000`.
* `ORNN_API_BASE_URL`: API gateway origin. Falls back to `apiBaseUrl` in `config.json`, then maps known Ornn auth hosts (for example `https://compute.ornn.com` → `https://api.ornn.com`). Localhost and custom origins stay as-is.
* `ORNN_CONFIG_HOME`: directory for CLI auth state. Defaults to `~/.config/ornn`.

## Troubleshooting

### Login opens the wrong host

Check the origin the installer recorded, and whether an environment variable is overriding it:

```bash theme={null}
cat ~/.config/ornn/config.json
echo "$ORNN_AUTH_BASE_URL"
```

Override it for a single login:

```bash theme={null}
ornn login --auth-base https://compute.ornn.com
```

### Browser does not open

Use the manual URL fallback:

```bash theme={null}
ornn login --no-browser
```

Copy the printed URL into any browser, complete web login, then return to the terminal.

### Login expires

Run `ornn login` again. Device login requests are short-lived by design.

### You are logged in but commands say unauthorized

Confirm the account and tenant:

```bash theme={null}
ornn whoami
```

Use an approved organization account. CLI commands use the same sign-in session and role checks as the browser app.

### A command is missing or the server rejects it

The CLI checks npm at most once a day and prints a notice when a newer
`@ornncompute/cli` is published. Update in place:

```bash theme={null}
ornn update
ornn --version
```

Then retry the command.

## What's next?

<div>
  <a href="/authentication">
    <div>
      <p>Sign In</p>

      <p>
        Use a magic link, Google, GitHub, or Microsoft to create or resume your Ornn account.
      </p>
    </div>

    <div />
  </a>

  <a href="/quickstart">
    <div>
      <p>Get Started</p>

      <p>
        Create an account, complete onboarding, and reach the reservation flow once approved.
      </p>
    </div>

    <div />
  </a>
</div>


# Choose how to access your Ornn compute
Source: https://docs.ornn.com/guides/access-overview



Ornn access modes are VM, Bare Metal, Kubernetes, and Slurm. Set VM or Bare Metal on the reservation detail page. Launch Kubernetes or Slurm from **Controllers** (`/controllers`).

When you have a confirmed reservation, Ornn lets you choose how your GPU hardware is materialized and made accessible. You set this choice per reservation from the reservation detail page (`/portfolio/[reservationId]`).

## Available access modes

VM and Bare Metal are configured on the reservation detail page:

<div>
  <span>Confirmed reservation</span>

  <span />

  <span>set per reservation on the detail page</span>

  <div>
    <div>
      <h4>VM</h4>

      <p>
        Managed virtual machine on your reserved hardware. Ornn base image (Ubuntu plus CUDA or
        ROCm, and PyTorch) or an approved custom image. SSH into the VM.
      </p>
    </div>

    <div>
      <h4>Bare Metal</h4>

      <p>
        Direct SSH to the physical host. No virtualization layer; you manage the software
        environment yourself.
      </p>
    </div>
  </div>
</div>

|                         | VM                                                                            | Bare Metal                                                        |
| ----------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **Use case**            | Most ML training and inference workloads                                      | Workloads that need direct hardware control or maximum throughput |
| **Performance profile** | Near-bare-metal; slight virtualization overhead                               | No virtualization, direct physical host                           |
| **Image options**       | Ornn base image (Ubuntu + CUDA or ROCm + PyTorch) or an approved custom image | No image; you manage the software environment directly            |
| **Recommended for**     | Most Ornn customers                                                           | Advanced users who need full hardware control                     |

<Note>
  Need a cluster instead of a single machine? You can also launch a managed
  **[Kubernetes](/guides/kubernetes-access)** or **[Slurm](/guides/slurm-access)**
  cluster across your reserved GPU nodes from the Orchestration page.
</Note>

## Prerequisites

Before you can configure an access mode for a reservation, the following must be true:

* The bid has been promoted to a confirmed reservation, and the reservation is visible in My GPUs.
* **Checkout and payment** for the reservation are complete. Access cannot be launched or changed on a reservation with outstanding payment.
* Your account has **at least one active SSH public key** registered. Add keys from the **SSH keys** tab on the Account page or with `ornn ssh-keys add`. See [Manage SSH keys](/guides/ssh-keys).

## Configure the access mode

<Steps>
  <Step title="Open the reservation detail page">
    From **My GPUs** (`/portfolio`), click **View** on the reservation you want to configure. The
    detail page opens at `/portfolio/[reservationId]`. The legacy `/portfolio/access` URL redirects
    here.
  </Step>

  <Step title="Choose VM or Bare Metal">
    Pick the access mode you want from the access section. VM and Bare Metal cannot run
    simultaneously on the same reservation.
  </Step>

  <Step title="Add an SSH key and launch">
    In the **SSH Keys** section, click **Add Key** to add a key to the reservation, or confirm one
    is already there. Then launch. Ornn authorizes the reservation's active keys on the host.
  </Step>

  <Step title="Wait for the host to be ready">
    Provisioning takes a few minutes. The **SSH Host** and **User** fields (plus a ready-to-run
    **Quick Connect** command) appear in the Connect section of the reservation detail page once the
    host is ready.
  </Step>
</Steps>

<Note>
  You can also launch and connect from the CLI: `ornn nodes launch <reservation-id>   --key <path|id|label> --mode vm|bare-metal --wait`, then `ornn ssh <node-id>`.
  `ornn telemetry latest` / `ornn logs latest` read a reserved machine's
  latest metrics and kernel or serial page; `telemetry tail` / `logs tail`
  follow the same live feed as the console graphs. The older
  `ornn access activate` command remains a reservation-oriented alias.
</Note>

## Connecting over SSH

Once the host is ready, connect with your preferred SSH client:

```bash theme={null}
ssh <tenant-username>@<ssh-endpoint>
```

The values for these placeholders come from the **SSH Host** and **User** fields in the Connect section of the reservation detail page. From the CLI you can also fetch them on demand:

```bash theme={null}
ornn access show <reservation-id>
ornn access show <reservation-id> --json
ornn nodes ssh-command <node-or-reservation-id>
```

### Save the connection in `~/.ssh/config`

For repeated access, add a Host entry to your local SSH config:

```bash theme={null}
Host ornn-h100
  HostName <ssh-endpoint>
  User <tenant-username>
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 60
```

Then connect with `ssh ornn-h100`.

### Port forwarding

Forward a local port to a service running on the host (for example, a Jupyter server on port 8888):

```bash theme={null}
ssh -L 8888:localhost:8888 <tenant-username>@<ssh-endpoint>
```

### Copying files

Move data on and off the host with `scp` or `rsync`:

```bash theme={null}
scp ./dataset.tar.gz <tenant-username>@<ssh-endpoint>:/data/
rsync -avh ./project/ <tenant-username>@<ssh-endpoint>:/home/<tenant-username>/project/
```

## After you connect

Verify the GPUs are visible to the host. NVIDIA reservations use `nvidia-smi`;
AMD Instinct reservations use `amd-smi`:

```bash theme={null}
nvidia-smi          # NVIDIA
amd-smi list        # AMD Instinct
```

You should see your allocated GPUs listed. If you're on the Ornn base image, PyTorch is already available:

```bash theme={null}
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.device_count())"
```

On AMD Instinct the same PyTorch check uses the HIP backend. Driver packages
and `amd-smi` are documented at [amd.com/gpu](https://www.amd.com/gpu).

## Adding more keys to a running reservation

If a teammate needs to connect to the same host, or if you want to rotate keys, open the reservation's **SSH Keys** section and use **Add Key**. Ornn associates the key with each active VM or Bare Metal node shown in the grouped reservation. It queues the access update without a relaunch.

From the CLI, add the new key directly to the reservation:

```bash theme={null}
ornn access keys add <reservation-id> --public-key-file ~/.ssh/id_ed25519.pub --label laptop
```

Active machines for that reservation automatically receive the updated key set. To re-sync a key that is already attached, run:

```bash theme={null}
ornn access keys push <reservation-id> --ssh-key-id <key-id>
```

## Switching access modes

You can switch between VM and Bare Metal on the same reservation, but it tears down the current environment.

<Danger>
  Switching access modes after launch tears down the existing environment. Anything stored on the
  previous mode that has not been persisted off the host will be lost. Copy out any data you need
  first.
</Danger>

To switch: open the reservation detail page, pick the other mode, make sure the reservation has an active SSH key, and launch.

## Data persistence

Ornn does not snapshot or back up data stored on the host. Treat the host as ephemeral within the reservation term:

* Persist datasets and checkpoints to your own object storage (S3, GCS, R2, etc.) regularly.
* Save before switching access modes; switching tears the environment down.
* At the end of the reservation term, the host is released and any data on it is no longer accessible.

## Troubleshooting

<AccordionGroup>
  <Accordion title="Permission denied (publickey)">
    The SSH key you're connecting with isn't authorized on the host. Confirm the key you attached to the reservation matches the private key your SSH client is using:

    ```bash theme={null}
    ssh -i ~/.ssh/id_ed25519 -v <tenant-username>@<ssh-endpoint>
    ```

    To push a different registered key onto the host, run `ornn access push-keys <reservation-id> --ssh-key-id <key-id>`.
  </Accordion>

  <Accordion title="Connection refused or timed out">
    The host may still be provisioning. Check the reservation detail page. If the **SSH Host** field
    isn't visible yet, wait a few minutes and retry. If the host is shown but unreachable, verify your
    local network allows outbound SSH on the listed port.
  </Accordion>

  <Accordion title="Host key changed warning">
    If you reconnect after switching access modes or relaunching, the host key may change. Remove the old entry from `~/.ssh/known_hosts` and reconnect:

    ```bash theme={null}
    ssh-keygen -R <ssh-endpoint>
    ```
  </Accordion>

  <Accordion title="`nvidia-smi` or `amd-smi` shows no GPUs">
    On the Ornn base image this should never happen; file a support ticket. On a custom image or Bare
    Metal, confirm the vendor driver is installed and loaded (`lsmod | grep nvidia` or
    `lsmod | grep amdgpu`) and that the kernel matches the driver build. AMD Instinct hosts use
    `amd-smi`, not `nvidia-smi`.
  </Accordion>

  <Accordion title="The access section is grayed out">
    Access setup is gated on **completed checkout/payment** and **at least one registered SSH key**. Confirm both: check Account → Billing for outstanding invoices, and the SSH keys tab for at least one active key.
  </Accordion>
</AccordionGroup>

## Learn more

<CardGroup>
  <Card title="VM access" href="/guides/vm-access">
    Launch a managed VM with the Ornn base image or an approved custom image.
  </Card>

  <Card title="Bare Metal access" href="/guides/bare-metal-access">
    SSH directly into the GPU host for maximum performance with no virtualization overhead.
  </Card>

  <Card title="Manage SSH keys" href="/guides/ssh-keys">
    Register the public key you'll attach to a reservation before launch.
  </Card>

  <Card title="Completing checkout" href="/guides/checkout">
    Finish payment so access mode changes are unlocked for your reservation.
  </Card>
</CardGroup>


# Update your profile and account preferences
Source: https://docs.ornn.com/guides/account-settings



Manage your profile, notifications, display settings, SSH keys, and billing from the Ornn Account page.

The Account page (`/account`) is where you manage everything tied to your Ornn identity. It's organized into five tabs:

* **Profile**: your personal information, your organization's company details, and notification preferences.
* **Team**: your organization's members and pending invites. See [Manage your team](/guides/team-management).
* **Billing**: billing overview, payment status, recent invoices, and History.
* **Settings**: display preferences and other personal settings.
* **SSH keys**: public keys used to authorize you on reservations.

Profile and company fields save when you press **Enter** or move focus away. Settings preferences (time zone, theme) save automatically a moment after you change them. Either way you'll see a short confirmation that your change was saved.

## Profile tab

The **Profile** tab is the default view when you open the Account page.

### Personal information

Click any field to edit it. The field saves when you press **Enter** or move focus away. Press **Escape** to discard a change before it saves.

| Field          | Description                                                                                                                                                                                                    |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **First Name** | Your given name. Required.                                                                                                                                                                                     |
| **Last Name**  | Your family name. Optional.                                                                                                                                                                                    |
| **Role**       | Your job title or role at your organization. Optional.                                                                                                                                                         |
| **Email**      | Your login email. Editable — changing it starts a two-step confirmation (link to your current inbox, then a verification link to the new address). Until both steps complete, your login email stays the same. |

<Note>
  Completing an email change signs out your other browser sessions and revokes
  connected MCP agents and CLI device logins. Reconnect agents from
  [Connected agents](/mcp-server#connect) and run `ornn login` again if you use
  the CLI.
</Note>

### Company information

The **Company Information** section shows your organization's details. **Website**, **Industry**, and **Address** are editable; **Company Name** is read-only.

| Field            | Description                                        |
| ---------------- | -------------------------------------------------- |
| **Company Name** | Your organization's legal or trading name.         |
| **Website**      | Your company's website URL.                        |
| **Industry**     | The industry or vertical your company operates in. |
| **Address**      | Your company's primary address.                    |

<Note>
  Company Name is read-only because it's your organization's canonical name across Ornn.
</Note>

### Notifications

The **Notifications** section also lives on the Profile tab. These preferences are organization-wide, not personal, and any organization member can save them.

See [Configure your Ornn notification preferences](/guides/notifications) for the four available toggles and their defaults.

## Team tab

The **Team** tab is where you view your organization's members and invite teammates. See [Manage your team](/guides/team-management) for the full workflow.

## Billing tab

The **Billing** tab shows your tenant's billing state. Admins and members can both open the tab and read the invoice list; only admins see the **Pay now**, **Pay overdue**, and hosted-invoice payment links. It includes:

* **Billing overview**: your current balance and any amount due.
* **Payment & invoicing**: status of recent payments and how invoices are being delivered.
* **Overdue**: a highlighted section that appears only when one or more invoices are past due.
* **Recent invoices**: your latest invoices with date, amount, and status.
* **History**: per-reservation GPU-hours and usage cost for a date range you choose. This is informational metering from reservation usage, not a new charge.

For each recent invoice, the actions available depend on the invoice state and whether the underlying URLs are available:

* **Pay now**: shown for open invoices. Opens the Stripe-hosted payment page.
* **Pay overdue**: shown for overdue invoices. Opens the Stripe-hosted payment page.
* **Download**: shown when a PDF copy of the invoice is available.

<Note>
  Net terms and the invoice delivery email are not editable from this tab in the current release. To change either, use the **Support** link in the Billing tab, or contact the Ornn billing team at [billing@ornn.com](mailto:billing@ornn.com).
</Note>

## Settings tab

The **Settings** tab controls personal preferences and account-level access, including Support, API Access, and a Danger Zone for signing out and deleting your account. These settings apply only to your account.

| Section         | What it controls                                                                |
| --------------- | ------------------------------------------------------------------------------- |
| **Time Zone**   | Your preferred time zone. Saved on your account.                                |
| **Appearance**  | Light or dark theme. Applied immediately and persists across sessions.          |
| **API Access**  | Programmatic API access. **Coming soon**; visible but not yet available.        |
| **Support**     | Opens `/support`, where you can create requests, read their history, and reply. |
| **Danger Zone** | Delete your account (handled via Support) or sign out of your current session.  |

<Note>
  Time Zone is saved as a preference today. It does not yet rewrite timestamps shown elsewhere in the product.
</Note>

Support is available as soon as your account belongs to an organization; you
do not need to wait for product approval. Requests and replies are scoped to
your organization, so members cannot read another organization's history.

## SSH keys tab

The **SSH keys** tab is where you register, label, and delete the public keys that authorize you on your reservations.

See [Manage SSH keys for compute access](/guides/ssh-keys) for the full workflow, including the equivalent Ornn Compute CLI commands.

## CLI equivalents

A few account-level actions are also available from the Ornn Compute CLI:

```bash theme={null}
ornn whoami            # show the signed-in user and tenant
ornn whoami --json
ornn status            # show public Ornn Compute service status
ornn update            # install the latest @ornncompute/cli from npm
ornn billing open      # open Account → Billing in a browser
ornn logout            # clear the local CLI session
```

See the [Ornn Compute CLI](/cli) for full syntax.

## What's next

<CardGroup>
  <Card title="Manage your team" href="/guides/team-management">
    Invite teammates, view the member list, and manage roles in your organization.
  </Card>

  <Card title="Notification preferences" href="/guides/notifications">
    Control which email notifications Ornn sends for your organization.
  </Card>
</CardGroup>


# Direct Bare Metal access to GPU hardware
Source: https://docs.ornn.com/guides/bare-metal-access



Configure Bare Metal access for an Ornn reservation to SSH directly into the GPU host with no virtualization overhead and no managed image.

Bare Metal access connects you directly to the physical GPU host, with no hypervisor, no managed VM, and no image selection. You launch Bare Metal access from the reservation detail page, attach a registered SSH key, and connect over SSH once the host is ready.

## When to use Bare Metal

* Your workload is sensitive to virtualization overhead.
* You need direct control over driver versions or kernel modules.
* You're running performance benchmarks or distributed training that benefits from bare physical networking.
* You want to manage the full software stack yourself.

<Note>
  For most ML training and inference workloads, [VM access](/guides/vm-access) is the simpler choice. Bare Metal is best when you need full hardware control.
</Note>

## Prerequisites

Before you can launch or switch to Bare Metal on a reservation:

* The bid must be promoted to a confirmed reservation, and the reservation must be visible in My GPUs.
* **Checkout and payment** for the reservation must be complete.
* You must have **at least one active SSH public key** registered on your account. Bare Metal does not use a VM image, so the SSH key is the only credential pushed to the host.

If you have not registered a key yet, see [Manage SSH keys for compute access](/guides/ssh-keys).

## Set up Bare Metal access

<Steps>
  <Step title="Open the reservation detail page">
    From **My GPUs** (`/portfolio`), click **View** on the reservation you want to configure. The detail page opens at `/portfolio/[reservationId]`. Access mode and state are managed here. The legacy `/portfolio/access` URL redirects to this page.
  </Step>

  <Step title="Select Bare Metal">
    Pick **Bare Metal** as the access mode. Bare Metal does not require an image selection; you manage the OS and software stack directly.
  </Step>

  <Step title="Add an SSH key and launch">
    In the **SSH Keys** section, use **Add Key** to add or confirm an SSH key on the reservation, then launch. Ornn pushes the active reservation keys to the host as part of the launch step.
  </Step>

  <Step title="Connect via SSH">
    Once the host is ready, the **SSH Host** and **User** fields (plus a ready-to-run **Quick Connect** command) appear in the Connect section of the reservation detail page. Connect directly:

    ```bash theme={null}
    ssh <tenant-username>@<ssh-endpoint>
    ```
  </Step>
</Steps>

<Warning>
  Bare Metal is direct physical host access. There is no snapshot, no image rollback, and no managed image. You're responsible for everything on the machine.
</Warning>

<Danger>
  VM and Bare Metal can't run on the same reservation at the same time. Switching modes after launch tears down the existing environment; anything not persisted off the host will be lost.
</Danger>

## Host firewall and GPU metrics

Bare Metal nodes ship with the DCGM exporter running on TCP `9400` so `ornn telemetry`, `ornn logs`, `ornn metrics`, and the reservation **Observability** tab can read live GPU health. Ornn opens `9400` on the host firewall (`ufw`, `firewall-cmd`, or `iptables`) and source-restricts it to Ornn's metrics collector — the port is not exposed to the public internet.

If you re-tighten firewall rules on the host, keep the collector's allow rule for `9400/tcp` in place, otherwise the node will show as **stale** or **offline** in [`ornn telemetry latest`](/cli#monitor-node-health), [`ornn metrics`](/cli#monitor-node-health), and Observability even while your workload is healthy. To verify the rule is present:

```bash theme={null}
sudo ufw status | grep 9400
# or
sudo iptables -S | grep 9400
```

## Push additional keys

To add another key to an already-launched Bare Metal reservation, open the reservation's **SSH Keys** section and use **Add Key**. Ornn queues the new key for every active machine in that grouped reservation.

From the CLI, add the key directly to the reservation:

```bash theme={null}
ornn access keys add <reservation-id> --public-key-file ~/.ssh/id_ed25519.pub --label laptop
```

Active machines for that reservation automatically receive the updated key set. To re-sync a key that is already attached, run:

```bash theme={null}
ornn access keys push <reservation-id> --ssh-key-id <key-id>
```

## Reboot and Hard reset

Bare Metal hosts stay live for the reservation term. Use **Reboot** or **Hard reset** from the reservation detail page when you need to recover from a stuck workload without giving up the reservation:

* **Reboot** cycles the operating system on the host. Your Linux user, home directory, authorized SSH keys, and any attached Ornn storage volumes stay in place. Ornn re-mounts volumes and reconnects the agent automatically.
* **Hard reset** wipes tenant data on the host (Linux user, home directory, authorized keys, `/tmp`, `/var/tmp`, `/dev/shm` residue) and then reboots. Once the host is back, Ornn re-pushes the reservation's active SSH keys, so you can reconnect once provisioning finishes. Use it to return the host to a clean state without releasing the reservation.

<Warning>
  Hard reset destroys everything on the host that isn't persisted off it. Copy datasets, checkpoints, and any local state to object storage or an Ornn storage volume before you trigger it.
</Warning>

The equivalent CLI commands take a node id:

```bash theme={null}
ornn nodes reboot <node-id>
ornn nodes hard-reset <node-id>
```

## CLI equivalents

The Ornn Compute CLI can queue Bare Metal access, wait for SSH readiness, and connect directly.

```bash theme={null}
ornn keys add ~/.ssh/id_ed25519.pub --label laptop
ornn nodes launch <reservation-id> --key laptop --mode bare-metal --username ubuntu --wait
ornn nodes list
ornn telemetry latest <node-id>
ornn logs latest <node-id>
ornn ssh <node-id> --identity-file ~/.ssh/id_ed25519
ornn access keys add <reservation-id> --public-key-file ~/.ssh/id_ed25519.pub --label workstation
```

`ornn ssh` opens an interactive session. Use `ornn telemetry tail` / `ornn logs tail` to follow the Observability subscribe feed. After you connect, verify GPUs with `nvidia-smi` on NVIDIA hosts or `amd-smi list` on AMD Instinct.

`--key` accepts a saved key id, saved key label, inline public key, or public-key file path. If you pass a private key path by mistake and the matching `.pub` exists, the CLI uses the public key file and refuses to upload private key material. The older `ornn access activate` command remains available as a reservation-oriented alias.

Because launch queues provisioning, use `--wait` or run `ornn nodes wait <reservation-id>` to wait until the host is reachable. `ornn nodes ssh-command <node-or-reservation-id>` prints the SSH command without connecting.

See the [Ornn Compute CLI](/cli) and [Manage SSH keys](/guides/ssh-keys) for details.

## What's next

<CardGroup>
  <Card title="Access overview" href="/guides/access-overview">
    Compare VM and Bare Metal and understand the prerequisites for each.
  </Card>

  <Card title="VM access" href="/guides/vm-access">
    Use a managed VM with the Ornn base image or an approved custom image.
  </Card>
</CardGroup>


# How bid-based pricing works on Ornn
Source: https://docs.ornn.com/guides/bidding



Learn how Ornn's bid-based pricing model works, the lifecycle a bid moves through from submission to acceptance, and how to update or withdraw a bid before the Ornn team reviews it.

Ornn uses a bid-based pricing model rather than fixed spot pricing. When you want to reserve GPU capacity, you submit a bid that states how much you're willing to pay per GPU-hour. Submitting a bid from the reserve form does **not** take payment or hold capacity — a bid is a record of interest that the Ornn team reviews and either accepts or rejects. Some bids require a **down payment** through the existing-bid checkout flow before they enter review.

## How bidding works

You submit a bid from the reservation form for a specific deployment. The bid records the **node count** you want, the date range, and the price per GPU-hour you're offering. The reserve form does not collect a payment method — the bid is created in the **Pending deposit** state.

From there, a bid moves to **Active** and enters review one of two ways:

* **No down payment required** — the bid transitions to **Active** automatically after submission and becomes visible to the Ornn team.
* **Down payment required** — the existing-bid checkout flow at `/checkout?bid=<bid-id>` (which `ornn exchange create` opens) collects a required down payment. Once the payment settles, the bid transitions to **Active** and becomes visible to the Ornn team.

The team then accepts or rejects the bid.

<Note>
  Accepting a bid is a status change — it does not charge you, create a reservation, consume the listing's capacity, or generate an invoice. A confirmed reservation is created separately after acceptance, when you sign the reservation agreement with Ornn.
</Note>

## Bid lifecycle

A bid moves through four states. The web app renders each label from the underlying status (it replaces underscores with spaces and capitalizes the first letter). The raw values shown in the CLI and detail pages are listed for reference.

| Label               | Meaning                                                                                                                                                                                                                                                                     | Underlying status |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| **Pending deposit** | The bid has been created but is not yet visible to the Ornn team. If a down payment is required, it must be paid through the existing-bid checkout flow before the bid advances to **Active**. Bids without a required down payment transition to **Active** automatically. | `pending_deposit` |
| **Active**          | The bid is live and visible to the Ornn team for review.                                                                                                                                                                                                                    | `active`          |
| **Accepted**        | The Ornn team approved your bid. The accepted node count and bid price are locked in. From here, the Ornn team follows up to sign the reservation agreement.                                                                                                                | `accepted`        |
| **Rejected**        | The Ornn team did not accept the bid.                                                                                                                                                                                                                                       | `rejected`        |

Bids you no longer want can be **withdrawn** while they are still **Pending deposit** or **Active**. Withdrawing removes the bid from the review queue.

<Warning>
  A bid stuck in **Pending deposit** is not yet in the Ornn team's review queue. If a down payment is required, complete the existing-bid checkout at `/checkout?bid=<bid-id>` to advance the bid to **Active**.
</Warning>

## What you submit in a bid

When you submit the reservation form, the bid captures:

* **Maximum node count**: how many nodes you want to reserve at most. Ornn sells capacity in whole nodes; partial nodes are rejected with a `400`.
* **Minimum node count**: the smallest number of nodes you'd still accept. The reserve form collects this as a Min/Max range alongside the maximum. When the listing only has a single node available (or a fixed quantity), no range is offered and the bid is all-or-nothing for that count.
* **Start date and end date**: the term you want.
* **Bid price per GPU-hour**: your offered price, in USD.

The bid carries both `min_node_count` and `node_count` (the maximum). When the Ornn team accepts, they can fill any whole-node count between your minimum and maximum — the reservation is created for the filled count, not necessarily your full requested count.

When the bid is accepted, the accepted node count and an `accepted_at` timestamp are recorded. The accepted count falls within your Min/Max range.

### Field reference

For scripted use, the bid record exposes these raw fields:

| Field                    | Type     | Description                                                                              |
| ------------------------ | -------- | ---------------------------------------------------------------------------------------- |
| `deployment_id`          | UUID     | The deployment the bid targets.                                                          |
| `node_count`             | integer  | Requested maximum node count.                                                            |
| `min_node_count`         | integer  | Minimum acceptable node count from your Min/Max bid range.                               |
| `start_date`             | date     | Requested start.                                                                         |
| `end_date`               | date     | Requested end.                                                                           |
| `bid_price_per_gpu_hour` | number   | Offered price per GPU-hour, USD.                                                         |
| `status`                 | string   | One of the lifecycle values above (`pending_deposit`, `active`, `accepted`, `rejected`). |
| `accepted_at`            | datetime | When the bid was accepted. `null` if not yet accepted.                                   |
| `accepted_node_count`    | integer  | Node count locked in at acceptance. `null` if not yet accepted.                          |

## Pricing your bid

The reservation form's summary rail shows a **Rate (Buy-now price)** figure: the deployment's buy-now price per GPU-hour. Use it as a reference — it is the fixed rate at which a buy-now purchase would settle.

You can bid **below, at, or above** the buy-now price. Bids do not have a price ceiling, and a bid at or above the buy-now rate is **not** auto-converted into a reservation. Every bid lands as **Pending deposit**, advances to **Active** (immediately, or after the required down payment settles), and awaits review by the Ornn team. If you want a listing at its published rate with no review step, choose **Buy now** instead of submitting a bid.

If the listing publishes a **floor price**, it sets the lowest bid the operator will consider. The reserve form checks your bid against the floor before it lets you continue: a bid below the floor is blocked with a message naming the minimum acceptable rate, so you catch it before submitting. The floor is displayed at the precision it's compared at (up to four decimals). When a listing has no floor set, no lower bound applies.

Some listings publish **no buy-now price** — the rate column shows a placeholder ("—") instead of a number. Those listings are bid-only; there is no fixed rate to reference, and you set the price you're offering.

<Tip>
  A higher bid trades cost for better acceptance odds, while a lower bid trades acceptance odds for a lower rate. Every bid is reviewed by the Ornn team regardless of how it compares to the buy-now price.
</Tip>

## Updating or withdrawing a bid

You can update or withdraw a bid while it is **Pending deposit** or **Active** (that is, before it's accepted or rejected).

* **Update**: from the bid detail page, change the node count, dates, or price, then save. All bid fields are submitted together.
* **Withdraw**: from the bid detail page, click **Withdraw bid** to remove the bid from the review queue.

<Info>
  Once a bid is **Accepted** or **Rejected**, it can no longer be updated or withdrawn.
</Info>

## Managing bids from the CLI

All bid actions are available through the Ornn Compute CLI. Prefer `ornn exchange` (`ornn bid` is an alias). `ornn exchange create` submits the bid and opens the existing-bid checkout flow at `/checkout?bid=<bid-id>` in your browser, which may collect the required down payment before the bid becomes active:

```bash theme={null}
ornn exchange create <listing-id> --node-count 8 \
  --start-date 2026-06-01 --end-date 2026-07-01 --price 2.75
ornn exchange list
ornn exchange show <bid-id>
ornn exchange update <bid-id> --node-count 8 \
  --start-date 2026-06-01 --end-date 2026-07-01 --price 3.10
ornn exchange withdraw <bid-id>
```

<Note>
  The CLI still accepts legacy `--gpu-count` and `--min-gpu-count` flags; they are converted to node counts using the listing's GPUs per node. The reserve form submits `node_count` and `min_node_count` directly. Older bids may carry `null` min values or a value equal to `node_count` (all-or-nothing).
</Note>

`ornn exchange withdraw` is the CLI equivalent of **Withdraw bid** in the web app. See the [Ornn Compute CLI](/cli) for full syntax.

## What's next

<CardGroup>
  <Card title="Managing your bids" href="/guides/managing-bids">
    Track active bids, withdraw pending offers, and see what happens after acceptance.
  </Card>

  <Card title="Reserving compute" href="/guides/reserving-compute">
    Browse Listings and open the reserve form to submit your bid.
  </Card>
</CardGroup>


# Completing your Ornn reservation checkout
Source: https://docs.ornn.com/guides/checkout

Walk through Ornn's inline checkout: company details, billing address, review, and paying by card or ACH within the 15-minute capacity hold.

Ornn checkout is a four-step form on `/checkout` that captures your company and billing details, lets you review the order, and takes payment by card or ACH — all inside the Ornn web app. Entering checkout places a 15‑minute hold on the listing's capacity, so a buyer next to you can't grab the same nodes while you finish the form.

Checkout is how you pay for a **Buy now** reservation. **Bid** orders placed from the reservation form route through the same company and billing details steps, then skip the payment step — submitting a bid from the reserve form does not require a payment method and does not charge you. The existing-bid checkout flow at `/checkout?bid=<bid-id>`, which `ornn exchange create` opens, may instead collect the required down payment before the bid becomes active. See [How bid-based pricing works](/guides/bidding).

When you complete a **Buy now** checkout, Ornn:

* Places a 15‑minute **capacity hold** on the listing so the requested nodes are reserved for you while you finish the form.
* Records your **company details**, **billing address**, and the **invoice email** on your tenant.
* Creates the **pending-payment reservation** for the listing you selected.
* Takes payment inline with the rail you pick — **card** (Visa, Mastercard, and other major networks) or **ACH (US bank account)**.

Once payment is accepted, your reservation becomes confirmed and ready to launch. For a **Bid** order, the confirm control on the review step places the bid directly and the confirmation reads *"Your bid was submitted. If it is accepted, the reservation will appear in your portfolio."*

## The checkout flow

Checkout runs as four steps in a fixed order. Each step's Continue button gates the next, and Back returns to the previous step; the steps aren't reachable by clicking the progress rule at the top.

<Steps>
  <Step title="Start checkout from a listing">
    Kick off checkout from a listing's **Buy now** or **Bid** action, or from a pending-payment reservation in My GPUs. Ornn opens `/checkout` pre-filled with the order summary — GPU type, node count, facility and region, term, price per GPU-hour, and total. For **Buy now**, a 15‑minute capacity hold is placed immediately and a countdown runs next to the order summary. **Bid** does not hold capacity.

    <Info>
      If the hold expires while you're on any step, checkout switches to an **expired** screen with a **Start over** link. Starting over mints a new hold and a fresh checkout key.
    </Info>
  </Step>

  <Step title="Enter company details">
    Provide your **Company name** and the **Invoice email** where Ornn sends the invoice for this order. This is the tenant-level billing email; future invoices for the same tenant also go here.
  </Step>

  <Step title="Enter your billing address">
    Fill in **Billing name**, **Billing email**, then **Address**, **Address 2** (optional), **City**, **State**, **Country**, and **Zip / postal code**. Country and State are selects — countries use ISO‑3166 alpha‑2 codes, US states use USPS two-letter codes, and armed forces addresses (AA, AE, AP) are supported. Postal-code format is checked for the US (5 or 5+4 digits) and Canada.
  </Step>

  <Step title="Review and confirm">
    Review the order and the details you just entered. **Buy now** shows the heading **Review reservation**; a bid shows **Review bid** and states plainly that nothing is charged. Add an optional **CC recipient** and **PO number** for the invoice, tick the terms checkbox, and confirm:

    * **Buy now** continues to the payment step.
    * **Bid** places the bid immediately from the review step — there is no payment step — and takes you straight to the confirmation screen.
  </Step>

  <Step title="Pay by card or ACH (Buy now only)">
    For a **Buy now** order, pick a payment rail and enter the details inline in Ornn's own fields:

    * **Card** — Card number, Expiration, CVC. Confirmed with Stripe's card intent.
    * **Bank transfer (ACH)** — Account holder name, email, routing number, account number, account type, and account holder type. The Nacha authorisation appears above the CTA. Confirmed with Stripe's US bank account intent.

    Country is locked to US on payment. Submitting the form creates the payment intent, and the CTA reads **Buy now**.
  </Step>

  <Step title="Confirmation">
    Ornn lands on a single confirmation screen with the outcome for the order:

    * **Card (Buy now)** — Once the charge settles, you see a payment-confirmed message and the reservation is ready to launch.
    * **ACH (Buy now)** — The reservation is granted immediately while the bank transfer settles in 1–2 US business days. The confirmation screen says the reservation exists and the bank payment is still pending — it does not claim the payment has cleared.
    * **Bid** — The screen confirms *"Your bid was submitted. If it is accepted, the reservation will appear in your portfolio."* No charge is made; track the bid in **My GPUs → Bids**.

    A confirmation stays on screen once you land on it; a hold that ticks past afterwards will not replace it with **Start over**.
  </Step>
</Steps>

<Note>
  Checkout does not select an access mode. **VM** and **Bare Metal** are configured later from the reservation detail page (`/portfolio/[reservationId]`). See [Choose how to access your Ornn compute](/guides/access-overview).
</Note>

## The 15-minute capacity hold

Entering checkout places a hold on the listing's capacity so nobody else can buy the same nodes while you fill in your details. The hold:

* Starts the moment you land on the first step, not when you submit payment.
* Runs a live countdown next to the order summary that ticks in your browser and re-syncs against Ornn on each step.
* Expires after 15 minutes if you haven't submitted payment. On expiry, checkout shows a **Start over** screen and a fresh key is minted when you restart. Any progress in the form is discarded.

If Ornn refuses the initial hold (for example, another buyer took the last node while the page was loading), you see a dedicated error screen rather than being dropped into the checkout form.

## Billing details captured at checkout

| Field                       | What it controls                                                      |
| --------------------------- | --------------------------------------------------------------------- |
| **Company name**            | The legal name printed on the invoice.                                |
| **Invoice email**           | Where Ornn delivers the invoice and future invoices for this tenant.  |
| **Billing name & email**    | The contact on the invoice for this specific order.                   |
| **Billing address**         | Street, city, state, country, and postal code printed on the invoice. |
| **CC recipient** (optional) | Extra email address CC'd on the invoice.                              |
| **PO number** (optional)    | Purchase-order reference echoed onto the invoice.                     |

To change the tenant-level invoice email or address later, contact the Ornn billing team at [billing@ornn.com](mailto:billing@ornn.com).

## Payment rails

| Rail                      | Fields collected                                                                              | Settlement           | Reservation state on confirm                                 |
| ------------------------- | --------------------------------------------------------------------------------------------- | -------------------- | ------------------------------------------------------------ |
| **Card**                  | Card number, expiration, CVC                                                                  | Seconds              | Confirmed once the charge settles.                           |
| **ACH (US bank account)** | Account holder name, email, routing number, account number, account type, account holder type | 1–2 US business days | Granted immediately; bank payment settles in the background. |

Card payments confirm through Stripe's card intent flow; ACH payments confirm through Stripe's US bank account flow. Self-collected bank details can't be verified instantly, so Stripe may return `requires_action` with `verify_with_microdeposits` — that is an accepted payment, not a failure, and it lands on the same confirmation screen.

<Note>
  Microdeposit verification is not yet completable inside Ornn — Ornn has no in-product field for the six-digit code. Payments that require microdeposits still grant the reservation, but the bank transfer stays pending until verification lands.
</Note>

## Alpha caveat

<Note>
  Checkout is in active development during the Ornn alpha. If anything in your order needs hands-on coordination, the Ornn team will reach out directly.
</Note>

## Checkout from the CLI

```bash theme={null}
ornn buy <listing-id>
ornn billing open
```

`ornn buy` opens the Ornn web checkout for the listing. `ornn billing open` opens **Account → Billing**, where past invoices for your tenant are listed. See the [Ornn Compute CLI](/cli) for details.

<Note>
  `ornn exchange create` submits the bid and opens the Ornn web app at `/checkout?bid=<bid-id>` unless you pass `--no-open`. The existing-bid checkout flow may collect the required down payment before the bid becomes active. See [How bid-based pricing works](/guides/bidding).
</Note>

<Note>
  A pending-payment reservation can no longer be resumed from a link. If your capacity hold expires or you close the tab mid-checkout, start over from the listing rather than from the reservation row in My GPUs.
</Note>

## What's next

<CardGroup>
  <Card title="Choose your access mode" href="/guides/access-overview">
    After payment settles, pick VM or Bare Metal on the reservation detail page.
  </Card>

  <Card title="My GPUs overview" href="/guides/portfolio-overview">
    Track reservation status and invoices from your My GPUs section.
  </Card>
</CardGroup>


# Connect to a managed Kubernetes cluster
Source: https://docs.ornn.com/guides/kubernetes-access



Launch a managed Kubernetes cluster on your reserved Ornn GPUs, download the namespace-scoped kubeconfig, and run your first GPU workload.

A managed Kubernetes cluster turns the GPU nodes you already reserved into a Kubernetes cluster you reach with a namespace-scoped kubeconfig. Ornn runs the control plane; you get full control inside your own namespace. You launch the cluster from the console, download a kubeconfig, and connect with `kubectl`.

## When to use Kubernetes

* You run containerized training or inference and want orchestration, not a single host.
* You want to schedule multiple GPU jobs across your reserved nodes.
* You already have Kubernetes manifests, Helm charts, or operators to deploy.

<Note>
  For a single machine you SSH into, [VM access](/guides/vm-access) or [Bare Metal access](/guides/bare-metal-access) is simpler. Choose Kubernetes when you want a cluster.
</Note>

## Prerequisites

* The bid is promoted to a confirmed reservation that is visible in My GPUs.
* **Checkout and payment** for the reservation are complete.
* You have `kubectl` installed locally.

## Launch the cluster

<Steps>
  <Step title="Open Orchestration">
    From the console, go to **Orchestration** (`/controllers`) and start a new Kubernetes cluster. Cluster launch is not on the reservation access-mode toggle in My GPUs. The Orchestration list shows each cluster's region and reserved GPU hourly rate.
  </Step>

  <Step title="Choose Kubernetes and a network mode">
    Pick **Kubernetes**, then a network mode:

    * **Public** — the API is reachable over the internet.
    * **Private** — the API is reachable only over your reservation's WireGuard VPN (nothing is exposed publicly).
  </Step>

  <Step title="Launch">
    Launch the cluster. The first launch after an enrollment takes a few extra minutes while the GPU images download. The manage page shows live progress and, once the cluster is active, a **Download kubeconfig** action plus a **Need help connecting?** link to this guide.
  </Step>
</Steps>

CLI equivalent:

```bash theme={null}
ornn kubernetes launch <reservation-id> --network public --node <node-id> --wait
ornn kubernetes kubeconfig <reservation-id> --output kubeconfig.yaml
```

`ornn kubernetes` is the preferred verb. `ornn clusters create --type kubernetes`
does the same work. Launch is blocked only when those nodes already belong to
a Slurm controller.

## Connect with kubeconfig

<Steps>
  <Step title="Download the kubeconfig">
    On the cluster panel, click **Download kubeconfig**. It contains a short-lived, namespace-scoped token and the API endpoint.
  </Step>

  <Step title="Point kubectl at it">
    ```bash theme={null}
    export KUBECONFIG="$HOME/Downloads/ornn-<reservation-id>-kubeconfig.yaml"
    ```
  </Step>

  <Step title="Confirm the connection">
    Your access is scoped to your namespace, so namespace commands work:

    ```bash theme={null}
    kubectl get ns tenant-<id>
    kubectl get pods
    ```
  </Step>
</Steps>

<Note>
  Cluster-wide commands like `kubectl get nodes` and `kubectl cluster-info` return `Forbidden`. That is the security boundary working as intended — your token is scoped to your namespace — not a connection failure.
</Note>

## Run a GPU smoke test

Your reserved GPU nodes are dedicated to your reservation, and your cluster automatically pins your pods to them — you don't set any node selector or toleration yourself. NVIDIA reservations request `nvidia.com/gpu` and run `nvidia-smi`. AMD Instinct reservations request `amd.com/gpu` and run `amd-smi`. This NVIDIA example runs `nvidia-smi` and cleans up after itself:

```bash theme={null}
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ornn-smoke
  namespace: tenant-<id>
spec:
  restartPolicy: Never
  containers:
    - name: smoke
      image: nvidia/cuda:12.4.1-base-ubuntu22.04
      command: ["nvidia-smi"]
      resources:
        limits:
          nvidia.com/gpu: 1
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/ornn-smoke --timeout=300s || true
kubectl logs ornn-smoke || true
kubectl delete pod ornn-smoke --ignore-not-found
```

You should see your allocated GPU in the `nvidia-smi` table. On AMD Instinct, request `amd.com/gpu` and run `amd-smi` instead. Your real workloads only need to request the matching GPU resource — the cluster pins them to your reserved nodes for you.

```bash theme={null}
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ornn-smoke-amd
  namespace: tenant-<id>
spec:
  restartPolicy: Never
  containers:
    - name: smoke
      image: rocm/dev-ubuntu-22.04:6.3.3
      command: ["amd-smi", "list"]
      resources:
        limits:
          amd.com/gpu: 1
EOF
```

## What your namespace can't do

Your namespace is isolated from other tenants by admission-time policy. A pod or PVC that hits one of the rules below is rejected before it schedules, with a message that starts `ValidatingAdmissionPolicy 'ornn-tenant-security-baseline'`. In the current rollout you may see this as a warning first, then as a hard denial — treat both the same.

* **No `hostPath` volumes.** Node filesystem paths belong to the cluster, not the tenant. Use a PVC or your own object storage.
* **No privileged containers or host namespaces** (`securityContext.privileged`, `hostPID`, `hostIPC`, `hostNetwork`). Drop the privilege escalation; if you need GPU profiling capabilities, contact support to be added to the profiling-allowed group.
* **No pinning a PVC to an existing PV by name.** Leave `spec.volumeName` unset and let the default StorageClass provision a fresh volume inside your namespace.
* **No custom `nodeName` or `nodeSelector` targeting other reservations.** The cluster already pins your pods to your reserved nodes. Either omit node targeting entirely, or match the reservation label the cluster injects for you.

## Private clusters: bring up WireGuard first

Private clusters expose nothing publicly — the API is reachable only over your reservation's WireGuard tunnel. Set it up once:

```bash theme={null}
# 1. Generate a WireGuard keypair locally.
wg genkey | tee privatekey | wg pubkey

# 2. In My GPUs, open the reservation's Network tab, paste the printed PUBLIC
#    key, and generate a config.
# 3. Save the returned config (fill in your private key) and bring the tunnel up.
sudo wg-quick up ./ornn-wg.conf
```

Once the tunnel is up, the downloaded kubeconfig reaches the API and the steps above are unchanged.

Your existing WireGuard config is preserved when the cluster toggles between **Public** and **Private** — you don't need to regenerate it after switching modes.

### Replace or remove a WireGuard config

Each WireGuard public key is registered once per gateway. To rotate the key or move the tunnel to a different machine, remove the existing peer from the reservation's Network tab first, then paste the new public key and generate a fresh config. If you paste a key that another reservation on the same gateway already owns, the console returns a **WireGuard public key already in use** error — generate a new keypair with `wg genkey` and try again, or remove the key from the reservation that currently owns it.

## Tear down

Tearing down drains all workers, revokes the kubeconfig, and returns the GPU nodes to your reservation. A torn-down or failed cluster relaunches in place.

<Danger>
  Teardown interrupts running workloads and can't be undone. Persist checkpoints and data to your own object storage first.
</Danger>

## Troubleshooting

<AccordionGroup>
  <Accordion title="`kubectl get nodes` is Forbidden">
    Expected. Your token is namespace-scoped, so cluster-wide reads (`get nodes`, `cluster-info`, other namespaces) are denied by design. Use namespace-scoped commands like `kubectl get pods`.
  </Accordion>

  <Accordion title="Commands return Unauthorized">
    The kubeconfig token is short-lived. Download a fresh kubeconfig from the cluster panel and re-export `KUBECONFIG`.
  </Accordion>

  <Accordion title="My pod is stuck Pending">
    Your pods are pinned to your reserved GPU nodes automatically. If a pod stays `Pending`, confirm it requests `nvidia.com/gpu` and that your reservation still has free GPU capacity (each node has a fixed number of GPUs). Don't add your own `nodeSelector` or toleration — the cluster sets those for you.
  </Accordion>

  <Accordion title="Image pull fails with 403 Forbidden / DENIED">
    A `failed to fetch anonymous token: ... 403 Forbidden` (or `DENIED`) on `kubectl describe pod` means the container registry refused an **anonymous** pull of that image — the image is private or the path doesn't exist. This is not an Ornn credential issue; no Ornn-provided credential unlocks a third-party registry. Fixes:

    * Use a **public** image (the smoke test above uses `nvidia/cuda:12.4.1-base-ubuntu22.04` from Docker Hub, which pulls with no credentials).
    * For gated NVIDIA images, pull from **NGC** (`nvcr.io/nvidia/...`) and create an `imagePullSecret` from **your own** NGC API key, then reference it in the pod's `imagePullSecrets`.
    * Double-check the registry and repository path — some images are published on NGC (`nvcr.io`) rather than other registries.
  </Accordion>

  <Accordion title="A private cluster won't connect">
    Make sure the WireGuard tunnel is up (`sudo wg show`) before using the kubeconfig. Re-generate the peer config from the reservation's Network tab if your public key changed.
  </Accordion>

  <Accordion title="My pod or PVC is rejected by `ornn-tenant-security-baseline`">
    The cluster runs an admission policy that keeps tenants isolated. Common causes:

    * `hostPath` volume in the pod spec — remove it and use a PVC instead.
    * `securityContext.privileged: true`, or `hostPID`, `hostIPC`, or `hostNetwork` set to `true` — drop the privileged setting.
    * PVC with `spec.volumeName` set — remove it so a new volume is provisioned dynamically.
    * Explicit `spec.nodeName` or a `spec.nodeSelector` that targets a node outside your reservation — remove your own node targeting and let the cluster pin the pod for you.

    See [What your namespace can't do](#what-your-namespace-cant-do) for the full list.
  </Accordion>
</AccordionGroup>

## What's next

<CardGroup>
  <Card title="Slurm access" href="/guides/slurm-access">
    Prefer batch scheduling? Run a managed Slurm cluster on your reserved GPUs instead.
  </Card>

  <Card title="Access overview" href="/guides/access-overview">
    Compare the ways to access your reserved Ornn compute.
  </Card>
</CardGroup>


# View and manage your bids on Ornn
Source: https://docs.ornn.com/guides/managing-bids



Track submitted bids from the My GPUs Bids page, view bid details and lifecycle status, update or withdraw editable bids, and understand what happens after acceptance.

Every bid you submit through the reservation flow is tracked under **My GPUs**. The **Bids** page gives you a full view of submitted and in-flight offers so you can monitor their progress, update them while they're still editable, or withdraw them before they're reviewed.

## The Bids list

Open **My GPUs → Bids** to see all bids your tenant has submitted. Each row shows:

* **GPU label and quantity**: the GPU model and node count you bid on.
* **Facility and region**: where the inventory is located.
* **Term**: the start and end dates you requested.

Selecting a row previews the bid in the right-hand panel, where the current lifecycle status appears as a chip and as a **State** field (see below). The row's **View** link and the panel's **View full bid** link both open the full bid detail page.

<Info>
  If you have no bids yet, the page shows an empty state with a **Reserve now** link. Browse inventory to submit a new bid.
</Info>

## Bid lifecycle and statuses

Bids move through a defined lifecycle. The web app and CLI both surface the underlying status value. The web UI renders underscores as spaces and capitalizes the first letter.

| Label               | Meaning                                                                                                                                                                                 | Underlying status |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| **Pending deposit** | The bid has been created but is not yet in the Ornn team's review queue. If a down payment is required, pay it through the existing-bid checkout flow to advance the bid to **Active**. | `pending_deposit` |
| **Active**          | The bid is live and visible to the Ornn team for review.                                                                                                                                | `active`          |
| **Accepted**        | The Ornn team accepted the bid. Accepted node count and price are locked in.                                                                                                            | `accepted`        |
| **Rejected**        | The Ornn team did not accept the bid.                                                                                                                                                   | `rejected`        |

<Note>
  Submitting a bid from the reserve form does not take payment or hold capacity. Some bids require a **down payment** through the existing-bid checkout flow at `/checkout?bid=<bid-id>` before they advance from **Pending deposit** to **Active** and become reviewable. Acceptance itself is a status change only — Ornn does not automatically charge the remaining balance or create a reservation. A confirmed reservation is created separately, after you sign the reservation agreement following acceptance.
</Note>

## Bid detail page

Click **View** on a bid row to open the bid detail page. It shows the full record:

<ResponseField name="bid_price_per_gpu_hour" type="number">
  The price per GPU-hour you offered, in USD.
</ResponseField>

<ResponseField name="node_count" type="integer">
  The number of nodes you requested in the bid.
</ResponseField>

<ResponseField name="min_node_count" type="integer">
  The minimum node count from your Min/Max bid range — the smallest count you'd still accept. The Ornn team can fill any whole-node count between `min_node_count` and `node_count` when accepting. Older bids may carry `null` or a value equal to `node_count` (all-or-nothing).
</ResponseField>

<ResponseField name="start_date" type="date">
  The requested start date for the reservation term.
</ResponseField>

<ResponseField name="end_date" type="date">
  The requested end date for the reservation term.
</ResponseField>

<ResponseField name="status" type="string">
  The current lifecycle status (`pending_deposit`, `active`, `accepted`, or `rejected`).
</ResponseField>

<ResponseField name="accepted_at" type="datetime">
  When the bid was accepted. `null` if it has not been accepted.
</ResponseField>

<ResponseField name="accepted_node_count" type="integer">
  The node count locked in at acceptance. This falls within your Min/Max bid range (between `min_node_count` and `node_count`). `null` if not yet accepted.
</ResponseField>

## Updating a bid

You can update a bid while it is **Pending deposit** or **Active** (that is, before it's accepted or rejected).

<Steps>
  <Step title="Open the bid detail page">
    Open **My GPUs → Bids** and click **View** on the bid you want to change.
  </Step>

  <Step title="Edit the bid terms">
    Update the node count, start date, end date, or price per GPU-hour.
  </Step>

  <Step title="Save your changes">
    Submit the form. All bid fields are saved together; partial updates aren't supported.
  </Step>
</Steps>

## Withdrawing a bid

To withdraw an editable bid, open the bid detail page and click **Withdraw bid**. The bid is removed from the review queue; withdrawn bids cannot be reopened.

<Info>
  Update and withdraw are only available while the bid is **Pending deposit** or **Active**. Once it's **Accepted** or **Rejected**, no further changes are possible.
</Info>

## What happens after acceptance

When the Ornn team accepts a bid:

1. The status changes to **Accepted** and `accepted_at` and `accepted_node_count` are recorded.
2. Acceptance does not by itself charge you, create an invoice, or consume the listing's capacity.
3. The Ornn team follows up to sign the reservation agreement. Once the agreement is in place, a confirmed reservation is created and appears in **My GPUs** under the **Active** or **Upcoming** view, with details at `/portfolio/[reservationId]`, where you can configure access.

Bids submitted from the current reserve form carry a Min/Max range, so `accepted_node_count` falls between `min_node_count` and `node_count`.

## CLI equivalents

Every action on this page maps to an Ornn Compute CLI command:

```bash theme={null}
ornn exchange list                     # list all bids your tenant has submitted
ornn exchange show <bid-id>            # view a bid's full record
ornn exchange show <bid-id> --open     # open the bid in the web app
ornn exchange update <bid-id> ...      # update an editable bid (all fields required)
ornn exchange withdraw <bid-id>        # withdraw an editable bid
```

`ornn bid` remains an alias for `ornn exchange`.

Use `--json` on any read command for scripted workflows. See the [Ornn Compute CLI](/cli) for full syntax.

## Secondary market

Ornn supports resale of confirmed reservations through a secondary market. If you hold a reservation you no longer need, you can list it for sale and recover spend on the unused portion.

See [Resell reservations on the secondary market](/guides/resale) for the full workflow.

## What's next

<CardGroup>
  <Card title="My GPUs overview" href="/guides/portfolio-overview">
    View your active reservations, check connection details, and monitor GPU utilization.
  </Card>

  <Card title="Track GPU usage and invoices" href="/guides/usage-and-billing">
    Understand GPU-hour utilization, recent job history, and how to find and pay your invoices.
  </Card>
</CardGroup>


# Configure your Ornn notification preferences
Source: https://docs.ornn.com/guides/notifications



Manage organization-wide notification preferences for your Ornn tenant. Enable or disable reservation confirmations, platform announcements, billing alerts, and utilization warnings.

Notification preferences in Ornn are set **per organization**, not per individual user. They control which emails Ornn sends about activity on your tenant. Anyone in your organization can save these preferences; updates apply across the whole org.

## How to update preferences

<Steps>
  <Step title="Open the Account page">
    Go to the **Account page** (`/account`). The **Profile** tab opens by default.
  </Step>

  <Step title="Find the Notifications section">
    Scroll to the **Notifications** section on the Profile tab. It sits alongside your profile and company information; there is no separate Notifications tab.
  </Step>

  <Step title="Toggle each preference">
    Flip the toggle for any notification type. Changes autosave after a short debounce, and a **Preferences saved** toast confirms when the new value is persisted.
  </Step>
</Steps>

## Notification types

<div>
  <div>
    <div>Reservation confirmations</div>

    <p>
      Controls emails about bids being accepted and reservations being confirmed on your tenant.
    </p>
  </div>

  <div>
    <div>Platform announcements</div>

    <p>
      Controls product updates and other communications from the Ornn team.
    </p>
  </div>

  <div>
    <div>Billing alerts</div>

    <p>
      Controls emails about invoices, payment status changes, and other billing events on your tenant.
    </p>
  </div>

  <div>
    <div>Utilization warnings</div>

    <p>
      Controls emails about GPU utilization on a reservation crossing a notable threshold.
    </p>
  </div>
</div>

<Note>
  Some notification emails are still being rolled out. Billing alerts are wired up today; the other categories save your preference but may not send mail yet. Your settings are saved either way and take effect once each sender ships.
</Note>

## Default values

| Notification              | Default |
| ------------------------- | ------- |
| Reservation confirmations | On      |
| Platform announcements    | On      |
| Billing alerts            | On      |
| Utilization warnings      | Off     |

<Tip>
  Keep **Billing alerts** on so your team is notified about invoice and payment activity before it affects access to reservations.
</Tip>

## What's next

<CardGroup>
  <Card title="Account settings" href="/guides/account-settings">
    Update your profile, display preferences, and billing details.
  </Card>

  <Card title="Manage your team" href="/guides/team-management">
    Review admin and member roles, and invite teammates.
  </Card>
</CardGroup>


# Manage your GPU reservations in My GPUs
Source: https://docs.ornn.com/guides/portfolio-overview



Use the My GPUs section to track active, upcoming, and past reservations, review bids, check connection details, and monitor utilization.

**My GPUs** (the `/portfolio` route) is your central view of every GPU reservation your tenant holds. Use it to track current activity, see what's coming up, review your bids, and look back at past reservations.

## My GPUs tabs

My GPUs has four tabs:

| Tab          | What it shows                                                                                                            |
| ------------ | ------------------------------------------------------------------------------------------------------------------------ |
| **Active**   | Current reservations that are live right now. This is the default view when you open My GPUs.                            |
| **Upcoming** | Reservations that have been confirmed but haven't started yet.                                                           |
| **Bids**     | All bids your tenant has submitted, with their lifecycle status. See [View and manage your bids](/guides/managing-bids). |
| **History**  | Completed and other past reservations.                                                                                   |

<Note>
  Access setup is **not** a My GPUs tab. You configure VM or Bare Metal from the reservation detail page itself. See [Choose how to access your Ornn compute](/guides/access-overview).
</Note>

## What each reservation row shows

Each row in **Active** and **Upcoming** displays:

* **GPU**: the GPU label, for example `H100 SXM`.
* **Region**: the facility location.
* **Qty**: reserved GPU count and booked host count, for example `64x (8 nodes)`.
* **Term**: the start and end dates of the reservation.

Reservations stay in My GPUs after you launch Kubernetes or Slurm. Quantity stays the reserved GPU and host count even when every host has joined a cluster. Region and the reserved GPU rate also appear on **Orchestration**.

Selecting a row opens the **detail panel** on the right side of the page with summary information for that reservation. Click **View** on the row to open the full detail page at `/portfolio/[reservationId]`.

## Reservation statuses

The web app uses a reservation's underlying `status`, start date, and cancellation state to determine whether it appears in Active, Upcoming, or History.

| Status               | Meaning                                                                                                                                                                                                               |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Awaiting payment** | Checkout has not been paid yet. Underlying status: `pending_payment`. There is no in-app "Complete checkout" affordance for this state — start a fresh checkout from the listing instead of resuming the reservation. |
| **confirmed**        | Reserved but not yet live (for example, the start date hasn't been reached). Confirmed future reservations appear in the Upcoming tab until their start date.                                                         |
| **active**           | GPUs are allocated and access is available.                                                                                                                                                                           |
| **completed**        | The reservation term has ended.                                                                                                                                                                                       |

## Reservation detail page

The full detail page at `/portfolio/[reservationId]` is where you manage everything tied to a single reservation: configure access, review connection details, and monitor utilization.

The **Nodes** panel lists every booked host. Hosts that have joined Kubernetes or Slurm appear in a numbered cluster group even when they are no longer listed as individual Bare Metal machines. Open the group to inspect each host.

Confirmed and active reservations also show a **Sublet capacity** button in the page header that lists the reservation on the resale market. See [Resell reservations on the secondary market](/guides/resale).

### Access setup

Access mode (VM or Bare Metal), SSH key attachment, and launch/relaunch live on this page. The legacy `/portfolio/access` URL redirects here. See [Choose how to access your Ornn compute](/guides/access-overview) for prerequisites and the full flow.

### Connection details

Once access is launched, the detail page shows:

* **SSH access**: the **SSH Host**, **User**, and **Port** fields for connecting to your allocated machines.
* **Quick Connect**: a ready-to-run SSH command you can copy to your clipboard.

### Utilization, Spend, and SLA Uptime

The detail page's **Utilization** and **SLA Uptime** panels render a placeholder until real telemetry has been received; Ornn no longer estimates either on the client from elapsed wall-clock time. **Spend** follows the commerce contract: for a booking with explicit start/end instants it accrues from the wall-clock term (clamped at `cancelled_at` for cancelled reservations), so a reservation that has started shows a live figure before any telemetry reports; otherwise it shows a dash until telemetry or an admin override lands.

**Spend** accrues directly from the commerce contract for reservations with timestamped start and end times: hours elapsed between the contract start and the earlier of now or the contract end, multiplied by GPU count and the contract's per-GPU-hour rate. This follows Commerce's accrued-cost calculation; it is an estimate of cost accrued so far and may be lower than a checkout or down-payment invoice that reflects the full contract amount. If a reservation is cancelled, Spend stops accruing at the cancellation time rather than running through the original end date. Admin-provided Spend overrides, when present, remain authoritative and replace the accrued value.

The **Total commitment** figure below the Spend value is the full contract cost across the entire term (GPU count × rate × exclusive term hours). It stays visible even before telemetry lands. A **pending\_payment** reservation shows a placeholder in the Spend value slot and moves the commitment to the subtext, consistent with the other unmeasured statistics.

<Note>
  The reservation detail page reads GPU quantity, per-GPU-hour rate, and term from the commerce contract. If you booked, for example, 16× B200 at \$7/GPU-hr for a one-week term, the detail page shows those exact numbers rather than any internal deploy defaults on the underlying compute rows.
</Note>

<Note>
  When telemetry starts flowing, the Utilization panel reads `<used>/<total> GPU hours` (for example, `120/960 GPU hours`), with the total derived from GPU count and term length. A secondary line below the value shows the recent-jobs synced count and a staleness figure.
</Note>

For a deeper breakdown of usage data and invoices, see [Track GPU usage and invoices](/guides/usage-and-billing).

## CLI equivalents

Inspect reservations from the Ornn Compute CLI:

```bash theme={null}
ornn reservations list
ornn reservations list --status active --json
ornn reservations show <reservation-id>
ornn reservations show <reservation-id> --open
```

`--open` launches the reservation detail page in your browser. See the [Ornn Compute CLI](/cli) for full syntax.

## What's next

<CardGroup>
  <Card title="View and manage your bids" href="/guides/managing-bids">
    Track submitted bids and manage editable offers from the Bids tab.
  </Card>

  <Card title="Choose your access mode" href="/guides/access-overview">
    Configure VM or Bare Metal access from the reservation detail page.
  </Card>
</CardGroup>


# Resell reservations on the secondary market
Source: https://docs.ornn.com/guides/resale



List unused reservations on the Ornn resale market, and update or delist your own resale positions from the web app.

If you hold a reservation you no longer need, you can list it on the Ornn resale market for another approved tenant to claim. Resale is available from the web app.

The **Sublet capacity** button appears on the reservation detail page for **confirmed** and **active** reservations; pending-payment reservations are not eligible. Listing does not depend on how many GPU-hours you have already consumed.

## List a reservation for resale

Open the reservation detail page at `/portfolio/[reservationId]` and click **Sublet capacity** in the page header. In the modal, set your **ask price per GPU-hour** and click **List on marketplace**. Your listing becomes visible to other approved tenants. Use the same button to update or delist your reservation.

<Note>
  Once a buyer claims a resale listing, the reservation transfers to their tenant. Delist promptly if your plans change.
</Note>

## What's next

<CardGroup>
  <Card title="Portfolio overview" href="/guides/portfolio-overview">
    Find the reservation detail page and the **Sublet capacity** button. The modal's submit button reads **List on marketplace**.
  </Card>

  <Card title="Track GPU usage and invoices" href="/guides/usage-and-billing">
    Find your invoices and review charges related to your reservations.
  </Card>
</CardGroup>


# Reserving GPU capacity on Ornn
Source: https://docs.ornn.com/guides/reserving-compute



This guide walks through the Ornn reservation flow.

Reserving compute on Ornn means selecting a GPU deployment, choosing a date range, picking how many **nodes** you need, and either submitting a bid price per GPU-hour or buying at the listing's published rate. Bids are submitted from the reserve form without a payment method or capacity hold and land as **Pending deposit**; some bids require a down payment through the existing-bid checkout flow before they advance to **Active** and enter review. **Buy now** takes you into checkout to pay for the reservation.

## Where you start

**Listings** (`/reserve`) is the reservation surface. It lists deployments grouped by availability and routes you to the deployment-scoped reservation form.

## The reservation flow

<Steps>
  <Step title="Open Inventory and pick a deployment">
    Open **Inventory** (the `/reserve` route). The page groups deployments under three tabs:

    * **All**: every deployment, current and upcoming.
    * **Available now**: deployments open for reservation now.
    * **Upcoming**: deployments opening soon.

    Each card shows GPU model, quantity, facility and region, and an availability or countdown indicator. Use the filter bar to narrow by **GPU model**, **Location**, or **Quantity**.

    Click **Reserve** on a deployment row to open its reservation form at `/reserve/[deploymentId]`. Clicking the row itself opens the deployment detail panel. (The sidebar label is **Inventory**, but the route path is `/reserve`.)
  </Step>

  <Step title="Pick your reservation window">
    Set the **Coverage Length** using the start and end fields in the reservation rail. Each end of the window has a **date** input (`MM/DD/YYYY`) and a **time** input, and both are captured as explicit UTC instants — the quote is priced against those exact instants, so the total you see in the summary equals what commerce bills for the term. If the listing's availability window has already started, the start renders as **Now** rather than the past availability date.

    Because the window is instant-based rather than whole-day, you can book same-day partial-day terms (for example, a single afternoon) and the quote reflects only the hours you selected. A one-day window is priced as 24 GPU-hours — the previous inclusive `+1` day that doubled short windows has been removed.

    Date filters on the reserve list use the same formatter, so the chip labels match what the form accepts. Changing the window refetches inventory against it — the previous rows stay on screen while the new results load.
  </Step>

  <Step title="Set your node count">
    Use the slider to pick how many nodes you want. The slider is node-denominated — it steps in whole nodes, not individual GPUs — because Ornn sells GPUs in whole nodes. For a deployment of 8-GPU nodes, valid requested counts are 1, 2, 3 nodes (8, 16, 24 GPUs), and so on. Checkout rejects a partial-node requested count with a `400`.

    In **Bid** mode, when more than one node is available, the form collects a **Min** and **Max** node range: your maximum is what you'd like to reserve, and the minimum is the smallest count you'd still accept. The Ornn team can then fill any whole-node count within your range when accepting. When the listing has a fixed quantity (a single option), no range is offered and the bid is all-or-nothing for that count.

    The reserve list only shows deployments with GPUs available for your selected date range. Sold-out listings, empty listings, and listings whose availability window doesn't overlap your date range are omitted. If a listing you expected doesn't appear, widen the date range or clear filters.
  </Step>

  <Step title="Pick Buy now or Bid">
    Toggle **Buy now** to reserve at the listing's published rate, or **Bid** to enter your own price per GPU-hour. Switching modes doesn't shift the summary — the price slot holds a fixed height for both.

    Enter your **bid price per GPU-hour** in USD. The **Rate** placeholder shows the deployment's buy-now price as a reference — you can bid below, at, or above it. Every bid lands as **Pending deposit**, advances to **Active** (immediately, or after the required down payment settles), and waits on Ornn team review, so bidding above buy-now does not auto-convert into a reservation. If you want the listing at its published rate with no review step, pick **Buy now** instead. If the listing publishes a floor, the reserve form blocks a bid below it before submission and names the minimum acceptable rate. If the listing has no published buy-now price, the rate field shows a placeholder and you set the price you're offering.

    If the operator has disabled either **Buy now** or **Bid** on this listing, the unavailable toggle is grayed out and you can only continue with the mode that's enabled.
  </Step>

  <Step title="Submit the order">
    Review the order summary (total GPU-hours, estimated cost) and submit. Both modes route through the same **checkout** form to collect your company and billing details, then diverge at the final step:

    * **Buy now** ends in a payment step (card or ACH) and places a 15‑minute hold on the listing's capacity for the duration of checkout. See [Completing checkout](/guides/checkout).
    * **Bid** skips the payment step in the reserve form. The **Review bid** screen states that nothing is charged; clicking **Bid now** submits the bid and takes you to a confirmation reading *"Your bid was submitted. If it is accepted, the reservation will appear in your portfolio."* No payment method is collected from the reserve form and no capacity is held. The bid lands as **Pending deposit** — if a down payment is required, complete it through the existing-bid checkout flow to advance the bid to **Active**. Track the bid in **My GPUs → Bids**.
  </Step>
</Steps>

## After submission: the lifecycle

For a **Buy now** reservation, once payment settles the reservation is confirmed and appears in My GPUs.

For a **bid**, the record moves through four states:

| Stage               | What it means                                                                                                                                                                                                                                                                             |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pending deposit** | The bid has been created but is not yet visible to the Ornn team. If a down payment is required, pay it through the existing-bid checkout flow at `/checkout?bid=<bid-id>` to advance the bid to **Active**. Bids without a required down payment transition to **Active** automatically. |
| **Active**          | The bid is live and visible to the Ornn team for review.                                                                                                                                                                                                                                  |
| **Accepted**        | The Ornn team accepted your bid. The accepted node count and price are locked in. Ornn follows up to sign the reservation agreement, after which a confirmed reservation is created.                                                                                                      |
| **Rejected**        | The Ornn team did not accept the bid.                                                                                                                                                                                                                                                     |

Once a confirmed reservation exists in My GPUs, it carries its own reservation status (distinct from the bid status): it shows **Active** when the term has started (configure VM or Bare Metal on the reservation detail page to connect) and **Completed** when the term ends.

You can edit or withdraw a bid while it is **Pending deposit** or **Active**, before it's accepted or rejected. See [Managing your bids](/guides/managing-bids) for details.

See [How bid-based pricing works](/guides/bidding) for the full bid flow.

## Sharing a listing

Use the **Copy link** action on a listing to grab its share URL. Every share link points at `/reserve/{listingId}` — the same URL whether the recipient has an Ornn account or not. Legacy `/listing/{listingId}` URLs still work and permanently redirect to the canonical `/reserve/{listingId}` path.

What the recipient sees depends on their account state:

* **Not signed in**: a read-only listing page with the GPU model, quantity, availability window, term, and price, plus a **Reserve** button that returns them to the same listing after login.
* **Signed in, tenant pending approval**: the same read-only listing page, so they can review the offer while approval is in flight.
* **Signed in with an approved tenant**: the reservation form for that listing, unchanged from the normal Inventory flow.

The share link also unlocks two artifacts that don't require an account:

* **Open Graph preview image** at `/listing/{listingId}/og.png` — used by Slack, iMessage, and other link unfurlers to render a rich preview card.
* **Spec sheet PDF** at `/listing/{listingId}/spec.pdf` — a downloadable one-pager summarizing the listing's hardware and terms.

Both artifacts render from the same public listing metadata that the shared page exposes; no private tenant, pricing floor, or bid history is included.

<Note>
  Sharing exposes only the fields visible on the public listing page. Bid history, tenant identity, and any operator-private notes are never included in the shared view, the OG image, or the PDF.
</Note>

## Reserve from the CLI

The Ornn Compute CLI mirrors the web flow once you've signed in with `ornn login`.

Submit a bid for a listing:

```bash theme={null}
ornn exchange create <listing-id> \
  --node-count 8 \
  --start-date 2026-06-01 \
  --end-date 2026-07-01 \
  --price 2.75
```

`ornn bid` remains an alias for `ornn exchange`.

Add `--no-open` to skip the browser confirmation, or `--json` to capture the created bid plus the browser handoff fields (`bid`, `opened`, `url`).

For a **fixed-price listing**, `ornn buy` jumps straight into the checkout flow for that listing:

```bash theme={null}
ornn buy <listing-id>
```

See the [Ornn Compute CLI](/cli) for the full command reference.

## What's next

<CardGroup>
  <Card title="Completing checkout" href="/guides/checkout">
    Pay for a **Buy now** reservation by card or ACH.
  </Card>

  <Card title="How bid-based pricing works" href="/guides/bidding">
    See the full bid lifecycle, including update and withdraw.
  </Card>
</CardGroup>


# Connect to a managed Slurm cluster
Source: https://docs.ornn.com/guides/slurm-access



Launch a managed Slurm cluster on your reserved Ornn GPUs, connect over SSH with your account keys, and submit your first GPU job.

A managed Slurm cluster turns the GPU nodes you already reserved into a Slurm scheduler you reach over SSH. Ornn runs the scheduler and login node; you submit batch and distributed jobs with the standard Slurm tools. Logins use the SSH keys saved on your account.

## When to use Slurm

* You run batch jobs or distributed training and want a queue and scheduler.
* Your team shares a pool of GPUs and needs fair scheduling across jobs.
* You already have `sbatch` job scripts.

<Note>
  Prefer containers and orchestration? Use [Kubernetes access](/guides/kubernetes-access) instead. Want a single host you SSH into? See [VM](/guides/vm-access) or [Bare Metal](/guides/bare-metal-access).
</Note>

## Prerequisites

* The bid is promoted to a confirmed reservation that is visible in My GPUs.
* **Checkout and payment** for the reservation are complete.
* Your account has **at least one active SSH public key** registered — Slurm logins use your account keys. See [Manage SSH keys](/guides/ssh-keys).

## Launch the cluster

<Steps>
  <Step title="Open Orchestration">
    From the console, go to **Orchestration** (`/controllers`) and start a new Slurm cluster. Cluster launch is not on the reservation access-mode toggle in My GPUs. The Orchestration list shows each cluster's region and reserved GPU hourly rate.
  </Step>

  <Step title="Choose Slurm and a network mode">
    Pick **Slurm**, then a network mode:

    * **Public** — the SSH login is reachable over the internet.
    * **Private** — the SSH login is reachable only over your reservation's WireGuard VPN.
  </Step>

  <Step title="Launch">
    Launch the cluster. The first launch after an enrollment takes a few extra minutes while the GPU images download. The scheduler starts once every node is GPU-ready; your SSH login details appear on the manage page when it's ready.
  </Step>
</Steps>

CLI equivalent:

```bash theme={null}
ornn slurm launch <reservation-id> --network public --node <node-id> --wait
ornn slurm credentials <reservation-id>
ornn slurm ssh <reservation-id> --identity-file ~/.ssh/id_ed25519
```

`ornn slurm` is the preferred verb. `ornn clusters create --type slurm` does
the same work. Launch is blocked only when those nodes already belong to a
Kubernetes controller.

## Connect over SSH

When the scheduler is ready, the cluster panel shows your **SSH login** host and port, a ready-to-run **Connect** command, and the login **host key** so you can verify it on first connect. Copy those values and connect:

```bash theme={null}
ssh <login-user>@<login-host> -p <login-port>
```

## Submit a job

On the login node, inspect the cluster and claim GPUs with the standard Slurm tools:

```bash theme={null}
sinfo                          # partitions and node states
sacct -n -X --format=JobID,State,Elapsed

srun -N1 hostname              # single-node smoke; use -N<node-count> to span nodes
ssh <node-name> hostname       # pick a node name shown by sinfo or srun

srun --gpus=1 nvidia-smi                 # NVIDIA: grab 1 GPU and print the GPU table
srun --gres=gpu:1 amd-smi list           # AMD Instinct: grab 1 GPU and list devices

sbatch my-job.sh               # submit a batch job
squeue --me                    # watch your queued and running jobs
```

A minimal GPU `sbatch` script:

```bash theme={null}
#!/bin/bash
#SBATCH --job-name=train
#SBATCH --gpus=1
#SBATCH --output=train-%j.out

srun python train.py
```

## Use attached object storage

If you deploy a bucket-backed Ornn storage volume to the reservation, wait for
its placement to show **Ready**. Slurm then exposes it on the login node and
every worker at:

```bash theme={null}
/home/tenant/volume
```

You do not need to tear down the cluster. The active cluster picks up an
attached or detached volume during its normal status reconciliation; the Slurm
pods may restart briefly while the mount changes.

<Warning>
  Attaching or detaching storage can restart the login and worker pods, which
  can interrupt running jobs. Save a checkpoint before changing the
  attachment.

  This path is backed by object storage, not NFS. It is useful for datasets,
  checkpoints, and artifacts, but it does not provide full POSIX locking or
  safe concurrent writes to the same object. Coordinate writers in your job.
</Warning>

## Private clusters: bring up WireGuard first

Private clusters expose nothing publicly — the SSH login is reachable only over your reservation's WireGuard tunnel. Set it up once:

```bash theme={null}
# 1. Generate a WireGuard keypair locally.
wg genkey | tee privatekey | wg pubkey

# 2. In My GPUs, open the reservation's Network tab, paste the printed PUBLIC
#    key, and generate a config.
# 3. Save the returned config (fill in your private key) and bring the tunnel up.
sudo wg-quick up ./ornn-wg.conf
```

Once the tunnel is up, the SSH login above works unchanged.

Your existing WireGuard config is preserved when the cluster toggles between **Public** and **Private** — you don't need to regenerate it after switching modes.

### Replace or remove a WireGuard config

Each WireGuard public key is registered once per gateway. To rotate the key or move the tunnel to a different machine, remove the existing peer from the reservation's Network tab first, then paste the new public key and generate a fresh config. If you paste a key that another reservation on the same gateway already owns, the console returns a **WireGuard public key already in use** error — generate a new keypair with `wg genkey` and try again, or remove the key from the reservation that currently owns it.

## Tear down

Tearing down stops the scheduler, revokes SSH login access, drains the workers, and returns the GPU nodes to your reservation. A torn-down or failed cluster relaunches in place.

<Danger>
  Teardown interrupts running jobs and can't be undone. Persist checkpoints and data to attached or external object storage first.
</Danger>

## Troubleshooting

<AccordionGroup>
  <Accordion title="Permission denied (publickey)">
    Slurm logins use your account SSH keys. Confirm the private key your SSH client uses matches a key registered on your account, and that the cluster has finished issuing login access (the panel shows the SSH login once it's ready).
  </Accordion>

  <Accordion title="No SSH login details yet">
    The scheduler starts after every node reports GPU-ready. Wait for the manage page to show the **SSH login** host and port; the first launch is paced by the GPU image pull.
  </Accordion>

  <Accordion title="Host key changed warning">
    If you reconnect after a relaunch, remove the old entry and reconnect: `ssh-keygen -R <login-host>`. Verify the new key against the host key shown on the cluster panel.
  </Accordion>

  <Accordion title="A private cluster won't connect">
    Make sure the WireGuard tunnel is up (`sudo wg show`) before connecting. Re-generate the peer config from the reservation's Network tab if your public key changed.
  </Accordion>
</AccordionGroup>

## What's next

<CardGroup>
  <Card title="Kubernetes access" href="/guides/kubernetes-access">
    Prefer container orchestration? Run a managed Kubernetes cluster on your reserved GPUs instead.
  </Card>

  <Card title="Manage SSH keys" href="/guides/ssh-keys">
    Register the account SSH keys your Slurm logins use.
  </Card>
</CardGroup>


# Manage SSH keys for compute access
Source: https://docs.ornn.com/guides/ssh-keys



Register, list, and delete SSH public keys on your Ornn account so they can be authorized on VM and Bare Metal reservations.

Ornn uses SSH public keys to authorize you on every reservation, whether you use VM or Bare Metal access. You register one or more public keys on your account, then add a key to a reservation when you activate access. Keys are scoped to your tenant and can be managed from both the web app and the Ornn Compute CLI.

Three terms are used throughout the access guides:

* **Register** a key on your account: click **Add public key** on the **SSH keys** tab of the Account page (or run `ornn ssh-keys add`).
* **Add** a key to a reservation: click **Add Key** in the reservation's **SSH Keys** section. From the CLI, run `ornn access keys add <reservation-id> ...`.
* **Launch** the reservation: Ornn authorizes the reservation's active keys on the host.

## Prerequisites

* An SSH key pair generated locally. If you don't have one, run:
  ```bash theme={null}
  ssh-keygen -t ed25519 -C "you@company.com"
  ```
* The **public** key only (`~/.ssh/id_ed25519.pub`) is uploaded to Ornn. Never share or upload the private key.

<Note>
  Ed25519, RSA, and ECDSA public keys are all supported. Ed25519 is recommended
  for new keys, but you can register an existing `ssh-rsa` or `ecdsa-sha2-*` key
  if you already use one.
</Note>

## Add a key (web app)

<Steps>
  <Step title="Open the SSH keys tab">
    Go to the Account page (`/account`) and open the **SSH keys** tab.
  </Step>

  <Step title="Find the Add key form">
    On the **SSH keys** tab, use the **Add key** form at the top.
  </Step>

  <Step title="Enter the key details">
    Enter a **Name** to identify the key (for example, `laptop` or `ci-runner`), then paste the full contents of your `.pub` file into the **SSH public key** field.
  </Step>

  <Step title="Add the key">
    Click **Add public key**. The key appears under **Saved keys** with its name, fingerprint, status, and added date.
  </Step>
</Steps>

## Add a key (CLI)

Paste the key inline:

```bash theme={null}
ornn ssh-keys add --public-key "ssh-ed25519 AAAAC3Nz... you@company.com" --label laptop
```

Or read it from a file:

```bash theme={null}
ornn ssh-keys add --public-key-file ~/.ssh/id_ed25519.pub --label laptop
```

The `--label` value is the CLI equivalent of the web **Name** field. Add `--json` to get the new key record as structured output, including its `id`, which you'll need to add the key to a reservation.

## List keys

**Web app:** the **SSH keys** tab on the Account page lists every registered key.

**CLI:**

```bash theme={null}
ornn ssh-keys list
ornn ssh-keys list --json
```

Each entry shows the key `id`, label, and fingerprint. Add `--json` for the full record, including the creation timestamp.

## Add a key to a reservation

Keys are not automatically pushed to every reservation. You add a specific key when you activate access for a reservation.

**Web app:** open the reservation detail page at `/portfolio/[reservationId]`, select your access mode, and use **Add Key** in the **SSH Keys** section. You can add a key before or after launch. Before launch, Ornn saves it for provisioning. After launch, Ornn associates it with each active VM or Bare Metal node shown in the grouped reservation. The SSH access update is queued immediately, so no relaunch is required.

<Note>
  The **SSH Keys** tab and panel are hidden when the reservation has no underlying compute reservation yet — for example, a reservation created through the exchange that hasn't been picked up for provisioning. Attaching a key requires a compute reservation, so the section reappears once one exists. A compute reservation that exists but hasn't launched a node still shows the section, since registering keys before launch is supported.
</Note>

For an active Slurm cluster, adding a saved or reservation key refreshes the login SSH access without relaunching workers.

**CLI:** `ornn nodes launch` queues VM or Bare Metal access and installs the key on the reservation's machines.

```bash theme={null}
ornn nodes launch <reservation-id> --key <key-id> --mode bare-metal --username worker
ornn nodes launch <reservation-id> --key ~/.ssh/id_ed25519.pub --mode vm --wait
```

Get the `<key-id>` from `ornn ssh-keys list`, which prints each registered key's id. `--key` also accepts a saved key label, inline public key, or public-key file path. If you pass a private key path by mistake and the matching `.pub` file exists, the CLI uses the public key file and refuses to upload private key material.

To add a key to an active reservation, use **Add Key** on the reservation detail page. Ornn queues it for every active VM or Bare Metal node in that grouped reservation.

From the CLI, add the key directly to the reservation:

```bash theme={null}
ornn access keys add <reservation-id> --public-key-file ~/.ssh/id_ed25519.pub --label laptop
```

The reservation command also queues the updated key set on any active machines for that reservation. To re-sync a key that is already attached, run:

```bash theme={null}
ornn access keys push <reservation-id> --ssh-key-id <key-id>
```

### Delivery status

Each key in a reservation's **SSH Keys** section shows a status label that reflects delivery across every active VM or Bare Metal node in the reservation:

* **Registered**: the key is on your account and attached to the reservation, but Ornn has not confirmed it is installed on every active machine. This is the state for reservations that haven't launched.
* **Queued**: Ornn is pushing the key to at least one active machine. The reservation page keeps polling until the update finishes.
* **Installed**: the key is applied on every active machine in the reservation and ready to use.
* **Failed**: the key push failed on at least one machine. If another machine is still queued, polling continues until every push settles.

Use **Push key** (or `ornn access keys push`) to retry a failed delivery.

## Delete a key

<Warning>
  Deleting a key revokes it from your account immediately. For every running machine (VM or Bare Metal) where that key was authorized, Ornn queues a key update that re-pushes your remaining active keys and drops the deleted one. The removal takes effect once the host applies the queued update; a host that is not currently running has the deleted key dropped the next time it is launched. Add or push a replacement key before deleting a key you still need.
</Warning>

**Web app:** on the **SSH keys** tab of the Account page, click **Delete** next to the key.

**CLI:**

```bash theme={null}
ornn ssh-keys delete <key-id>
```

## What's next

<CardGroup>
  <Card title="VM access" href="/guides/vm-access">
    Activate a managed VM and attach an SSH key to your reservation.
  </Card>

  <Card title="Bare Metal access" href="/guides/bare-metal-access">
    Attach an SSH key for direct host access on a Bare Metal reservation.
  </Card>
</CardGroup>


# Storage pricing
Source: https://docs.ornn.com/guides/storage-pricing



Pricing for Ornn object and file storage.

## Object storage

Ornn drives use regional, standard-class object storage. Stored data is billed at
**\$0.021 per GB-month**.

Object-storage charges are prorated by the amount of data stored and the time
it is stored. Requests, retrieval, and data transfer can add separate charges
based on how you use the drive. Object-storage prices are subject to change.

Ornn file storage provides fully managed, NFS-mountable shared filesystems for your reserved compute: training data, checkpoints, and shared home directories across nodes. This page lists the price of storage instances in every region where file storage is available.

Storage is billed for the provisioned capacity of the instance, not the data you store in it. Billing starts when the instance is created and stops when it is deleted, prorated per second. Monthly prices below assume a 730-hour month.

## Service tiers

| Tier           | Best for                                                 | Custom performance |
| -------------- | -------------------------------------------------------- | ------------------ |
| **Basic HDD**  | Cost-sensitive shared storage, dev/test                  | Not available      |
| **Basic SSD**  | Latency-sensitive workloads                              | Not available      |
| **Zonal**      | High-performance workloads within a single zone          | Optional           |
| **Regional**   | Mission-critical workloads needing regional availability | Optional           |
| **Enterprise** | Regionally replicated storage for critical applications  | Not available      |
| **High-Scale** | Large-scale, high-throughput compute clusters            | Not available      |

With **custom performance** enabled on the Zonal and Regional tiers, provisioned IOPS are decoupled from capacity and billed separately. You pay a per-instance fee plus a per-IOPS rate on top of the per-GiB price.

## Instance pricing

Prices are in USD per provisioned unit. Select a region to see the prices that apply there. Where a value shows N/A, that tier or fee does not apply in the region.

<div />

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | N/A             | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | N/A            | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.1848        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2888        | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.5198        | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.5198        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2888        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000253151  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000395548  | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000711986  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000711986  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000395548  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$45.05              | \$0.2205        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.4095        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | On                 | \$27.30              | \$0.1638        | \$0.0198         |
      | Regional    | Off                | \$0                  | \$0.6195        | \$0              |
      | Regional    | On                 | \$54.60              | \$0.2867        | \$0.0369         |
      | Enterprise  | N/A                | \$0                  | \$0.6195        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.3465        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.061705479       | \$0.000302055  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000560959  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | On                 | \$0.03739726        | \$0.000224384  | \$0.000027113   |
      | Regional    | Off                | \$0                 | \$0.00084863   | \$0             |
      | Regional    | On                 | \$0.074794521       | \$0.000392672  | \$0.000050486   |
      | Enterprise  | N/A                | \$0                 | \$0.00084863   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000474658  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | \$0.168         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.315         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2625        | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | Off                | \$0                  | \$0.4725        | \$0              |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
      | Enterprise  | N/A                | \$0                  | \$0.4725        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2625        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | \$0.000230137  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000359589  | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | Off                | \$0                 | \$0.00064726   | \$0             |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
      | Enterprise  | N/A                | \$0                 | \$0.00064726   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000359589  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$55.44              | \$0.273         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.504         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.42          | \$0              |
      | Zonal       | On                 | \$33.60              | \$0.2016        | \$0.0244         |
      | Regional    | Off                | \$0                  | \$0.756         | \$0              |
      | Regional    | On                 | \$67.20              | \$0.3528        | \$0.0454         |
      | Enterprise  | N/A                | \$0                  | \$0.756         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.42          | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.075945205       | \$0.000373972  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000690411  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000575342  | \$0             |
      | Zonal       | On                 | \$0.046027397       | \$0.000276165  | \$0.00003337    |
      | Regional    | Off                | \$0                 | \$0.001035616  | \$0             |
      | Regional    | On                 | \$0.092054795       | \$0.000483288  | \$0.000062137   |
      | Enterprise  | N/A                | \$0                 | \$0.001035616  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000575342  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$50.94              | \$0.1995        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.31              | \$0.1518        | \$0.0184         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.63              | \$0.2658        | \$0.0341         |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.069774658       | \$0.000273288  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034675891       | \$0.000207986  | \$0.000025172   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069351781       | \$0.000364048  | \$0.000046747   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$40.54              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3675        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.3045        | \$0              |
      | Zonal       | On                 | \$24.57              | \$0.1474        | \$0.0178         |
      | Regional    | Off                | \$0                  | \$0.5565        | \$0              |
      | Regional    | On                 | \$49.14              | \$0.258         | \$0.0332         |
      | Enterprise  | N/A                | \$0                  | \$0.5565        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.3045        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.055534932       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000503425  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000417123  | \$0             |
      | Zonal       | On                 | \$0.033657535       | \$0.000201945  | \$0.000024402   |
      | Regional    | Off                | \$0                 | \$0.000762328  | \$0             |
      | Regional    | On                 | \$0.067315068       | \$0.000353404  | \$0.000045438   |
      | Enterprise  | N/A                | \$0                 | \$0.000762328  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000417123  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier     | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | -------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Zonal    | On                 | \$21.00              | \$0.1386        | \$0.0168         |
      | Regional | On                 | \$46.31              | \$0.2426        | \$0.0313         |
    </Tab>

    <Tab title="Hourly">
      | Tier     | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | -------- | ------------------ | ------------------- | -------------- | --------------- |
      | Zonal    | On                 | \$0.028767123       | \$0.000189863  | \$0.000023014   |
      | Regional | On                 | \$0.063431507       | \$0.00033226   | \$0.000042863   |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$55.44              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.20              | \$0.1512        | \$0.0183         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.40              | \$0.2646        | \$0.034          |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.075945205       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034520548       | \$0.000207123  | \$0.000025028   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069041096       | \$0.000362465  | \$0.000046603   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$41.58              | N/A             | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.056958904       | N/A            | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$53.36              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.55              | \$0.1533        | \$0.0185         |
      | Regional    | Off                | \$0                  | \$0.5775        | \$0              |
      | Regional    | On                 | \$51.10              | \$0.2683        | \$0.0344         |
      | Enterprise  | N/A                | \$0                  | \$0.5775        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.07309726        | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034998082       | \$0.00021      | \$0.000025316   |
      | Regional    | Off                | \$0                 | \$0.000791096  | \$0             |
      | Regional    | On                 | \$0.069996165       | \$0.0003675    | \$0.000047179   |
      | Enterprise  | N/A                | \$0                 | \$0.000791096  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | \$0.168         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.315         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2625        | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | Off                | \$0                  | \$0.4725        | \$0              |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
      | Enterprise  | N/A                | \$0                  | \$0.4725        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2625        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | \$0.000230137  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000359589  | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | Off                | \$0                 | \$0.00064726   | \$0             |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
      | Enterprise  | N/A                | \$0                 | \$0.00064726   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000359589  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$46.43              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.33              | \$0.1519        | \$0.0184         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.65              | \$0.266         | \$0.0342         |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.063604109       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034693151       | \$0.00020813   | \$0.000025172   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069386302       | \$0.000364335  | \$0.000046891   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.1879        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3522        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000257341  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000482516  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.1848        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2888        | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.5198        | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.5198        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2888        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000253151  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000395548  | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000711986  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000711986  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000395548  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$41.23              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$24.99              | \$0.1499        | \$0.0181         |
      | Regional    | Off                | \$0                  | \$0.5628        | \$0              |
      | Regional    | On                 | \$49.98              | \$0.2624        | \$0.0337         |
      | Enterprise  | N/A                | \$0                  | \$0.5628        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.056484247       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034232877       | \$0.000205397  | \$0.000024819   |
      | Regional    | Off                | \$0                 | \$0.000770959  | \$0             |
      | Regional    | On                 | \$0.068465753       | \$0.000359445  | \$0.000046215   |
      | Enterprise  | N/A                | \$0                 | \$0.000770959  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$47.82              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.50              | \$0.153         | \$0.0185         |
      | Regional    | Off                | \$0                  | \$0.5775        | \$0              |
      | Regional    | On                 | \$51.00              | \$0.2678        | \$0.0344         |
      | Enterprise  | N/A                | \$0                  | \$0.5775        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.06550274        | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034934795       | \$0.000209568  | \$0.000025316   |
      | Regional    | Off                | \$0                 | \$0.000791096  | \$0             |
      | Regional    | On                 | \$0.069869589       | \$0.000366781  | \$0.000047179   |
      | Enterprise  | N/A                | \$0                 | \$0.000791096  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$61.33              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.42              | \$0.1405        | \$0.017          |
      | Regional    | Off                | \$0                  | \$0.5271        | \$0              |
      | Regional    | On                 | \$46.83              | \$0.2459        | \$0.0316         |
      | Enterprise  | N/A                | \$0                  | \$0.5271        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.084014384       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.032078219       | \$0.000192452  | \$0.000023302   |
      | Regional    | Off                | \$0                 | \$0.000722055  | \$0             |
      | Regional    | On                 | \$0.064156439       | \$0.000336863  | \$0.000043295   |
      | Enterprise  | N/A                | \$0                 | \$0.000722055  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$41.58              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.20              | \$0.1512        | \$0.0183         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.40              | \$0.2646        | \$0.034          |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.056958904       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034520548       | \$0.000207123  | \$0.000025028   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069041096       | \$0.000362465  | \$0.000046603   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$47.12              | \$0.1995        | \$0              |
      | Zonal       | On                 | \$25.13              | \$0.1508        | \$0.0183         |
      | Regional    | On                 | \$50.27              | \$0.2639        | \$0.0339         |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.064553425       | \$0.000273288  | \$0             |
      | Zonal       | On                 | \$0.034428493       | \$0.000206548  | \$0.000025028   |
      | Regional    | On                 | \$0.068856986       | \$0.000361459  | \$0.000046459   |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$41.58              | \$0.2016        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.20              | \$0.1512        | \$0.0183         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.40              | \$0.2646        | \$0.034          |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.056958904       | \$0.000276165  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034520548       | \$0.000207123  | \$0.000025028   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069041096       | \$0.000362465  | \$0.000046603   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$39.85              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3675        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.3045        | \$0              |
      | Zonal       | On                 | \$24.15              | \$0.1449        | \$0.0175         |
      | Regional    | Off                | \$0                  | \$0.546         | \$0              |
      | Regional    | On                 | \$48.30              | \$0.2536        | \$0.0326         |
      | Enterprise  | N/A                | \$0                  | \$0.546         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.3045        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.054585616       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000503425  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000417123  | \$0             |
      | Zonal       | On                 | \$0.033082191       | \$0.000198493  | \$0.000023984   |
      | Regional    | Off                | \$0                 | \$0.000747945  | \$0             |
      | Regional    | On                 | \$0.066164384       | \$0.000347363  | \$0.000044661   |
      | Enterprise  | N/A                | \$0                 | \$0.000747945  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000417123  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$47.82              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.50              | \$0.153         | \$0.0185         |
      | Regional    | Off                | \$0                  | \$0.5775        | \$0              |
      | Regional    | On                 | \$51.00              | \$0.2678        | \$0.0344         |
      | Enterprise  | N/A                | \$0                  | \$0.5775        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.06550274        | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034934795       | \$0.000209568  | \$0.000025316   |
      | Regional    | Off                | \$0                 | \$0.000791096  | \$0             |
      | Regional    | On                 | \$0.069869589       | \$0.000366781  | \$0.000047179   |
      | Enterprise  | N/A                | \$0                 | \$0.000791096  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$50.94              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.31              | \$0.1518        | \$0.0184         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.63              | \$0.2658        | \$0.0341         |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.069774658       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034675891       | \$0.000207986  | \$0.000025172   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069351781       | \$0.000364048  | \$0.000046747   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$41.23              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$24.99              | \$0.1499        | \$0.0181         |
      | Regional    | Off                | \$0                  | \$0.5628        | \$0              |
      | Regional    | On                 | \$49.98              | \$0.2624        | \$0.0337         |
      | Enterprise  | N/A                | \$0                  | \$0.5628        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.056484247       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034232877       | \$0.000205397  | \$0.000024819   |
      | Regional    | Off                | \$0                 | \$0.000770959  | \$0             |
      | Regional    | On                 | \$0.068465753       | \$0.000359445  | \$0.000046215   |
      | Enterprise  | N/A                | \$0                 | \$0.000770959  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | \$0.168         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2625        | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | Off                | \$0                  | \$0.4725        | \$0              |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
      | Enterprise  | N/A                | \$0                  | \$0.4725        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2625        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | \$0.000230137  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000359589  | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | Off                | \$0                 | \$0.00064726   | \$0             |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
      | Enterprise  | N/A                | \$0                 | \$0.00064726   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000359589  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | \$0.168         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.315         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2625        | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | Off                | \$0                  | \$0.4725        | \$0              |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
      | Enterprise  | N/A                | \$0                  | \$0.4725        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2625        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | \$0.000230137  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000359589  | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | Off                | \$0                 | \$0.00064726   | \$0             |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
      | Enterprise  | N/A                | \$0                 | \$0.00064726   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000359589  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$48.16              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.35              | \$0.1401        | \$0.0169         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.70              | \$0.2452        | \$0.0315         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.065977397       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031989041       | \$0.000191877  | \$0.000023158   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063978082       | \$0.000335856  | \$0.000043151   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | \$0.168         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.315         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2625        | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | Off                | \$0                  | \$0.4725        | \$0              |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
      | Enterprise  | N/A                | \$0                  | \$0.4725        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2625        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | \$0.000230137  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000359589  | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | Off                | \$0                 | \$0.00064726   | \$0             |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
      | Enterprise  | N/A                | \$0                 | \$0.00064726   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000359589  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$61.33              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.42              | \$0.1405        | \$0.017          |
      | Regional    | Off                | \$0                  | \$0.5271        | \$0              |
      | Regional    | On                 | \$46.83              | \$0.2459        | \$0.0316         |
      | Enterprise  | N/A                | \$0                  | \$0.5271        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.084014384       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.032078219       | \$0.000192452  | \$0.000023302   |
      | Regional    | Off                | \$0                 | \$0.000722055  | \$0             |
      | Regional    | On                 | \$0.064156439       | \$0.000336863  | \$0.000043295   |
      | Enterprise  | N/A                | \$0                 | \$0.000722055  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$48.51              | \$0.231         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.3675        | \$0              |
      | Zonal       | On                 | \$29.40              | \$0.1764        | \$0.0213         |
      | Regional    | Off                | \$0                  | \$0.6615        | \$0              |
      | Regional    | On                 | \$58.80              | \$0.3087        | \$0.0397         |
      | Enterprise  | N/A                | \$0                  | \$0.6615        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.3675        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.066452055       | \$0.000316439  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000503425  | \$0             |
      | Zonal       | On                 | \$0.040273972       | \$0.000241644  | \$0.000029198   |
      | Regional    | Off                | \$0                 | \$0.000906165  | \$0             |
      | Regional    | On                 | \$0.080547945       | \$0.000422877  | \$0.00005437    |
      | Enterprise  | N/A                | \$0                 | \$0.000906165  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000503425  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$51.98              | \$0.252         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.4725        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.399         | \$0              |
      | Zonal       | On                 | \$31.50              | \$0.189         | \$0.0228         |
      | Regional    | Off                | \$0                  | \$0.714         | \$0              |
      | Regional    | On                 | \$63.00              | \$0.3308        | \$0.0425         |
      | Enterprise  | N/A                | \$0                  | \$0.714         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.399         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.07119863        | \$0.000345205  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.00064726   | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000546575  | \$0             |
      | Zonal       | On                 | \$0.043150685       | \$0.000258904  | \$0.000031285   |
      | Regional    | Off                | \$0                 | \$0.000978082  | \$0             |
      | Regional    | On                 | \$0.08630137        | \$0.000453082  | \$0.000058253   |
      | Enterprise  | N/A                | \$0                 | \$0.000978082  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000546575  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$46.78              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.25              | \$0.1394        | \$0.0169         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.49              | \$0.2441        | \$0.0314         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.064078767       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031845205       | \$0.000191014  | \$0.000023158   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063690411       | \$0.000334418  | \$0.000043007   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | \$0.168         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.315         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2625        | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | Off                | \$0                  | \$0.4725        | \$0              |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
      | Enterprise  | N/A                | \$0                  | \$0.4725        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2625        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | \$0.000230137  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000359589  | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | Off                | \$0                 | \$0.00064726   | \$0             |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
      | Enterprise  | N/A                | \$0                 | \$0.00064726   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000359589  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$34.65              | \$0.168         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.315         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.2625        | \$0              |
      | Zonal       | On                 | \$21.00              | \$0.126         | \$0.0152         |
      | Regional    | Off                | \$0                  | \$0.4725        | \$0              |
      | Regional    | On                 | \$42.00              | \$0.2205        | \$0.0284         |
      | Enterprise  | N/A                | \$0                  | \$0.4725        | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.2625        | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.047465753       | \$0.000230137  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000359589  | \$0             |
      | Zonal       | On                 | \$0.028767123       | \$0.000172603  | \$0.000020856   |
      | Regional    | Off                | \$0                 | \$0.00064726   | \$0             |
      | Regional    | On                 | \$0.057534247       | \$0.000302055  | \$0.000038835   |
      | Enterprise  | N/A                | \$0                 | \$0.00064726   | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000359589  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$47.12              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.13              | \$0.1508        | \$0.0183         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.27              | \$0.2639        | \$0.0339         |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.064553425       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034428493       | \$0.000206548  | \$0.000025028   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.068856986       | \$0.000361459  | \$0.000046459   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$38.12              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.10              | \$0.1386        | \$0.0167         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.20              | \$0.2426        | \$0.0312         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.052212328       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.031643835       | \$0.000189863  | \$0.000022941   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.063287672       | \$0.00033226   | \$0.000042719   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$46.43              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.33              | \$0.1519        | \$0.0184         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.65              | \$0.266         | \$0.0342         |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.063604109       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034693151       | \$0.00020813   | \$0.000025172   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069386302       | \$0.000364335  | \$0.000046891   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$47.82              | \$0.1995        | \$0              |
      | Zonal       | On                 | \$25.50              | \$0.153         | \$0.0185         |
      | Regional    | On                 | \$51.00              | \$0.2678        | \$0.0344         |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.06550274        | \$0.000273288  | \$0             |
      | Zonal       | On                 | \$0.034934795       | \$0.000209568  | \$0.000025316   |
      | Regional    | On                 | \$0.069869589       | \$0.000366781  | \$0.000047179   |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$41.58              | \$0.1995        | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.378         | \$0              |
      | Zonal       | Off                | \$0                  | \$0.315         | \$0              |
      | Zonal       | On                 | \$25.20              | \$0.1512        | \$0.0183         |
      | Regional    | Off                | \$0                  | \$0.567         | \$0              |
      | Regional    | On                 | \$50.40              | \$0.2646        | \$0.034          |
      | Enterprise  | N/A                | \$0                  | \$0.567         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.315         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.056958904       | \$0.000273288  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000517809  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.000431507  | \$0             |
      | Zonal       | On                 | \$0.034520548       | \$0.000207123  | \$0.000025028   |
      | Regional    | Off                | \$0                 | \$0.000776712  | \$0             |
      | Regional    | On                 | \$0.069041096       | \$0.000362465  | \$0.000046603   |
      | Enterprise  | N/A                | \$0                 | \$0.000776712  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.000431507  | \$0             |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$55.44              | \$0.1995        | \$0              |
      | Zonal       | On                 | \$25.20              | \$0.1512        | \$0.0183         |
      | Regional    | On                 | \$50.40              | \$0.2646        | \$0.034          |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.075945205       | \$0.000273288  | \$0             |
      | Zonal       | On                 | \$0.034520548       | \$0.000207123  | \$0.000025028   |
      | Regional    | On                 | \$0.069041096       | \$0.000362465  | \$0.000046603   |
    </Tab>
  </Tabs>
</div>

<div>
  <Tabs>
    <Tab title="Monthly">
      | Tier        | Custom performance | Per instance / month | Per GiB / month | Per IOPS / month |
      | ----------- | ------------------ | -------------------- | --------------- | ---------------- |
      | Basic HDD\* | N/A                | \$52.32              | \$0.189         | \$0              |
      | Basic SSD   | N/A                | \$0                  | \$0.3465        | \$0              |
      | Zonal       | Off                | \$0                  | \$0.294         | \$0              |
      | Zonal       | On                 | \$23.15              | \$0.1389        | \$0.0168         |
      | Regional    | Off                | \$0                  | \$0.525         | \$0              |
      | Regional    | On                 | \$46.30              | \$0.2431        | \$0.0313         |
      | Enterprise  | N/A                | \$0                  | \$0.525         | \$0              |
      | High-Scale  | N/A                | \$0                  | \$0.294         | \$0              |
    </Tab>

    <Tab title="Hourly">
      | Tier        | Custom performance | Per instance / hour | Per GiB / hour | Per IOPS / hour |
      | ----------- | ------------------ | ------------------- | -------------- | --------------- |
      | Basic HDD\* | N/A                | \$0.071673288       | \$0.000258904  | \$0             |
      | Basic SSD   | N/A                | \$0                 | \$0.000474658  | \$0             |
      | Zonal       | Off                | \$0                 | \$0.00040274   | \$0             |
      | Zonal       | On                 | \$0.03171           | \$0.000190295  | \$0.000023014   |
      | Regional    | Off                | \$0                 | \$0.000719179  | \$0             |
      | Regional    | On                 | \$0.06342           | \$0.000332979  | \$0.000042863   |
      | Enterprise  | N/A                | \$0                 | \$0.000719179  | \$0             |
      | High-Scale  | N/A                | \$0                 | \$0.00040274   | \$0             |
    </Tab>
  </Tabs>
</div>

<Note>
  \* Basic HDD instances below 1 TiB are charged a per-instance fee, which is waived once the instance reaches 1 TiB of provisioned capacity.
</Note>

## Example

The unit cost for a Basic HDD instance in the Oregon region is \$0.168 per GiB per month. A 2 TiB instance therefore costs 2,048 GiB × \$0.168, or **\$344.06 per month**.

Have questions about storage pricing or need capacity in a region not listed here? [Talk to our team](https://ornn.com).


# Manage your Ornn organization and team
Source: https://docs.ornn.com/guides/team-management



View team members, understand admin and member roles, and invite colleagues to your Ornn organization from the Team tab. Financial actions stay admin-gated.

Every approved Ornn account belongs to an organization. Your organization groups your team members under a single tenant, giving everyone access to the same reservations, My GPUs page, and exchange inventory. Team membership is managed from the **Team** tab on the Account page (`/account`).

<Note>
  Your organization is created automatically when you complete the Ornn onboarding process. You don't need to set it up manually.
</Note>

## Roles

Ornn organizations have two roles: **admin** and **member**. Members have full read access to shared resources and can take non-financial actions on them; admins additionally control anything that spends money.

<Tabs>
  <Tab title="Admin">
    Admins can do everything a member can do, plus every financial and organization-management action:

    * Invite new members and revoke pending invites.
    * Promote members to admin or demote admins to member.
    * Remove members from the organization.
    * Submit and manage bids, complete checkout, and reserve compute.
    * Purchase listings and manage resale on the exchange.
    * Pay invoices from the **Billing** tab.

    At least one admin must exist at all times. You can't demote or remove the last remaining admin.
  </Tab>

  <Tab title="Member">
    Members share your organization's tenant and can act on its GPUs, with financial actions gated to admins.

    Members can:

    * Browse Listings and view deployments.
    * View the tenant's reservations, bids, and My GPUs page.
    * Configure a reservation's [access mode](/guides/access-overview) (VM or Bare Metal).
    * Manage SSH keys for cluster access on reservations they can see.
    * Read the **Billing** tab, including invoices and History.
    * See the team member list.

    Members **cannot**:

    * Submit, update, or withdraw bids.
    * Purchase listings, complete checkout, or list compute for resale.
    * Pay invoices. Payment links (`Pay now`, `Pay overdue`) are hidden from members.
    * Invite, promote, demote, or remove teammates.

    If you need a financial action taken, ask an admin on your team.
  </Tab>
</Tabs>

## Viewing your team

<Steps>
  <Step title="Open the Account page">
    Go to the Account page (`/account`).
  </Step>

  <Step title="Open the Team tab">
    Select the **Team** tab. Team management is a first-class tab; you no longer need to open a modal from the Profile tab.
  </Step>

  <Step title="Review the member list">
    Each row shows the member's name, email, and role (**Admin** or **Member**). Your own row is marked **(you)**.
  </Step>
</Steps>

## Inviting a teammate

Only admins can send invitations.

<Steps>
  <Step title="Open the Team tab">
    On the Account page, select **Team**.
  </Step>

  <Step title="Enter the email address">
    In the invite form at the top of the tab, type the teammate's work email in the **Enter email** field. You can add up to 3 addresses at a time, separated by commas, spaces, or new lines.
  </Step>

  <Step title="Click Invite member">
    Click **Invite member**. Ornn emails each person a secure link to join your organization.
  </Step>
</Steps>

<Note>
  Invitations expire **7 days** after they're sent. New members join with the **member** role by default; promote them to admin after they accept.
</Note>

## Changing a member's role

Only admins can change roles.

<Steps>
  <Step title="Open the Team tab">
    On the Account page, select **Team**.
  </Step>

  <Step title="Open the actions menu">
    Click the **Edit** button on the member's row.
  </Step>

  <Step title="Select the role action">
    * Click **Make admin** to promote a member.
    * Click **Demote to member** to reduce an admin to member.
  </Step>

  <Step title="Confirm the change">
    Review the confirmation dialog and apply.
  </Step>
</Steps>

<Note>
  You can't demote an admin if they're the only admin in the organization. Promote another member to admin first, then demote the original admin.
</Note>

## Removing a member

<Steps>
  <Step title="Open the Team tab">
    On the Account page, select **Team**.
  </Step>

  <Step title="Open the actions menu">
    Click **Edit** on the member's row and select **Remove from org**.
  </Step>

  <Step title="Confirm the removal">
    Review the confirmation and click **Remove**. The member loses access to the organization immediately.
  </Step>
</Steps>

<Info>
  To leave the organization yourself, open the actions menu on your own row and select **Leave organization**. You can't leave if you're the only admin.
</Info>

## Revoking a pending invitation

Admins can cancel an invitation before the invitee accepts it.

<Steps>
  <Step title="Open the Team tab">
    On the Account page, select **Team**.
  </Step>

  <Step title="Find the invite in Pending invites">
    Scroll to the **Pending invites** section of the Team tab.
  </Step>

  <Step title="Click Revoke">
    Click **Revoke** on the invite row and confirm. The invite link becomes invalid immediately.
  </Step>
</Steps>

## Transferring admin ownership

To transfer admin ownership, promote the new owner to admin first, then leave the organization or ask them to demote you to member.

<Note>
  If you need to transfer ownership but have lost admin access or are locked out, contact Ornn support at [support@ornn.com](mailto:support@ornn.com).
</Note>

## What's next

<CardGroup>
  <Card title="Account settings" href="/guides/account-settings">
    Update your personal profile, display preferences, and billing details.
  </Card>

  <Card title="Notification preferences" href="/guides/notifications">
    Configure organization-wide email notifications.
  </Card>
</CardGroup>


# Track GPU usage and invoices on Ornn
Source: https://docs.ornn.com/guides/usage-and-billing



Monitor GPU-hour consumption on the reservation detail page, and review and pay Stripe-hosted invoices from Account → Billing.

Ornn surfaces GPU utilization on each reservation when telemetry is available, and issues invoices through Stripe. You can check usage from the reservation detail page and review or pay invoices from **Account → Billing**.

## Viewing GPU usage

Usage data for a reservation is shown on its detail page (`/portfolio/[reservationId]`) when telemetry from the underlying hardware has been received. The panel is labeled **Utilization** and shows a progress bar whose value reads `<used>/<total> GPU hours` (for example, `120/960 GPU hours`), where the total is derived from GPU count and term length. A secondary line below the value shows the recent-jobs synced count and a staleness figure. From the CLI, `ornn telemetry latest <node-id>` and `ornn logs latest <node-id>` read the same Observability data for a reserved machine.

<Note>
  Until real telemetry lands, Utilization and SLA Uptime render placeholders — Ornn no longer estimates either from elapsed wall-clock time. **Spend** follows the commerce contract: for a booking with explicit start/end instants, it accrues `hoursBetween(start, min(end, now)) × GPUs × rate` (clamped at `cancelled_at` for cancelled reservations); otherwise it renders a placeholder until telemetry or an admin override is present. Spend is an accrued estimate and may be lower than a checkout or down-payment invoice that reflects the full contract amount. The commitment figure below Spend is the full contract cost across the term and remains visible.
</Note>

### Recent jobs

When usage data is available, the utilization panel shows a recent-jobs synced count alongside the GPU-hour figure, with text like "12 recent jobs synced · 45s stale". The detail page does not render per-job rows. If usage data hasn't synced yet, no count appears.

The usage response still carries per-job details for scripted use; see the **Raw fields (advanced)** section below.

### Raw fields (advanced)

For scripted use, the usage response exposes these fields:

| Field                 | Type    | Description                                                        |
| --------------------- | ------- | ------------------------------------------------------------------ |
| `used_gpu_hours`      | number  | Total GPU-hours consumed so far.                                   |
| `remaining_gpu_hours` | number  | GPU-hours still available within the allocated total.              |
| `allocated_gpu_hours` | number  | Total GPU-hours allocated for the term.                            |
| `staleness_secs`      | integer | Seconds since the last usage sync. `null` if no sync has occurred. |

Each job entry exposes: `job_id`, `account`, `user`, `state`, `gpu_count`, `duration_secs`, `gpu_hours`, `start_time`, `end_time`.

## Invoices in Account → Billing

The **Billing** tab on the Account page is the source of truth for billing activity on your tenant. It includes:

* **Billing overview**: your current balance and any amount due.
* **Payment & invoicing**: your payment method and the email address invoices are sent to.
* **Overdue**: a highlighted section that appears only when one or more open invoices are past their due date.
* **Recent invoices**: your latest invoices with date, amount, and status, plus actions to pay or download.
* **History**: per-reservation GPU-hours and usage cost for a date range you choose. This is informational metering from reservation usage, not a new charge.

<Note>
  Invoice delivery email and billing details are not editable from Account → Billing in the current release. To update them, use the **Support** link in the Billing tab.
</Note>

### Invoice statuses

Ornn surfaces the following invoice statuses from Stripe:

| Status            | Meaning                                                    |
| ----------------- | ---------------------------------------------------------- |
| **Draft**         | The invoice is being prepared and has not been issued yet. |
| **Open**          | The invoice has been issued and payment is expected.       |
| **Paid**          | Payment has been received and the invoice is settled.      |
| **Void**          | The invoice was voided and does not require payment.       |
| **Uncollectible** | Payment is no longer expected to be collected.             |

**Overdue** is not a separate Stripe status; it's derived from an **Open** invoice whose due date has passed. Overdue invoices are highlighted in the Billing tab.

### Invoice fields (advanced)

| Field                | Type    | Description                                                               |
| -------------------- | ------- | ------------------------------------------------------------------------- |
| `amount_cents`       | integer | Amount in the smallest unit of the currency (for example, cents for USD). |
| `currency`           | string  | ISO currency code (for example, `usd`).                                   |
| `status`             | string  | One of the statuses above.                                                |
| `due_date`           | date    | Payment due date. `null` if no fixed due date.                            |
| `hosted_invoice_url` | string  | Link to the Stripe-hosted invoice and payment page.                       |
| `invoice_pdf_url`    | string  | Direct link to the invoice PDF, when available.                           |

## Paying an invoice

Recent invoice rows in Account → Billing expose actions based on the invoice state and whether the underlying URLs are available:

* **Pay now**: shown for open invoices. Opens the Stripe-hosted invoice page.
* **Pay overdue**: shown for open invoices past their due date. Opens the Stripe-hosted invoice page.
* **Download**: shown when a PDF copy is available.

All payments happen on the Stripe-hosted invoice page; the link from each row is the source of truth for payment status.

<Note>
  Only organization admins can pay invoices and use billing actions. Members can view the Billing tab but cannot launch payment.
</Note>

<Tip>
  Check the Stripe-hosted invoice page for the full list of accepted payment methods on your invoice.
</Tip>

## What's next

<CardGroup>
  <Card title="My GPUs overview" href="/guides/portfolio-overview">
    Find the reservation detail page and the utilization bar.
  </Card>

  <Card title="Account settings" href="/guides/account-settings">
    Open the Billing tab and review your tenant's billing state.
  </Card>
</CardGroup>


# Connect to your GPU reservation via VM
Source: https://docs.ornn.com/guides/vm-access



Launch VM access for an Ornn reservation, choose the Ornn base image or an approved custom image, and SSH into your GPU environment.

VM access is the default, recommended way to use your Ornn GPU reservation. Ornn launches a managed virtual machine on your reserved hardware, pre-configured with your chosen image and the active reservation SSH keys. Once the VM is ready, the SSH Host and connection details appear on the reservation detail page.

## Prerequisites

Before launching or switching to VM on a reservation:

* The bid has been promoted to a confirmed reservation, and the reservation is visible in My GPUs.
* **Checkout and payment** for the reservation are complete.
* You have at least **one active SSH public key** registered on your account. See [Manage SSH keys](/guides/ssh-keys).

## Set up VM access

<Steps>
  <Step title="Open the reservation detail page">
    From **My GPUs**, click **View** on the reservation you want to configure. The detail page opens at `/portfolio/[reservationId]`. The legacy `/portfolio/access` URL redirects here.
  </Step>

  <Step title="Select VM">
    Pick **VM** as the access mode on the reservation. VM is the default on new reservations.
  </Step>

  <Step title="Choose a VM image">
    Pick the image Ornn should use when launching the machine:

    * **Ornn base image · Ubuntu + CUDA or ROCm + PyTorch**: the default. A clean Ubuntu environment with vendor GPU drivers and PyTorch pre-installed (CUDA on NVIDIA, ROCm and `amd-smi` on AMD Instinct). The right choice for most workloads.
    * **Approved custom image**: any custom images on your account that have passed Ornn's security scan appear in the dropdown alongside the base image.

    The image selector shows a detail line describing the selected image.

    <Note>
      Pick your image **before launch**. Changing the image after launch is only available where the reservation detail page exposes it, typically by tearing down the current VM and relaunching with a new selection.
    </Note>
  </Step>

  <Step title="Attach an SSH key and launch">
    In the **SSH Keys** section, add or confirm an active reservation SSH key (use **Add Key**), then launch the VM. Ornn authorizes the active reservation keys on the machine.
  </Step>

  <Step title="Connect via SSH">
    Once the VM is ready, the **SSH Host** and **User** fields (plus a ready-to-run **Quick Connect** command) appear in the Connect section of the reservation detail page. Connect:

    ```bash theme={null}
    ssh <user>@<ssh-host>
    ```
  </Step>
</Steps>

## The Ornn base image

The Ornn base image is an Ubuntu-based environment ready for GPU workloads out of the box:

* **OS:** Ubuntu (22.04 or 24.04)
* **GPU drivers:** NVIDIA drivers or AMDGPU / ROCm, matching the reserved hardware
* **CUDA or ROCm:** Installed and configured (`nvidia-smi` on NVIDIA, `amd-smi` on AMD Instinct)
* **Framework:** PyTorch included

You don't need to install drivers or CUDA/ROCm manually when using the base image.

## Custom images

Custom images uploaded to your account appear in the image dropdown once they've been reviewed and approved. The dropdown shows the display name and OS family; the detail line shows the image slug and a partial hash for verification.

<Note>
  Custom images must pass an Ornn security scan before they become available for selection. To submit an image for approval, contact [Ornn support](mailto:support@ornn.com).
</Note>

<Note>
  Only images with a `clean` scan status appear in the dropdown. Images that are pending review, blocked, or revoked aren't available for selection.
</Note>

<Danger>
  Switching access modes (VM ↔ Bare Metal) after launch tears down the existing environment. Anything stored on the VM that isn't persisted off the host will be lost.
</Danger>

## VM access and the CLI

You can configure, launch, wait, and connect from the CLI:

```bash theme={null}
ornn keys add ~/.ssh/id_ed25519.pub --label laptop
ornn nodes launch <reservation-id> --key laptop --mode vm --username ubuntu --wait
ornn nodes list
ornn telemetry latest <node-id>
ornn logs latest <node-id>
ornn ssh <node-id> --identity-file ~/.ssh/id_ed25519
```

`ornn ssh` opens an interactive session with your local OpenSSH client. `ornn telemetry latest` / `ornn logs latest` read a one-shot window; `ornn telemetry tail` / `ornn logs tail` follow the same Observability feed as the reservation **Observability** tab. After you connect, verify GPUs with `nvidia-smi` on NVIDIA hosts or `amd-smi list` on AMD Instinct.

The CLI uses the default Ornn VM image when no custom image is selected. Use the
web reservation detail page when you need visual image selection or custom image
management.

## What's next

<CardGroup>
  <Card title="Access overview" href="/guides/access-overview">
    Compare VM and Bare Metal and understand the prerequisites for each.
  </Card>

  <Card title="Bare Metal access" href="/guides/bare-metal-access">
    Connect directly to the GPU host when you need full hardware control.
  </Card>
</CardGroup>


# Introduction
Source: https://docs.ornn.com/introduction



Docs and resources for reserving GPU capacity, managing your portfolio, and connecting to Ornn compute.

<div>
  <section aria-label="GPU capacity docs">
    <div>
      <img alt="" />
    </div>

    <div>
      ## GPU Capacity Docs

      <p>
        Start with account approval, reserve capacity by GPU type and term, then connect through VM, Bare Metal, Kubernetes, or Slurm.
      </p>

      <div>
        <a href="/quickstart">Get Started</a>
        <a href="/guides/reserving-compute">Reserve Compute</a>
      </div>
    </div>
  </section>

  <section aria-label="Documentation sections">
    <a href="/quickstart">
      <div>
        <div>
          <p>Get Started</p>
          <p>Docs and resources for reserving GPU capacity, managing your portfolio, and connecting to Ornn compute.</p>
        </div>
      </div>

      <div />
    </a>

    <a href="/guides/reserving-compute">
      <div>
        <div>
          <p>Listings</p>
          <p>Browse GPU listings by model, location, term, and price.</p>
        </div>
      </div>

      <div />
    </a>

    <a href="/guides/access-overview">
      <div>
        <div>
          <p>Access Compute</p>
          <p>Choose VM, Bare Metal, Kubernetes, or Slurm access.</p>
        </div>
      </div>

      <div />
    </a>

    <a href="/guides/kubernetes-access">
      <div>
        <div>
          <p>Kubernetes Clusters</p>
          <p>Launch a managed Kubernetes cluster on reserved GPUs and connect with kubectl.</p>
        </div>
      </div>

      <div />
    </a>

    <a href="/guides/slurm-access">
      <div>
        <div>
          <p>Slurm Clusters</p>
          <p>Launch a managed Slurm cluster on reserved GPUs and connect over SSH.</p>
        </div>
      </div>

      <div />
    </a>

    <a href="/guides/portfolio-overview">
      <div>
        <div>
          <p>My GPUs</p>
          <p>Track reservations, bids, usage, invoices, and resale options.</p>
        </div>
      </div>

      <div />
    </a>
  </section>

  <section aria-label="Reservation lifecycle">
    <div>
      <img alt="" />
    </div>

    <div>
      ## Reservation Lifecycle

      <p>From Listings search to live access</p>

      <p>
        Ornn guides each reservation through account approval, bid review, checkout, confirmation, and access launch.
      </p>

      <div>
        <a href="/guides/bidding">Review bid states</a>
      </div>
    </div>
  </section>

  <section aria-label="Core guides">
    <div>
      <p>Core Guides</p>
      <a href="/changelog">View Changelog</a>
    </div>

    <div>
      <a href="/guides/reserving-compute">
        <div>
          <div>
            <p>Reserving GPU Capacity</p>
            <p>Select dates, submit a bid, and move into review.</p>
          </div>

          <svg>
            <path />
          </svg>
        </div>
      </a>

      <a href="/guides/checkout">
        <div>
          <div>
            <p>Checkout</p>
            <p>Pay for a Buy now reservation by card or ACH.</p>
          </div>

          <svg>
            <path />
          </svg>
        </div>
      </a>

      <a href="/guides/vm-access">
        <div>
          <div>
            <p>VM Access</p>
            <p>Launch a managed VM and connect after readiness checks pass.</p>
          </div>

          <svg>
            <path />
          </svg>
        </div>
      </a>

      <a href="/guides/kubernetes-access">
        <div>
          <div>
            <p>Kubernetes Clusters</p>
            <p>Run Kubernetes on your reserved GPU nodes.</p>
          </div>

          <svg>
            <path />
          </svg>
        </div>
      </a>

      <a href="/guides/bare-metal-access">
        <div>
          <div>
            <p>Bare Metal Access</p>
            <p>Connect directly to hardware when you need full host control.</p>
          </div>

          <svg>
            <path />
          </svg>
        </div>
      </a>

      <a href="/guides/ssh-keys">
        <div>
          <div>
            <p>SSH Keys</p>
            <p>Register keys and attach them to reservation access.</p>
          </div>

          <svg>
            <path />
          </svg>
        </div>
      </a>
    </div>
  </section>
</div>


# MCP Server
Source: https://docs.ornn.com/mcp-server



Connect Claude, Cursor, ChatGPT, or Devin to Ornn Compute over MCP

Ornn runs a hosted [Model Context Protocol](https://modelcontextprotocol.io) server
that gives AI assistants the same tenant capabilities as the `ornn` [CLI](/cli):
finding capacity, buying and bidding, managing reservations, launching
access, following telemetry and logs, managing Kubernetes or Slurm,
reselling, and billing. Open a shell with the CLI: `ornn ssh <node-id>`.

## Connect

Add this server URL to your MCP client's configuration:

```
https://mcp.ornn.com/mcp
```

Your client will prompt you to sign in with your Ornn account via OAuth and
approve the connection on the consent screen. You can revoke access at any
time from [Connected agents](https://compute.ornn.com/settings/mcp-connections).

If you change the login email on your Ornn account, existing MCP tokens are
revoked automatically as part of that security cleanup. Reconnect the agent
after the email change completes.

## Tools

| Tool                                                                                                                                                                                                                                         | Description                                                                                                                                                                                                                                                                                                       |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `identity_whoami` / `identity_status`                                                                                                                                                                                                        | Show the signed-in user, organization, and platform status                                                                                                                                                                                                                                                        |
| `telemetry_latest`                                                                                                                                                                                                                           | One-shot telemetry window for a reserved machine (`span` or `start`/`end`, plus `max_points`)                                                                                                                                                                                                                     |
| `telemetry_tail`                                                                                                                                                                                                                             | Live telemetry follow on the Observability subscribe feed                                                                                                                                                                                                                                                         |
| `logs_latest`                                                                                                                                                                                                                                | Newest kernel or serial page (`count`, `before`, `cursor`) for a reserved machine                                                                                                                                                                                                                                 |
| `logs_tail`                                                                                                                                                                                                                                  | Live kernel or serial follow on the Observability subscribe feed                                                                                                                                                                                                                                                  |
| `ornn_availability_list` / `ornn_availability_show`                                                                                                                                                                                          | Find GPU capacity                                                                                                                                                                                                                                                                                                 |
| `ornn_buy`                                                                                                                                                                                                                                   | Get a checkout URL to buy a listing outright (requires `confirm: true`)                                                                                                                                                                                                                                           |
| `ornn_bid_create`                                                                                                                                                                                                                            | Create a bid and get a checkout URL for it (requires `confirm: true`)                                                                                                                                                                                                                                             |
| `ornn_bid_list` / `ornn_bid_show`                                                                                                                                                                                                            | List or look up a bid                                                                                                                                                                                                                                                                                             |
| `ornn_bid_update` / `ornn_bid_withdraw`                                                                                                                                                                                                      | Change or withdraw a bid (require `confirm: true`)                                                                                                                                                                                                                                                                |
| `ornn_reservations_list` / `ornn_reservations_show`                                                                                                                                                                                          | List or look up a reservation                                                                                                                                                                                                                                                                                     |
| `ornn_reservations_checkout`                                                                                                                                                                                                                 | Get the checkout URL for a reservation already awaiting payment (requires `confirm: true`)                                                                                                                                                                                                                        |
| `ornn_access_show`                                                                                                                                                                                                                           | Show bare-metal SSH machines for a reservation                                                                                                                                                                                                                                                                    |
| `ornn_access_activate`                                                                                                                                                                                                                       | Activate access (bare-metal or VM) and launch machine(s), optionally on the private network (requires `confirm: true`)                                                                                                                                                                                            |
| `ornn_access_switch`                                                                                                                                                                                                                         | Switch a reservation between public and private network, or VM and Bare Metal (requires `confirm: true`)                                                                                                                                                                                                          |
| `ornn_access_push_keys` / `ornn_access_keys_push`                                                                                                                                                                                            | Push SSH key(s) onto a reservation's active machines (require `confirm: true`)                                                                                                                                                                                                                                    |
| `ornn_access_keys_list` / `ornn_access_keys_add` / `ornn_access_keys_status`                                                                                                                                                                 | Manage and check SSH keys on a reservation                                                                                                                                                                                                                                                                        |
| `ornn_nodes_reboot` / `ornn_nodes_hard_reset`                                                                                                                                                                                                | Reboot or hard-reset (wipe + reboot) a reservation machine (require `confirm: true`)                                                                                                                                                                                                                              |
| `ornn_clusters_*` (`list`, `reservations_list`, `create`, `show`, `credentials`, `kubeconfig`, `add_node`, `remove_node`, `teardown`)                                                                                                        | Launch and manage Kubernetes or Slurm on reserved nodes. Launch is blocked only when those nodes already belong to the other controller (`create`, `add_node`, `remove_node`, `teardown` require `confirm: true`)                                                                                                 |
| `ornn_cluster_users_list` / `ornn_cluster_users_add` / `ornn_cluster_users_revoke`                                                                                                                                                           | Manage cluster-user SSH keys for Kubernetes/Slurm login access (`add`, `revoke` require `confirm: true`)                                                                                                                                                                                                          |
| `ornn_networks_*` (`list`, `show`, `create`, `update`, `delete`, `reservation_show`, `attach`, `detach`)                                                                                                                                     | Manage tenant-owned private networks and reservation attachments (`create`, `update`, `delete`, `attach`, `detach` require `confirm: true`)                                                                                                                                                                       |
| `ornn_vpn_peers_list` / `ornn_vpn_peers_create` / `ornn_vpn_peers_delete`                                                                                                                                                                    | Manage a reservation's WireGuard VPN peer configs (`create`, `delete` require `confirm: true`)                                                                                                                                                                                                                    |
| `ornn_storage_volumes_*` (`list`, `show`, `create`, `refresh`, `clear`, `delete`) / `ornn_storage_deploy` / `ornn_storage_filesystem_deploy` / `ornn_storage_deployment_status` / `ornn_storage_filesystem_delete` / `ornn_storage_undeploy` | Manage storage volumes (drives), managed filesystems, and reservation storage attachments (state-changing tools require `confirm: true`)                                                                                                                                                                          |
| `ornn_storage_targets`                                                                                                                                                                                                                       | List reservations eligible for a storage deploy                                                                                                                                                                                                                                                                   |
| `ornn_storage_files_ls`                                                                                                                                                                                                                      | List files on a storage volume/drive, optionally filtered by prefix                                                                                                                                                                                                                                               |
| `ornn_storage_buckets_*` (`list`, `show`, `connect`, `verify`, `update_credentials`, `disconnect`)                                                                                                                                           | Connect and manage object-storage buckets as Ornn drives (`connect`, `update_credentials`, `disconnect` require `confirm: true`)                                                                                                                                                                                  |
| `ornn_metrics_snapshot` / `ornn_metrics_history`                                                                                                                                                                                             | Read GPU health and utilization metrics for your reservation machines                                                                                                                                                                                                                                             |
| `ornn_resale_browse`                                                                                                                                                                                                                         | Browse the public resale marketplace                                                                                                                                                                                                                                                                              |
| `ornn_resale_list` / `ornn_resale_update` / `ornn_resale_delist`                                                                                                                                                                             | List, reprice, or remove a reservation on the resale marketplace (require `confirm: true`)                                                                                                                                                                                                                        |
| `ornn_ssh_keys_list` / `ornn_ssh_keys_add` / `ornn_ssh_keys_delete`                                                                                                                                                                          | Manage account-level SSH keys (delete requires `confirm: true`)                                                                                                                                                                                                                                                   |
| `ornn_billing_summary` / `ornn_billing_invoices` / `ornn_billing_showback`                                                                                                                                                                   | Account billing summary, invoices, and showback for a date range                                                                                                                                                                                                                                                  |
| `ornn_billing_open`                                                                                                                                                                                                                          | Get the billing portal URL                                                                                                                                                                                                                                                                                        |
| `ornn_api`                                                                                                                                                                                                                                   | Allowlisted compute API passthrough, for anything not covered above (non-`GET` calls require `confirm: true`). Tenant-scoped resources live under `/tenants/me/...` or `/organizations/me/...` (e.g. `/tenants/me/reservations` or `/organizations/me/reservations`) — both rewrite to the same thing server-side |

Tools that spend money, mutate resale/reservation/access state, or issue a
non-`GET` `ornn_api` call require an explicit `confirm: true` argument;
without it, they return a preview of what would happen instead of executing.
Several tools that create or change something (`ornn_bid_create`, the resale
mutations) also return a follow-up URL — for example, `ornn_bid_create`
creates the bid and returns its checkout URL in the same call.


# Get started with Ornn
Source: https://docs.ornn.com/quickstart



Create an Ornn account, complete onboarding, and reach the reservation flow once your tenant is approved.

This guide walks you through creating an Ornn account, submitting your company details for review, and reaching the reservation flow once your account is approved. Account creation and onboarding take just a few minutes; approval is handled manually by the Ornn team.

<Steps>
  <Step title="Open the sign-in page">
    Go to [compute.ornn.com](https://compute.ornn.com). The sign-in page opens.

    <div>
      <div>
        <div>New Account</div>

        <p>
          Click <strong>Sign Up</strong> under <strong>Don't have an account?</strong>. The page switches to <strong>Create your account</strong>.
        </p>
      </div>

      <div>
        <div>Existing Account</div>

        <p>
          Stay on the sign-in page. If you are in account creation mode, click <strong>Sign In</strong> to switch back.
        </p>
      </div>
    </div>

    The sign-in methods below work the same in either mode.
  </Step>

  <Step title="Choose how to sign in">
    Ornn supports several sign-in methods:

    <div>
      <div>
        <input type="checkbox" />

        <label>
          <span>
            <span>Magic Link</span>
          </span>
        </label>

        <div>
          <p>
            Enter your work email and click <strong>Sign In</strong>. The page switches to a <strong>Check your inbox</strong> screen confirming the link was sent to your address. Open the one-time link in your inbox to finish signing in; you can leave this tab open or close it.
          </p>
        </div>
      </div>

      <div>
        <input type="checkbox" />

        <label>
          <span>
            <span>Google</span>
          </span>
        </label>

        <div>
          <p>
            Click the Google tile (labeled <strong>Sign in with Google</strong>) and complete the Google OAuth flow.
          </p>
        </div>
      </div>

      <div>
        <input type="checkbox" />

        <label>
          <span>
            <span>GitHub</span>
          </span>
        </label>

        <div>
          <p>
            Click the GitHub tile (labeled <strong>Sign in with GitHub</strong>) and complete the GitHub OAuth flow.
          </p>
        </div>
      </div>

      <div>
        <input type="checkbox" />

        <label>
          <span>
            <span>Microsoft</span>
          </span>
        </label>

        <div>
          <p>
            Click the Microsoft tile (labeled <strong>Sign in with Microsoft</strong>) and complete the Microsoft OAuth flow.
          </p>
        </div>
      </div>
    </div>

    <Tip>
      If the email doesn't arrive within a minute, check your spam or junk folder. The link is single-use and expires after a short window.
    </Tip>
  </Step>

  <Step title="Complete onboarding">
    After you submit the form, you'll see a confirmation page (`/onboarding`). You'll fill in your company and contact details across two short steps.

    **Company details**

    | Field        | What to enter                           |
    | ------------ | --------------------------------------- |
    | Company name | Your organization's legal or trade name |

    **Your details**

    | Field     | What to enter                                                                    |
    | --------- | -------------------------------------------------------------------------------- |
    | Full name | Your full name, as you'd like it shown on Ornn                                   |
    | Role      | Your title from the dropdown (for example, CTO, Founder, Head of Infrastructure) |
    | Email     | Pre-filled from your sign-in. Read-only.                                         |
  </Step>

  <Step title="Wait for approval">
    After you submit the form, you'll see a confirmation page (`/onboarding/schedule`) letting you know your application is under review.

    Booking an intro call with the Ornn team from this page is optional; you'll get an email when your tenant is approved. If you sign in again before approval, you land back on this same schedule page.

    <Tip>
      The Ornn team reviews approvals manually. Timelines vary depending on workload and verification needs. You'll be notified by email when your tenant is approved.
    </Tip>
  </Step>

  <Step title="Reserve your first GPU cluster">
    Once approved, your next sign-in takes you straight to the reservation flow (`/reserve`). From there, you can browse available GPU deployments and filter by GPU model, Quantity, and Location. Open a deployment to select available month blocks and continue to checkout.

    A **Buy now** order requires paying a Stripe-hosted [payment](/guides/checkout) (card or ACH) at checkout. A **Bid** is submitted from the reserve form with no payment method at submission; the existing-bid checkout flow may collect a required down payment before the bid becomes active and enters review. See [How bid-based pricing works](/guides/bidding).
  </Step>
</Steps>

## What's next?

<div>
  <a href="/guides/reserving-compute">
    <div>
      <p>Reserve Compute</p>
      <p>Docs and resources for reserving GPU capacity, managing your portfolio, and connecting to Ornn compute.</p>
    </div>

    <div />
  </a>

  <a href="/guides/bidding">
    <div>
      <p>Place a Bid</p>
      <p>Submit a bid from a listing and track it in Portfolio.</p>
    </div>

    <div />
  </a>
</div>


