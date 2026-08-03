import { useState } from 'react';
import { LogIn } from 'lucide-react';
import { Field } from './shared';
import { login as loginApi } from '../lib/api';
import { salvarToken, salvarPerfilCache } from '../lib/auth';
import { supabase } from '../lib/supabase';

export default function Login({ onEntrar, onIrParaCadastro }) {
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [carregando, setCarregando] = useState(false);
  const [carregandoGoogle, setCarregandoGoogle] = useState(false);
  const [erro, setErro] = useState('');

  const entrar = async (e) => {
    e.preventDefault();
    setErro('');
    setCarregando(true);
    try {
      const { accessToken } = await loginApi({ email, password: senha });
      salvarToken(accessToken);
      salvarPerfilCache({ email });
      onEntrar();
    } catch (err) {
      setErro(err.message);
    } finally {
      setCarregando(false);
    }
  };

  const entrarComGoogle = async () => {
    setErro('');
    setCarregandoGoogle(true);
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin },
    });
    if (error) {
      setErro(error.message);
      setCarregandoGoogle(false);
    }
    // Em caso de sucesso, o navegador é redirecionado — App.jsx trata a
    // sessão de volta no onAuthStateChange.
  };

  return (
    <div className="fm-card rounded-2xl p-5">
      <h3 className="font-black text-base mb-4 flex items-center gap-2">
        <LogIn size={18} style={{ color: 'var(--turf)' }} /> Entrar
      </h3>

      <form onSubmit={entrar}>
        <Field label="E-mail">
          <input
            type="email"
            required
            className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm"
            placeholder="voce@exemplo.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </Field>
        <Field label="Senha">
          <input
            type="password"
            required
            className="fm-input w-full rounded-xl px-3.5 py-2.5 text-sm"
            placeholder="••••••••"
            value={senha}
            onChange={(e) => setSenha(e.target.value)}
          />
        </Field>

        {erro && <p className="fm-error text-xs mb-3">{erro}</p>}

        <button
          type="submit"
          disabled={carregando}
          className="fm-btn-primary rounded-xl px-4 py-2.5 font-bold text-sm w-full"
        >
          {carregando ? 'Entrando…' : 'Entrar'}
        </button>
      </form>

      <div className="flex items-center gap-3 my-4">
        <div className="flex-1 h-px" style={{ background: 'var(--line)' }} />
        <span className="text-[11px]" style={{ color: 'var(--muted)' }}>ou</span>
        <div className="flex-1 h-px" style={{ background: 'var(--line)' }} />
      </div>

      <button
        onClick={entrarComGoogle}
        disabled={carregandoGoogle}
        className="fm-input rounded-xl px-4 py-2.5 font-bold text-sm w-full"
      >
        {carregandoGoogle ? 'Redirecionando…' : 'Entrar com Google'}
      </button>

      <p className="text-xs text-center mt-5" style={{ color: 'var(--muted)' }}>
        Ainda não tem conta?{' '}
        <button onClick={onIrParaCadastro} className="font-bold" style={{ color: 'var(--turf)' }}>
          Cadastre-se
        </button>
      </p>
    </div>
  );
}
