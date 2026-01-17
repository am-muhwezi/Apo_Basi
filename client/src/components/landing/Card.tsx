import { ReactNode } from 'react';

interface CardProps {
  variant?: 'default' | 'glass' | 'gradient';
  className?: string;
  children: ReactNode;
}

export default function Card({ variant = 'default', className = '', children }: CardProps) {
  const variants = {
    default: 'bg-white border-gray-200 dark:bg-gray-900 dark:border-gray-800',
    glass: 'glass backdrop-blur-sm bg-white/80 border-gray-200 shadow-sm dark:bg-gray-900/50 dark:border-gray-700/50',
    gradient:
      'bg-gradient-to-br from-blue-50 to-blue-100 border-blue-100 dark:from-gray-900 dark:to-gray-800 dark:border-gray-700/50',
  };

  const classes = `rounded-2xl border p-6 ${variants[variant]} ${className}`;

  return <div className={classes}>{children}</div>;
}
