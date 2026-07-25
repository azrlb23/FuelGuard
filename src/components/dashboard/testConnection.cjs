const { createClient } = require('/home/perhanjay/Documents/Programming/MV-2/node_modules/@supabase/supabase-js');
const fs = require('fs');

const envPath = '/home/perhanjay/Documents/Programming/MV-2/.env';
const envContent = fs.readFileSync(envPath, 'utf8');

const url = envContent.match(/VITE_SUPABASE_URL=(.*)/)?.[1]?.trim();
const key = envContent.match(/VITE_SUPABASE_ANON_KEY=(.*)/)?.[1]?.trim();

const supabase = createClient(url, key);

async function testFetchAndInsert() {
  console.log('--- 1. Cek Data di transaksi_pertalite ---');
  const { data, error, count, status } = await supabase
    .from('transaksi_pertalite')
    .select('*');

  console.log('HTTP Status:', status);
  if (error) {
    console.log('Error SELECT:', error);
  } else {
    console.log('Jumlah Data Ditemukan:', data.length);
    console.log('Isi Data:', JSON.stringify(data, null, 2));
  }

  console.log('\n--- 2. Coba Insert Data Sampel (Pemeriksaan RLS / Akses Tulis) ---');
  const sampleData = {
    plat_nomor: 'B1234TEST',
    liter: 5.0,
    harga: 50000,
    jenis_kendaraan: 'Mobil'
  };

  const { data: insertData, error: insertError } = await supabase
    .from('transaksi_pertalite')
    .insert([sampleData])
    .select();

  if (insertError) {
    console.log('Insert Error (Mungkin RLS aktif dan butuh login):', insertError.message);
  } else {
    console.log('✅ Insert Berhasil! Data baru:', insertData);
  }
}

testFetchAndInsert();
