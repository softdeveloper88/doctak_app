# DocTak App — Live API & Image QA Report

- **Device:** emulator-5554 (Android 16) · app `com.kt.doctak` (debug)
- **Backend:** PRODUCTION `https://doctak.net`
- **Session user:** `abc123@gmail.com` (app was already logged in; the provided `adnanpk44@gmail.com` was NOT used — see note)
- **Date:** 2026-06-05
- **Coverage:** 78 API responses observed across Home, Profile, CME, Subscription, Jobs, Notifications, Conferences + full prior-session log history.
- **Status totals:** ✅ 53× 2xx · 🔴 12× 404 · 🔴 13× 500

---

## 🔴 API FAILURES — all in the CME module

### 500 — SQL errors (route exists, query broken)
| Endpoint | Error |
|---|---|
| `GET /api/v1/cme/events?type=workshop` (and `conference`, `webinar`) | `Unknown column 'e.type' in 'where clause'` |
| `GET /api/v1/cme/dashboard` | `Unknown column 'e.credits' in 'field list'` |

→ The CME events table has no `type` or `credits` column (or the query alias `e` is wrong). The "All" filter works; **every type filter (Workshop/Conference/Webinar) shows "Server error. Please try again later."**

### 404 — route not implemented on backend (returns Next.js HTML, not JSON)
| Endpoint | Called |
|---|---|
| `GET /api/v1/cme/profile/achievements` | 3× (retried) |
| `GET /api/v1/cme/learning-paths/browse` | 3× |
| `GET /api/v1/cme/learning-paths/my/enrolled` | 3× |
| `GET /api/v1/cme/analytics/compliance` | 1× |
| `GET /api/v1/cme/analytics/performance` | 1× |
| `GET /api/v1/cme/analytics/credits` | 1× |

→ The Flutter CME module calls these but the `doctak-node` backend has no matching route — requests fall through to the Next.js catch-all 404 HTML page.

### ✅ CME endpoints that DO work
`GET /cme/events` (unfiltered) · `/cme/events/{id}` · `/cme/events/my/events` · `/cme/certificates`

---

## 🟡 IMAGE / MEDIA FAILURES (broken images in UI)

| Image URL pattern | HTTP | Load attempts |
|---|---|---|
| `https://doctak-file.s3.ap-south-1.amazonaws.com/images/users/profile_pic/<id>.jpg` | **403 Forbidden** | 222 |
| `https://doctak.net/r2-media/chat/19/<file>.png` | **404 Not Found** | 218 |

**Root cause (S3 403):** The posts/profile API returns raw **S3** URLs (`doctak-file.s3...`) for `profile_pic`, but the S3 bucket denies public access (403). Per `app_environment.dart`, legacy S3 paths are supposed to be served via the R2 proxy (`/r2-media/`) — so either the API should return `/r2-media/...` URLs, or the app should rewrite `s3 → /r2-media/` before loading. Profile avatars currently fall back to initials (good), but post/feed avatars break.

**R2 404 (chat image):** A chat image that exists in the DB record is missing from the R2 bucket (or the proxy path is wrong), so it 404s on every retry.

> Both images retry ~220× each — worth adding a failure cap / placeholder to stop the retry storm.

---

## ⚠️ Notes
1. **Credentials not used:** the emulator already had an active session as `abc123@gmail.com`. I did not log out / log in as `adnanpk44@gmail.com`. Say the word and I'll log out and re-run the login flow to test `/login` + the new account's data.
2. **Email-verification banner** shows on Home ("Please verify your email to continue") for this account.
3. Screenshots saved in `/tmp/doctak-qa/shots/`.
