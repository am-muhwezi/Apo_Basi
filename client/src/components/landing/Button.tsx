import { ReactNode } from 'react';
import { Link } from 'react-router-dom';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  href?: string;
  className?: string;
  children: ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
}

export default function Button({
  variant = 'primary',
  size = 'md',
  href,
  className = '',
  children,
  onClick,
  type = 'button',
}: ButtonProps) {
  const baseClasses =
    'inline-flex items-center justify-center font-semibold rounded-full transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 focus:ring-offset-dark-950';

  const variants = {
    primary: 'bg-gradient-to-r from-blue-500 to-blue-600 text-white hover:opacity-90 shadow-lg hover:shadow-xl',
    secondary: 'bg-gray-800 text-white hover:bg-gray-700 border border-gray-700',
    outline: 'border border-gray-600 text-gray-200 hover:bg-gray-800 hover:text-white',
    ghost: 'text-gray-300 hover:text-white hover:bg-gray-800',
  };

  const sizes = {
    sm: 'px-4 py-2 text-sm gap-1.5',
    md: 'px-6 py-2.5 text-sm gap-2',
    lg: 'px-8 py-3 text-base gap-2',
  };

  const classes = `${baseClasses} ${variants[variant]} ${sizes[size]} ${className}`;

  // If href starts with '/', use React Router Link for internal navigation
  // If href starts with '#', use regular anchor for hash links
  // Otherwise use regular anchor for external links
  if (href) {
    if (href.startsWith('/') && !href.startsWith('//')) {
      return (
        <Link to={href} className={classes}>
          {children}
        </Link>
      );
    }
    return (
      <a href={href} className={classes}>
        {children}
      </a>
    );
  }

  return (
    <button type={type} className={classes} onClick={onClick}>
      {children}
    </button>
  );
}
