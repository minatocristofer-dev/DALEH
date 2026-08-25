/**
 * Fase 8.5 — Ambiente de dados de teste (QA manual).
 *
 * NÃO escreve no banco diretamente. Usa exclusivamente os endpoints HTTP já
 * existentes da API (mesmo caminho que o app Flutter usa), pra garantir que
 * os dados criados passem por toda a validação/autorização/regra de negócio
 * real — nenhum endpoint foi inventado, nenhuma regra foi alterada.
 *
 * Idempotente: seguro rodar mais de uma vez.
 * - Usuário: registra; se já existir (409), loga.
 * - Time/Quadra: procura por nome antes de criar (não existe endpoint de
 *   busca por nome, então usa GET /teams/mine e GET /venues/mine e filtra).
 * - Membro de time / reserva: tenta criar e tolera 409 ("já existe").
 * - Desafio de time → partida: procura em GET /team-challenges/mine se já
 *   existe um desafio CONFIRMADA entre os dois times de teste; se sim,
 *   reaproveita o matchId em vez de rodar o fluxo de novo.
 * - Convocação: só convoca o time pra uma partida se ainda não existir
 *   nenhuma convocação daquele time pra aquele matchId.
 *
 * Uso:
 *   SEED_API_BASE_URL=http://localhost:3000/v1 npx ts-node scripts/seed-qa.ts
 * (SEED_API_BASE_URL é opcional, default é http://localhost:3000/v1)
 */

const API_BASE_URL = process.env.SEED_API_BASE_URL ?? 'http://localhost:3000/v1';
const SENHA_TESTE = 'Daleh@Teste2026!';
const CIDADE = 'Santa Maria';
const ESTADO = 'RS';

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

interface DefinicaoUsuario {
  chave: string;
  nome: string;
  email: string;
  posicao: string;
  peDominante: 'Direito' | 'Esquerdo' | 'Ambos';
}

const USUARIOS: DefinicaoUsuario[] = [
  { chave: 'lucas', nome: 'Lucas Ferreira', email: 'lucas.teste@daleh.local', posicao: 'Meia', peDominante: 'Direito' },
  { chave: 'rafael', nome: 'Rafael Martins', email: 'rafael.teste@daleh.local', posicao: 'Zagueiro', peDominante: 'Direito' },
  { chave: 'gabriel', nome: 'Gabriel Souza', email: 'gabriel.teste@daleh.local', posicao: 'Atacante', peDominante: 'Esquerdo' },
  { chave: 'matheus', nome: 'Matheus Oliveira', email: 'matheus.teste@daleh.local', posicao: 'Lateral', peDominante: 'Direito' },
  { chave: 'pedro', nome: 'Pedro Henrique', email: 'pedro.teste@daleh.local', posicao: 'Goleiro', peDominante: 'Ambos' },
  { chave: 'joao', nome: 'João Vitor', email: 'joao.teste@daleh.local', posicao: 'Meia', peDominante: 'Esquerdo' },
  { chave: 'bruno', nome: 'Bruno Almeida', email: 'bruno.teste@daleh.local', posicao: 'Atacante', peDominante: 'Direito' },
  { chave: 'marcos', nome: 'Marcos Ribeiro', email: 'marcos.teste@daleh.local', posicao: 'Zagueiro', peDominante: 'Direito' },
];

async function registrarOuLogar(u: DefinicaoUsuario): Promise<{ token: string; userId: string; criado: boolean }> {
  const registro = await api('/auth/register', {
    method: 'POST',
    body: {
      fullName: u.nome,
      email: u.email,
      password: SENHA_TESTE,
      city: CIDADE,
      state: ESTADO,
      dominantFoot: u.peDominante,
      modalidades: [{ modalidade: 'SOCIETY', posicaoPrincipal: u.posicao }],
      consentimentoDadosSensiveis: true,
    },
  });

  let token: string;
  let criado: boolean;
  if (registro.status === 201) {
    token = registro.dados.accessToken;
    criado = true;
  } else {
    const login = await api('/auth/login', { method: 'POST', body: { email: u.email, password: SENHA_TESTE } });
    if (login.status !== 200) {
      throw new Error(`Não consegui autenticar ${u.email} (register: ${registro.status}, login: ${login.status}) — ${JSON.stringify(login.dados)}`);
    }
    token = login.dados.accessToken;
    criado = false;
  }

  const me = await api('/auth/me', { token });
  if (me.status !== 200) throw new Error(`Falha ao confirmar perfil de ${u.email}: ${JSON.stringify(me.dados)}`);

  console.log(`  ${criado ? 'criado' : 'já existia, login ok'}: ${u.nome} <${u.email}> (id ${me.dados.id})`);
  return { token, userId: me.dados.id, criado };
}

