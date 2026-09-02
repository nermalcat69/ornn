// npm i -D playwright tsx && npx playwright install chromium
// npx tsx record.ts   (browser opens, use it, Ctrl+C to stop)
import { chromium } from "playwright";
import { appendFileSync } from "fs";

const OUT = process.argv[2] ?? process.env.RECORD_OUT ?? "network.txt";
const log = (o: unknown) => appendFileSync(OUT, JSON.stringify(o) + "\n");

async function main() {
  const browser = await chromium.launch({ headless: false });
  const ctx = await browser.newContext();

  ctx.on("request", async (req) => {
    log({
      t: new Date().toISOString(),
      kind: "request",
      method: req.method(),
      url: req.url(),
      resourceType: req.resourceType(),
      headers: await req.allHeaders(),
      postData: req.postData() ?? null,
    });
  });

  ctx.on("response", async (res) => {
    let body: string | null = null;
    try {
      const buf = await res.body();
      body = buf.length > 1_000_000 ? `<${buf.length} bytes omitted>` : buf.toString("utf8");
    } catch { /* body unavailable (redirect, cached, etc.) */ }
    log({
      t: new Date().toISOString(),
      kind: "response",
      status: res.status(),
      url: res.url(),
      headers: await res.allHeaders(),
      body,
    });
  });

  await ctx.newPage();
  console.log(`recording to ${OUT} — Ctrl+C to stop`);
}

main();
