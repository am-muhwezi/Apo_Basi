import { useState } from 'react';
import { Link } from 'react-router-dom';
import ThemeToggle from './ThemeToggle';

const navLinks = [
  { href: '/#features', label: 'Features' },
  { href: '/#how-it-works', label: 'How it Works' },
  { href: '/download', label: 'Download' },
  { href: '/#contact', label: 'Contact' },
];

export default function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const closeMobileMenu = () => setMobileMenuOpen(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 glass backdrop-blur-sm bg-white/80 border-b border-gray-200/80 dark:bg-gray-900/90 dark:border-gray-800/80">
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2 group">
            <div className="w-9 h-9 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 flex items-center justify-center text-white font-bold text-sm shadow-lg group-hover:scale-105 transition-transform">
              AB
            </div>
            <span className="font-bold text-lg text-gray-900 dark:text-white tracking-tight">ApoBasi</span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-8">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors text-sm font-medium"
              >
                {link.label}
              </a>
            ))}
          </div>

          {/* CTA Buttons & Theme Toggle */}
          <div className="hidden md:flex items-center gap-3">
            <ThemeToggle />
            <Link
              to="/admin/login"
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900 border border-gray-300 rounded-full hover:border-gray-400 dark:text-gray-300 dark:hover:text-white dark:border-gray-700 dark:hover:border-gray-500 transition-all"
            >
              Admin Sign In
            </Link>
            <a
              href="/#contact"
              className="px-4 py-2 text-sm font-semibold text-white bg-gradient-to-r from-blue-500 to-blue-600 rounded-full hover:opacity-90 transition-opacity shadow-lg"
            >
              Request Demo
            </a>
          </div>

          {/* Mobile Menu Button */}
          <div className="flex md:hidden items-center gap-2">
            <ThemeToggle />
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white"
              aria-label="Toggle menu"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M4 6h16M4 12h16M4 18h16"
                />
              </svg>
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden pb-4">
            <div className="flex flex-col gap-2 pt-4 border-t border-gray-200 dark:border-gray-800">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  onClick={closeMobileMenu}
                  className="px-4 py-2 text-gray-700 hover:text-gray-900 hover:bg-gray-100 rounded-lg dark:text-gray-300 dark:hover:text-white dark:hover:bg-gray-800 transition-colors"
                >
                  {link.label}
                </a>
              ))}
              <div className="flex flex-col gap-2 mt-4 px-4">
                <Link
                  to="/admin/login"
                  onClick={closeMobileMenu}
                  className="py-2 text-center text-sm font-medium text-gray-700 border border-gray-300 rounded-full dark:text-gray-300 dark:border-gray-700"
                >
                  Admin Sign In
                </Link>
                <a
                  href="/#contact"
                  onClick={closeMobileMenu}
                  className="py-2 text-center text-sm font-semibold text-white bg-gradient-to-r from-blue-500 to-blue-600 rounded-full"
                >
                  Request Demo
                </a>
              </div>
            </div>
          </div>
        )}
      </nav>
    </header>
  );
}