async function obterOuCriarTime(tokenDono: string, nome: string): Promise<{ id: string; criado: boolean }> {
  const meus = await api('/teams/mine', { token: tokenDono });
  if (meus.status !== 200) throw new Error(`Falha ao listar times: ${JSON.stringify(meus.dados)}`);
  const existente = (meus.dados as any[]).find((t) => t.name === nome);
  if (existente) return { id: existente.id, criado: false };

  const criado = await api('/teams', { method: 'POST', token: tokenDono, body: { name: nome, city: CIDADE, state: ESTADO } });
  if (criado.status !== 201) throw new Error(`Falha ao criar time "${nome}": ${JSON.stringify(criado.dados)}`);
  return { id: criado.dados.id, criado: true };
}

async function adicionarMembro(tokenCapitao: string, teamId: string, email: string) {
  const resp = await api(`/teams/${teamId}/members`, { method: 'POST', token: tokenCapitao, body: { email } });
  if (resp.status === 201) {
    console.log(`    adicionado ao elenco: ${email}`);
  } else if (resp.status === 409) {
    console.log(`    já estava no elenco: ${email}`);
  } else {
    throw new Error(`Falha ao adicionar ${email} no time ${teamId}: ${resp.status} ${JSON.stringify(resp.dados)}`);
  }
}

async function obterOuCriarQuadra(tokenDono: string, nome: string): Promise<{ id: string; criada: boolean }> {
  const minhas = await api('/venues/mine', { token: tokenDono });
  if (minhas.status !== 200) throw new Error(`Falha ao listar quadras: ${JSON.stringify(minhas.dados)}`);
  const existente = (minhas.dados as any[]).find((v) => v.name === nome);
  if (existente) return { id: existente.id, criada: false };

  const criada = await api('/venues', {
    method: 'POST',
    token: tokenDono,
    body: { name: nome, address: 'Rua de Teste, 100', covered: true, hasParking: true, hasBar: false, hasLockerRoom: true, rentsVests: false, rentsBalls: true, pricePerHour: 120 },
  });
  if (criada.status !== 201) throw new Error(`Falha ao criar quadra "${nome}": ${JSON.stringify(criada.dados)}`);
  return { id: criada.dados.id, criada: true };
}

async function obterOuCriarSlot(
  tokenDono: string,
  venueId: string,
  weekday: number,
  startTime: string,
  endTime: string,
): Promise<{ id: string; criado: boolean }> {
  const detalhe = await api(`/venues/${venueId}`, { token: tokenDono });
  if (detalhe.status !== 200) throw new Error(`Falha ao obter quadra: ${JSON.stringify(detalhe.dados)}`);
  const existente = (detalhe.dados.slots as any[] | undefined)?.find((s) => s.weekday === weekday && s.startTime === startTime);
  if (existente) return { id: existente.id, criado: false };

  const criado = await api(`/venues/${venueId}/slots`, { method: 'POST', token: tokenDono, body: { weekday, startTime, endTime, price: 100 } });
  if (criado.status !== 201) throw new Error(`Falha ao criar horário: ${JSON.stringify(criado.dados)}`);
  return { id: criado.dados.id, criado: true };
}

async function obterOuCriarReserva(tokenLocatario: string, venueId: string, slotId: string, data: string) {
  const resp = await api(`/venues/${venueId}/slots/${slotId}/bookings`, { method: 'POST', token: tokenLocatario, body: { date: data } });
  if (resp.status === 201) return { ...resp.dados, criada: true };
  if (resp.status === 409) {
    const minhas = await api('/bookings/mine', { token: tokenLocatario });
    const existente = (minhas.dados as any[]).find((b) => b.venueSlotId === slotId);
    if (!existente) throw new Error('Reserva conflitou (409) mas não achei ela em /bookings/mine.');
    return { ...existente, criada: false };
  }
  throw new Error(`Falha ao reservar: ${resp.status} ${JSON.stringify(resp.dados)}`);
}

