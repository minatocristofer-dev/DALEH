import { obterToken } from './auth';

const API_URL = import.meta.env.VITE_API_URL || 'https://daleh-fx5c.onrender.com/v1';

async function chamar(metodo, caminho, body) {
  const token = obterToken();
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  const resp = await fetch(`${API_URL}${caminho}`, {
    method: metodo,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const dados = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const mensagem = Array.isArray(dados.message) ? dados.message.join(', ') : dados.message;
    throw new Error(mensagem || 'Algo deu errado. Tenta de novo.');
  }
  return dados;
}

export function registrar(dto) {
  return chamar('POST', '/auth/register', dto);
}

export function login(dto) {
  return chamar('POST', '/auth/login', dto);
}

export function loginSocial(dto) {
  return chamar('POST', '/auth/social', dto);
}

// Times
export const listarMeusTimes = () => chamar('GET', '/teams/mine');
export const criarTime = (dto) => chamar('POST', '/teams', dto);
export const obterTime = (id) => chamar('GET', `/teams/${id}`);
export const adicionarMembro = (teamId, dto) => chamar('POST', `/teams/${teamId}/members`, dto);
export const removerMembro = (teamId, userId) => chamar('DELETE', `/teams/${teamId}/members/${userId}`);

// Quadras
export const listarQuadras = () => chamar('GET', '/venues');
export const listarMinhasQuadras = () => chamar('GET', '/venues/mine');
export const criarQuadra = (dto) => chamar('POST', '/venues', dto);
