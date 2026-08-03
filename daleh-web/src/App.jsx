import { useEffect, useState } from 'react';
import { User, Building2, Shield, Users } from 'lucide-react';
import { Segmented } from './components/shared';
import Login from './components/Login';
import Cadastro from './components/Cadastro';
import Perfil from './components/Perfil';
import Quadras from './components/Quadras';
import Times from './components/Times';
import { supabase } from './lib/supabase';
import { loginSocial } from './lib/api';
import { obterToken, salvarToken, limparToken, obterPerfilCache, salvarPerfilCache, usuarioDoToken } from './lib/auth';

export default function App() {
  const [logado, setLogado] = useState(Boolean(obterToken()));
  const [telaAuth, setTelaAuth] = useState('login'); // 'login' | 'cadastro'
  const [tab, setTab] = useState('perfil');
  const [processandoOAuth, setProcessandoOAuth] = useState(false);

  // Depois do redirect do Google, o Supabase deixa a sessão disponível aqui —
  // trocamos o access_token dele pelo nosso, via POST /auth/social.
  useEffect(() => {
    const trocarSessaoSocial = async (session) => {
      if (!session || obterToken()) return;
      setProcessandoOAuth(true);
      try {
        const { accessToken } = await loginSocial({
          accessToken: session.access_token,
          consentimentoDadosSensiveis: true,
        });
        salvarToken(accessToken);
        salvarPerfilCache({
          fullName: session.user.user_metadata?.full_name || session.user.user_metadata?.name,
          email: session.user.email,
          avatarUrl: session.user.user_metadata?.avatar_url,
        });
        setLogado(true);
      } catch (err) {
        console.error('Falha ao trocar sessão social:', err.message);
      } finally {
        setProcessandoOAuth(false);
      }
    };

    supabase.auth.getSession().then(({ data }) => trocarSessaoSocial(data.session));
    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      trocarSessaoSocial(session);
    });
    return () => listener.subscription.unsubscribe();
  }, []);

  const sair = async () => {
    limparToken();
    await supabase.auth.signOut();
    setLogado(false);
    setTelaAuth('login');
  };

  const perfilCache = obterPerfilCache();
  const tokenPayload = usuarioDoToken(obterToken() || '');
  const usuario = {
    fullName: perfilCache?.fullName,
    email: perfilCache?.email || tokenPayload?.email,
    avatarUrl: perfilCache?.avatarUrl,
  };

  const tabs = [
    { key: 'perfil', label: 'Perfil', icon: User },
    { key: 'quadras', label: 'Quadras', icon: Building2 },
    { key: 'times', label: 'Times', icon: Shield },
  ];

  return (
    <div className="fm-root min-h-screen flex justify-center py-6 px-3">
      <div className="w-full max-w-sm">
        <div className="fm-stripes rounded-2xl px-4 py-4 mb-4 flex items-center justify-between">
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest" style={{ color: 'var(--turf)' }}>DALEH</p>
            <h1 className="text-lg font-black leading-tight">O básico do app</h1>
          </div>
          <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ background: 'var(--turf)' }}>
            <Users size={18} color="#08130E" />
          </div>
        </div>

        {processandoOAuth && (
          <div className="fm-card rounded-2xl p-5 text-center text-sm" style={{ color: 'var(--muted)' }}>
            Concluindo login com Google…
          </div>
        )}

        {!processandoOAuth && !logado && telaAuth === 'login' && (
          <Login onEntrar={() => setLogado(true)} onIrParaCadastro={() => setTelaAuth('cadastro')} />
        )}

        {!processandoOAuth && !logado && telaAuth === 'cadastro' && (
          <Cadastro onCadastrado={() => setLogado(true)} onIrParaLogin={() => setTelaAuth('login')} />
        )}

        {!processandoOAuth && logado && (
          <>
            <div className="mb-4">
              <Segmented options={tabs} value={tab} onChange={setTab} />
            </div>
            {tab === 'perfil' && <Perfil usuario={usuario} onSair={sair} />}
            {tab === 'quadras' && <Quadras />}
            {tab === 'times' && <Times />}
          </>
        )}
      </div>
    </div>
  );
}