async function obterOuCriarPartida(
  tokenLucas: string,
  tokenRafael: string,
  teamAId: string,
  teamBId: string,
  venueId: string,
  scheduledDate: string,
  scheduledTime: string,
): Promise<{ matchId: string; criada: boolean }> {
  const meusLucas = await api('/team-challenges/mine', { token: tokenLucas });
  if (meusLucas.status !== 200) throw new Error(`Falha ao listar desafios: ${JSON.stringify(meusLucas.dados)}`);
  const existente = (meusLucas.dados.comoOrganizador as any[]).find(
    (d) => d.teamId === teamAId && d.opponentTeamId === teamBId && d.status === 'CONFIRMADA' && d.matchId,
  );
  if (existente) return { matchId: existente.matchId, criada: false };

  const desafio = await api('/team-challenges', {
    method: 'POST',
    token: tokenLucas,
    body: { teamId: teamAId, modalidade: 'SOCIETY', city: CIDADE, venueId, scheduledDate, scheduledTime, desiredLevel: 'intermediario' },
  });
  if (desafio.status !== 201) throw new Error(`Falha ao criar desafio: ${JSON.stringify(desafio.dados)}`);

  const solicitacao = await api(`/team-challenges/${desafio.dados.id}/requests`, {
    method: 'POST',
    token: tokenRafael,
    body: { requestingTeamId: teamBId },
  });
  if (solicitacao.status !== 201) throw new Error(`Falha ao solicitar desafio: ${JSON.stringify(solicitacao.dados)}`);

  const aceite = await api(`/team-challenges/${desafio.dados.id}/requests/${solicitacao.dados.id}/accept`, {
    method: 'POST',
    token: tokenLucas,
  });
  if (aceite.status !== 201) throw new Error(`Falha ao aceitar desafio: ${JSON.stringify(aceite.dados)}`);

  return { matchId: aceite.dados.matchId, criada: true };
}

async function obterOuConvocarTime(
  tokenCapitao: string,
  teamId: string,
  matchId: string,
  venueNameSnapshot: string,
  scheduledDate: string,
  scheduledTime: string,
): Promise<{ callUps: any[]; criadas: boolean }> {
  const existentes = await api(`/teams/${teamId}/call-ups`, { token: tokenCapitao });
  if (existentes.status !== 200) throw new Error(`Falha ao listar convocações do time: ${JSON.stringify(existentes.dados)}`);
  const jaConvocado = (existentes.dados as any[]).filter((c) => c.matchId === matchId);
  if (jaConvocado.length > 0) return { callUps: jaConvocado, criadas: false };

  const resp = await api(`/teams/${teamId}/call-ups`, {
    method: 'POST',
    token: tokenCapitao,
    body: { matchId, venueNameSnapshot, scheduledDate, scheduledTime },
  });
  if (resp.status !== 201) throw new Error(`Falha ao convocar time: ${JSON.stringify(resp.dados)}`);
  return { callUps: resp.dados, criadas: true };
}

async function responderConvocacao(tokenJogador: string, callUpId: string, status: 'CONFIRMADO' | 'RECUSADO') {
  const resp = await api(`/call-ups/${callUpId}/respond`, { method: 'PATCH', token: tokenJogador, body: { status } });
  if (resp.status !== 200) throw new Error(`Falha ao responder convocação ${callUpId}: ${JSON.stringify(resp.dados)}`);
  return resp.dados;
}

