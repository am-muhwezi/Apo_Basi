
import React from 'react';

type Role = 'parent' | 'driver' | 'admin' | 'assistant';

interface Props {
  activeRole: Role;
  onRoleChange: (role: Role) => void;
}

const RoleSelector: React.FC<Props> = ({ activeRole, onRoleChange }) => {
  const roles: { id: Role; label: string; description: string }[] = [
    { id: 'parent', label: 'For Parents', description: 'Real-time peace of mind.' },
    { id: 'driver', label: 'For Drivers', description: 'Navigation & Route help.' },
    { id: 'assistant', label: 'For Assistants', description: 'Easy attendance logs.' },
    { id: 'admin', label: 'For Schools', description: 'Full fleet oversight.' },
  ];

  return (
    <div className="flex flex-wrap justify-center gap-4">
      {roles.map((role) => (
        <button
          key={role.id}
          onClick={() => onRoleChange(role.id)}
          className={`flex flex-col items-center px-6 py-4 rounded-2xl transition-all border-2 w-full sm:w-48 ${
            activeRole === role.id
              ? 'bg-blue-600 border-blue-600 text-white shadow-lg'
              : 'bg-slate-50 border-slate-100 text-slate-600 hover:border-blue-200'
          }`}
        >
          <span className="text-lg font-bold">{role.label}</span>
          <span className={`text-xs mt-1 ${activeRole === role.id ? 'text-blue-100' : 'text-slate-400'}`}>
            {role.description}
          </span>
        </button>
      ))}
    </div>
  );
};

export default RoleSelector;
