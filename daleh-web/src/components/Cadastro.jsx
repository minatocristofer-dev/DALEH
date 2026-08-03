import { useState, useEffect } from 'react';
import { User, Shield, Camera, Check, ChevronRight, ChevronLeft } from 'lucide-react';
import { Field, ScoreDigits } from './shared';
import { registrar } from '../lib/api';
import { salvarToken, salvarPerfilCache } from '../lib/auth';

const ESTADOS = ['RS', 'SP', 'RJ', 'MG', 'PR', 'SC', 'BA'];

const MODALIDADES = [
  { key: 'futsal', label: 'Futsal', posicoes: ['Goleiro', 'Fixo', 'Ala', 'Pivô'] },
  { key: 'society', label: 'Society/Campo 7', posicoes: ['Goleiro', 'Zagueiro', 'Lateral', 'Meia', 'Atacante'] },
  { key: 'campo11', label: 'Campo 11', posicoes: ['Goleiro', 'Zagueiro', 'Lateral', 'Volante', 'Meia', 'Atacante'] },
];

function posicoesPorModalidades(chaves) {
  const selecionadas = MODALIDADES.filter((m) => chaves.includes(m.key));
  const base = selecionadas.length ? selecionadas : MODALIDADES;
  const unicas = [];
  base.forEach((m) => m.posicoes.forEach((p) => { if (!unicas.includes(p)) unicas.push(p); }));
  return unicas;
}

