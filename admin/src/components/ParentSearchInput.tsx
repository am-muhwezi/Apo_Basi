import React, { useState, useEffect, useRef } from 'react';
import { Search, X, User } from 'lucide-react';
import { config } from '../config/environment';

interface Parent {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
}

interface ParentSearchInputProps {
  value?: string;
  selectedParent?: Parent | null;
  onChange: (parentId: string, parent: Parent | null) => void;
  label?: string;
  placeholder?: string;
  required?: boolean;
}

export default function ParentSearchInput({
  value,
  selectedParent,
  onChange,
  label = 'Parent',
  placeholder = 'Search parent by name, email, or phone...',
  required = false,
}: ParentSearchInputProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [results, setResults] = useState<Parent[]>([]);
  const [loading, setLoading] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);
  const [selected, setSelected] = useState<Parent | null>(selectedParent || null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const timeoutRef = useRef<NodeJS.Timeout>();

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowDropdown(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Search parents when query changes
  useEffect(() => {
    if (!searchQuery.trim()) {
      setResults([]);
      setShowDropdown(false);
      return;
    }

    // Debounce search
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(async () => {
      try {
        setLoading(true);
        const response = await fetch(
          `${config.apiBaseUrl}/api/parents/search/?q=${encodeURIComponent(searchQuery)}`,
          {
            headers: {
              'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
            },
          }
        );
        const data = await response.json();
        setResults(data.results || []);
        setShowDropdown(true);
      } catch (error) {
        console.error('Failed to search parents:', error);
        setResults([]);
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, [searchQuery]);

  const handleSelect = (parent: Parent) => {
    setSelected(parent);
    setSearchQuery('');
    setShowDropdown(false);
    onChange(parent.id, parent);
  };

  const handleClear = () => {
    setSelected(null);
    setSearchQuery('');
    onChange('', null);
  };

  return (
    <div className="space-y-1">
      {label && (
        <label className="block text-sm font-medium text-slate-700">
          {label}
          {required && <span className="text-red-500 ml-1">*</span>}
        </label>
      )}

      {selected ? (
        // Show selected parent
        <div className="relative">
          <div className="flex items-center justify-between px-4 py-2 border border-slate-300 rounded-lg bg-blue-50">
            <div className="flex items-center gap-2">
              <div className="p-1 bg-blue-100 rounded">
                <User className="w-4 h-4 text-blue-600" />
              </div>
              <div>
                <p className="text-sm font-medium text-slate-900">
                  {selected.firstName} {selected.lastName}
                </p>
                <p className="text-xs text-slate-600">{selected.email || selected.phone}</p>
              </div>
            </div>
            <button
              type="button"
              onClick={handleClear}
              className="p-1 hover:bg-blue-100 rounded text-slate-500 hover:text-slate-700"
            >
              <X size={18} />
            </button>
          </div>
        </div>
      ) : (
        // Show search input
        <div className="relative" ref={dropdownRef}>
          <div className="relative">
            <Search
              className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400"
              size={18}
            />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onFocus={() => {
                if (results.length > 0) setShowDropdown(true);
              }}
              placeholder={placeholder}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required={required && !selected}
            />
          </div>

          {/* Dropdown */}
          {showDropdown && (
            <div className="absolute z-10 w-full mt-1 bg-white border border-slate-200 rounded-lg shadow-lg max-h-60 overflow-auto">
              {loading ? (
                <div className="p-3 text-center text-slate-500">
                  <div className="inline-block animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>
                  <span className="ml-2">Searching...</span>
                </div>
              ) : results.length > 0 ? (
                results.map((parent) => (
                  <button
                    key={parent.id}
                    type="button"
                    onClick={() => handleSelect(parent)}
                    className="w-full px-4 py-2 text-left hover:bg-slate-50 flex items-start gap-2 border-b border-slate-100 last:border-b-0"
                  >
                    <div className="p-1 bg-slate-100 rounded mt-0.5">
                      <User className="w-4 h-4 text-slate-600" />
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-slate-900">
                        {parent.firstName} {parent.lastName}
                      </p>
                      <p className="text-xs text-slate-600">
                        {parent.email && <span>{parent.email}</span>}
                        {parent.email && parent.phone && <span> • </span>}
                        {parent.phone && <span>{parent.phone}</span>}
                      </p>
                    </div>
                  </button>
                ))
              ) : (
                <div className="p-3 text-center text-slate-500 text-sm">
                  {searchQuery ? 'No parents found' : 'Start typing to search...'}
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
