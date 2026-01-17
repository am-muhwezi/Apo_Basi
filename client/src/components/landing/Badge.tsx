import { ReactNode } from 'react';

interface BadgeProps {
  variant?: 'default' | 'success' | 'warning' | 'info';
  className?: string;
  children: ReactNode;
}

export default function Badge({ variant = 'default', className = '', children }: BadgeProps) {
  const variants = {
    default: 'bg-gray-800 border-gray-700 text-gray-300',
    success: 'bg-orange-500/10 border-orange-500/30 text-orange-300',
    warning: 'bg-yellow-500/10 border-yellow-500/30 text-yellow-300',
    info: 'bg-blue-500/10 border-blue-500/30 text-blue-300',
  };

  const classes = `inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border ${variants[variant]} ${className}`;

  return <span className={classes}>{children}</span>;
}
