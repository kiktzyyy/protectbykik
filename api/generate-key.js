// /api/generate-key.js
import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  // Membuat kunci yang unik dengan prefix LIMEHUB
  const generatedKey = `LIMEHUB-${crypto.randomUUID()}`;
  
  // Menyimpan kunci ke database Vercel KV dengan masa berlaku 24 jam.
  // 'ex: 86400' berarti kunci akan otomatis dihapus setelah 24 jam.
  await kv.set(generatedKey, { hwid: null, created: Date.now() }, { ex: 86400 });

  // Menampilkan halaman HTML ke pengguna
  const pageHTML = `
    <html>
      <head><title>Your Key</title><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>body{font-family:monospace,sans-serif;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background-color:#121212;color:#e0e0e0;text-align:center;padding:1em}.container{max-width:100%;padding:2em;border:1px solid #333;border-radius:8px;background-color:#1e1e1e}#key{background-color:#333;padding:.8em;margin:1em 0;border-radius:4px;user-select:all;cursor:pointer;word-break:break-all}</style></head>
      <body><div class="container"><h1>Here Is Your LimeHub Key</h1><p>Copy this key and paste it into the script:</p><div id="key" onclick="navigator.clipboard.writeText(this.innerText)">${generatedKey}</div><p><small>This key is valid for 24 hours and locked to the first PC that uses it.</small></p></div></body>
    </html>
  `;
  response.setHeader('Content-Type', 'text/html');
  response.status(200).send(pageHTML);
}
