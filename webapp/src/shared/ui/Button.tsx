import React from 'react';
import { motion, type HTMLMotionProps } from 'framer-motion';
import { cn } from '../lib/cn';

interface ButtonProps extends Omit<HTMLMotionProps<"button">, 'ref'> {
    variant?: 'primary' | 'outline' | 'ghost' | 'bakiza';
    isLoading?: boolean;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
    ({ className, variant = 'primary', isLoading, children, ...props }, ref) => {
        return (
            <motion.button
                ref={ref}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.95 }}
                disabled={isLoading || props.disabled}
                className={cn(
                    'font-bold rounded-full px-6 py-4 flex items-center justify-center gap-2 transition-all duration-200 disabled:opacity-50 select-none shadow-none',
                    {
                        'bg-primary text-white hover:bg-primary/90': variant === 'primary',
                        'bg-surface-container-high text-on-surface hover:bg-surface-container-highest': variant === 'outline',
                        'bg-transparent text-on-surface-variant hover:bg-surface-container-low hover:text-primary': variant === 'ghost',
                    },
                    className
                )}
                {...props}
            >
                {isLoading ? (
                    <div className="flex items-center gap-2">
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        <span>جاري التحميل...</span>
                    </div>
                ) : (
                    children
                )}
            </motion.button>
        );
    }
);

Button.displayName = 'Button';
