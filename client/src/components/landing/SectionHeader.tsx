interface SectionHeaderProps {
  badge?: string;
  title: string;
  description?: string;
  align?: 'left' | 'center';
}

export default function SectionHeader({
  badge,
  title,
  description,
  align = 'center',
}: SectionHeaderProps) {
  const alignClasses = align === 'center' ? 'text-center mx-auto' : 'text-left';

  return (
    <div className={`max-w-3xl mb-12 ${alignClasses}`}>
      {badge && (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-blue-50 border border-blue-200 text-blue-700 mb-4 dark:bg-blue-500/10 dark:border-blue-500/30 dark:text-blue-300">
          {badge}
        </span>
      )}
      <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4 tracking-tight dark:text-white">{title}</h2>
      {description && (
        <p className="text-gray-600 text-lg leading-relaxed dark:text-gray-400">{description}</p>
      )}
    </div>
  );
}
