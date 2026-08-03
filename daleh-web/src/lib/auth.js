const CHAVE = 'daleh_access_token';
const CHAVE_PERFIL = 'daleh_perfil_cache';

export function salvarToken(token) {
  localStorage.setItem(CHAVE, token);
}

export function limparToken() {
  localStorage.removeItem(CHAVE);
  localStorage.removeItem(CHAVE_PERFIL);
}

export function obterToken() {
  return localStorage.getItem(CHAVE);
}

// Nossa API não devolve nome/foto no login (só o token) — guardamos aqui, no
// momento do cadastro/login social, os dados que já temos em mãos no
// cliente, só pra exibir na tela de Perfil. Não é sincronizado com o servidor.
export function salvarPerfilCache(perfil) {
  localStorage.setItem(CHAVE_PERFIL, JSON.stringify(perfil));
}

export function obterPerfilCache() {
  try {
    return JSON.parse(localStorage.getItem(CHAVE_PERFIL) || 'null');
  } catch {
    return null;
  }
}

// Decodifica só o payload do JWT (sem verificar assinatura) — usado apenas
// pra exibir nome/e-mail na tela, nunca pra autorizar nada sensível.
export function usuarioDoToken(token) {
  try {
    const payloadBase64 = token.split('.')[1];
    const payload = JSON.parse(atob(payloadBase64.replace(/-/g, '+').replace(/_/g, '/')));
    return payload;
  } catch {
    return null;
  }
}
