// Servidor estático mínimo (sem dependências) só para testar o login social
// via navegador — o fluxo OAuth do Supabase precisa de uma origem http(s),
// não funciona abrindo o HTML direto como arquivo local (file://).
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const DIR = __dirname;

http
  .createServer((req, res) => {
    const filePath = path.join(DIR, req.url === '/' ? 'test-social-login.html' : req.url.split('?')[0]);
    fs.readFile(filePath, (err, content) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(content);
    });
  })
  .listen(PORT, () => console.log(`Servindo página de teste em http://localhost:${PORT}`));
