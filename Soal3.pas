Program HasilStudiMahasiswa;

uses crt;

const
  MaxMhs  = 20;    // Batas jumlah mahasiswa
  MaxMK   = 10;    // Batas mata kuliah per mahasiswa (tabel tetap muat di layar 25 baris)
  MaxNama = 30;    // Panjang maksimum nama mahasiswa
  MaxNIM  = 15;    // Panjang maksimum NIM
  MaxSKS  = 6;     // SKS maksimum per mata kuliah

  // Lebar setiap kolom tabel
  LNo    = 2;
  LMK    = 30;
  LSKS   = 3;
  LNilai = 5;
  LSkor  = 5;
  // Lebar garis = "| " + kolom-kolom + pemisah " | " + " |"
  LGaris = 2 + LNo + 3 + LMK + 3 + LSKS + 3 + LNilai + 3 + LSkor + 2;
  // Lebar area label TOTAL = seluruh kolom sebelum kolom Skor
  LTotal = LNo + 3 + LMK + 3 + LSKS + 3 + LNilai;

type
  TNilai = string[2];

var
  // Data disimpan dalam array paralel; indeks pertama = mahasiswa
  Nama   : array[1..MaxMhs] of string[MaxNama];
  NIM    : array[1..MaxMhs] of string[MaxNIM];
  JmlMK  : array[1..MaxMhs] of integer;
  NamaMK : array[1..MaxMhs, 1..MaxMK] of string[LMK];
  SKS    : array[1..MaxMhs, 1..MaxMK] of integer;
  Nilai  : array[1..MaxMhs, 1..MaxMK] of TNilai;
  JmlMhs, i : integer;

// ====================== FUNGSI BANTU ======================

// Membuang spasi/tab di awal dan akhir teks
function Rapikan(s: string): string;
var
  a, b: integer;
