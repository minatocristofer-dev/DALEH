import { Check } from 'lucide-react';

export function Segmented({ options, value, onChange }) {
  return (
    <div className="flex fm-card rounded-2xl p-1 gap-1">
      {options.map((opt) => (
        <button
          key={opt.key}
          onClick={() => onChange(opt.key)}
          className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wide transition-colors fm-tab ${value === opt.key ? 'on' : ''}`}
          style={value === opt.key ? { background: 'var(--surface2)' } : {}}
        >
          <opt.icon size={14} />
          {opt.label}
        </button>
      ))}
    </div>
  );
}

export function ScoreDigits({ step, total }) {
  return (
    <div className="flex items-center gap-2">
      {Array.from({ length: total }).map((_, i) => {
        const n = i + 1;
        const cls = n === step ? 'active' : n < step ? 'done' : '';
        return (
          <div key={i} className={`fm-digit w-8 h-8 rounded-md flex items-center justify-center font-black text-sm ${cls}`}>
            {n < step ? <Check size={14} /> : n}
          </div>
        );
      })}
    </div>
  );
}

export function Field({ label, children }) {
  return (
    <label className="block mb-4">
      <span className="block text-xs font-semibold uppercase tracking-wide mb-1.5" style={{ color: 'var(--muted)' }}>
        {label}
      </span>
      {children}
    </label>
  );
}
