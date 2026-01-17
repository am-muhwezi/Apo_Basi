import { ReactNode } from 'react';

interface CardProps {
  variant?: 'default' | 'glass' | 'gradient';
  className?: string;
  children: ReactNode;
}

export default function Card({ variant = 'default', className = '', children }: CardProps) {
  const variants = {
    default: 'bg-gray-900 border-gray-800',
    glass: 'glass backdrop-blur-sm bg-gray-900/50',
    gradient: 'bg-gradient-to-br from-gray-900 to-gray-800 border-gray-700/50',
  };

  const classes = `rounded-2xl border p-6 ${variants[variant]} ${className}`;

  return <div className={classes}>{children}</div>;
}
