import { LogOut, User as UserIcon } from 'lucide-react';

export default function Perfil({ usuario, onSair }) {
  const inicial = (usuario?.fullName || usuario?.email || '?').slice(0, 1).toUpperCase();

  return (
    <div className="fm-card rounded-2xl p-5">
      <div className="flex items-center gap-3 mb-5">
        {usuario?.avatarUrl ? (
          <img src={usuario.avatarUrl} alt="" className="w-14 h-14 rounded-full object-cover" />
        ) : (
          <div
            className="w-14 h-14 rounded-full flex items-center justify-center font-black text-lg"
            style={{ background: 'var(--turf)', color: '#08130E' }}
          >
            {inicial}
          </div>
        )}
        <div>
          <h3 className="font-black text-base">{usuario?.fullName || 'Jogador'}</h3>
          <p className="text-xs flex items-center gap-1" style={{ color: 'var(--muted)' }}>
            <UserIcon size={12} /> {usuario?.email}
          </p>
        </div>
      </div>

      <p className="text-xs mb-5" style={{ color: 'var(--muted)' }}>
        Sessão válida — o token de acesso já está sendo enviado nas chamadas
        pra API real do DALEH.
      </p>

      <button
        onClick={onSair}
        className="fm-input rounded-xl px-4 py-2.5 font-bold text-sm w-full flex items-center justify-center gap-2"
      >
        <LogOut size={16} /> Sair
      </button>
    </div>
  );
}
