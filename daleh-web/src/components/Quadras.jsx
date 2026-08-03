import { useState } from 'react';
import { Building2, MapPin, Star, Clock, Sun, Car, Beer, Users, Flame, ShoppingBag, DoorOpen } from 'lucide-react';
import { Field } from './shared';

const QUADRAS_INICIAIS = [
  { id: 1, nome: 'Arena Gol de Placa', cidade: 'Santa Maria/RS', preco: 180, rating: 4.8, tags: ['Coberta', 'Iluminação', 'Bar'] },
  { id: 2, nome: 'Society Vila Nova', cidade: 'Santa Maria/RS', preco: 140, rating: 4.5, tags: ['Iluminação', 'Estacionamento'] },
];

const CARACTERISTICAS = [
  { key: 'coberta', label: 'Coberta', icon: DoorOpen },
  { key: 'iluminacao', label: 'Iluminação', icon: Sun },
  { key: 'estacionamento', label: 'Estacionamento', icon: Car },
  { key: 'bar', label: 'Bar', icon: Beer },
  { key: 'vestiario', label: 'Vestiário', icon: Users },
  { key: 'churrasqueira', label: 'Churrasqueira', icon: Flame },
  { key: 'coletes', label: 'Aluguel de coletes', icon: ShoppingBag },
];

// Ainda sem VenuesModule no backend — dados fake, iguais ao protótipo original.
export default function Quadras() {
  const [view, setView] = useState('lista');
  const [quadras, setQuadras] = useState(QUADRAS_INICIAIS);
  const [nome, setNome] = useState('');
  const [cidade, setCidade] = useState('');
  const [preco, setPreco] = useState('');
  const [tags, setTags] = useState([]);

  const toggleTag = (key) => setTags((t) => (t.includes(key) ? t.filter((x) => x !== key) : [...t, key]));

  const salvar = () => {
    if (!nome.trim()) return;
    const labels = CARACTERISTICAS.filter((c) => tags.includes(c.key)).map((c) => c.label);
    setQuadras([{ id: Date.now(), nome, cidade: cidade || 'Não informado', preco: Number(preco) || 0, rating: 0, tags: labels }, ...quadras]);
    setNome(''); setCidade(''); setPreco(''); setTags([]);
    setView('lista');
  };

  return (
    <div>
      <div className="flex gap-2 mb-4">
        <button onClick={() => setView('lista')}
          className={`flex-1 rounded-xl py-2 text-xs font-bold uppercase fm-chip ${view === 'lista' ? 'on' : ''}`}>
          Minhas quadras
        </button>
        <button onClick={() => setView('form')}
          className={`flex-1 rounded-xl py-2 text-xs font-bold uppercase fm-chip ${view === 'form' ? 'on' : ''}`}>
          Cadastrar quadra
        </button>
      </div>

      {view === 'lista' && (
        <div className="space-y-3">
          {quadras.map((q) => (
            <div key={q.id} className="fm-card rounded-2xl p-4">
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="font-black text-sm flex items-center gap-1.5">
                    <Building2 size={15} style={{ color: 'var(--turf)' }} /> {q.nome}
                  </h4>
                  <p className="text-xs flex items-center gap-1 mt-0.5" style={{ color: 'var(--muted)' }}>
                    <MapPin size={12} /> {q.cidade}
                  </p>
                </div>
                {q.rating > 0 && (
                  <div className="flex items-center gap-1 text-xs font-bold" style={{ color: 'var(--amber)' }}>
                    <Star size={12} fill="var(--amber)" /> {q.rating}
                  </div>
                )}
              </div>
              <div className="flex flex-wrap gap-1.5 mt-3">
                {q.tags.map((t) => (
                  <span key={t} className="fm-chip px-2 py-1 rounded-full text-[10px] font-semibold">{t}</span>
                ))}
              </div>
              <div className="flex items-center justify-between mt-3 pt-3" style={{ borderTop: '1px solid var(--line)' }}>
                <span className="font-black text-sm">R$ {q.preco}<span className="text-xs font-normal" style={{ color: 'var(--muted)' }}>/hora</span></span>
                <button className="fm-btn-primary rounded-lg px-3 py-1.5 text-xs font-bold flex items-center gap-1">
                  <Clock size={12} /> Ver agenda
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {view === 'form' && (
        <div className="fm-card rounded-2xl p-5">
          <Field label="Nome da quadra">
            <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Ex: Arena Beira Rio"
              value={nome} onChange={(e) => setNome(e.target.value)} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Cidade/UF">
              <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Cidade/UF"
                value={cidade} onChange={(e) => setCidade(e.target.value)} />
            </Field>
            <Field label="Preço/hora (R$)">
              <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="180"
                value={preco} onChange={(e) => setPreco(e.target.value)} />
            </Field>
          </div>
          <Field label="Características">
            <div className="flex flex-wrap gap-2">
              {CARACTERISTICAS.map((c) => (
                <button key={c.key} onClick={() => toggleTag(c.key)}
                  className={`fm-chip px-3 py-1.5 rounded-full text-xs font-semibold flex items-center gap-1.5 ${tags.includes(c.key) ? 'on' : ''}`}>
                  <c.icon size={12} /> {c.label}
                </button>
              ))}
            </div>
          </Field>
          <button onClick={salvar} className="fm-btn-primary rounded-xl px-4 py-2.5 font-bold text-sm w-full mt-2">
            Salvar quadra
          </button>
        </div>
      )}
    </div>
  );
}
