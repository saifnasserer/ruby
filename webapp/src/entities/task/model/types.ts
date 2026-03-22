export type Subtask = {
    id: string;
    text: string;
    description?: string;
    isCompleted: boolean;
    createdAt: string;
};

export type Task = {
    id: string;
    text: string;
    is_completed: boolean;
    day_of_week: string;
    user: string;
    created: string;
    updated: string;
    data?: string | any;
    subtasks?: Subtask[];
};
