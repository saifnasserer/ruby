# 📱 Ruby App Architecture & Implementation Guide

This document captures the architectural changes and features implemented in the **Ruby** application to support cloud synchronization and authentication.

## 🌟 Key Features Implemented

1.  **Cloud Synchronization**:
    -   Seamlessly syncs tasks between local device and **PocketBase** cloud.
    -   **Offline-First**: App works 100% offline. Data syncs automatically when connection is restored.
    -   Uses `SyncService` to handle merging of local and cloud data.

2.  **Authentication**:
    -   **Google Sign-In**: Integrated using OAuth2.
    -   **Persistent Session**: Token stored securely; user stays logged in across restarts.
    -   **State Management**: `AuthController` broadcasts auth state changes to the UI updates.

3.  **UI Updates**:
    -   **Login Screen**: Adaptive login screen shown only when unauthenticated.
    -   **Settings Integration**: "Sign Out" button added to settings; Profile data (Avatar/Name) pulled from Google.

---

## 🏗 Data Flow Architecture

```mermaid
graph TD
    UI[Flutter UI] --> Controller[TaskController]
    Controller --> LocalDB[StorageService (SharedPreferences)]
    Controller --> Sync[SyncService]
    
    Sync --> |Push/Pull| Cloud[BackendService (PocketBase)]
    Sync --> |Read/Write| LocalDB
    
    Cloud -.-> VPS[VPS: backend.kingsaif.cloud]
```

### 1. `SyncService` (The Brain)
-   Located in `lib/core/services/sync_service.dart`.
-   **Responsibility**:
    -   Listens to app updates.
    -   Pushes local changes `updateTask(task)` to cloud.
    -   Fetches `fetchAllTasks()` on startup to get data from other devices.

### 2. `AuthController`
-   Located in `lib/features/auth/controllers/auth_controller.dart`.
-   Manages user session.
-   Exposes `userEmail` and access specific user data.

### 3. `BackendService`
-   Located in `lib/core/services/backend_service.dart`.
-   Single source of truth for the API URL (`https://backend.kingsaif.cloud`).
-   Wraps the `PocketBase` client instance.

---

## 🔄 Sync Logic Details

The app uses a **"Soft Delete"** strategy for safety:
1.  When you delete a task, it is marked `isDeleted = true` locally.
2.  Synced to cloud as an update (not a hard delete).
3.  UI filters out deleted items.

**Conflict Resolution**:
-   Currently favoring **Last Write Wins**.
-   When `loadTasks()` is called, we merge Cloud tasks into Local tasks based on ID matching.

---

## 📲 How to Extend

### Adding a New Feature (e.g., Notes)
1.  **Backend**: Create `notes` collection in PocketBase dashboard.
2.  **App Model**: Create `Note` model in Flutter.
3.  **Service**: Add `fetchNotes()` and `createNote()` to `SyncService`.
4.  **UI**: Build your UI and call the service methods.
