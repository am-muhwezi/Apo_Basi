import React, { useState, useEffect, useRef } from 'react';
import { Search, X, ChevronDown } from 'lucide-react';

interface Option {
  id: string | number;
  label: string;
  sublabel?: string;
}

interface SearchableSelectProps {
  label: string;
  placeholder?: string;
  options: Option[];
  value: string | number | null;
  onChange: (value: string | number) => void;
  required?: boolean;
  error?: string;
}

export default function SearchableSelect({
  label,
  placeholder = 'Search...',
  options,
  value,
  onChange,
  required = false,
  error,
}: SearchableSelectProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredOptions, setFilteredOptions] = useState<Option[]>([]);
  const containerRef = useRef<HTMLDivElement>(null);

  // Get selected option
  const selectedOption = options.find((opt) => opt.id === value);

  // Filter options based on search
  useEffect(() => {
    if (searchTerm.trim() === '') {
      // Show first 50 results when no search
      setFilteredOptions(options.slice(0, 50));
    } else {
      // Filter by search term
      const filtered = options.filter(
        (opt) =>
          opt.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
          opt.sublabel?.toLowerCase().includes(searchTerm.toLowerCase())
      );
      setFilteredOptions(filtered.slice(0, 50)); // Limit to 50 results
    }
  }, [searchTerm, options]);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setSearchTerm('');
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
      return () => document.removeEventListener('mousedown', handleClickOutside);
    }
  }, [isOpen]);

  const handleSelect = (option: Option) => {
    onChange(option.id);
    setIsOpen(false);
    setSearchTerm('');
  };

  const handleClear = (e: React.MouseEvent) => {
    e.stopPropagation();
    onChange('');
    setSearchTerm('');
  };

  return (
    <div ref={containerRef} className="relative">
      <label className="block text-sm font-medium text-slate-700 mb-2">
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>

      {/* Selected value or search input */}
      <div
        onClick={() => setIsOpen(!isOpen)}
        className={`w-full px-4 py-2 border rounded-lg cursor-pointer flex items-center justify-between transition-colors ${
          isOpen
            ? 'border-blue-500 ring-2 ring-blue-500 ring-opacity-20'
            : error
            ? 'border-red-300'
            : 'border-slate-300 hover:border-slate-400'
        }`}
      >
        {selectedOption ? (
          <div className="flex-1">
            <span className="text-slate-900">{selectedOption.label}</span>
            {selectedOption.sublabel && (
              <span className="text-sm text-slate-500 ml-2">({selectedOption.sublabel})</span>
            )}
          </div>
        ) : (
          <span className="text-slate-400">{placeholder}</span>
        )}

        <div className="flex items-center gap-2">
          {selectedOption && (
            <button
              onClick={handleClear}
              className="text-slate-400 hover:text-slate-600 transition-colors"
              type="button"
            >
              <X size={18} />
            </button>
          )}
          <ChevronDown
            size={18}
            className={`text-slate-400 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          />
        </div>
      </div>

      {error && <p className="text-sm text-red-600 mt-1">{error}</p>}

      {/* Dropdown */}
      {isOpen && (
        <div className="absolute z-50 w-full mt-2 bg-white border border-slate-200 rounded-lg shadow-lg max-h-80 overflow-hidden">
          {/* Search input */}
          <div className="p-2 border-b border-slate-200 sticky top-0 bg-white">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={18} />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Type to search..."
                className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                autoFocus
                onClick={(e) => e.stopPropagation()}
              />
            </div>
          </div>

          {/* Options list */}
          <div className="overflow-y-auto max-h-64">
            {filteredOptions.length === 0 ? (
              <div className="px-4 py-8 text-center text-slate-500">
                <p>No results found</p>
                <p className="text-sm mt-1">Try a different search term</p>
              </div>
            ) : (
              <div className="py-1">
                {filteredOptions.map((option) => (
                  <button
                    key={option.id}
                    onClick={() => handleSelect(option)}
                    className={`w-full px-4 py-2 text-left hover:bg-slate-50 transition-colors ${
                      option.id === value ? 'bg-blue-50 text-blue-700' : 'text-slate-900'
                    }`}
                    type="button"
                  >
                    <div>
                      <span className="font-medium">{option.label}</span>
                      {option.sublabel && (
                        <span className="text-sm text-slate-500 ml-2">({option.sublabel})</span>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            )}

            {/* Show hint if more results exist */}
            {searchTerm && options.length > filteredOptions.length && (
              <div className="px-4 py-2 text-xs text-slate-500 bg-slate-50 border-t border-slate-200">
                Showing {filteredOptions.length} of {options.length} results. Type more to narrow down.
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
