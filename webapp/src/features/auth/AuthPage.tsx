import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { pb } from '../../core/services/pocketbase';
import { Button } from '../../shared/ui/Button';

export default function AuthPage() {
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleGoogleLogin = async () => {
        setIsLoading(true);
        setError('');

        try {
            console.log('Initiating Google OAuth2 login...');
            const authData = await pb.collection('users').authWithOAuth2({ provider: 'google' });
            console.log('Auth successful:', authData);

            if (pb.authStore.isValid) {
                console.log('AuthStore is valid, navigating to home');
                navigate('/');
            } else {
                console.warn('Auth successful but AuthStore is NOT valid');
                setError('حدث خطأ في تحديث بيانات الجلسة. يرجى المحاولة مرة أخرى.');
            }
        } catch (err: any) {
            console.error('Login error detail:', err);
            setError(`فشل تسجيل الدخول: ${err.message || 'خطأ غير معروف'}`);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex flex-col items-center justify-center min-h-screen px-4 bg-background overflow-hidden relative">
            {/* Animated Background Orbs */}
            <motion.div
                animate={{
                    scale: [1, 1.2, 1],
                    x: [0, 50, 0],
                    y: [0, 30, 0]
                }}
                transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
                className="absolute -top-24 -left-24 w-96 h-96 bg-primary/5 blur-[100px] rounded-full"
            />
            <motion.div
                animate={{
                    scale: [1, 1.3, 1],
                    x: [0, -40, 0],
                    y: [0, -50, 0]
                }}
                transition={{ duration: 12, repeat: Infinity, ease: "easeInOut" }}
                className="absolute -bottom-32 -right-32 w-[30rem] h-[30rem] bg-secondary/5 blur-[120px] rounded-full"
            />

            <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, ease: "circOut" }}
                className="w-full max-w-md p-10 bg-surface-container-lowest rounded-[4rem] border-4 border-surface-container flex flex-col items-center relative z-10"
            >
                <motion.img
                    initial={{ scale: 0.8 }}
                    animate={{ scale: 1 }}
                    whileHover={{ rotate: [0, -10, 10, 0] }}
                    src="/bakiza_mascot.png"
                    alt="Bakiza"
                    className="w-40 h-40 mb-8 object-contain cursor-pointer"
                />
                <h2 className="text-5xl font-black mb-3 text-center text-on-surface tracking-tight">بكيزة</h2>
                <p className="text-on-surface-variant font-bold text-lg text-center mb-10">خطط يومك مع بكيزة 🐾</p>

                {error && (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="bg-destructive/10 text-destructive p-4 rounded-2xl mb-8 text-sm font-bold text-center w-full border border-destructive/20"
                    >
                        {error}
                    </motion.div>
                )}

                <div className="flex flex-col gap-4 w-full">
                    <Button
                        onClick={handleGoogleLogin}
                        isLoading={isLoading}
                        className="w-full h-16 flex items-center gap-4 justify-center bg-surface-container-lowest border-4 border-surface-container text-on-surface hover:bg-surface-container transition-all rounded-[2rem]"
                    >
                        <svg className="w-7 h-7" viewBox="0 0 24 24">
                            <path
                                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                                fill="#4285F4"
                            />
                            <path
                                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                                fill="#34A853"
                            />
                            <path
                                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
                                fill="#FBBC05"
                            />
                            <path
                                d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 12-4.53z"
                                fill="#EA4335"
                            />
                        </svg>
                        <span className="font-black text-lg">تسجيل الدخول باستخدام جوجل</span>
                    </Button>
                </div>
            </motion.div>
        </div>
    );
}
