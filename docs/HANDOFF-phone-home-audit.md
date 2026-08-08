# Handoff: build `bin/phone-home-audit` — detect and `--fix` cloud calls from adapters

**Date:** 2026-08-08
**Goal:** a repo-wide tool that proves every adapter run is fully local — no
telemetry, update checks, or "preconnect" pings escape to a vendor's cloud —
and, given `--fix`, applies the known env-var/setting suppressions
automatically instead of us hand-discovering them per adapter.

## Why this exists

This bench's entire premise is *local* model evaluation. A CLI agent that
quietly opens sockets to its vendor's cloud on every run breaks that premise
even if the actual inference call goes to oMLX/LM Studio/Ollama — it leaks
your prompts' *metadata* (timing, error text, sometimes prompt content) to a
third party you didn't choose, and it's a trust problem independent of
correctness. We nearly shipped `adapters/qwen-omlx.sh` without noticing this.

## Case study: what we found in qwen-code (2026-08-08)

`adapters/qwen-omlx.sh` correctly points `OPENAI_BASE_URL` at oMLX and the
model output was genuinely local (verified: response length/content varied
per prompt, unlike the truncated-442-char symptom that got `qwen` rejected
back in `APPROVED_AGENTS.md` on 2026-07-05). But the *process itself* still
called home, on **three independent, unrelated code paths**, none of them
related to model routing:

| # | What | Destination | Trigger | Env var to disable |
|---|---|---|---|---|
| 1 | Usage/error telemetry, recurring ~60s | `*.rum.aliyuncs.com` (Alibaba Cloud RUM) | `privacy.usageStatisticsEnabled`, default **on** | `QWEN_USAGE_STATISTICS_ENABLED=false` |
| 2 | Startup latency "preconnect" HEAD request | `dashscope.aliyuncs.com` (hardcoded `DEFAULT_BASE_URLS` table, fires even with a custom `baseUrl` configured) | always, unless disabled | `QWEN_CODE_DISABLE_PRECONNECT=1` |
| 3 | Standalone-update check | `qwen-code-assets.oss-cn-hangzhou.aliyuncs.com` | `general.enableAutoUpdate`, default **on** | `QWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true` |

None of these three appear in the CLI's own `--help` output or are mentioned
as a group anywhere in its docs — each had to be found separately by reading
minified bundle source (`chunks/*.js` under
`~/.npm-global/lib/node_modules/@qwen-code/qwen-code`) after noticing a live
TCP connection via `lsof`, then a CONNECT-logging local proxy to get hostnames
for the ones `lsof` alone couldn't attribute (see Method below). This is a
completely manual, adapter-specific process today — it doesn't scale past one
adapter per debugging session, and it's the kind of thing that's easy to skip
under time pressure. That's the gap this tool closes.

## Method that worked (reuse this, don't reinvent)

