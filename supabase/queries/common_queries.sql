-- ============================================================
-- TUS Asistanı — Sık Kullanılan Sorgular
-- ============================================================

-- ── Tablo İlişkisi ───────────────────────────────────────────
--
-- kullanicilar
--     └── desteler
--             └── kartlar
--                     └── kart_durumlari  (FSRS verisi)
--                     └── tekrar_gecmisi  (AI için ham veri)
--     └── kullanici_istatistik            (günlük özet)

-- ── 1a. Bugün tekrar edilecek kartlar (tüm desteler) ─────────
SELECT
    k.id,
    k.on_yuz,
    k.arka_yuz,
    k.deste_id,
    kd.state,
    kd.difficulty,
    kd.lapses,
    kd.due
FROM kartlar k
JOIN kart_durumlari kd ON k.id = kd.kart_id
WHERE
    kd.kullanici_id = 'kullanici-uuid'
    AND kd.due <= NOW()
ORDER BY kd.due ASC;

-- ── 1b. Bugün tekrar edilecek kartlar (belirli bir deste) ────
-- kart_durumlari → kartlar → desteler join zinciri
SELECT
    k.id,
    k.on_yuz,
    k.arka_yuz,
    kd.state,
    kd.difficulty,
    kd.lapses,
    kd.due
FROM kartlar k
JOIN desteler d      ON k.deste_id = d.id
JOIN kart_durumlari kd ON k.id = kd.kart_id
WHERE
    kd.kullanici_id = 'kullanici-uuid'
    AND d.id        = 'deste-uuid'        -- deste filtresi
    AND kd.due <= NOW()
ORDER BY kd.due ASC;

-- ── 2. Deste bazlı kart sayısı ───────────────────────────────
SELECT
    d.id,
    d.baslik,
    d.toplam_kart,
    COUNT(kd.id) FILTER (WHERE kd.due <= NOW()) AS bugun_tekrar
FROM desteler d
LEFT JOIN kartlar k ON k.deste_id = d.id
LEFT JOIN kart_durumlari kd ON kd.kart_id = k.id AND kd.kullanici_id = 'kullanici-uuid'
WHERE d.kullanici_id = 'kullanici-uuid'
GROUP BY d.id;

-- ── 3. Kullanıcı günlük özet (streak dahil) ──────────────────
SELECT *
FROM kullanici_istatistik
WHERE kullanici_id = 'kullanici-uuid'
ORDER BY tarih DESC
LIMIT 30;

-- ── 4. Tekrar geçmişi (AI için) ──────────────────────────────
SELECT
    tg.tarih,
    tg.rating,
    tg.cevap_suresi_ms,
    tg.onceki_state,
    tg.yeni_state,
    k.on_yuz
FROM tekrar_gecmisi tg
JOIN kartlar k ON k.id = tg.kart_id
WHERE tg.kullanici_id = 'kullanici-uuid'
ORDER BY tg.tarih DESC
LIMIT 100;
