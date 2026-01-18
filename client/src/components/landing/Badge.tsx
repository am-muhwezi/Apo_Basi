import { ReactNode } from 'react';

interface BadgeProps {
  variant?: 'default' | 'success' | 'warning' | 'info';
  className?: string;
  children: ReactNode;
}

export default function Badge({ variant = 'default', className = '', children }: BadgeProps) {
  const variants = {
    default:
      'bg-gray-100 border-gray-300 text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-300',
    success:
      'bg-green-50 border-green-200 text-green-700 dark:bg-orange-500/10 dark:border-orange-500/30 dark:text-orange-300',
    warning:
      'bg-yellow-50 border-yellow-200 text-yellow-700 dark:bg-yellow-500/10 dark:border-yellow-500/30 dark:text-yellow-300',
    info:
      'bg-blue-50 border-blue-200 text-blue-700 dark:bg-blue-500/10 dark:border-blue-500/30 dark:text-blue-300',
  };

  const classes = `inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border ${variants[variant]} ${className}`;

  return <span className={classes}>{children}</span>;
}
