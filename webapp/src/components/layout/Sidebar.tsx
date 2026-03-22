import { NavLink, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { LogOut, PanelLeftClose } from 'lucide-react';
import { logout } from '../../core/services/pocketbase';
import { cn } from '../../shared/lib/cn';
import { Button } from '../../shared/ui/Button';

interface SidebarProps {
    isOpen: boolean;
    setIsOpen: (open: boolean) => void;
}

export default function Sidebar({ isOpen, setIsOpen }: SidebarProps) {
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate('/auth');
    };

    const navItems = [
        { icon: 'dashboard', label: 'الرئيسية', to: '/' },
        { icon: 'task_alt', label: 'المهام', to: '/tasks' },
        { icon: 'calendar_month', label: 'التقويم', to: '/calendar' },
        { icon: 'settings', label: 'الإعدادات', to: '/settings' },
    ];

    return (
        <AnimatePresence mode="wait">
            {isOpen && (
                <motion.aside
                    initial={{ width: 0, opacity: 0, x: 50 }}
                    animate={{ width: 256, opacity: 1, x: 0 }}
                    exit={{ width: 0, opacity: 0, x: 50 }}
                    transition={{ type: "spring", damping: 25, stiffness: 200 }}
                    className="bg-surface-container-low flex flex-col h-full sticky top-0 z-40 overflow-hidden shrink-0 border-none"
                >
                    <div className="px-8 py-10 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <img src="/bakiza-cat.png" alt="Bakiza Logo" className="w-10 h-10 object-contain drop-shadow-sm" />
                            <div className="flex flex-col">
                                <h1 className="text-2xl font-headline font-black text-primary tracking-tighter leading-none">بكيزة</h1>
                                <p className="text-[10px] font-headline font-bold tracking-tight text-on-surface uppercase opacity-50 mt-1">Bakiza Assistant</p>
                            </div>
                        </div>
                        <button
                            onClick={() => setIsOpen(false)}
                            className="p-2 text-on-surface-variant hover:text-primary hover:bg-surface-container rounded-full transition-all"
                        >
                            <PanelLeftClose className="w-5 h-5" />
                        </button>
                    </div>

                    <nav className="flex-1 px-4 space-y-1 mt-4">
                        {navItems.map((item) => (
                            <NavLink
                                key={item.to}
                                to={item.to}
                                className={({ isActive }) => cn(
                                    "flex items-center gap-3 px-6 py-4 rounded-full transition-all duration-200 group relative overflow-hidden font-headline font-bold tracking-tight scale-100 active:scale-95",
                                    isActive
                                        ? "bg-white text-primary shadow-none"
                                        : "text-on-surface-variant hover:bg-surface-container-high"
                                )}
                            >
                                <span className="material-symbols-outlined text-2xl">{item.icon}</span>
                                <span className="text-base">{item.label}</span>
                            </NavLink>
                        ))}
                    </nav>

                    <div className="p-6 space-y-4 mt-auto">
                        <Button
                            onClick={() => navigate('/tasks/new')}
                            className="w-full bg-primary text-white rounded-full py-4 flex items-center justify-center gap-2 font-bold transition-transform hover:scale-[1.02] active:scale-95 shadow-none"
                        >
                            <span className="material-symbols-outlined">add</span>
                            <span>مهمة جديدة</span>
                        </Button>

                        <button
                            onClick={handleLogout}
                            className="w-full flex items-center justify-center gap-3 px-4 py-4 rounded-full text-on-surface-variant hover:bg-error-dim hover:text-white transition-all duration-300 group font-bold font-headline"
                        >
                            <LogOut className="w-5 h-5 group-hover:-translate-x-1 transition-transform" />
                            <span>تسجيل الخروج</span>
                        </button>

                        <p className="text-[10px] text-center font-bold text-on-surface-variant opacity-30 uppercase tracking-[0.2em] font-headline">
                            Made with 🐾 for Productivity
                        </p>
                    </div>
                </motion.aside>
            )}
        </AnimatePresence>
    );
}
