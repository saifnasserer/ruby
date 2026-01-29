# ☁️ Reusable PocketBase Backend Guide

**URL:** `https://backend.kingsaif.cloud`
**Admin Dashboard:** `https://backend.kingsaif.cloud/_/`

This guide explains the backend infrastructure we established on your VPS, how it works, and how to leverage it for future applications.

---

## 🏗 Infrastructure Overview

We have deployed **PocketBase**, an open-source "Realtime Backend in 1 File", to your VPS. It is containerized and sits behind an Nginx Reverse Proxy with SSL auto-configured.

### 🧩 Components
1.  **PocketBase Container**: Running on port `8090` (internal).
    -   Handles Authentication (Email, Google, etc.).
    -   Provides Realtime Database (SQLite underneath, high performance).
    -   Manages File Storage.
2.  **Nginx Proxy**:
    -   Listens on port `80` (HTTP) and `443` (HTTPS).
    -   Routes `backend.kingsaif.cloud` traffic to the PocketBase container.
    -   Handles SSL Termination (Let's Encrypt).
3.  **Data Persistence**:
    -   All data is stored in `/home/deploy/docker-infra/pocketbase/pb_data` on the host.
    -   Backing up this one folder backs up your *entire* backend.

---

## 🚀 How to Use for Other Apps

You can use this single backend instance to power **multiple different applications**.

### Strategy A: The "Single Sign-On" Ecosystem (Recommended)
All your apps share this one database. Steps to add a new app (e.g., "Inventory App"):

1.  **Create Collection**:
    -   Go to Admin Dashboard > **New Collection**.
    -   Name it `inventory_items`.
2.  **Auth is Ready**:
    -   You don't need to do *anything* for auth.
    -   Users log in with their existing "Ruby" account.
    -   You implicitly get "Single Sign-On" across your products.
3.  **Connect**:
    -   Point your new Flutter/Web app to `https://backend.kingsaif.cloud`.

### Strategy B: Isolated Environments
If you want a completely separate database (e.g., for a client who shouldn't share data):

1.  SSH into VPS: `ssh deploy@82.112.253.29`
2.  Duplicate the PocketBase folder: `cp -r pocketbase client-x-backend`
3.  Edit `docker-compose.yml`: Change external port from `8090` to `8091`.
4.  Run `docker compose up -d`.
5.  Now you have a fresh backend at `http://IP:8091`.

---

## 🛠️ Maintenance & CLI

### Creating a Superuser (Admin) via CLI
If you ever get locked out of the UI:
```bash
docker exec -it pocketbase ./pocketbase superuser create
```

### Upgrading
To upgrade PocketBase to a new version:
1.  Edit `/home/deploy/docker-infra/pocketbase/Dockerfile` and update `PB_VERSION`.
2.  Run:
    ```bash
    cd /home/deploy/docker-infra/pocketbase
    docker compose up -d --build
    ```

---

## 🔐 Security Configuration
-   **Nginx** forces HTTPS.
-   **Google Cloud** is configured to authorize `https://backend.kingsaif.cloud` for OAuth logins.
-   **Database Rules**: Always set API rules in the Collections panel (e.g., `@request.auth.id != ""`) to prevent unauthorized access.
