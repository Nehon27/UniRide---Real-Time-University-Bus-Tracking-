# UniRide — Live University Bus Tracker

A minimal system to track university buses in real time:
- **Drivers** log into a Flutter app and start a trip → their phone's GPS is sent to the server every 5 seconds.
- **Students** open a public web page (no login) and see live bus markers on an OpenStreetMap/Leaflet map, auto-updating every 5 seconds.
- **Admins** log into a small web dashboard to add/remove buses and driver accounts.

No routes or stops are tracked — only the driver's live position, since routes can change.

---

## What's in this folder

```
UniRide/
├── backend/        PHP + MySQL API (the server everything talks to)
├── admin/          Admin web dashboard (manage buses & drivers)
├── viewer/         Public live map page (students open this, no login)
└── driver_app/     Flutter app source (driver logs in, shares GPS)
```

Everything in `backend/`, `admin/`, and `viewer/` has been **tested and confirmed working** against a live MySQL + PHP server. The `driver_app/` Dart code is complete; you'll generate the native Android/iOS project files yourself in Step 4 (explained below — this is standard practice, not a shortcut).

---

## Step 1 — Install prerequisites

You need, on your PC:

1. **XAMPP** (or Laragon) — gives you PHP + MySQL + Apache in one install.
   Download: https://www.apachefriends.org/
2. **Flutter SDK** — only needed if you want to run the driver app.
   Download: https://docs.flutter.dev/get-started/install
3. A code editor (VS Code is fine) — optional but helpful.

---

## Step 2 — Set up the backend (PHP + MySQL)

1. Install and start **XAMPP**. Open the XAMPP Control Panel and start **Apache** and **MySQL**.
2. Copy the whole `backend/` folder into your XAMPP web root:
   - Windows: `C:\xampp\htdocs\uniride-backend\`
   - macOS/Linux: `/Applications/XAMPP/htdocs/uniride-backend/` (or your `htdocs` path)

   So you should end up with files at `C:\xampp\htdocs\uniride-backend\config.php`, etc.

3. Import the database:
   - Open **phpMyAdmin** (`http://localhost/phpmyadmin`)
   - Click **Import** → choose `backend/schema.sql` → Go
   - This creates the `uniride` database with all tables, plus one default admin account:
     - **username:** `admin`
     - **password:** `admin123`
     - **Change this password** once you're logged in (or directly in the `admins` table) before real use.

4. `backend/config.php` already defaults to XAMPP's standard MySQL settings (`localhost`, user `root`, no password). If your MySQL setup differs, edit the top of `config.php`:
   ```php
   $DB_HOST = "localhost";
   $DB_NAME = "uniride";
   $DB_USER = "root";
   $DB_PASS = "";
   ```

5. Test it's working: open `http://localhost/uniride-backend/list_buses.php` in your browser.
   You should see `{"status":"ok","buses":[]}`.

---

## Step 3 — Set up the Admin dashboard and public Viewer

Both are plain HTML/JS — no build step, no server-side rendering needed. You can even open them directly as files, but serving them through Apache avoids browser quirks, so:

1. Copy `admin/` into `C:\xampp\htdocs\uniride-admin\`
2. Copy `viewer/` into `C:\xampp\htdocs\uniride-viewer\`

3. Point them at your backend. Both have a config line to edit:
   - `admin/config.js` → set `API_BASE` to `http://localhost/uniride-backend`
   - `viewer/index.html` → find the `API_BASE` line near the top of the `<script>` block, set it the same way

   (They already default to `http://localhost/uniride-backend`, so if you used the exact folder name above, you can skip this.)

4. Open:
   - Admin dashboard: `http://localhost/uniride-admin/`  → log in with `admin` / `admin123`
   - Public viewer: `http://localhost/uniride-viewer/`

5. In the admin dashboard, add a bus (e.g. "Bus 1") and a driver account (full name, username, password, assign to the bus). This is the account your driver will log into on their phone.

At this point your backend + admin + viewer are fully working. You can test the whole pipeline without the Flutter app at all, using curl or Postman to simulate a driver:

```bash
curl -X POST http://localhost/uniride-backend/update_location.php \
  -d "driver_id=1&lat=23.8103&lng=90.4125"
```

Refresh the viewer page — you should see a bus marker appear on the map within 5 seconds.

---

## Step 4 — Set up the Driver page

There are two ways to get GPS from a driver's phone into the system. **Use the web page** (`driver_web/`) unless you specifically need a native app — it works on both Android and iPhone with zero installation, and avoids needing a Mac/Xcode for iOS entirely.

### Option A (recommended): Driver web page — works on any phone, no install

1. Copy the `driver_web` folder to `C:\xampp\htdocs\uniride-driver\`
2. Open `driver_web/index.html` and confirm the `API_BASE` line near the top of the `<script>` block matches your backend URL (same pattern as `admin/config.js` and `viewer/index.html`).
3. On the driver's phone, open `http://<your-backend-address>/uniride-driver/` in Safari (iPhone) or Chrome (Android).
   - Testing locally on your own Wi-Fi: use your PC's LAN IP, e.g. `http://192.168.0.105/uniride-driver/`
   - Once hosted online (see the Hosting section below): use your real domain, e.g. `https://yoursite.com/uniride-driver/`
4. Log in with the driver's username/password. The browser will natively prompt "Allow location access?" — that's the browser's own permission dialog, no extra code needed.
5. Tap **Start Trip**. The page sends the phone's GPS coordinates every 5 seconds for as long as the page stays open.

