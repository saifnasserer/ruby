import { motion } from 'framer-motion';
import { format } from 'date-fns';
import { ar } from 'date-fns/locale';
import { Check, Trash2, Clock, Calendar, ListChecks } from 'lucide-react';
import { cn } from '../../../shared/lib/cn';
import type { Task } from '../model/types';

interface TaskCardProps {
    task: Task;
    onToggle: (task: Task) => void;
    onDelete: (taskId: string) => void;
    onClick: (task: Task) => void;
}

export const TaskCard = ({ task, onToggle, onDelete, onClick }: TaskCardProps) => {
    const isCompleted = task.is_completed || false;
    const createdDate = task.created ? new Date(task.created) : new Date();
    
    // Extract metadata from data field
    const subtasks = task.subtasks || [];
    const completedSubtasks = subtasks.filter(s => s.isCompleted).length;
    const deadline = task.data?.deadline ? new Date(task.data.deadline) : null;
    const tags = task.data?.tags || [];
    
    const getAccentColor = () => {
        if (isCompleted) return "bg-secondary";
        if (deadline && !isCompleted && deadline < new Date()) return "bg-destructive";
        return "bg-primary";
    };

    return (
        <motion.div
            layout
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            whileHover={{ y: -2 }}
            onClick={() => onClick(task)}
            className={cn(
                "relative flex items-center gap-6 p-4 bg-white rounded-full border border-surface-container group cursor-pointer transition-all hover:bg-surface-container-low/30 overflow-hidden",
                isCompleted && "opacity-60"
            )}
            dir="rtl"
        >
            {/* Accent Bar */}
            <div className={cn("absolute right-0 top-1 bottom-1 w-1.5 rounded-l-full", getAccentColor())} />

            {/* Checkbox */}
            <div 
                onClick={(e) => { e.stopPropagation(); onToggle(task); }}
                className={cn(
                    "flex-shrink-0 w-8 h-8 rounded-full border-2 flex items-center justify-center transition-all mr-4",
                    isCompleted 
                        ? "bg-secondary border-secondary text-white" 
                        : "border-surface-container bg-white group-hover:border-primary/50"
                )}
            >
                {isCompleted ? <Check className="w-4 h-4" /> : <div className="w-4 h-4 rounded-full border border-surface-container-high" />}
            </div>

            {/* Title and Meta */}
            <div className="flex-1 min-w-0 flex flex-col sm:flex-row sm:items-center justify-between gap-2 sm:gap-4 text-right">
                <div className="flex items-center gap-3 min-w-0">
                    <h3 className={cn(
                        "font-headline font-extrabold text-lg truncate tracking-tight transition-all",
                        isCompleted ? "text-on-surface-variant line-through opacity-50" : "text-on-surface"
                    )}>
                        {task.text}
                    </h3>
                    {tags.length > 0 && (
                        <div className="flex gap-1 overflow-x-auto no-scrollbar max-w-[120px] shrink-0">
                            {tags.map((tag: string) => (
                                <span key={tag} className="px-2 py-0.5 bg-surface-container text-[8px] font-black uppercase tracking-tighter rounded-full opacity-60 flex-shrink-0">
                                    {tag}
                                </span>
                            ))}
                        </div>
                    )}
                </div>
                <div className="flex items-center gap-4 shrink-0 flex-row-reverse self-start sm:self-auto py-1 sm:py-0">
                    <div className="flex items-center gap-1.5 text-on-surface-variant text-[11px] font-bold">
                        <Clock className="w-3.5 h-3.5 opacity-50" />
                        <span>{format(createdDate, 'dd MMM', { locale: ar })}</span>
                    </div>
                    {subtasks.length > 0 && (
                        <div className="flex items-center gap-1.5 text-on-surface-variant text-[11px] font-bold">
                            <ListChecks className="w-3.5 h-3.5 opacity-50" />
                            <span>{completedSubtasks}/{subtasks.length}</span>
                        </div>
                    )}
                    {deadline && (
                        <div className={cn(
                            "flex items-center gap-1.5 text-[11px] font-bold",
                            !isCompleted && deadline < new Date() ? "text-destructive" : "text-on-surface-variant"
                        )}>
                            <Calendar className="w-3.5 h-3.5 opacity-50" />
                            <span>{format(deadline, 'dd MMM', { locale: ar })}</span>
                        </div>
                    )}
                </div>
            </div>

            {/* Right Side: Actions */}
            <div className="flex items-center shrink-0">
                <button
                    onClick={(e) => { e.stopPropagation(); onDelete(task.id); }}
                    className="w-8 h-8 flex items-center justify-center text-on-surface-variant hover:text-red-500 hover:bg-red-50 rounded-full transition-all md:opacity-0 md:-translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 mr-1 sm:mr-2"
                >
                    <Trash2 className="w-5 h-5" />
                </button>
            </div>
        </motion.div>
    );
};
