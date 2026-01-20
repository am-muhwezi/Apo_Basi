
import { AlertCircle, X } from 'lucide-react';


type ErrorMessage = string | null | { [key: string]: string };

interface FormErrorProps {
  message: ErrorMessage;
  onDismiss?: () => void;
}

export default function FormError({ message, onDismiss }: FormErrorProps) {
  if (!message) return null;

  // Helper to render error messages
  const renderMessage = (msg: ErrorMessage) => {
    if (typeof msg === 'string') return msg;
    if (msg && typeof msg === 'object') {
      return Object.entries(msg).map(([field, value]) => {
        // Custom highlight for phone/email errors
        if (field === 'phone') {
          return <span key={field}><b>Phone:</b> {value}</span>;
        }
        if (field === 'email') {
          return <span key={field}><b>Email:</b> {value}</span>;
        }
        return <span key={field}><b>{field}:</b> {value}</span>;
      });
    }
    return null;
  };

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4">
      <div className="flex items-start gap-3">
        <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
        <div className="flex-1 text-sm text-red-700">{renderMessage(message)}</div>
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