begin
  a := 1;
  b := length(s);
  while (a <= b) and (s[a] in [' ', #9]) do inc(a);
  while (b >= a) and (s[b] in [' ', #9]) do dec(b);
  Rapikan := copy(s, a, b - a + 1);
end;

// Mengubah seluruh huruf menjadi huruf kapital
function Kapital(s: string): string;
var
  k: integer;
begin
  for k := 1 to length(s) do
    s[k] := UpCase(s[k]);
  Kapital := s;
end;

// Menambah spasi di kanan agar teks rata kiri sepanjang 'lebar'
function Pad(s: string; lebar: integer): string;
begin
  while length(s) < lebar do
    s := s + ' ';
  Pad := s;
end;

// Membuat deretan karakter c sebanyak n kali
function Ulang(c: char; n: integer): string;
var
  s: string;
  k: integer;
begin
  s := '';
  for k := 1 to n do
    s := s + c;
  Ulang := s;
end;

// Konversi bilangan bulat ke string
function IntKeStr(n: longint): string;
var
  s: string;
begin
  Str(n, s);
  IntKeStr := s;
end;

// Skor tampil sebagai bilangan bulat bila tidak berkoma (9, 12), selain itu 1 desimal (10.5)
function FormatSkor(x: real): string;
var
  s: string;
begin
  if abs(x - round(x)) < 0.001 then
    Str(round(x), s)
  else
    Str(x:0:1, s);
  FormatSkor := s;
end;

// Memeriksa bahwa teks tidak kosong dan seluruhnya angka 0-9
function HanyaAngka(s: string): boolean;
var
  k: integer;
  ok: boolean;
begin
  ok := (s <> '');
  for k := 1 to length(s) do
    if not (s[k] in ['0'..'9']) then ok := false;
  HanyaAngka := ok;
end;

// Memeriksa nama orang: hanya huruf, spasi, titik, apostrof, strip; minimal satu huruf
function NamaValid(s: string): boolean;
var
  k: integer;
  ok, adaHuruf: boolean;
begin
  ok := (s <> '');
  adaHuruf := false;
  for k := 1 to length(s) do
  begin
    if s[k] in ['A'..'Z', 'a'..'z'] then
      adaHuruf := true
    else if not (s[k] in [' ', '.', '''', '-']) then
      ok := false;
  end;
  NamaValid := ok and adaHuruf;
end;

// Memeriksa teks hanya berisi karakter yang dapat dicetak (ASCII 32-126)
// sehingga tab atau karakter kontrol tidak merusak tabel
function TeksCetak(s: string): boolean;
var
  k: integer;
  ok: boolean;
begin
  ok := (s <> '');
  for k := 1 to length(s) do
    if (ord(s[k]) < 32) or (ord(s[k]) > 126) then ok := false;
  TeksCetak := ok;
end;

// Mengubah nilai huruf menjadi bobot sesuai soal; mengembalikan -1 jika tidak valid
function BobotNilai(n: string): real;
begin
  if n = 'A' then BobotNilai := 4
  else if n = 'B+' then BobotNilai := 3.5
  else if n = 'B' then BobotNilai := 3
  else if n = 'C+' then BobotNilai := 2.5
  else if n = 'C' then BobotNilai := 2
  else if n = 'D' then BobotNilai := 1
  else if n = 'E' then BobotNilai := 0
  else BobotNilai := -1;
end;

// Memeriksa apakah NIM sudah dipakai oleh mahasiswa sebelumnya (indeks 1..batas)
function NIMSudahAda(s: string; batas: integer): boolean;
var
  k: integer;
  ada: boolean;
begin
  ada := false;
  for k := 1 to batas do
    if NIM[k] = s then ada := true;
  NIMSudahAda := ada;
end;

// ====================== FUNGSI INPUT AMAN ======================

// Membaca bilangan bulat dalam rentang [minimal..maksimal].
// Input dibaca sebagai string agar huruf/simbol tidak menyebabkan runtime error.
function BacaAngka(pesan: string; minimal, maksimal: integer): integer;
var
  s: string;
  n: longint;
  kode: integer;
  valid: boolean;
begin
  n := minimal;
  repeat
    write(pesan);
    readln(s);
    s := Rapikan(s);
    valid := false;
    // Batas 9 digit mencegah overflow pada longint
    if HanyaAngka(s) and (length(s) <= 9) then
    begin
      Val(s, n, kode);
      valid := (kode = 0) and (n >= minimal) and (n <= maksimal);
    end;
    if not valid then
      writeln('  [!] Input tidak valid. Masukkan bilangan bulat ',
              minimal, ' sampai ', maksimal, '.');
  until valid;
  BacaAngka := n;
end;

// Membaca nama mahasiswa
function BacaNamaMhs(pesan: string): string;
var
  s: string;
  valid: boolean;
begin
  repeat
    write(pesan);
    readln(s);
    s := Rapikan(s);
    valid := NamaValid(s) and (length(s) <= MaxNama);
    if not valid then
      writeln('  [!] Nama hanya boleh huruf (maks. ', MaxNama, ' karakter).');
  until valid;
  BacaNamaMhs := s;
end;

// Membaca NIM (angka saja, tidak kosong, belum pernah dipakai)
function BacaNIM(pesan: string; indeks: integer): string;
var
  s: string;
  valid: boolean;
begin
  repeat
    write(pesan);
    readln(s);
    s := Rapikan(s);
    valid := HanyaAngka(s) and (length(s) <= MaxNIM);
    if not valid then
      writeln('  [!] NIM hanya boleh angka (maks. ', MaxNIM, ' digit).')
    else if NIMSudahAda(s, indeks - 1) then
    begin
      valid := false;
      writeln('  [!] NIM sudah terdaftar pada mahasiswa lain.');
    end;
  until valid;
  BacaNIM := s;
end;

// Membaca nama mata kuliah (tidak kosong, karakter tercetak, muat di kolom tabel)
function BacaNamaMK(pesan: string): string;
var
  s: string;
  valid: boolean;
begin
  repeat
    write(pesan);
    readln(s);
    s := Rapikan(s);
    valid := TeksCetak(s) and (length(s) <= LMK);
    if not valid then
      writeln('  [!] Nama mata kuliah wajib diisi (maks. ', LMK, ' karakter).');
  until valid;
  BacaNamaMK := s;
end;

// Membaca nilai huruf; huruf kecil otomatis diubah menjadi kapital
function BacaNilai(pesan: string): TNilai;
var
  s: string;
  valid: boolean;
begin
  repeat
    write(pesan);
    readln(s);
    s := Kapital(Rapikan(s));
    valid := BobotNilai(s) >= 0;
    if not valid then
      writeln('  [!] Nilai harus salah satu dari: A, B+, B, C+, C, D, E.');
  until valid;
  BacaNilai := s;
end;

// ====================== PROSEDUR UTAMA ======================

// Input data satu mahasiswa beserta seluruh mata kuliahnya
procedure InputMahasiswa(m: integer);
var
  k: integer;
begin
  clrscr;
  writeln('=== INPUT DATA MAHASISWA KE-', m, ' DARI ', JmlMhs, ' ===');
  Nama[m]  := BacaNamaMhs('Nama                    : ');
  NIM[m]   := BacaNIM    ('NIM                     : ', m);
  JmlMK[m] := BacaAngka  ('Jumlah Mata Kuliah (1-' + IntKeStr(MaxMK) + ') : ', 1, MaxMK);

  for k := 1 to JmlMK[m] do
  begin
    // Layar dibersihkan tiap mata kuliah agar judul selalu terlihat
    clrscr;
    writeln('=== MAHASISWA KE-', m, ' : ', Nama[m], ' (', NIM[m], ') ===');
    writeln('--- Mata Kuliah ke-', k, ' dari ', JmlMK[m], ' ---');
    NamaMK[m, k] := BacaNamaMK('Nama Mata Kuliah          : ');
    SKS[m, k]    := BacaAngka ('Jumlah SKS (1-' + IntKeStr(MaxSKS) + ')          : ', 1, MaxSKS);
    Nilai[m, k]  := BacaNilai ('Nilai (A/B+/B/C+/C/D/E)  : ');
  end;
end;

// Menampilkan data satu mahasiswa dalam bentuk tabel sesuai contoh soal
procedure TampilMahasiswa(m: integer);
var
  k, totalSKS: integer;
  skor, totalSkor, ip: real;
  sIP: string;
begin
  totalSKS  := 0;
  totalSkor := 0;
  clrscr;
  writeln('Nama : ', Nama[m]);
  writeln('NIM  : ', NIM[m]);
  writeln(Ulang('-', LGaris));
  writeln('| ', Pad('No', LNo), ' | ', Pad('Mata Kuliah', LMK), ' | ',
          Pad('SKS', LSKS), ' | ', Pad('Nilai', LNilai), ' | ',
          Pad('Skor', LSkor), ' |');
  writeln(Ulang('-', LGaris));

  for k := 1 to JmlMK[m] do
  begin
    // Skor = SKS x bobot nilai; diakumulasi untuk TOTAL dan IP
    skor      := SKS[m, k] * BobotNilai(Nilai[m, k]);
    totalSKS  := totalSKS + SKS[m, k];
    totalSkor := totalSkor + skor;
    writeln('| ', Pad(IntKeStr(k), LNo), ' | ', Pad(NamaMK[m, k], LMK), ' | ',
            Pad(IntKeStr(SKS[m, k]), LSKS), ' | ', Pad(Nilai[m, k], LNilai), ' | ',
            Pad(FormatSkor(skor), LSkor), ' |');
  end;

  writeln(Ulang('-', LGaris));
  writeln('| ', Pad('TOTAL', LTotal), ' | ', Pad(FormatSkor(totalSkor), LSkor), ' |');
  writeln(Ulang('-', LGaris));

  // Pengaman pembagian nol (secara logika totalSKS >= 1)
  if totalSKS > 0 then
    ip := totalSkor / totalSKS
  else
    ip := 0;

  // Selisih sangat kecil ditambahkan agar nilai tepat di tengah (mis. 3.125)
  // selalu dibulatkan ke atas secara konsisten di semua compiler
  Str(ip + 0.0000001:0:2, sIP);

  writeln('Jumlah SKS : ', totalSKS);
  writeln('IP         : ', sIP);
  writeln;
end;

// Menunggu satu tombol ditekan (termasuk tombol khusus yang menghasilkan 2 kode)
procedure TungguTombol;
var
  c: char;
begin
  while KeyPressed do c := ReadKey;   // Kosongkan buffer keyboard
  c := ReadKey;
  if (c = #0) and KeyPressed then c := ReadKey;
end;

// ====================== PROGRAM UTAMA ======================
begin
  clrscr;
  writeln('=== PROGRAM HASIL STUDI MAHASISWA ===');
  writeln;
  JmlMhs := BacaAngka('Jumlah Mahasiswa (1-' + IntKeStr(MaxMhs) + ') : ', 1, MaxMhs);

  // Tahap 1: input seluruh data
  for i := 1 to JmlMhs do
    InputMahasiswa(i);

  // Tahap 2: tampilkan data satu per satu
  for i := 1 to JmlMhs do
  begin
    TampilMahasiswa(i);
    if i < JmlMhs then
      writeln('Tekan sembarang tombol untuk melihat data selanjutnya..')
    else
      writeln('Seluruh data telah ditampilkan. Tekan sembarang tombol untuk keluar..');
    TungguTombol;
  end;
end.