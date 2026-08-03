import { useState } from 'react';
import { MapPin, Shield, UserPlus, Plus, Trash2 } from 'lucide-react';
import { Field } from './shared';

const POSICOES = ['Goleiro', 'Zagueiro', 'Lateral', 'Volante', 'Meia', 'Atacante'];

const ELENCO_INICIAL = [
  { id: 1, nome: 'João Silva', posicao: 'Atacante', papel: 'Capitão' },
  { id: 2, nome: 'Marcos Lima', posicao: 'Zagueiro', papel: 'Jogador' },
  { id: 3, nome: 'Pedro Alves', posicao: 'Goleiro', papel: 'Tesoureiro' },
];

// Ainda sem TeamsModule no backend — dados fake, iguais ao protótipo original.
export default function Times() {
  const [criado, setCriado] = useState(true);
  const [nomeTime, setNomeTime] = useState('Furacão FC');
  const [cidadeTime, setCidadeTime] = useState('Santa Maria/RS');
  const [elenco, setElenco] = useState(ELENCO_INICIAL);
  const [novoNome, setNovoNome] = useState('');
  const [novaPos, setNovaPos] = useState('Meia');
  const [novoPapel, setNovoPapel] = useState('Jogador');

  const adicionar = () => {
    if (!novoNome.trim()) return;
    setElenco([...elenco, { id: Date.now(), nome: novoNome, posicao: novaPos, papel: novoPapel }]);
    setNovoNome('');
  };
  const remover = (id) => setElenco(elenco.filter((m) => m.id !== id));

  if (!criado) {
    return (
      <div className="fm-card rounded-2xl p-5">
        <h3 className="font-black text-base mb-4 flex items-center gap-2">
          <Shield size={18} style={{ color: 'var(--turf)' }} /> Criar time
        </h3>
        <Field label="Nome do time">
          <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Ex: Furacão FC"
            value={nomeTime} onChange={(e) => setNomeTime(e.target.value)} />
        </Field>
        <Field label="Cidade/UF">
          <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Cidade/UF"
            value={cidadeTime} onChange={(e) => setCidadeTime(e.target.value)} />
        </Field>
        <button onClick={() => setCriado(true)} disabled={!nomeTime.trim()}
          className="fm-btn-primary rounded-xl px-4 py-2.5 font-bold text-sm w-full mt-2">
          Criar time
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="fm-card rounded-2xl p-4 flex items-center gap-3">
        <div className="w-12 h-12 rounded-xl flex items-center justify-center font-black text-lg"
          style={{ background: 'var(--turf)', color: '#08130E' }}>
          {nomeTime.slice(0, 2).toUpperCase()}
        </div>
        <div>
          <h3 className="font-black text-sm">{nomeTime}</h3>
          <p className="text-xs flex items-center gap-1" style={{ color: 'var(--muted)' }}>
            <MapPin size={11} /> {cidadeTime} · {elenco.length} atletas
          </p>
        </div>
      </div>

      <div className="fm-card rounded-2xl p-4">
        <h4 className="font-bold text-xs uppercase tracking-wide mb-3 flex items-center gap-1.5" style={{ color: 'var(--muted)' }}>
          <UserPlus size={14} /> Convidar jogador
        </h4>
        <div className="flex gap-2 mb-2">
          <input className="fm-input flex-1 rounded-xl px-3 py-2 text-sm" placeholder="Nome do jogador"
            value={novoNome} onChange={(e) => setNovoNome(e.target.value)} />
        </div>
        <div className="flex gap-2">
          <select className="fm-input flex-1 rounded-xl px-2 py-2 text-xs" value={novaPos} onChange={(e) => setNovaPos(e.target.value)}>
            {POSICOES.map((p) => <option key={p} value={p}>{p}</option>)}
          </select>
          <select className="fm-input flex-1 rounded-xl px-2 py-2 text-xs" value={novoPapel} onChange={(e) => setNovoPapel(e.target.value)}>
            {['Jogador', 'Capitão', 'Vice-capitão', 'Tesoureiro'].map((p) => <option key={p} value={p}>{p}</option>)}
          </select>
          <button onClick={adicionar} className="fm-btn-primary rounded-xl px-3 py-2 font-bold flex items-center">
            <Plus size={16} />
          </button>
        </div>
      </div>

      <div className="fm-card rounded-2xl p-4">
        <h4 className="font-bold text-xs uppercase tracking-wide mb-3" style={{ color: 'var(--muted)' }}>Elenco</h4>
        <div className="space-y-2">
          {elenco.map((m) => (
            <div key={m.id} className="flex items-center justify-between rounded-xl px-3 py-2.5" style={{ background: 'var(--surface2)' }}>
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-black"
                  style={{ background: 'var(--line)', color: 'var(--text)' }}>
                  {m.nome.split(' ').map((n) => n[0]).slice(0, 2).join('')}
                </div>
                <div>
                  <p className="text-sm font-semibold leading-tight">{m.nome}</p>
                  <p className="text-[11px]" style={{ color: 'var(--muted)' }}>{m.posicao}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span className="fm-chip on px-2 py-0.5 rounded-full text-[10px] font-bold">{m.papel}</span>
                <button onClick={() => remover(m.id)} style={{ color: 'var(--danger)' }}>
                  <Trash2 size={14} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