async function main() {
  console.log(`Ambiente de teste DALEH (Fase 8.5) — API: ${API_BASE_URL}\n`);

  console.log('1. Usuários');
  const usuarios: Record<string, { token: string; userId: string }> = {};
  for (const u of USUARIOS) {
    usuarios[u.chave] = await registrarOuLogar(u);
  }

  console.log('\n2. Times');
  const timeA = await obterOuCriarTime(usuarios.lucas.token, 'DALEH UNITED');
  console.log(`  DALEH UNITED: ${timeA.criado ? 'criado' : 'já existia'} (${timeA.id})`);
  const timeB = await obterOuCriarTime(usuarios.rafael.token, 'DALEH FC');
  console.log(`  DALEH FC: ${timeB.criado ? 'criado' : 'já existia'} (${timeB.id})`);

  console.log('  Elenco DALEH UNITED:');
  await adicionarMembro(usuarios.lucas.token, timeA.id, 'gabriel.teste@daleh.local');
  await adicionarMembro(usuarios.lucas.token, timeA.id, 'matheus.teste@daleh.local');
  console.log('  Elenco DALEH FC:');
  await adicionarMembro(usuarios.rafael.token, timeB.id, 'pedro.teste@daleh.local');
  await adicionarMembro(usuarios.rafael.token, timeB.id, 'joao.teste@daleh.local');

  console.log('\n3. Quadra');
  const quadra = await obterOuCriarQuadra(usuarios.marcos.token, 'DALEH Arena');
  console.log(`  DALEH Arena: ${quadra.criada ? 'criada' : 'já existia'} (${quadra.id})`);

  const hoje = new Date();
  const diaDaSemana = (hoje.getUTCDay() + 6) % 7; // 0=Segunda...6=Domingo, igual ao resto do sistema
  const slot = await obterOuCriarSlot(usuarios.marcos.token, quadra.id, diaDaSemana, '19:00', '20:00');
  console.log(`  Horário 19:00-20:00: ${slot.criado ? 'criado' : 'já existia'} (${slot.id})`);

  console.log('\n4. Reserva (Bruno reserva a DALEH Arena)');
  const dataReserva = hoje.toISOString().slice(0, 10);
  const reserva = await obterOuCriarReserva(usuarios.bruno.token, quadra.id, slot.id, dataReserva);
  console.log(`  Reserva de ${dataReserva}: ${reserva.criada ? 'criada' : 'já existia'} (${reserva.id}, status ${reserva.status})`);
  console.log('  Deixada como "pending" de propósito — confirmar/cancelar é o teste manual do dono (Marcos).');

  console.log('\n5. Partida — desafio DALEH UNITED x DALEH FC (fluxo real de desafio/aceite)');
  // Horário no passado próximo (algumas horas antes de agora) — garante que
  // "jogos disputados" já conte essa partida assim que ela for finalizada
  // manualmente, sem esperar o relógio virar o dia.
  const dataPartida = hoje.toISOString().slice(0, 10);
  const horaPartida = new Date(hoje.getTime() - 3 * 60 * 60 * 1000).toISOString().slice(11, 16);
  const partida = await obterOuCriarPartida(usuarios.lucas.token, usuarios.rafael.token, timeA.id, timeB.id, quadra.id, dataPartida, horaPartida);
  console.log(`  Partida: ${partida.criada ? 'criada agora (desafio aceito)' : 'já existia'} (matchId ${partida.matchId})`);

  console.log('\n6. Convocações');
  const convocacoesA = await obterOuConvocarTime(usuarios.lucas.token, timeA.id, partida.matchId, 'DALEH Arena', dataPartida, horaPartida);
  console.log(`  DALEH UNITED: ${convocacoesA.criadas ? 'convocado agora' : 'já estava convocado'} (${convocacoesA.callUps.length} convocações)`);
  const convocacoesB = await obterOuConvocarTime(usuarios.rafael.token, timeB.id, partida.matchId, 'DALEH Arena', dataPartida, horaPartida);
  console.log(`  DALEH FC: ${convocacoesB.criadas ? 'convocado agora' : 'já estava convocado'} (${convocacoesB.callUps.length} convocações)`);

  if (convocacoesA.criadas || convocacoesB.criadas) {
    console.log('\n7. Confirmando presença via resposta de convocação (fluxo da Fase 8 — CONFIRMADO cria MatchAttendance)');
    const porUserId = (lista: any[], userId: string) => lista.find((c) => c.userId === userId);

    // Time A: Lucas e Matheus confirmam agora. Gabriel fica PENDENTE de
    // propósito — é o teste manual "confirmar convocação" (seção 8/9), e o
    // roteiro de gol (seção 11) já espera Gabriel como o goleador, então
    // confirmá-lo é o primeiro passo do QA, não algo que o seed deveria fazer.
    await responderConvocacao(usuarios.lucas.token, porUserId(convocacoesA.callUps, usuarios.lucas.userId).id, 'CONFIRMADO');
    console.log('    Lucas: CONFIRMADO (presença criada)');
    await responderConvocacao(usuarios.matheus.token, porUserId(convocacoesA.callUps, usuarios.matheus.userId).id, 'CONFIRMADO');
    console.log('    Matheus: CONFIRMADO (presença criada)');
    console.log('    Gabriel: deixado PENDENTE — confirmar isso é o primeiro passo do roteiro manual.');

    // Time B: Rafael, Pedro e João confirmam — todos os três são necessários
    // pro roteiro de gol da seção 11 (Rafael marca pra Pedro, assistência de
    // João), então não sobra ninguém pra deixar como teste de "recusar" sem
    // quebrar esse roteiro exato. Ver LIMITAÇÕES no relatório.
    await responderConvocacao(usuarios.rafael.token, porUserId(convocacoesB.callUps, usuarios.rafael.userId).id, 'CONFIRMADO');
    console.log('    Rafael: CONFIRMADO (presença criada)');
    await responderConvocacao(usuarios.pedro.token, porUserId(convocacoesB.callUps, usuarios.pedro.userId).id, 'CONFIRMADO');
    console.log('    Pedro: CONFIRMADO (presença criada)');
    await responderConvocacao(usuarios.joao.token, porUserId(convocacoesB.callUps, usuarios.joao.userId).id, 'CONFIRMADO');
    console.log('    João: CONFIRMADO (presença criada)');
  } else {
    console.log('\n7. Convocações já existiam de uma execução anterior — não mexi nas respostas (preserva o que já foi testado manualmente).');
  }

  console.log('\n✅ Seed concluído.\n');
  console.log('Resumo:');
  console.log(`  Time A (DALEH UNITED): ${timeA.id}`);
  console.log(`  Time B (DALEH FC): ${timeB.id}`);
  console.log(`  Quadra (DALEH Arena): ${quadra.id}`);
  console.log(`  Reserva: ${reserva.id}`);
  console.log(`  Partida: ${partida.matchId}`);
}

main().catch((erro) => {
  console.error('\n❌ Seed falhou:', erro.message ?? erro);
  process.exit(1);
});
