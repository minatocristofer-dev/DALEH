import { useEffect, useState } from 'react';
import { MapPin, Shield, UserPlus, Trash2 } from 'lucide-react';
import { Field } from './shared';
import { listarMeusTimes, criarTime, obterTime, adicionarMembro, removerMembro } from '../lib/api';

// Times reais, conectados na API do DALEH (TeamsModule).
export default function Times() {
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState('');
  const [meusTimes, setMeusTimes] = useState([]);
  const [timeAtivo, setTimeAtivo] = useState(null);

  const [nomeTime, setNomeTime] = useState('');
  const [cidadeTime, setCidadeTime] = useState('');
  const [emailNovoMembro, setEmailNovoMembro] = useState('');

  const carregar = async () => {
    setCarregando(true);
    setErro('');
    try {
      const times = await listarMeusTimes();
      setMeusTimes(times);
      if (times.length > 0) {
        const detalhe = await obterTime(times[0].id);
        setTimeAtivo(detalhe);
      } else {
        setTimeAtivo(null);
      }
    } catch (err) {
      setErro(err.message);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregar();
  }, []);

  const criar = async () => {
    if (!nomeTime.trim()) return;
    setErro('');
    try {
      await criarTime({ name: nomeTime, city: cidadeTime || undefined });
      setNomeTime('');
      setCidadeTime('');
      await carregar();
    } catch (err) {
      setErro(err.message);
    }
  };

  const convidar = async () => {
    if (!emailNovoMembro.trim() || !timeAtivo) return;
    setErro('');
    try {
      await adicionarMembro(timeAtivo.id, { email: emailNovoMembro });
      setEmailNovoMembro('');
      const detalhe = await obterTime(timeAtivo.id);
      setTimeAtivo(detalhe);
    } catch (err) {
      setErro(err.message);
    }
  };

  const remover = async (userId) => {
    if (!timeAtivo) return;
    try {
      await removerMembro(timeAtivo.id, userId);
      const detalhe = await obterTime(timeAtivo.id);
      setTimeAtivo(detalhe);
    } catch (err) {
      setErro(err.message);
    }
  };

  if (carregando) {
    return <div className="fm-card rounded-2xl p-5 text-sm" style={{ color: 'var(--muted)' }}>Carregando…</div>;
  }

  if (!timeAtivo) {
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
        {erro && <p className="fm-error text-xs mb-3">{erro}</p>}
        <button onClick={criar} disabled={!nomeTime.trim()}
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
          {timeAtivo.name.slice(0, 2).toUpperCase()}
        </div>
        <div>
          <h3 className="font-black text-sm">{timeAtivo.name}</h3>
          <p className="text-xs flex items-center gap-1" style={{ color: 'var(--muted)' }}>
            <MapPin size={11} /> {timeAtivo.city || 'Cidade não informada'} · {timeAtivo.members?.length ?? 0} atletas
          </p>
        </div>
      </div>

      <div className="fm-card rounded-2xl p-4">
        <h4 className="font-bold text-xs uppercase tracking-wide mb-3 flex items-center gap-1.5" style={{ color: 'var(--muted)' }}>
          <UserPlus size={14} /> Convidar jogador (precisa já ter conta no DALEH)
        </h4>
        <div className="flex gap-2">
          <input className="fm-input flex-1 rounded-xl px-3 py-2 text-sm" placeholder="E-mail do jogador"
            value={emailNovoMembro} onChange={(e) => setEmailNovoMembro(e.target.value)} />
          <button onClick={convidar} className="fm-btn-primary rounded-xl px-4 py-2 font-bold text-sm">
            Adicionar
          </button>
        </div>
        {erro && <p className="fm-error text-xs mt-2">{erro}</p>}
      </div>

      <div className="fm-card rounded-2xl p-4">
        <h4 className="font-bold text-xs uppercase tracking-wide mb-3" style={{ color: 'var(--muted)' }}>Elenco</h4>
        <div className="space-y-2">
          {(timeAtivo.members || []).map((m) => (
            <div key={m.id} className="flex items-center justify-between rounded-xl px-3 py-2.5" style={{ background: 'var(--surface2)' }}>
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-black"
                  style={{ background: 'var(--line)', color: 'var(--text)' }}>
                  {m.user.fullName.split(' ').map((n) => n[0]).slice(0, 2).join('')}
                </div>
                <p className="text-sm font-semibold leading-tight">{m.user.fullName}</p>
              </div>
              <div className="flex items-center gap-2">
                <span className="fm-chip on px-2 py-0.5 rounded-full text-[10px] font-bold">{m.papel}</span>
                <button onClick={() => remover(m.user.id)} style={{ color: 'var(--danger)' }}>
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