1. **Detect that *something* calls out**, cheaply, with `lsof`:
   ```bash
   { <adapter invocation> ; } &
   JOBPID=$!
   while kill -0 $JOBPID 2>/dev/null; do
     for p in $(pgrep -f "<process name pattern>"); do
       lsof -a -p "$p" -i -P 2>/dev/null | grep -v LISTEN
     done
     sleep 0.2
   done
   ```
   Any `ESTABLISHED`/`SYN_SENT` line whose remote isn't `127.0.0.1`/`localhost`
   (i.e. not oMLX/LMS/Ollama's port) is a hit. `lsof` gives you an IP, which is
   often enough alone (reverse-`whois` an unfamiliar IP block — that's how
   `161.117.125.x` → Alibaba Cloud Singapore got identified here) but not a
   hostname, and TLS SNI is invisible to `lsof`.

2. **Get the actual hostname** by forcing traffic through a local
   CONNECT-logging stub (works for any Node/Python/Go CLI that honors
   `HTTP_PROXY`/`HTTPS_PROXY` — most do, since proxy-env respect is a common
   library default):
   ```bash
   python3 -c '
   import socket, threading, time
   def handle(conn):
       print(conn.recv(4096).decode(errors="replace"))
       conn.sendall(b"HTTP/1.1 502 Bad Gateway\r\n\r\n"); conn.close()
   s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
   s.bind(("127.0.0.1", 18080)); s.listen(50)
   end = time.time() + 20
   while time.time() < end:
       s.settimeout(1)
       try: conn, _ = s.accept()
       except socket.timeout: continue
       threading.Thread(target=handle, args=(conn,)).start()
   ' &
   HTTPS_PROXY=http://127.0.0.1:18080 HTTP_PROXY=http://127.0.0.1:18080 <adapter invocation>
   ```
   The `CONNECT <host>:443` lines are your answer. This is how RUM telemetry
   (item #1 above) was found — `lsof` alone only showed an IP, disabling the
   two known suspects (preconnect, update-check) didn't stop the connection,
   and the proxy trace revealed a third, previously-unknown culprit.

3. **Grep the installed package for the hostname** to find the gating
   setting/env var (works when the tool ships readable JS/Python, not for
   compiled binaries):
   ```bash
   grep -rn "<hostname-fragment>" "$(npm root -g)/<pkg>"/**/*.js
   ```
   Then read backward from the match for the env-var check
   (`process.env["SOME_VAR"]`) or settings key gating the call.

## What `bin/phone-home-audit` should do

**Detect mode (default):**
- For each `adapters/*.sh` (or a `--adapter` filter), run a short smoke prompt
  through it with network capture active (method above, generalized into a
  reusable bash function/helper — put shared bits in `bin/lib/` per repo
  convention, e.g. `bin/lib/netcapture.sh`).
- Resolve every non-loopback remote IP to its `whois`/`org` (cache lookups —
  don't re-whois the same IP every run) and flag anything outside the
  expected loopback traffic to `$OMLX_BASE_URL`/`$LMS_BASE_URL`/`$OLLAMA_BASE_URL`.
- Where the destination is HTTPS and the IP alone isn't conclusive, fall back
  to the CONNECT-proxy trick to get the SNI hostname.
- Print a report per adapter: clean / suspect connections found (host, org,
  count) — pattern this after `bin/lint-adapters`'s `[OK]`/`[FAIL]`/`[WARN]`
  output and exit-code convention (0 = all clean, 1 = findings).
- Exit nonzero if any adapter has an unexplained outbound connection, so this
  can gate CI/`bin/smoke` the way `bin/lint-adapters` already gates syntax.

**`--fix` mode:**
- Maintain a small **known-suppressions table** (adapter or tool name → env
  vars to export) — seed it with the three qwen entries above. This table is
  the actual deliverable; the detect logic just tells you where to look next.
- When `--fix` is passed, `--fix` doesn't "discover" anything new — it applies
  entries from that table to the relevant adapter script (as `export FOO=bar`
  lines near the top, matching the existing style of `pi-omlx.sh`'s
  `export LMS_API_KEY` / `qwen-omlx.sh`'s `export QWEN_*` lines) and re-runs
  detect to confirm the fix actually silenced the connection before
  committing to the file. Never apply a suppression blind — always
  verify-after-fix, since a wrong env var name (had one typo'd attempt
  mid-session: `QWEN_CODE_NO_UPDATE_NOTIFIER`, which doesn't exist) silently
  does nothing.
- For a *newly discovered* phone-home with no table entry yet, `--fix` should
  refuse and print what it found (host, org, adapter) so a human decides
  whether there's actually a suppression available (some tools don't have
  one — that's a real "reject this agent" outcome, not a bug to silence).

## Suggested seed table (`bin/lib/phone-home-suppressions.sh` or similar)

```
qwen  QWEN_USAGE_STATISTICS_ENABLED=false
qwen  QWEN_CODE_DISABLE_PRECONNECT=1
qwen  QWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true
```

Other adapters are unaudited — this table currently covers exactly one tool.
Auditing the other ~17 adapters (see `docs/HANDOFF-omlx-adapters.md` for the
full list) for the same class of issue is follow-up work once the tool
exists; don't assume any of them are clean just because they weren't flagged
by APPROVED_AGENTS.md-style output-truncation testing — that testing method
doesn't check for phone-home at all, it only checks response variance.

## Open questions for whoever picks this up

- Does every adapter's CLI even honor `HTTP_PROXY`/`HTTPS_PROXY`? Some may
  need a different interception method (e.g. a local mitmproxy CA, or just
  `lsof`-only IP-based detection when hostname isn't obtainable).
- Should the audit run as part of `bin/smoke` by default, or stay a separate
  opt-in check (cost: it adds real wall-clock time per adapter for the
  capture loop)?
- Whois lookups can rate-limit or vary in output format across networks —
  consider a small local IP-range table for known cloud providers
  (Alibaba/AWS/GCP/Azure ranges) as a faster first pass before shelling out
  to `whois`.
