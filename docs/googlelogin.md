Google OAuth2 Authentication Fix
Resolved the "Auth Failed" issue by bridging the gap between the mobile browser and the app.

The Problem
Google Auth opens in an external browser, which doesn't share sessions with the app, causing "state mismatch" errors.

The Solution: HTTPS Bounce Workaround
App initiates login: Requests fallback URL from PocketBase.
Browser Auth: User logs in securely via Google.
The "Bouncer": Google redirects to https://backend.kingsaif.cloud/api/mobile-auth (on your VPS).
The Jump: Nginx on your VPS instantly redirects to ruby-app://auth?code=....
Back to App: The Ruby app captures the deep link, takes the code, and exchanges it for a token.
Results
✅ Native snapping: The app automatically re-opens after login.
✅ Cloud Sync ready: Authentication now triggers an immediate data sync.