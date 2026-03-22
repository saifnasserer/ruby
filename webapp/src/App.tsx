import { Routes, Route, Navigate, Outlet } from 'react-router-dom';
import AuthPage from './features/auth/AuthPage';
import TasksPage from './features/tasks/TasksPage';
import HomePage from './features/dashboard/HomePage';
import MainLayout from './components/layout/MainLayout';
import { isAuthenticated } from './core/services/pocketbase';

// Protected Route Wrapper
const ProtectedRoute = () => {
  if (!isAuthenticated()) {
    return <Navigate to="/auth" replace />;
  }
  return (
    <MainLayout>
      <Outlet />
    </MainLayout>
  );
};

function App() {
  return (
    <div className="min-h-screen bg-background text-textPrimary flex flex-col font-arabic">
      <Routes>
        <Route path="/auth" element={<AuthPage />} />
        <Route element={<ProtectedRoute />}>
          <Route path="/" element={<HomePage />} />
          <Route path="/tasks" element={<TasksPage />} />
        </Route>
      </Routes>
    </div>
  );
}

export default App;