export default function Cadastro({ onCadastrado, onIrParaLogin }) {
  const [step, setStep] = useState(1);
  const [carregando, setCarregando] = useState(false);
  const [erro, setErro] = useState('');
  const [form, setForm] = useState({
    nome: '', email: '', senha: '', telefone: '', cidade: '', estado: 'RS',
    modalidades: ['campo11'],
    posicao: 'Atacante', posicaoSec: 'Meia', pe: 'Direito',
    consentimento: false,
  });

  const posicoesDisponiveis = posicoesPorModalidades(form.modalidades);

  useEffect(() => {
    setForm((f) => {
      const disponiveis = posicoesPorModalidades(f.modalidades);
      const posicao = disponiveis.includes(f.posicao) ? f.posicao : disponiveis[0];
      const posicaoSec = disponiveis.includes(f.posicaoSec) ? f.posicaoSec : disponiveis[1] || disponiveis[0];
      if (posicao === f.posicao && posicaoSec === f.posicaoSec) return f;
      return { ...f, posicao, posicaoSec };
    });
  }, [form.modalidades]);

  const toggleModalidade = (key) => setForm((f) => {
    const ja = f.modalidades.includes(key);
    const modalidades = ja ? f.modalidades.filter((k) => k !== key) : [...f.modalidades, key];
    return { ...f, modalidades: modalidades.length ? modalidades : f.modalidades };
  });

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });
  const next = () => { setErro(''); setStep((s) => Math.min(3, s + 1)); };
  const back = () => setStep((s) => Math.max(1, s - 1));

  const concluir = async () => {
    setErro('');
    if (!form.consentimento) {
      setErro('Você precisa aceitar o consentimento de dados sensíveis pra continuar.');
      return;
    }
    setCarregando(true);
    try {
      const { accessToken } = await registrar({
        fullName: form.nome,
        email: form.email,
        password: form.senha,
        phone: form.telefone || undefined,
        city: form.cidade || undefined,
        state: form.estado || undefined,
        dominantFoot: form.pe,
        modalidades: form.modalidades.map((k) => ({
          modalidade: k.toUpperCase(),
          posicaoPrincipal: form.posicao,
          posicaoSecundaria: form.posicaoSec,
        })),
        consentimentoDadosSensiveis: form.consentimento,
      });
      salvarToken(accessToken);
      salvarPerfilCache({ fullName: form.nome, email: form.email });
      onCadastrado();
    } catch (err) {
      setErro(err.message);
    } finally {
      setCarregando(false);
    }
  };

  return (
    <div className="fm-card rounded-2xl p-5">
      <div className="flex items-center justify-between mb-6">
        <ScoreDigits step={step} total={3} />
        <span className="text-xs font-bold uppercase" style={{ color: 'var(--muted)' }}>Passo {step}/3</span>
      </div>

      {step === 1 && (
        <div>
          <h3 className="font-black text-base mb-4 flex items-center gap-2">
            <User size={18} style={{ color: 'var(--turf)' }} /> Dados básicos
          </h3>
          <Field label="Nome completo">
            <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Seu nome"
              value={form.nome} onChange={set('nome')} />
          </Field>
          <Field label="E-mail">
            <input type="email" className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="voce@exemplo.com"
              value={form.email} onChange={set('email')} />
          </Field>
          <Field label="Senha">
            <input type="password" className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Mínimo 8 caracteres"
              value={form.senha} onChange={set('senha')} />
          </Field>
          <Field label="Telefone">
            <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="(00) 00000-0000"
              value={form.telefone} onChange={set('telefone')} />
          </Field>
          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2">
              <Field label="Cidade">
                <input className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" placeholder="Sua cidade"
                  value={form.cidade} onChange={set('cidade')} />
              </Field>
            </div>
            <Field label="UF">
              <select className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm" value={form.estado} onChange={set('estado')}>
                {ESTADOS.map((uf) => <option key={uf} value={uf}>{uf}</option>)}
              </select>
            </Field>
          </div>
        </div>
      )}

      {step === 2 && (
        <div>
          <h3 className="font-black text-base mb-4 flex items-center gap-2">
            <Shield size={18} style={{ color: 'var(--turf)' }} /> Perfil esportivo
          </h3>
          <Field label="Modalidades que joga">
            <div className="flex flex-wrap gap-2">
              {MODALIDADES.map((m) => (
                <button key={m.key} onClick={() => toggleModalidade(m.key)}
                  className={`fm-chip px-3 py-1.5 rounded-full text-xs font-semibold ${form.modalidades.includes(m.key) ? 'on' : ''}`}>
                  {m.label}
                </button>
              ))}
            </div>
          </Field>
          <Field label="Posição principal">
            <div className="flex flex-wrap gap-2">
              {posicoesDisponiveis.map((p) => (
                <button key={p} onClick={() => setForm({ ...form, posicao: p })}
                  className={`fm-chip px-3 py-1.5 rounded-full text-xs font-semibold ${form.posicao === p ? 'on' : ''}`}>
                  {p}
                </button>
              ))}
            </div>
          </Field>
          <Field label="Posição secundária">
            <div className="flex flex-wrap gap-2">
              {posicoesDisponiveis.map((p) => (
                <button key={p} onClick={() => setForm({ ...form, posicaoSec: p })}
                  className={`fm-chip px-3 py-1.5 rounded-full text-xs font-semibold ${form.posicaoSec === p ? 'on' : ''}`}>
                  {p}
                </button>
              ))}
            </div>
          </Field>
          <Field label="Pé dominante">
            <div className="flex gap-2">
              {['Direito', 'Esquerdo', 'Ambos'].map((p) => (
                <button key={p} onClick={() => setForm({ ...form, pe: p })}
                  className={`fm-chip px-3 py-1.5 rounded-full text-xs font-semibold ${form.pe === p ? 'on' : ''}`}>
                  {p}
                </button>
              ))}
            </div>
          </Field>
        </div>
      )}

      {step === 3 && (
        <div>
          <h3 className="font-black text-base mb-4 flex items-center gap-2">
            <Camera size={18} style={{ color: 'var(--turf)' }} /> Revisão e consentimento
          </h3>
          <div className="fm-input rounded-xl p-4 text-sm space-y-1.5 mb-4" style={{ borderStyle: 'solid' }}>
            <p><span style={{ color: 'var(--muted)' }}>Nome: </span>{form.nome || '—'}</p>
            <p><span style={{ color: 'var(--muted)' }}>E-mail: </span>{form.email || '—'}</p>
            <p><span style={{ color: 'var(--muted)' }}>Cidade: </span>{form.cidade || '—'}/{form.estado}</p>
            <p><span style={{ color: 'var(--muted)' }}>Modalidades: </span>
              {form.modalidades.map((k) => MODALIDADES.find((m) => m.key === k)?.label).join(', ')}
            </p>
            <p><span style={{ color: 'var(--muted)' }}>Posição: </span>{form.posicao} · {form.posicaoSec}</p>
            <p><span style={{ color: 'var(--muted)' }}>Pé: </span>{form.pe}</p>
          </div>

          <label className="flex items-start gap-2.5 mb-4 cursor-pointer">
            <input
              type="checkbox"
              className="mt-1"
              checked={form.consentimento}
              onChange={(e) => setForm({ ...form, consentimento: e.target.checked })}
            />
            <span className="text-xs" style={{ color: 'var(--muted)' }}>
              Autorizo o uso dos meus dados esportivos (posição, estatísticas, localização de jogos)
              conforme a LGPD, separado do aceite geral dos termos de uso.
            </span>
          </label>

          {erro && <p className="fm-error text-xs mb-3">{erro}</p>}
        </div>
      )}

      {erro && step !== 3 && <p className="fm-error text-xs mt-2">{erro}</p>}

      <div className="flex gap-3 mt-6">
        {step > 1 && (
          <button onClick={back} className="fm-input rounded-xl px-4 py-2.5 font-bold text-sm flex items-center gap-1">
            <ChevronLeft size={16} /> Voltar
          </button>
        )}
        <button
          onClick={step === 3 ? concluir : next}
          disabled={carregando}
          className="fm-btn-primary rounded-xl px-4 py-2.5 font-bold text-sm flex-1 flex items-center justify-center gap-1"
        >
          {step === 3 ? (carregando ? 'Enviando…' : 'Concluir cadastro') : 'Continuar'}
          {step < 3 && <ChevronRight size={16} />}
          {step === 3 && !carregando && <Check size={16} />}
        </button>
      </div>

      <p className="text-xs text-center mt-5" style={{ color: 'var(--muted)' }}>
        Já tem conta?{' '}
        <button onClick={onIrParaLogin} className="font-bold" style={{ color: 'var(--turf)' }}>
          Entrar
        </button>
      </p>
    </div>
  );
}
