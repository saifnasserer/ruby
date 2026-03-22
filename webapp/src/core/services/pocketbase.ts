import PocketBase from 'pocketbase';

// Connect to the remote VPS PocketBase instance
export const pb = new PocketBase('https://backend.kingsaif.cloud');

// Helper to check auth
export const isAuthenticated = () => pb.authStore.isValid;
export const logout = () => pb.authStore.clear();
