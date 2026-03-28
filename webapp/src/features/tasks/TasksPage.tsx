import { useEffect, useState, useMemo, useRef, useCallback } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { Plus, Check, ArrowLeft, Filter, ArrowUpDown, Loader2, Trash2, FileText, Pencil, X, Calendar } from 'lucide-react';
import { format } from 'date-fns';
import { ar } from 'date-fns/locale';
import { pb } from '../../core/services/pocketbase';
import { Button } from '../../shared/ui/Button';
import { Input } from '../../shared/ui/Input';
import Modal from '../../shared/ui/Modal';
import { cn } from '../../shared/lib/cn';
import { TaskCard } from '../../entities/task/ui/TaskCard';
import type { Task, Subtask } from '../../entities/task/model/types';

type SortOption = 'newest' | 'oldest' | 'alphabetical';
type FilterStatus = 'all' | 'active' | 'completed';
type DateFilter = string;

const PAGE_SIZE = 20;
const DEFAULT_TAGS = ['شخصي', 'عمل', 'عاجل', 'أفكار', 'أخرى'];

export default function TasksPage() {
    const [tasks, setTasks] = useState<Task[]>([]);
    const [page, setPage] = useState(1);
    const [hasMore, setHasMore] = useState(true);
    const [isLoadingMore, setIsLoadingMore] = useState(false);

    const [newTaskText, setNewTaskText] = useState('');
    const [newSubtaskText, setNewSubtaskText] = useState('');
    const [activeTab, setActiveTab] = useState('الكل');
    const [sortBy, setSortBy] = useState<SortOption>('newest');
    const [filterStatus, setFilterStatus] = useState<FilterStatus>('all');
    const [dateFilter, setDateFilter] = useState<DateFilter>('all');
    const [openDropdown, setOpenDropdown] = useState<'filter' | 'sort' | 'date' | null>(null);

    const [searchQuery, setSearchQuery] = useState('');
    const [debouncedSearchQuery, setDebouncedSearchQuery] = useState('');

    useEffect(() => {
        const timer = setTimeout(() => setDebouncedSearchQuery(searchQuery), 400);
        return () => clearTimeout(timer);
    }, [searchQuery]);

    const [selectedTask, setSelectedTask] = useState<Task | null>(null);
    const [isDetailsOpen, setIsDetailsOpen] = useState(false);
    const [isInitialLoad, setIsInitialLoad] = useState(true);

    const [workspaceTitle, setWorkspaceTitle] = useState('مهامي');
    const [isEditingWorkspaceTitle, setIsEditingWorkspaceTitle] = useState(false);

    const [isEditingTitle, setIsEditingTitle] = useState(false);
    const [editedTitle, setEditedTitle] = useState('');

    const [availableTags, setAvailableTags] = useState<string[]>(() => {
        const saved = localStorage.getItem('bakiza_available_tags');
        return saved ? JSON.parse(saved) : DEFAULT_TAGS;
    });
    const [isTagsModalOpen, setIsTagsModalOpen] = useState(false);
    const [newTagInput, setNewTagInput] = useState('');
    const [selectedTags, setSelectedTags] = useState<string[]>([]);

    const observer = useRef<IntersectionObserver | null>(null);
    const lastTaskElementRef = useCallback((node: HTMLDivElement | null) => {
        if (isLoadingMore || isInitialLoad) return;
        if (observer.current) observer.current.disconnect();
        observer.current = new IntersectionObserver(entries => {
            if (entries[0].isIntersecting && hasMore) {
                setPage(prev => prev + 1);
            }
        });
        if (node) observer.current.observe(node);
    }, [isLoadingMore, isInitialLoad, hasMore]);

    // Save tags when they change
    useEffect(() => {
        localStorage.setItem('bakiza_available_tags', JSON.stringify(availableTags));
    }, [availableTags]);

    const fetchTasks = async (pageNum: number, isRefresh = false) => {
        try {
            const userId = pb.authStore.model?.id;
            if (!userId) return;

            if (pageNum > 1) setIsLoadingMore(true);

            let filterString = `user = "${userId}" && local_id != "__global_tags__"`;
            if (activeTab !== 'الكل') {
                filterString += ` && data ~ "${activeTab}"`;
            }
            if (filterStatus === 'active') {
                filterString += ` && is_completed = false`;
            } else if (filterStatus === 'completed') {
                filterString += ` && is_completed = true`;
            }

            if (debouncedSearchQuery.trim()) {
                filterString += ` && text ~ "${debouncedSearchQuery.trim()}"`;
            }

            if (dateFilter === 'today') {
                const today = new Date(); today.setHours(0, 0, 0, 0);
                const tmr = new Date(today); tmr.setDate(tmr.getDate() + 1);
                filterString += ` && data.deadline >= "${today.toISOString()}" && data.deadline < "${tmr.toISOString()}"`;
            } else if (dateFilter === 'tomorrow') {
                const tmr = new Date(); tmr.setDate(tmr.getDate() + 1); tmr.setHours(0, 0, 0, 0);
                const dayAfter = new Date(tmr); dayAfter.setDate(dayAfter.getDate() + 1);
                filterString += ` && data.deadline >= "${tmr.toISOString()}" && data.deadline < "${dayAfter.toISOString()}"`;
            } else if (dateFilter === 'upcoming') {
                const min = new Date(); min.setDate(min.getDate() + 2); min.setHours(0, 0, 0, 0);
                filterString += ` && data.deadline >= "${min.toISOString()}"`;
            } else if (dateFilter && dateFilter !== 'all') {
                const specificDate = new Date(dateFilter);
                if (!isNaN(specificDate.getTime())) {
                    specificDate.setHours(0, 0, 0, 0);
                    const nextDay = new Date(specificDate); nextDay.setDate(nextDay.getDate() + 1);
                    filterString += ` && data.deadline >= "${specificDate.toISOString()}" && data.deadline < "${nextDay.toISOString()}"`;
                }
            }

            const result = await pb.collection('tasks').getList<Task>(pageNum, PAGE_SIZE, {
                sort: sortBy === 'alphabetical' ? 'text' : sortBy === 'oldest' ? 'created' : '-created',
                filter: filterString,
            });

            // Handle Global Tags Sync - Fetch specifically
            if (pageNum === 1) {
                try {
                    const tagResult = await pb.collection('tasks').getFirstListItem(`user = "${userId}" && local_id = "__global_tags__"`);
                    if (tagResult) {
                        const data = typeof tagResult.data === 'string' ? JSON.parse(tagResult.data) : tagResult.data;
                        if (data.tags && Array.isArray(data.tags) && data.tags.length > 0) {
                            setAvailableTags(data.tags);
                        }
                    }
                } catch (e) { /* ignore if not found */ }
            }

            const mappedRecords = result.items.map(record => {
                let subtasks: Subtask[] = [];
                if (record.data) {
                    try {
                        const parsedData = typeof record.data === 'string' ? JSON.parse(record.data) : record.data;
                        subtasks = parsedData.subtasks || [];
                    } catch (e) { console.error('Failed to parse task data', e); }
                }
                if (!record.text && record.data?.text) record.text = record.data.text;
                return { ...record, subtasks };
            });

            if (isRefresh) {
                setTasks(mappedRecords);
            } else {
                setTasks(prev => [...prev, ...mappedRecords]);
            }

            setHasMore(result.items.length === PAGE_SIZE);
        } catch (error) {
            console.error('Failed to fetch tasks', error);
        } finally {
            setIsInitialLoad(false);
            setIsLoadingMore(false);
        }
    };

    // Refresh on filter/sort change
    useEffect(() => {
        setPage(1);
        setTasks([]);
        setHasMore(true);
        fetchTasks(1, true);
    }, [sortBy, activeTab, filterStatus, debouncedSearchQuery, dateFilter]);

    // Load next page
    useEffect(() => {
        if (page > 1) fetchTasks(page);
    }, [page]);

    // Auto-select active tag when switching tabs
    useEffect(() => {
        if (activeTab !== 'الكل') {
            setSelectedTags([activeTab]);
        } else {
            setSelectedTags([]);
        }
    }, [activeTab]);

    useEffect(() => {
        const userId = pb.authStore.model?.id;
        pb.collection('tasks').subscribe<Task>('*', (e) => {
            if (e.record.user !== userId) return;
            // Real-time: For now simpler to re-fetch first page
        });
        return () => { pb.collection('tasks').unsubscribe('*'); };
    }, []);

    const filteredTasks = useMemo(() => {
        return [...tasks];
    }, [tasks]);

    const handleCreateTask = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newTaskText.trim()) return;
        const now = new Date().toISOString();
        const taskId = Date.now().toString();
        const taskData = {
            text: newTaskText,
            is_completed: false,
            day_of_week: new Date().toLocaleDateString('ar-EG', { weekday: 'long' }),
            user: pb.authStore.model?.id,
            local_id: taskId,
            data: { id: taskId, text: newTaskText, createdAt: now, subtasks: [], tags: selectedTags },
        };
        try {
            setNewTaskText('');
            setSelectedTags(activeTab !== 'الكل' ? [activeTab] : []);
            await pb.collection('tasks').create(taskData);
            setPage(1); // Reset to catch new task
            fetchTasks(1, true);
        } catch (error) { console.error('Failed to create task', error); }
    };

    const handleToggleTask = async (task: Task) => {
        try {
            await pb.collection('tasks').update(task.id, { is_completed: !task.is_completed });
            setTasks(prev => prev.map(t => t.id === task.id ? { ...t, is_completed: !t.is_completed } : t));
        } catch (error) { console.error('Failed to toggle task', error); }
    };

    const handleDeleteTask = async (taskId: string) => {
        if (!window.confirm('هل أنت متأكد من حذف هذه المهمة؟')) return;
        try {
            await pb.collection('tasks').delete(taskId);
            setTasks(prev => prev.filter(t => t.id !== taskId));
        } catch (error) { console.error('Failed to delete task', error); }
    };

    const syncGlobalTags = async (newTags: string[]) => {
        try {
            const userId = pb.authStore.model?.id;
            if (!userId) return;

            // Try to find existing record
            let recordId = '';
            try {
                const existing = await pb.collection('tasks').getFirstListItem(`user = "${userId}" && local_id = "__global_tags__"`);
                recordId = existing.id;
            } catch (e) { /* not found */ }

            const taskData = {
                text: 'Global Tags Configuration',
                is_completed: false,
                day_of_week: 'config',
                user: userId,
                local_id: '__global_tags__',
                data: JSON.stringify({ id: '__global_tags__', tags: newTags }),
            };

            if (recordId) {
                await pb.collection('tasks').update(recordId, taskData);
            } else {
                await pb.collection('tasks').create(taskData);
            }
        } catch (error) {
            console.error('Failed to sync global tags', error);
        }
    };

    const handleAddGlobalTag = () => {
        if (!newTagInput.trim()) return;
        if (availableTags.includes(newTagInput.trim())) return;
        const updated = [...availableTags, newTagInput.trim()];
        setAvailableTags(updated);
        setNewTagInput('');
        syncGlobalTags(updated);
    };

    const handleDeleteGlobalTag = (tagToDelete: string) => {
        if (!window.confirm(`هل أنت متأكد من حذف التصنيف "${tagToDelete}"؟`)) return;
        const updated = availableTags.filter(t => t !== tagToDelete);
        setAvailableTags(updated);
        if (activeTab === tagToDelete) setActiveTab('الكل');
        if (selectedTags.includes(tagToDelete)) setSelectedTags(prev => prev.filter(t => t !== tagToDelete));
        syncGlobalTags(updated);
    };

    const handleEditGlobalTag = (oldTag: string) => {
        const newTag = window.prompt('أدخل الاسم الجديد للتصنيف:', oldTag);
        if (!newTag || !newTag.trim() || newTag === oldTag) return;
        if (availableTags.includes(newTag.trim())) {
            alert('هذا التصنيف موجود بالفعل!');
            return;
        }

        const trimmedNewTag = newTag.trim();
        const updated = availableTags.map(t => t === oldTag ? trimmedNewTag : t);
        setAvailableTags(updated);
        syncGlobalTags(updated);
        
        if (activeTab === oldTag) setActiveTab(trimmedNewTag);
        setSelectedTags(prev => prev.map(t => t === oldTag ? trimmedNewTag : t));
        
        // Update tags in existing tasks currently in state
        setTasks(prev => prev.map(task => {
            if (task.data?.tags?.includes(oldTag)) {
                const updatedTags = task.data.tags.map((t: string) => t === oldTag ? trimmedNewTag : t);
                const updatedData = { ...task.data, tags: updatedTags };
                
                // Fire and forget update to PocketBase for this task
                pb.collection('tasks').update(task.id, { 
                    data: JSON.stringify(updatedData) 
                }).catch(err => console.error('Failed to update task tag during rename', err));
                
                return { ...task, data: updatedData };
            }
            return task;
        }));
    };

    const handleToggleTaskTag = async (task: Task, tag: string) => {
        const currentData = typeof task.data === 'string' ? JSON.parse(task.data) : task.data || {};
        const currentTags = currentData.tags || [];
        const isSelected = currentTags.includes(tag);
        
        const updatedTags = isSelected 
            ? currentTags.filter((t: string) => t !== tag)
            : [...currentTags, tag];
            
        const updatedData = { ...currentData, tags: updatedTags };
        
        try {
            const updatedTask = { ...task, data: updatedData };
            setSelectedTask(updatedTask);
            setTasks(prev => prev.map(t => t.id === task.id ? updatedTask : t));
            
            await pb.collection('tasks').update(task.id, {
                data: JSON.stringify(updatedData)
            });
        } catch (error) {
            console.error('Failed to toggle task tag', error);
        }
    };

    const handleUpdateTaskTitle = async () => {
        if (!selectedTask || !editedTitle.trim()) {
            setIsEditingTitle(false);
            return;
        }
        try {
            const updatedTask = { ...selectedTask, text: editedTitle };
            setSelectedTask(updatedTask);
            setTasks(prev => prev.map(t => t.id === selectedTask.id ? updatedTask : t));
            setIsEditingTitle(false);

            const updatedData = { ...selectedTask.data, text: editedTitle };
            await pb.collection('tasks').update(selectedTask.id, {
                text: editedTitle,
                data: JSON.stringify(updatedData)
            });
        } catch (error) { console.error('Failed to update task title', error); }
    };

    const handleToggleSubtask = async (subtaskId: string) => {
        if (!selectedTask) return;
        const updatedSubtasks = (selectedTask.subtasks || []).map(s =>
            s.id === subtaskId ? { ...s, isCompleted: !s.isCompleted } : s
        );
        try {
            const updatedTask = { ...selectedTask, subtasks: updatedSubtasks };
            setSelectedTask(updatedTask);
            setTasks(prev => prev.map(t => t.id === selectedTask.id ? updatedTask : t));
            await pb.collection('tasks').update(selectedTask.id, {
                data: JSON.stringify({ ...selectedTask.data, subtasks: updatedSubtasks })
            });
        } catch (error) { console.error('Failed to toggle subtask', error); }
    };

    const handleAddSubtask = async (e?: React.FormEvent) => {
        if (e) e.preventDefault();
        if (!selectedTask || !newSubtaskText.trim()) return;

        const newSubtask: Subtask = {
            id: Date.now().toString(),
            text: newSubtaskText,
            isCompleted: false,
            createdAt: new Date().toISOString()
        };

        const updatedSubtasks = [...(selectedTask.subtasks || []), newSubtask];
        try {
            const updatedTask = { ...selectedTask, subtasks: updatedSubtasks };
            setSelectedTask(updatedTask);
            setTasks(prev => prev.map(t => t.id === selectedTask.id ? updatedTask : t));
            setNewSubtaskText('');
            await pb.collection('tasks').update(selectedTask.id, {
                data: JSON.stringify({ ...selectedTask.data, subtasks: updatedSubtasks })
            });
        } catch (error) { console.error('Failed to add subtask', error); }
    };

    const handleDeleteSubtask = async (subtaskId: string) => {
        if (!selectedTask) return;
        const updatedSubtasks = (selectedTask.subtasks || []).filter(s => s.id !== subtaskId);
        try {
            const updatedTask = { ...selectedTask, subtasks: updatedSubtasks };
            setSelectedTask(updatedTask);
            setTasks(prev => prev.map(t => t.id === selectedTask.id ? updatedTask : t));
            await pb.collection('tasks').update(selectedTask.id, {
                data: JSON.stringify({ ...selectedTask.data, subtasks: updatedSubtasks })
            });
        } catch (error) { console.error('Failed to delete subtask', error); }
    };

    const totalActiveCount = tasks.filter(t => !t.is_completed).length;

    return (
        <div className="flex flex-col gap-10 max-w-5xl mx-auto py-4 mb-32" dir="rtl">
            {/* Header Section */}
            <header className="flex flex-col md:flex-row justify-between items-center gap-6 px-4 md:px-0">
                <div className="flex items-baseline gap-4 text-right">
                    {isEditingWorkspaceTitle ? (
                        <input
                            autoFocus
                            value={workspaceTitle}
                            onChange={(e) => setWorkspaceTitle(e.target.value)}
                            onBlur={() => setIsEditingWorkspaceTitle(false)}
                            onKeyDown={(e) => e.key === 'Enter' && setIsEditingWorkspaceTitle(false)}
                            className="text-5xl font-headline font-extrabold text-on-surface tracking-tighter bg-transparent border-none outline-none focus:ring-0 max-w-[250px]"
                        />
                    ) : (
                        <h1
                            onClick={() => setIsEditingWorkspaceTitle(true)}
                            className="text-5xl font-headline font-extrabold text-on-surface tracking-tighter cursor-text hover:opacity-80 transition-opacity"
                        >
                            {workspaceTitle}
                        </h1>
                    )}
                    <p className="text-on-surface-variant font-bold text-lg opacity-60">
                        ({totalActiveCount} متبقية لليوم)
                    </p>
                </div>

                {/* Tags / Categories Tabs */}
                <div className="group relative flex items-center gap-2">
                    <div className="flex p-1 bg-surface-container-high/50 rounded-full backdrop-blur-sm border border-surface-container overflow-x-auto no-scrollbar max-w-[480px]">
                        <button
                            onClick={() => setActiveTab('الكل')}
                            className={cn(
                                "px-4 py-1.5 rounded-full text-sm font-bold transition-all whitespace-nowrap",
                                activeTab === 'الكل' ? "bg-white text-primary shadow-sm" : "text-on-surface-variant hover:text-on-surface"
                            )}
                        >
                            الكل
                        </button>
                        {availableTags.map(tab => (
                            <button
                                key={tab}
                                onClick={() => setActiveTab(tab)}
                                className={cn(
                                    "px-4 py-1.5 rounded-full text-sm font-bold transition-all whitespace-nowrap",
                                    activeTab === tab ? "bg-white text-primary shadow-sm" : "text-on-surface-variant hover:text-on-surface"
                                )}
                            >
                                {tab}
                            </button>
                        ))}
                    </div>

                    <button
                        onClick={() => setIsTagsModalOpen(true)}
                        className="p-2 text-on-surface-variant hover:text-primary opacity-0 group-hover:opacity-100 transition-all bg-white/50 rounded-full border border-surface-container hover:shadow-sm"
                    >
                        <Pencil className="w-4 h-4" />
                    </button>
                </div>
            </header>

            {/* Unified Filter/Search Row */}
            <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 p-3 bg-white md:rounded-full rounded-3xl border border-surface-container shadow-sm mx-4 md:mx-0">
                {/* Search Input */}
                <div className="w-full md:flex-1 flex items-center gap-3 pl-6 pr-4 bg-surface-container-lowest rounded-full p-2 md:p-0 md:bg-transparent">
                    <span className="material-symbols-outlined text-on-surface-variant/50 shrink-0">search</span>
                    <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="البحث في المهام..."
                        className="w-full bg-transparent border-none outline-none text-sm placeholder:text-on-surface-variant/50 focus:ring-0 text-on-surface"
                    />
                </div>

                {/* Filter Actions */}
                {openDropdown && <div className="fixed inset-0 z-40" onClick={() => setOpenDropdown(null)} />}
                <div className="flex items-center flex-wrap gap-2 shrink-0 border-none md:border-r border-surface-container md:pr-4 relative z-50 pb-1 md:pb-0">
                    <div className="relative">
                        <Button
                            variant="ghost"
                            onClick={() => setOpenDropdown(prev => prev === 'filter' ? null : 'filter')}
                            className="bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container rounded-full px-4 py-2 h-auto text-[11px] font-black uppercase tracking-widest gap-2"
                        >
                            <Filter className="w-4 h-4" />
                            {filterStatus === 'all' ? 'فلترة' : filterStatus === 'active' ? 'قيد التنفيذ' : 'مكتملة'}
                        </Button>
                        <AnimatePresence>
                            {openDropdown === 'filter' && (
                                <motion.div
                                    initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 5 }}
                                    className="absolute top-full right-0 mt-2 w-40 bg-white rounded-3xl shadow-xl border border-surface-container p-2 z-50"
                                >
                                    {(['all', 'active', 'completed'] as FilterStatus[]).map(s => (
                                        <button key={s} onClick={() => { setFilterStatus(s); setOpenDropdown(null); }} className={cn("w-full text-right px-4 py-2 hover:bg-surface-container-low rounded-2xl text-sm font-bold transition-colors", filterStatus === s ? "bg-surface-container-low text-primary" : "text-on-surface")}>
                                            {s === 'all' ? 'الكل' : s === 'active' ? 'قيد التنفيذ' : 'مكتملة'}
                                        </button>
                                    ))}
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>

                    <div className="relative">
                        <Button
                            variant="ghost"
                            onClick={() => setOpenDropdown(prev => prev === 'sort' ? null : 'sort')}
                            className="bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container rounded-full px-4 py-2 h-auto text-[11px] font-black uppercase tracking-widest gap-2"
                        >
                            <ArrowUpDown className="w-4 h-4" />
                            {sortBy === 'newest' ? 'الأحدث' : sortBy === 'oldest' ? 'الأقدم' : 'أبجدياً'}
                        </Button>
                        <AnimatePresence>
                            {openDropdown === 'sort' && (
                                <motion.div
                                    initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 5 }}
                                    className="absolute top-full right-0 mt-2 w-40 bg-white rounded-3xl shadow-xl border border-surface-container p-2 z-50"
                                >
                                    {(['newest', 'oldest', 'alphabetical'] as SortOption[]).map(s => (
                                        <button key={s} onClick={() => { setSortBy(s); setOpenDropdown(null); }} className={cn("w-full text-right px-4 py-2 hover:bg-surface-container-low rounded-2xl text-sm font-bold transition-colors", sortBy === s ? "bg-surface-container-low text-primary" : "text-on-surface")}>
                                            {s === 'newest' ? 'الأحدث' : s === 'oldest' ? 'الأقدم' : 'أبجدياً'}
                                        </button>
                                    ))}
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>

                    <div className="relative">
                        <Button
                            variant="ghost"
                            onClick={() => setOpenDropdown(prev => prev === 'date' ? null : 'date')}
                            className="bg-surface-container-lowest hover:bg-surface-container-low border border-surface-container rounded-full px-4 py-2 h-auto text-[11px] font-black uppercase tracking-widest gap-2"
                        >
                            <Calendar className="w-4 h-4" />
                            {dateFilter === 'all' ? 'التاريخ' : dateFilter === 'today' ? 'اليوم' : dateFilter === 'tomorrow' ? 'غداً' : dateFilter === 'upcoming' ? 'القادم' : dateFilter}
                        </Button>
                        <AnimatePresence>
                            {openDropdown === 'date' && (
                                <motion.div
                                    initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 5 }}
                                    className="absolute top-full right-0 mt-2 w-48 bg-white rounded-3xl shadow-xl border border-surface-container p-3 z-50 flex flex-col gap-1"
                                >
                                    {(['all', 'today', 'tomorrow', 'upcoming'] as const).map(s => (
                                        <button key={s} onClick={() => { setDateFilter(s); setOpenDropdown(null); }} className={cn("w-full text-right px-4 py-2 hover:bg-surface-container-low rounded-2xl text-sm font-bold transition-colors", dateFilter === s ? "bg-surface-container-low text-primary" : "text-on-surface")}>
                                            {s === 'all' ? 'الكل' : s === 'today' ? 'اليوم' : s === 'tomorrow' ? 'غداً' : 'القادم'}
                                        </button>
                                    ))}
                                    <div className="pt-2 mt-1 border-t border-surface-container">
                                        <input
                                            type="date"
                                            onChange={(e) => {
                                                if (e.target.value) {
                                                    setDateFilter(e.target.value);
                                                    setOpenDropdown(null);
                                                }
                                            }}
                                            className="w-full text-sm px-3 py-2 rounded-2xl bg-surface-container-lowest border border-surface-container hover:border-primary/50 focus:border-primary outline-none transition-all text-on-surface font-headline font-bold"
                                        />
                                    </div>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </div>
                </div>
            </div>

            {/* Task List */}
            <div className="flex flex-col gap-4 min-h-[400px] px-4 md:px-0 pb-20">
                <AnimatePresence mode="popLayout" initial={false}>
                    {isInitialLoad ? (
                        <div className="flex flex-col items-center justify-center py-20 gap-4 opacity-50">
                            <motion.div
                                animate={{ rotate: 360 }}
                                transition={{ repeat: Infinity, duration: 2, ease: "linear" }}
                                className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full"
                            />
                            <p className="font-bold">جاري تحميل المهام...</p>
                        </div>
                    ) : filteredTasks.length === 0 ? (
                        <div className="flex flex-col items-center justify-center py-20 gap-6 bg-surface-container-low/30 rounded-[3rem] border-2 border-dashed border-surface-container">
                            <img src="/bakiza-cat.png" alt="No tasks" className="w-32 h-32 md:w-40 md:h-40 object-contain drop-shadow-sm opacity-90" />
                            <div className="text-center">
                                <h3 className="text-xl font-headline font-extrabold text-on-surface">لا يوجد مهام حالياً</h3>
                                <p className="text-on-surface-variant font-medium mt-1">ابدأ يومك بإضافة مهمة جديدة بالأسفل!</p>
                            </div>
                        </div>
                    ) : (
                        filteredTasks.map((task, index) => (
                            <div
                                key={task.id}
                                ref={index === filteredTasks.length - 5 ? lastTaskElementRef : null}
                            >
                                <TaskCard
                                    task={task}
                                    onToggle={handleToggleTask}
                                    onDelete={handleDeleteTask}
                                    onClick={(t) => { setSelectedTask(t); setEditedTitle(t.text); setIsDetailsOpen(true); }}
                                />
                            </div>
                        ))
                    )}
                </AnimatePresence>

                {isLoadingMore && (
                    <div className="flex justify-center py-4">
                        <Loader2 className="w-6 h-6 animate-spin text-primary opacity-50" />
                    </div>
                )}
            </div>

            <div className="fixed bottom-0 left-0 right-0 p-4 mb-2 flex flex-col items-center gap-4 z-[100] pointer-events-none">
                {/* Tag Selection Row */}
                <div className="flex items-center gap-2 px-1.0 py-0.5 bg-white/60 backdrop-blur-md border border-surface-container rounded-full pointer-events-auto shadow-sm max-w-[480px] overflow-x-auto no-scrollbar">
                    {availableTags.map(tag => (
                        <button
                            key={tag}
                            type="button"
                            onClick={() => setSelectedTags(prev =>
                                prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]
                            )}
                            className={cn(
                                "px-3.5 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest transition-all truncate max-w-[120px] flex-shrink-0 align-middle",
                                selectedTags.includes(tag)
                                    ? "bg-primary text-white shadow-sm scale-105"
                                    : "bg-surface-container-high text-on-surface-variant hover:bg-surface-container opacity-60"
                            )}
                        >
                            {tag}
                        </button>
                    ))}
                </div>

                <form
                    onSubmit={handleCreateTask}
                    className="w-full max-w-2xl flex gap-3 p-2 bg-white/80 backdrop-blur-xl border-2 border-surface-container rounded-full shadow-2xl pointer-events-auto transition-all focus-within:border-primary/50 focus-within:scale-[1.02]"
                >
                    <Input
                        value={newTaskText}
                        onChange={(e) => setNewTaskText(e.target.value)}
                        placeholder="إضافة مهمة جديدة..."
                        className="bg-transparent border-none shadow-none focus:ring-0 px-6 h-12 font-bold text-right text-lg"
                    />
                    <Button type="submit" disabled={!newTaskText.trim()} className="h-12 w-12 !p-0 !rounded-full shrink-0 shadow-lg">
                        <Plus className="w-6 h-6" />
                    </Button>
                </form>
            </div>

            {/* Detail Modal Overhaul - Full Screen */}
            <Modal
                isOpen={isDetailsOpen}
                onClose={() => { setIsDetailsOpen(false); setIsEditingTitle(false); }}
                title=""
                className="max-w-none w-screen h-screen m-0 rounded-none overflow-y-auto"
            >
                {selectedTask && (
                    <div className="flex flex-col gap-6 md:gap-10 max-w-4xl mx-auto py-6 px-4 md:py-12 md:px-6" dir="rtl">
                        {/* Modal Header */}
                        <header className="flex justify-between items-center">
                            <button
                                onClick={() => { setIsDetailsOpen(false); setIsEditingTitle(false); }}
                                className="flex items-center gap-2 text-on-surface-variant hover:text-primary transition-all font-black text-xs uppercase tracking-widest"
                            >
                                <ArrowLeft className="w-4 h-4 ml-1 rotate-180" /> العودة لمساحة العمل
                            </button>
                            <div className="text-left">
                                <span className="text-[10px] font-black text-on-surface-variant opacity-40 uppercase tracking-[0.2em]">
                                    أنشئت في {format(new Date(selectedTask.created), 'dd MMMM yyyy', { locale: ar })}
                                </span>
                            </div>
                        </header>

                        {/* Main Detail Card */}
                        <div className="relative bg-surface-container-lowest rounded-[2rem] md:rounded-[3rem] p-6 md:p-12 border border-surface-container overflow-hidden group shadow-sm text-right">
                            <div className={cn(
                                "absolute right-0 top-0 bottom-0 w-3",
                                selectedTask.is_completed ? "bg-secondary" : "bg-primary"
                            )} />

                            <div className="flex flex-col gap-8">
                                <div className="flex gap-3 justify-between items-center">
                                    <div className="flex gap-3">
                                        <span className={cn(
                                            "px-4 py-1.5 text-[10px] font-black uppercase tracking-widest rounded-full",
                                            selectedTask.is_completed ? "bg-secondary/10 text-secondary" : "bg-primary/10 text-primary"
                                        )}>
                                            {selectedTask.is_completed ? 'مكتملة' : 'قيد التنفيذ'}
                                        </span>
                                        <span className="px-4 py-1.5 bg-surface-container-high text-on-surface-variant text-[10px] font-black uppercase tracking-widest rounded-full">
                                            تفاصيل المهمة
                                        </span>
                                    </div>

                                    <Button
                                        variant="ghost"
                                        onClick={() => setIsEditingTitle(!isEditingTitle)}
                                        className="w-10 h-10 rounded-full bg-surface-container hover:bg-primary hover:text-white transition-all shadow-sm"
                                    >
                                        <Pencil className="w-5 h-5" />
                                    </Button>
                                </div>

                                {isEditingTitle ? (
                                    <div className="flex flex-col gap-4">
                                        <textarea
                                            value={editedTitle}
                                            onChange={(e) => setEditedTitle(e.target.value)}
                                            onBlur={handleUpdateTaskTitle}
                                            autoFocus
                                            className="text-4xl md:text-6xl font-headline font-extrabold text-on-surface bg-surface-container-low/50 rounded-3xl p-6 border-2 border-primary/20 focus:border-primary outline-none resize-none w-full"
                                            rows={3}
                                        />
                                        <Button onClick={handleUpdateTaskTitle} className="self-end px-8 rounded-full">حفظ التعديلات</Button>
                                    </div>
                                ) : (
                                    <h2 className="text-4xl md:text-6xl font-headline font-extrabold text-on-surface leading-[1.1] tracking-tight break-words whitespace-pre-wrap">
                                        {selectedTask.text}
                                    </h2>
                                )}

                                {/* Tags Management for Selected Task */}
                                <div className="flex flex-wrap gap-2 mt-4 overflow-x-auto no-scrollbar py-2">
                                    <span className="text-[10px] font-black text-on-surface-variant/40 uppercase tracking-widest ml-2 self-center">التصنيفات:</span>
                                    {availableTags.map(tag => {
                                        const isSelected = selectedTask.data?.tags?.includes(tag);
                                        return (
                                            <button
                                                key={tag}
                                                onClick={() => handleToggleTaskTag(selectedTask, tag)}
                                                className={cn(
                                                    "px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest transition-all whitespace-nowrap",
                                                    isSelected
                                                        ? "bg-primary text-white shadow-sm scale-105"
                                                        : "bg-surface-container-high text-on-surface-variant hover:bg-surface-container opacity-60"
                                                )}
                                            >
                                                {tag}
                                            </button>
                                        );
                                    })}
                                </div>
                            </div>
                        </div>

                        {/* Subtasks Section */}
                        <div className="flex flex-col gap-8 px-4 text-right">
                            <div className="flex items-center justify-between">
                                <div className="flex flex-col gap-1">
                                    <h3 className="text-2xl font-headline font-extrabold text-on-surface">المهام الفرعية</h3>
                                    <p className="text-sm font-bold text-on-surface-variant opacity-50">قسم نشاطك إلى خطوات أصغر.</p>
                                </div>
                                <div className="bg-surface-container-low px-4 py-2 rounded-2xl">
                                    <span className="text-xs font-black text-primary">
                                        تم إنجاز {selectedTask.subtasks?.filter(s => s.isCompleted).length || 0} من {selectedTask.subtasks?.length || 0}
                                    </span>
                                </div>
                            </div>

                            <div className="flex flex-col gap-3">
                                {selectedTask.subtasks && selectedTask.subtasks.map((sub) => (
                                    <div
                                        key={sub.id}
                                        className="flex items-center justify-between p-5 bg-surface-container-low/30 rounded-full border border-surface-container group cursor-pointer hover:bg-surface-container-low/50 transition-all ml-0"
                                    >
                                        <div
                                            className="flex items-center gap-5 flex-1"
                                            onClick={() => handleToggleSubtask(sub.id)}
                                        >
                                            <div className={cn(
                                                "w-7 h-7 rounded-full flex items-center justify-center border-2 transition-all",
                                                sub.isCompleted ? "bg-secondary border-secondary text-white" : "border-surface-container bg-white group-hover:border-primary/50"
                                            )}>
                                                {sub.isCompleted && <Check className="w-4 h-4" />}
                                            </div>
                                            <span className={cn("font-bold text-base", sub.isCompleted ? "text-on-surface-variant line-through opacity-50" : "text-on-surface")}>
                                                {sub.text}
                                            </span>
                                        </div>

                                        <div className="flex items-center gap-2">
                                            {sub.description && (
                                                <Button
                                                    variant="ghost"
                                                    className="w-8 h-8 !p-0 rounded-full text-on-surface-variant hover:text-primary"
                                                    title={sub.description}
                                                >
                                                    <FileText className="w-4 h-4" />
                                                </Button>
                                            )}
                                            <Button
                                                variant="ghost"
                                                onClick={() => handleDeleteSubtask(sub.id)}
                                                className="w-8 h-8 !p-0 rounded-full text-on-surface-variant hover:text-error"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </Button>
                                        </div>
                                    </div>
                                ))}

                                {/* Inline Add Subtask Form - Always Visible */}
                                <form
                                    onSubmit={handleAddSubtask}
                                    className="mt-6 flex gap-3 p-2 bg-surface-container-low/50 border-2 border-dashed border-surface-container rounded-full focus-within:border-primary/50 transition-all"
                                >
                                    <Input
                                        value={newSubtaskText}
                                        onChange={(e) => setNewSubtaskText(e.target.value)}
                                        placeholder="إضافة مهمة فرعية جديدة..."
                                        className="bg-transparent border-none shadow-none focus:ring-0 px-6 h-10 font-bold text-right"
                                    />
                                    <Button type="submit" disabled={!newSubtaskText.trim()} className="h-10 w-10 !p-0 !rounded-full shrink-0 shadow-sm">
                                        <Plus className="w-5 h-5" />
                                    </Button>
                                </form>
                            </div>
                        </div>

                        {/* Footer Spacer */}
                        <div className="h-20" />
                    </div>
                )}
            </Modal>

            {/* Tags Management Modal */}
            <AnimatePresence>
                {isTagsModalOpen && (
                    <div className="fixed inset-0 z-[300] flex items-center justify-center p-4 bg-on-surface/20 backdrop-blur-sm" onClick={() => setIsTagsModalOpen(false)}>
                        <motion.div
                            initial={{ opacity: 0, scale: 0.9, y: 20 }}
                            animate={{ opacity: 1, scale: 1, y: 0 }}
                            exit={{ opacity: 0, scale: 0.9, y: 20 }}
                            onClick={(e) => e.stopPropagation()}
                            className="bg-white rounded-[3rem] shadow-2xl p-10 w-full max-w-md flex flex-col gap-8"
                            dir="rtl"
                        >
                            <div className="flex justify-between items-center">
                                <h3 className="text-3xl font-headline font-black text-on-surface tracking-tight">إدارة التصنيفات</h3>
                                <button onClick={() => setIsTagsModalOpen(false)} className="p-2 hover:bg-surface-container rounded-full transition-colors text-on-surface-variant">
                                    <X className="w-6 h-6" />
                                </button>
                            </div>

                            <div className="flex flex-wrap gap-2.5 py-4 border-y border-surface-container max-h-[40vh] overflow-y-auto no-scrollbar pr-1">
                                {availableTags.map(tag => (
                                    <div key={tag} className="flex items-center gap-2.5 px-3 py-0.5 bg-surface-container-low rounded-full border border-surface-container group hover:border-primary/20 transition-all">
                                        <span className="font-bold text-xs text-on-surface">{tag}</span>
                                        <div className="flex items-center gap-1">
                                            <button
                                                onClick={() => handleEditGlobalTag(tag)}
                                                className="p-1 hover:text-primary opacity-30 group-hover:opacity-100 transition-all"
                                            >
                                                <Pencil className="w-3.5 h-3.5" />
                                            </button>
                                            <button
                                                onClick={() => handleDeleteGlobalTag(tag)}
                                                className="p-1 hover:text-red-500 opacity-30 group-hover:opacity-100 transition-all"
                                            >
                                                <Trash2 className="w-3.5 h-3.5" />
                                            </button>
                                        </div>
                                    </div>
                                ))}
                                {availableTags.length === 0 && (
                                    <p className="text-on-surface-variant italic opacity-50 w-full text-center py-4">لا يوجد تصنيفات مضافة حالياً.</p>
                                )}
                            </div>

                            <div className="flex gap-3">
                                <input
                                    autoFocus
                                    placeholder="أضف تصنيفاً جديداً..."
                                    value={newTagInput}
                                    onChange={(e) => setNewTagInput(e.target.value)}
                                    onKeyDown={(e) => e.key === 'Enter' && handleAddGlobalTag()}
                                    className="flex-1 px-8 py-4 bg-surface-container-low rounded-full border-2 border-transparent focus:border-primary/30 outline-none font-bold transition-all placeholder:opacity-50"
                                />
                                <button
                                    onClick={handleAddGlobalTag}
                                    disabled={!newTagInput.trim()}
                                    className="p-4 bg-primary text-white rounded-full shadow-lg hover:shadow-xl hover:scale-105 active:scale-95 transition-all disabled:opacity-50 disabled:shadow-none disabled:scale-100"
                                >
                                    <Plus className="w-6 h-6" />
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
}