**Important limitation to know:** browsers pause GPS updates once the screen locks or the driver switches to another app — this is a browser-level restriction on all phones, not something we can code around from a plain web page. For a short campus bus route where the driver just keeps the page open, this is fine in practice. If you need location updates to keep working with the screen off or the app backgrounded, that requires a native app (Option B) using a background/foreground location service — worth mentioning as a possible future improvement in your report.

**HTTPS note:** most mobile browsers block GPS access entirely on a plain `http://` site once it's on the public internet (this restriction is relaxed for `localhost`/LAN testing, which is why local testing works over plain HTTP). Any free host recommended below includes a free SSL certificate — make sure you access your site via `https://`, not `http://`, once it's hosted.

### Option B: Native Flutter app (Android only, without a Mac)

The `driver_app/` folder still contains a complete native Flutter version if you want it later. Skip it for now unless the web page doesn't meet your needs.

---

## Step 5 — Hosting: making it reachable from anywhere, not just your PC

Everything above works over your local Wi-Fi via XAMPP. For students to reach it from anywhere (mobile data, off-campus, etc.) and for it to be available even when your PC is off, you need real hosting.

**Recommended for a student project: [InfinityFree](https://infinityfree.com)** — genuinely free, no credit card, no time limit, includes PHP 8 + unlimited MySQL databases + free SSL. (Skip 000webhost if you see it mentioned anywhere online — it shut down in 2024.)

One caveat worth knowing: InfinityFree's bot-protection sometimes blocks requests from **native apps** calling their API directly. Since everything in this project now runs as a normal web page (viewer, admin, and the driver page), your traffic looks like ordinary browser visits, which InfinityFree handles fine — so this caveat doesn't affect you, but it's why we steered away from the native app as the default.

### Deploying there

1. Sign up at infinityfree.com (no credit card needed) and create a new hosting account — you'll get a free subdomain like `yourproject.infinityfreeapp.com`, or you can connect your own domain if you have one.
2. In their control panel, open **MySQL Databases**, create a database, and note the exact database name, username, password, and **hostname** it gives you (it will NOT be `localhost` — free hosts usually assign something like `sql200.infinityfree.com`).
3. Open **phpMyAdmin** from their control panel and import `backend/schema.sql` the same way you did locally.
4. Use their **File Manager** (or an FTP client like FileZilla with the credentials they provide) to upload the contents of `backend/`, `admin/`, `viewer/`, and `driver_web/` — each into its own subfolder under `htdocs/` (e.g. `htdocs/backend/`, `htdocs/admin/`, etc.)
5. Edit `backend/config.php` on the server (via File Manager's built-in editor) to use the real database host/name/user/password from step 2, instead of the `localhost`/`root` defaults.
6. Update `API_BASE` in `admin/config.js`, `viewer/index.html`, and `driver_web/index.html` to your new live URL, e.g. `https://yourproject.infinityfreeapp.com/backend`.
7. Test the same way you did locally: visit `https://yourproject.infinityfreeapp.com/backend/list_buses.php` first to confirm the backend works, then the admin/viewer/driver pages.

From this point on, any student's phone — Android or iPhone, on any network — can reach the live map and any driver can log into the driver page from anywhere, with your PC and XAMPP no longer needed at all.

---

## How the pieces talk to each other

```
[Driver's Flutter App]                          [Public Viewer / Admin Dashboard]
        |                                                    |
        |  POST driver_id, lat, lng   (every 5s)             |  GET latest positions (every 5s)
        v                                                    v
                     ============================
                     |   backend/*.php (PHP)     |
                     |   -> MySQL "uniride" DB   |
                     ============================
```

- Only the driver app **writes** location data.
- The admin dashboard and public viewer only **read**.
- No student-facing login exists anywhere — the viewer page is fully public by design.
- A bus disappears from the public map automatically if its driver hasn't sent an update in the last 2 minutes (e.g. they tapped "Stop Trip" or closed the app), so a stale marker never sits on the map indefinitely.

---

## Security notes for your project report

This is intentionally a lightweight trust model appropriate for a lab project, not a production deployment:

- Driver and admin passwords are stored as bcrypt hashes (`password_hash()`/`password_verify()` in PHP) — never in plain text.
- There is no session/token system — the driver app simply remembers its own `driver_id` locally after login. This is simple but means anyone who has a driver's `driver_id` could technically POST fake locations; worth mentioning as a known limitation and possible future improvement (e.g. a signed token) in your report.
- The admin dashboard has no server-side session either — `admin_login.php` just verifies credentials once at login time. Same trade-off, same reasoning.
- CORS is fully open (`Access-Control-Allow-Origin: *`) so the pieces can talk to each other easily during development/demo. For a real deployment you'd restrict this to your actual domains.

---

## Troubleshooting

| Problem | Likely fix |
|---|---|
| Admin/viewer page shows a blank map or "Connection error" | Check `API_BASE` in `config.js` / `index.html` matches where you put `backend/`, and that Apache + MySQL are running |
| `list_buses.php` shows a database error | Re-check `backend/config.php` DB credentials, confirm you imported `schema.sql` |
| Flutter app can't reach server from an emulator | Use `10.0.2.2`, not `localhost` — the emulator has its own network namespace |
| Flutter app can't reach server from a real phone | Use your PC's LAN IP, ensure phone and PC are on the same Wi-Fi, check Windows Firewall isn't blocking Apache |
| Marker never appears on the viewer | Confirm the driver tapped "Start Trip" and granted location permission; check `list_drivers.php` in a browser — `is_active` should be `1` |
