import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { format, subDays, startOfDay, endOfDay, isWithinInterval } from 'date-fns';
import { ar } from 'date-fns/locale';
import { pb } from '../../core/services/pocketbase';
import { Target, CheckCircle2, Clock, Zap } from 'lucide-react';
import { cn } from '../../shared/lib/cn';
import type { Task } from '../../entities/task/model/types';

interface Stats {
    total: number;
    completed: number;
    pending: number;
    completionRate: number;
}

interface DailyStat {
    date: Date;
    label: string; // Day name (e.g. 'الأحد')
    percentage: number;
}

const container = {
    hidden: { opacity: 0 },
    show: {
        opacity: 1,
        transition: {
            staggerChildren: 0.1
        }
    }
};

const item = {
    hidden: { y: 20, opacity: 0 },
    show: { y: 0, opacity: 1 }
};

export default function HomePage() {
    const [stats, setStats] = useState<Stats>({
        total: 0,
        completed: 0,
        pending: 0,
        completionRate: 0
    });
    const [weeklyStats, setWeeklyStats] = useState<DailyStat[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    const getGreeting = () => {
        const hour = new Date().getHours();
        if (hour >= 5 && hour < 12) return 'صباح الخير';
        if (hour >= 12 && hour < 17) return 'طاب يومك';
        return 'مساء الخير';
    };

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const userId = pb.authStore.model?.id;
                // Fetch all tasks for comprehensive stats
                const records = await pb.collection('tasks').getFullList<Task>({
                    filter: `user = "${userId}"`,
                    sort: '-created', // Newest first
                });

                // 1. Calculate Overall Stats (Active/Pending vs Completed overall)
                const total = records.length;
                const completed = records.filter(r => r.is_completed).length;
                const pending = total - completed;
                const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
                setStats({ total, completed, pending, completionRate });

                // 2. Calculate Weekly Activity (Last 7 Days)
                const last7Days = Array.from({ length: 7 }).map((_, i) => {
                    const d = subDays(new Date(), 6 - i); // Start from 6 days ago up to today
                    return {
                        date: d,
                        start: startOfDay(d),
                        end: endOfDay(d),
                        label: format(d, 'EEEEEE', { locale: ar }), // e.g., 'ح', 'ن' 
                    };
                });

                const computedWeeklyStats: DailyStat[] = last7Days.map(dayInfo => {
                    // Find tasks completed on this specific day
                    // Assuming 'updated' field reflects completion time, or we just look at all tasks created/updated
                    // For a robust system, we need a 'completed_at' timestamp. If not available, we estimate based on updated.
                    // Let's look at tasks updated within this day that are completed
                    const tasksForDay = records.filter(r => {
                        const taskDate = new Date(r.updated);
                        return isWithinInterval(taskDate, { start: dayInfo.start, end: dayInfo.end });
                    });

                    const totalOnDay = tasksForDay.length;
                    const completedOnDay = tasksForDay.filter(r => r.is_completed).length;

                    // If no tasks were interacted with on this day, percentage is 0
                    const perc = totalOnDay > 0 ? Math.round((completedOnDay / totalOnDay) * 100) : 0;

                    return {
                        date: dayInfo.date,
                        label: dayInfo.label,
                        percentage: perc
                    };
                });

                setWeeklyStats(computedWeeklyStats);

            } catch (error) {
                console.error('Failed to fetch stats', error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchStats();
    }, []);

    if (isLoading) {
        return (
            <div className="flex flex-col items-center justify-center h-full gap-4">
                <motion.div
                    animate={{ y: [0, -20, 0] }}
                    transition={{ repeat: Infinity, duration: 1.5 }}
                >
                    <img src="/bakiza-cat.png" alt="Loading" className="w-16 h-16 object-contain drop-shadow-md" />
                </motion.div>
                <p className="text-on-surface-variant font-bold">بكيزة بتجهز البيانات...</p>
            </div>
        );
    }

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex flex-col gap-10"
        >
            <header className="flex flex-col gap-2">
                <h1 className="text-4xl md:text-5xl font-black text-on-surface tracking-tight flex items-center gap-3">
                    {getGreeting()}، {pb.authStore.model?.username || ''}!
                    <img src="/bakiza-cat.png" alt="Bakiza" className="w-10 h-10 md:w-12 md:h-12 object-contain drop-shadow-sm" />
                </h1>
                <p className="text-on-surface-variant text-lg md:text-xl font-medium">إليك ملخص سريع لإنتاجيتك وأدائك.</p>
            </header>

            <motion.div
                variants={container}
                initial="hidden"
                animate="show"
                className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
            >
                {[
                    { label: 'إجمالي المهام', value: stats.total, icon: Target, color: 'bg-primary/10 text-primary' },
                    { label: 'مهام مكتملة', value: stats.completed, icon: CheckCircle2, color: 'bg-success/10 text-success' },
                    { label: 'مهام قيد التنفيذ', value: stats.pending, icon: Clock, color: 'bg-warning/10 text-warning' },
                    { label: 'نسبة الإنجاز', value: `${stats.completionRate}%`, icon: Zap, color: 'bg-secondary/10 text-secondary' },
                ].map((stat, i) => (
                    <motion.div
                        key={i}
                        variants={item}
                        whileHover={{ y: -4 }}
                        className="bg-surface-container-lowest rounded-[2rem] flex items-center gap-6 p-8 border-4 border-surface-container transition-all cursor-pointer relative overflow-hidden active:bg-surface-container-low hover:border-surface-container-high"
                    >
                        <div className={cn("p-4 rounded-[1.5rem] relative z-10", stat.color)}>
                            <stat.icon className="w-7 h-7" />
                        </div>
                        <div className="flex flex-col relative z-10">
                            <span className="text-3xl font-black text-on-surface">{stat.value}</span>
                            <span className="text-on-surface-variant font-bold text-sm tracking-wide mt-1">{stat.label}</span>
                        </div>
                    </motion.div>
                ))}
            </motion.div>

            <motion.section
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="flex flex-col gap-6"
            >
                <div className="flex items-center justify-between">
                    <h2 className="text-2xl font-black text-on-surface">إجراءات سريعة</h2>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {[
                        { label: 'إضافة مهمة', icon: Zap, color: 'bg-primary text-white', link: '/tasks' },
                        { label: 'إدارة التصنيفات', icon: Target, color: 'bg-secondary text-white', link: '/tasks' },
                        { label: 'المهام المتأخرة', icon: Clock, color: 'bg-warning text-on-warning-container', link: '/tasks' },
                        { label: 'تقارير الأداء', icon: CheckCircle2, color: 'bg-success text-white', link: '/' },
                    ].map((action, i) => (
                        <motion.a
                            key={i}
                            href={action.link}
                            whileHover={{ scale: 1.02, y: -2 }}
                            whileTap={{ scale: 0.98 }}
                            className={cn(
                                "flex flex-col items-center justify-center gap-3 p-6 rounded-[2rem] border-4 border-surface-container transition-all cursor-pointer bg-surface-container-lowest hover:border-surface-container-high shadow-sm",
                                "group"
                            )}
                        >
                            <div className={cn("p-4 rounded-2xl transition-transform group-hover:rotate-12", action.color)}>
                                <action.icon className="w-6 h-6" />
                            </div>
                            <span className="font-black text-on-surface text-sm">{action.label}</span>
                        </motion.a>
                    ))}
                </div>
            </motion.section>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <motion.div
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.4 }}
                    className="bg-surface-container-lowest rounded-[2rem] sm:rounded-[2.5rem] p-6 sm:p-10 flex flex-col gap-6 md:gap-8 border-4 border-surface-container"
                >
                    <h2 className="text-xl md:text-2xl font-black flex items-center gap-3 text-on-surface">
                        <Zap className="w-5 h-5 md:w-6 md:h-6 text-secondary fill-secondary" />
                        نصيحة بكيزة اليوم
                    </h2>
                    <div className="bg-surface-container-low/50 p-6 sm:p-8 rounded-[1.5rem] sm:rounded-[2rem] border-r-[8px] sm:border-r-[12px] border-secondary flex flex-col sm:flex-row gap-4 sm:gap-6 items-start sm:items-center">
                        <img src="/bakiza-cat.png" alt="Bakiza Tip" className="w-16 h-16 sm:w-20 sm:h-20 object-contain drop-shadow-md shrink-0" />
                        <p className="text-on-surface text-base sm:text-lg leading-relaxed sm:leading-loose font-bold opacity-80 pt-1 sm:pt-2">
                            "{stats.completionRate > 70
                                ? 'بكيزة فخورة جداً بيك'
                                : 'حاول تركز على تقسيم مهامك لأجزاء صغيرة!'}"
                        </p>
                    </div>
                </motion.div>

                <motion.div
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.4 }}
                    className="bg-white rounded-[2rem] sm:rounded-[2.5rem] p-6 sm:p-10 flex flex-col gap-6 md:gap-8 border-4 border-slate-100"
                >
                    <header className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-3 sm:gap-0">
                        <div className="flex flex-col gap-1">
                            <h2 className="text-xl md:text-2xl font-black text-on-surface">النشاط الأسبوعي</h2>
                            <p className="text-xs sm:text-sm font-bold text-on-surface-variant opacity-60">معدل الإنجاز لآخر ٧ أيام</p>
                        </div>
                        <div className="bg-primary/10 text-primary px-4 py-2 rounded-xl sm:rounded-2xl font-black text-xs sm:text-sm">
                            {format(new Date(), 'MMMM', { locale: ar })}
                        </div>
                    </header>

                    <div className="flex items-end justify-between h-40 sm:h-48 gap-2 sm:gap-4 pt-6 mt-auto">
                        {weeklyStats.map((stat, i) => {
                            const isToday = i === weeklyStats.length - 1;
                            return (
                                <div key={i} className="flex-1 flex flex-col items-center gap-2 sm:gap-4 group cursor-pointer relative h-full justify-end">
                                    <motion.div
                                        initial={{ height: 0 }}
                                        animate={{ height: `${Math.max(stat.percentage, 5)}%` }} // Minimum 5% height for visibility
                                        transition={{ duration: 1, delay: 0.5 + i * 0.1, ease: "circOut" }}
                                        className={cn(
                                            "w-full rounded-xl transition-all duration-300 relative group-hover:scale-y-[1.05] origin-bottom",
                                            isToday ? "bg-primary" : "bg-surface-container-low group-hover:bg-primary/30"
                                        )}
                                    >
                                        <div className={cn(
                                            "absolute -top-8 sm:-top-10 left-1/2 -translate-x-1/2 text-[10px] sm:text-sm font-black transition-all",
                                            isToday ? "text-primary opacity-100" : "text-on-surface opacity-0 group-hover:opacity-100 -translate-y-2 group-hover:translate-y-0"
                                        )}>
                                            {stat.percentage}%
                                        </div>
                                    </motion.div>
                                    <span className={cn(
                                        "text-[9px] sm:text-sm font-black transition-colors rounded-lg sm:rounded-xl px-1 sm:px-2 py-1",
                                        isToday ? "text-primary bg-primary/10" : "text-on-surface-variant group-hover:text-primary"
                                    )}>
                                        {stat.label}
                                    </span>
                                </div>
                            );
                        })}
                    </div>
                </motion.div>
            </div>
        </motion.div>
    );
}
