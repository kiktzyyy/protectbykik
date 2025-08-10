// /api/loader.js
import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  // Ambil 'key', 'hwid', dan 'placeId' dari URL yang dikirim oleh loader.
  const { key, hwid, placeId } = request.query;

  // Validasi input dasar, pastikan tidak ada yang kosong.
  if (!key || !hwid || !placeId) {
    return response.status(400).send('print("Error: Missing key, HWID, or PlaceId.")');
  }

  // 1. Cek kunci di database Vercel KV.
  const keyData = await kv.get(key);
  if (!keyData) {
    // Jika kunci tidak ditemukan, berarti sudah kedaluwarsa atau tidak valid.
    return response.status(403).send('print("Key is invalid or has expired.")');
  }

  // 2. Logika Verifikasi HWID
  if (keyData.hwid === null) {
    // Penggunaan pertama: Kunci ini belum terikat.
    // Ikat (lock) HWID ke pengguna ini sekarang.
    await kv.set(key, { ...keyData, hwid: hwid });
    console.log(`Key ${key} has been locked to HWID ${hwid}`);
  } else if (keyData.hwid !== hwid) {
    // Penggunaan selanjutnya: HWID yang dikirim tidak cocok dengan yang tersimpan.
    return response.status(403).send('print("This key is already locked to another PC.")');
  }
  
  // Jika lolos verifikasi HWID, lanjutkan ke pengiriman skrip.
  
  // 3. Peta dari PlaceId ke Nama File Skrip di folder /scripts.
  //    GANTI BAGIAN INI DENGAN GAME ID DAN NAMA FILE ANDA.
  const scriptMap = {
    '994732206': 'blox-fruit.lua',
    '4777817887': 'blade-ball.lua',
    '0': 'contoh-game.lua', // Ganti '0' dengan PlaceId asli
  };
  const fileName = scriptMap[placeId];

  // Jika game tidak ada di dalam peta (tidak didukung).
  if (!fileName) {
    return response.status(404).send(`print("This game is not supported.")`);
  }

  // 4. Ambil skrip yang benar dari Repositori GitHub Private Anda.
  const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
  const REPO_PATH = process.env.GITHUB_REPO_PATH;
  const SCRIPT_URL = `https://raw.githubusercontent.com/${REPO_PATH}/main/scripts/${fileName}`;

  try {
    const scriptResponse = await fetch(SCRIPT_URL, {
      headers: { 'Authorization': `Bearer ${GITHUB_TOKEN}` }
    });
    if (!scriptResponse.ok) throw new Error('Script not found on GitHub.');
    
    const scriptContent = await scriptResponse.text();

    // Kirim konten skrip sebagai respons.
    response.setHeader('Content-Type', 'text/plain');
    response.status(200).send(scriptContent);
  } catch (error) {
    console.error(error);
    response.status(500).send('print("Error loading script from server. Please contact developer.")');
  }
}
