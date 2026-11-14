---
title: "04 Pre-launch Security Checklist"
project: Relivable
phase: 2
status: audited 13 Nov 2026
updated: 2026-11-13
tags: [relivable, phase-2, security, launch]
---

# 04 Pre-launch Security Checklist

*Purpose:* A common 20-point pre-launch security checklist, run against both apps in this repo on 13 Nov 2026. It records what passes, what was fixed, and what still needs the owner.

There are two apps:
- **The web studio:** `src/`, TanStack Start with Supabase, single owner. It has a server, a database and sign-in, so most of the checklist applies.
- **Relivable, the game:** `game/`, Flutter. It is fully offline, with no accounts, server or database, so most items don't apply yet. They will matter once cloud saves, purchases and analytics arrive ([[01 Phase 2 Open Items]] C1–C3, B1).

Key: ✅ passes · 🔧 fixed in this audit · ⚠️ needs the owner · ➖ does not apply.

## Web studio

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Hide API keys | ⚠️ | The Supabase service-role key is read only from server env (`client.server.ts`). **Gap:** the owner's own AI key (`ai_settings.custom_api_key`) is loaded into the browser by Settings (`select("*")`). It's only readable by the owner, because of row-level security, but any script injected into the page could read it. Fix: make the key write-only (a server function saves it; the page shows only "key saved"). |
| 2 | Purge Git secrets | ✅ | History scan: the only env file ever committed is `.env`, holding the Supabase URL and **publishable** key, which are meant to be public. No keystores, private keys or service tokens. Also turn on GitHub secret scanning for the repo. |
| 3 | Use the public DB key in the client | ✅ | The client uses `SUPABASE_PUBLISHABLE_KEY` only |
| 4 | Enable row-level security | ✅ | RLS is on for all 8 tables (`drizzle/migrations/0000`–`0003`) |
| 5 | Encrypt sensitive data | ⚠️ | Supabase encrypts at rest. The custom AI key sits in a plain-text column: move it to Supabase Vault, or at least make it write-only (item 1) |
| 6 | Enforce server-side auth | ✅ | All 6 server functions use `requireAppAuth`. `/api/chat` checks the token and ownership. `/api/local/*` only answers requests carrying the desktop app's per-launch secret on 127.0.0.1 |
| 7 | Lock record access | ✅ | Every policy is `is_owner() and user_id = auth.uid()` |
| 8 | Block field tampering | ✅ | `WITH CHECK` on `user_id`. `app_owner` has no write policy; it can only change through `claim_owner()` |
| 9 | Secure session cookies | ✅ | Supabase keeps the session in browser storage, not cookies, so CSP (item 18) is the main protection. Dev sign-in returns tokens only to a loopback origin |
| 10 | Hash passwords | ➖ | Google sign-in only; Supabase Auth handles credentials |
| 11 | Rate-limit login | ✅ | Supabase Auth's built-in limits. Check the values in the Supabase dashboard (Auth › Rate limits) |
| 12 | Bot protection | ⚠️ | Single-owner: the **first** account to sign in claims ownership (`claim_owner()`). Confirm ownership is already claimed on the live project, so no stranger can claim it |
| 13 | Parameterise queries | ✅ | supabase-js query builder only; no SQL built from strings. The desktop JSON store uses no SQL |
| 14 | Validate all input | 🔧 | Server functions validate (UUIDs, lengths, the zod schema for customisations). **Fixed:** `/api/chat` parsed an unbounded body *before* checking sign-in (any non-empty token passed the first check). It now refuses bodies over 8 MB and caps invited agents (20), knowledge (200,000 characters) and messages (2,000) |
| 15 | Escape user content | ✅ | React escapes text. The only `dangerouslySetInnerHTML` is the chart component's generated CSS. AI-built features and previews run in iframes with `sandbox="allow-scripts"` (no same-origin) |
| 16 | Restrict file uploads | ➖ | There's no file upload to storage. The prompt input's attachments stay in the browser |
| 17 | Trim API responses | ⚠️ | Several pages use `select("*")`. That's harmless under owner-only RLS, except for the AI key (item 1) |
| 18 | Add security headers | ⚠️ | The app sets none. Add `Content-Security-Policy`, `X-Content-Type-Options: nosniff` and `Referrer-Policy` at the hosting layer. Use CSP `frame-ancestors` only if the Lovable editor preview doesn't need to frame the app; don't use `X-Frame-Options: DENY` |
| 19 | Force HTTPS | ✅ | The hosting serves HTTPS. The desktop app's local server is loopback-only |
| 20 | Scan dependencies | 🔧 | `bun audit` found **30** advisories (1 critical, 14 high). After in-range updates (vite 8.1.6, vitest 4.1.12, shell-quote, brace-expansion, js-yaml, nanoid, seroval…) there are **4**. Tests (45) and the production build pass. Left: **zod 3** (high; the fix needs the zod 4 major upgrade, and item 14's caps limit the exposure), plus build-time-only esbuild and minimatch, and a low-severity KaTeX issue |

## Relivable (the game)

| # | Check | Result | Notes |
|---|---|---|---|
| 1–3 | Keys and Git secrets | ✅ | No API keys in the game. No keystores in Git; signing comes from CI secrets or the CI cache |
| — | **Release signing key** | ⚠️ **Important before the stores** | Without the `RELIVABLE_KEYSTORE_BASE64` secret, the Android key lives only in the GitHub Actions cache (`relivable.yml`). GitHub can evict that cache, and every later APK would then be signed with a new key, which breaks updates for everyone. The password also defaults to `relivable`. **Owner action:** export the current key once, store it (plus a strong password) as repository secrets, and keep an offline backup. Enrol in Play App Signing when the Play listing exists (A1) |
| — | Self-update integrity | ✅ | The app downloads updates over HTTPS from GitHub releases and checks the APK's signing certificate (`RELIVABLE_CERT`) before installing |
| 4–17 | Database, auth, sessions, input, uploads | ➖ | No server, accounts or uploads. Saves are local; an unreadable save is set aside, not overwritten. Re-run this checklist when cloud saves, purchases and analytics are built |
| 18–19 | Headers and HTTPS for the web build | ⚠️ | The web build's host should serve HTTPS with the same headers as item 18 |
| 20 | Dependencies | ⚠️ | Run `flutter pub outdated` and review advisories before the store builds |

## Owner to-do, in order
1. Put the Android signing key into repository secrets, with a strong password and an offline backup.
2. Confirm ownership of the live studio is already claimed.
3. Make the custom AI key write-only, or move it to Supabase Vault.
4. Add CSP, nosniff and referrer headers at the host.
5. Plan the zod 4 upgrade.
6. Turn on GitHub secret scanning and Dependabot alerts.
