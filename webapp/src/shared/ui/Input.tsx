import React from 'react';
import { cn } from '../lib/cn';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> { }

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
    ({ className, type, ...props }, ref) => {
        return (
            <input
                type={type}
                className={cn(
                    'bg-surface-container-lowest rounded-full px-6 py-3.5 text-on-surface placeholder:text-outline w-full transition-all duration-200 focus:ring-2 focus:ring-primary/20 outline-none border-none',
                    className
                )}
                ref={ref}
                {...props}
            />
        );
    }
);

Input.displayName = 'Input';
