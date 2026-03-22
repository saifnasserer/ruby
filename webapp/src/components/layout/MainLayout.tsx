import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useLocation } from 'react-router-dom';
import { PanelLeftOpen } from 'lucide-react';
import Sidebar from './Sidebar';
import { pb } from '../../core/services/pocketbase';

interface MainLayoutProps {
    children: React.ReactNode;
}

export default function MainLayout({ children }: MainLayoutProps) {
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);
    const location = useLocation();

    return (
        <div className="flex h-screen bg-background overflow-hidden relative font-body text-on-surface">
            <Sidebar isOpen={isSidebarOpen} setIsOpen={setIsSidebarOpen} />

            <AnimatePresence>
                {isSidebarOpen && (
                    <motion.div 
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={() => setIsSidebarOpen(false)}
                        className="fixed inset-0 bg-on-surface/10 backdrop-blur-[2px] z-[35]"
                    />
                )}
            </AnimatePresence>

            <main className="flex-1 overflow-y-auto relative scroll-smooth transition-all duration-500">
                {/* TopNavBar */}
                <header className="flex items-center justify-between px-8 py-4 sticky top-0 bg-background/80 backdrop-blur-md z-30 border-b border-surface-container/50">
                    <div className="flex items-center gap-4">
                        {!isSidebarOpen && (
                            <button
                                onClick={() => setIsSidebarOpen(true)}
                                className="p-2.5 bg-surface-container-lowest border border-surface-container rounded-full text-primary hover:bg-surface-container-low transition-all"
                            >
                                <PanelLeftOpen className="w-5 h-5" />
                            </button>
                        )}
                    </div>

                    {/* Centered Search Bar */}
                    <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md hidden md:block">
                        <div className="relative group">
                            <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-outline text-xl transition-colors group-focus-within:text-primary">search</span>
                            <input
                                className="w-full bg-surface-container-lowest border border-surface-container rounded-full py-2.5 pl-12 pr-6 focus:bg-white focus:border-primary/30 transition-all outline-none text-sm placeholder:text-outline/50 shadow-sm"
                                placeholder="البحث عن المهام..."
                                type="text"
                            />
                        </div>
                    </div>

                    <div className="flex items-center gap-3">
                        <div className="h-10 w-10 rounded-full bg-primary-container overflow-hidden border-2 border-white shadow-sm cursor-pointer hover:scale-105 transition-transform">
                            {pb.authStore.model?.avatar ? (
                                <img
                                    src={pb.getFileUrl(pb.authStore.model, pb.authStore.model.avatar)}
                                    alt="User"
                                    className="w-full h-full object-cover"
                                />
                            ) : (
                                <div className="w-full h-full bg-primary flex items-center justify-center text-white font-bold">
                                    {pb.authStore.model?.username?.[0]?.toUpperCase() || 'U'}
                                </div>
                            )}
                        </div>
                    </div>
                </header>

                <AnimatePresence mode="wait">
                    <motion.div
                        key={location.pathname}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -10 }}
                        transition={{ duration: 0.3, ease: "easeOut" }}
                        className="w-full h-full p-8 md:p-12 max-w-7xl mx-auto"
                    >
                        {children}
                    </motion.div>
                </AnimatePresence>
            </main>
        </div>
    );
}
