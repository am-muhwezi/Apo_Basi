import { AlertCircle, X } from 'lucide-react';

interface FormErrorProps {
  message: string | null;
  onDismiss?: () => void;
}

export default function FormError({ message, onDismiss }: FormErrorProps) {
  if (!message) return null;

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4">
      <div className="flex items-start gap-3">
        <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
        <p className="flex-1 text-sm text-red-700">{message}</p>
        {onDismiss && (
          <button
            type="button"
            onClick={onDismiss}
            className="p-1 hover:bg-red-100 rounded transition-colors"
          >
            <X className="w-4 h-4 text-red-500" />
          </button>
        )}
      </div>
    </div>
  );
}
