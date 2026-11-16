/**
 * Quadras reais de Santa Maria, sem perfil/dono próprio no DALEH ainda —
 * cadastradas sob uma conta placeholder ("DALEH Quadras Parceiras") só pra
 * permitir testar o fluxo de reserva de ponta a ponta durante o teste
 * fechado. NÃO é uma parceria real com essas quadras: preço e horários são
 * valores de teste (ver PRECO_TESTE abaixo), não os valores reais cobrados
 * por cada quadra. Antes de qualquer teste público mais amplo, ou um dono
 * real assume o perfil (endpoint de transferência ainda não existe) ou os
 * dados de preço/horário precisam ser substituídos pelos reais.
 *
 * Mesmo padrão do scripts/seed-qa.ts: só usa os endpoints HTTP já
 * existentes da API (nenhuma escrita direta no banco), idempotente.
 *
 * Uso:
 *   SEED_API_BASE_URL=https://daleh-fx5c.onrender.com/v1 npx ts-node scripts/seed-quadras-santa-maria.ts
 * (SEED_API_BASE_URL é opcional, default é http://localhost:3000/v1)
 */

const API_BASE_URL = process.env.SEED_API_BASE_URL ?? 'http://localhost:3000/v1';
const CIDADE = 'Santa Maria';
const ESTADO = 'RS';

const DONO = {
  nome: 'DALEH Quadras Parceiras',
  email: 'quadras.parceiras@daleh.local',
  senha: 'Daleh@Teste2026!',
};

// Preço de teste — NÃO é o preço real cobrado por nenhuma dessas quadras.
// Só existe pra satisfazer o campo obrigatório `price` do VenueSlot durante
// o teste fechado.
const PRECO_TESTE = 100;

// Lista passada diretamente pelo dono do projeto (quadras reais de Santa
// Maria que ele conhece) — nenhum nome foi pesquisado/inventado por IA.
const QUADRAS = [
  'Quadra da Miriam',
  'Ginásio Basso',
  'Ginásio Dalla Favera',
  'Ginásio do Atlético',
  'Ginásio Silva Jardim',
  'Ginásio Jatobá',
  'Ginásio Fólis',
  'Pinheirão',
  'Planeta Bola',
  'Complexo G7',
  'Quadra Cerrito',
  'PainSport',
  'La Guerrilla',
];

// Dois horários recorrentes por dia da semana (0=Segunda...6=Domingo),
// horário de pico de pelada — valor de teste, não é a disponibilidade real.
const HORARIOS = [
  { start: '19:00', end: '20:00' },
  { start: '20:00', end: '21:00' },
];

type Metodo = 'GET' | 'POST' | 'PATCH' | 'DELETE';

async function api(path: string, opcoes: { method?: Metodo; token?: string; body?: unknown } = {}) {
  const resp = await fetch(`${API_BASE_URL}${path}`, {
    method: opcoes.method ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(opcoes.token ? { Authorization: `Bearer ${opcoes.token}` } : {}),
    },
    body: opcoes.body !== undefined ? JSON.stringify(opcoes.body) : undefined,
  });
  const texto = await resp.text();
  const dados = texto ? JSON.parse(texto) : null;
  return { status: resp.status, dados };
}

async function registrarOuLogarDono(): Promise<string> {
  const registro = await api('/auth/register', {
    method: 'POST',
    body: {
      fullName: DONO.nome,
      email: DONO.email,
      password: DONO.senha,
      city: CIDADE,
      state: ESTADO,
      // Campo obrigatório no cadastro (RegisterDto) mesmo pra uma conta
      // que não é de jogador de verdade — valor sem efeito aqui.
      modalidades: [{ modalidade: 'SOCIETY', posicaoPrincipal: 'N/A' }],
      consentimentoDadosSensiveis: true,
    },
  });

  if (registro.status === 201) {
    console.log(`  conta criada: ${DONO.nome} <${DONO.email}>`);
    return registro.dados.accessToken;
  }

  const login = await api('/auth/login', { method: 'POST', body: { email: DONO.email, password: DONO.senha } });
  if (login.status !== 200) {
    throw new Error(`Não consegui autenticar ${DONO.email} (register: ${registro.status}, login: ${login.status}) — ${JSON.stringify(login.dados)}`);
  }
  console.log(`  conta já existia, login ok: ${DONO.nome} <${DONO.email}>`);
  return login.dados.accessToken;
}

async function obterOuCriarQuadra(token: string, nome: string): Promise<{ id: string; criada: boolean }> {
  const minhas = await api('/venues/mine', { token });
  if (minhas.status !== 200) throw new Error(`Falha ao listar quadras: ${JSON.stringify(minhas.dados)}`);
  const existente = (minhas.dados as any[]).find((v) => v.name === nome);
  if (existente) return { id: existente.id, criada: false };

  const criada = await api('/venues', {
    method: 'POST',
    token,
    body: { name: nome, pricePerHour: PRECO_TESTE },
  });
  if (criada.status !== 201) throw new Error(`Falha ao criar quadra "${nome}": ${JSON.stringify(criada.dados)}`);
  return { id: criada.dados.id, criada: true };
}

async function obterOuCriarSlot(token: string, venueId: string, weekday: number, startTime: string, endTime: string) {
  const detalhe = await api(`/venues/${venueId}`, { token });
  if (detalhe.status !== 200) throw new Error(`Falha ao obter quadra: ${JSON.stringify(detalhe.dados)}`);
  const existente = (detalhe.dados.slots as any[] | undefined)?.find((s) => s.weekday === weekday && s.startTime === startTime);
  if (existente) return { id: existente.id, criado: false };

  const criado = await api(`/venues/${venueId}/slots`, {
    method: 'POST',
    token,
    body: { weekday, startTime, endTime, price: PRECO_TESTE },
  });
  if (criado.status !== 201) throw new Error(`Falha ao criar horário ${startTime}-${endTime} (dia ${weekday}): ${JSON.stringify(criado.dados)}`);
  return { id: criado.dados.id, criado: true };
}

async function main() {
  console.log(`Seed de quadras de Santa Maria (sem dono real) — API: ${API_BASE_URL}\n`);

  console.log('1. Conta placeholder (dono das quadras)');
  const token = await registrarOuLogarDono();

  console.log('\n2. Quadras + horários recorrentes');
  for (const nome of QUADRAS) {
    const quadra = await obterOuCriarQuadra(token, nome);
    console.log(`  ${nome}: ${quadra.criada ? 'criada' : 'já existia'} (${quadra.id})`);

    for (let weekday = 0; weekday <= 6; weekday++) {
      for (const h of HORARIOS) {
        const slot = await obterOuCriarSlot(token, quadra.id, weekday, h.start, h.end);
        if (slot.criado) console.log(`    dia ${weekday} ${h.start}-${h.end}: criado`);
      }
    }
  }

  console.log('\n✅ Seed concluído.');
  console.log(`\nLembrete: pra confirmar/gerenciar as reservas que chegarem, logue no app com <${DONO.email}> (modo Locador).`);
}

main().catch((erro) => {
  console.error('\n❌ Seed falhou:', erro.message ?? erro);
  process.exit(1);
});

// Transforma este arquivo num module TS (escopo próprio) em vez de script
// global — evita colisão de nomes com scripts/seed-qa.ts no `tsc --noEmit`
// do projeto (cada script roda isolado via ts-node, isso não afeta a
// execução, só a checagem de tipos do projeto como um todo).
export {};
