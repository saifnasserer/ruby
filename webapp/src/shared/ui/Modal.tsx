import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import { Button } from './Button';
import { cn } from '../lib/cn';

interface ModalProps {
    isOpen: boolean;
    onClose: () => void;
    title?: string;
    children: React.ReactNode;
    className?: string;
}

export default function Modal({ isOpen, onClose, title, children, className }: ModalProps) {
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
        }
        return () => {
            document.body.style.overflow = 'unset';
        };
    }, [isOpen]);

    return (
        <AnimatePresence>
            {isOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    {/* Backdrop */}
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="absolute inset-0 bg-text-primary/10 backdrop-blur-sm transition-opacity"
                        onClick={onClose}
                    />

                    {/* Modal Content */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 10 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 10 }}
                        transition={{ type: 'spring', damping: 30, stiffness: 400 }}
                        className={cn(
                            "relative bg-surface-container-lowest w-full max-w-lg rounded-[3rem] p-8 overflow-hidden shadow-none border border-surface-container",
                            className
                        )}
                    >
                        <div className="relative z-10">
                            {title && (
                                <div className="flex justify-between items-center mb-6">
                                    <h3 className="text-2xl font-headline font-extrabold text-on-surface">{title}</h3>
                                    <Button
                                        variant="ghost"
                                        onClick={onClose}
                                        className="p-2 !rounded-full hover:bg-surface-container-low transition-transform hover:rotate-90"
                                    >
                                        <X className="w-5 h-5 text-on-surface-variant" />
                                    </Button>
                                </div>
                            )}
                            <div className="text-on-surface font-body">
                                {children}
                            </div>
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
}
