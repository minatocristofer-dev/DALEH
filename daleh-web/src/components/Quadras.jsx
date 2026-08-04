import { useEffect, useState } from 'react';
import { Building2, MapPin, Star, DoorOpen, Car, Beer, Users, ShoppingBag } from 'lucide-react';
import { Field } from './shared';
import { listarMinhasQuadras, criarQuadra } from '../lib/api';

const CARACTERISTICAS = [
  { key: 'covered', label: 'Coberta', icon: DoorOpen },
  { key: 'hasParking', label: 'Estacionamento', icon: Car },
  { key: 'hasBar', label: 'Bar', icon: Beer },
  { key: 'hasLockerRoom', label: 'Vestiário', icon: Users },
  { key: 'rentsVests', label: 'Aluguel de coletes', icon: ShoppingBag },
];

function tagsDaQuadra(q) {
  return CARACTERISTICAS.filter((c) => q[c.key]).map((c) => c.label);
}

// Quadras reais, conectadas na API do DALEH (VenuesModule) — mostra as
// quadras que o usuário logado é dono. Reserva/agenda ainda não tem tela
// aqui, é o próximo passo natural quando o app ganhar navegação de verdade.
export default function Quadras() {
  const [view, setView] = useState('lista');
  const [quadras, setQuadras] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState('');

  const [nome, setNome] = useState('');
  const [endereco, setEndereco] = useState('');
  const [preco, setPreco] = useState('');
  const [tags, setTags] = useState([]);

  const carregar = async () => {
    setCarregando(true);
    setErro('');
    try {
      setQuadras(await listarMinhasQuadras());
    } catch (err) {
      setErro(err.message);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregar();
  }, []);

  const toggleTag = (key) => setTags((t) => (t.includes(key) ? t.filter((x) => x !== key) : [...t, key]));

  const salvar = async () => {
    if (!nome.trim()) return;
    setErro('');
    try {
      const dto = { name: nome, address: endereco || undefined, pricePerHour: preco ? Number(preco) : undefined };
      tags.forEach((k) => { dto[k] = true; });
      await criarQuadra(dto);
      setNome(''); setEndereco(''); setPreco(''); setTags([]);
      setView('lista');
      await carregar();
    } catch (err) {
      setErro(err.message);
    }
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

      {erro && <p className="fm-error text-xs mb-3">{erro}</p>}

      {view === 'lista' && (
        <div className="space-y-3">
          {carregando && <p className="text-sm" style={{ color: 'var(--muted)' }}>Carregando…</p>}
          {!carregando && quadras.length === 0 && (
            <p className="text-sm" style={{ color: 'var(--muted)' }}>Você ainda não tem quadras cadastradas.</p>
          )}
          {quadras.map((q) => (
            <div key={q.id} className="fm-card rounded-2xl p-4">
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="font-black text-sm flex items-center gap-1.5">
                    <Building2 size={15} style={{ color: 'var(--turf)' }} /> {q.name}
                  </h4>
                  <p className="text-xs flex items-center gap-1 mt-0.5" style={{ color: 'var(--muted)' }}>
                    <MapPin size={12} /> {q.address || 'Endereço não informado'}
                  </p>
                </div>
                {q.avgRating > 0 && (
                  <div className="flex items-center gap-1 text-xs font-bold" style={{ color: 'var(--amber)' }}>
                    <Star size={12} fill="var(--amber)" /> {q.avgRating}
                  </div>
                )}
              </div>
              <div className="flex flex-wrap gap-1.5 mt-3">
                {tagsDaQuadra(q).map((t) => (
                  <span key={t} className="fm-chip px-2 py-1 rounded-full text-[10px] font-semibold">{t}</span>
                ))}
              </div>
              {q.pricePerHour && (
                <div className="flex items-center justify-between mt-3 pt-3" style={{ borderTop: '1px solid var(--line)' }}>
                  <span className="font-black text-sm">R$ {q.pricePerHour}<span className="text-xs font-normal" style={{ color: 'var(--muted)' }}>/hora</span></span>
                </div>
              )}
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
            <Field label="Endereço">
              <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Rua, Cidade/UF"
                value={endereco} onChange={(e) => setEndereco(e.target.value)} />
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
