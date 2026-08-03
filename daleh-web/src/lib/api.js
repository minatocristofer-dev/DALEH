const API_URL = import.meta.env.VITE_API_URL || 'https://daleh-fx5c.onrender.com/v1';

async function chamar(caminho, body) {
  const resp = await fetch(`${API_URL}${caminho}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const dados = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const mensagem = Array.isArray(dados.message) ? dados.message.join(', ') : dados.message;
    throw new Error(mensagem || 'Algo deu errado. Tenta de novo.');
  }
  return dados;
}

export function registrar(dto) {
  return chamar('/auth/register', dto);
}

export function login(dto) {
  return chamar('/auth/login', dto);
}

export function loginSocial(dto) {
  return chamar('/auth/social', dto);
}
