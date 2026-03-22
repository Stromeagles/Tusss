-- ============================================================
-- TUS Asistanı — Initial Schema
-- Supabase (PostgreSQL) migration
-- ============================================================

-- ── Tablolar ─────────────────────────────────────────────────

-- Kullanıcılar
CREATE TABLE kullanicilar (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email            VARCHAR(255) UNIQUE NOT NULL,
    ad               VARCHAR(100),
    olusturma_tarihi TIMESTAMP DEFAULT NOW(),
    son_giris        TIMESTAMP
);

-- Desteler (Kart grupları)
CREATE TABLE desteler (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kullanici_id     UUID REFERENCES kullanicilar(id) ON DELETE CASCADE,
    baslik           VARCHAR(255) NOT NULL,
    aciklama         TEXT,
    renk             VARCHAR(7),        -- logo rengi için #HEX
    ikon             VARCHAR(50),       -- Flutter icon adı
    toplam_kart      INT DEFAULT 0,
    olusturma_tarihi TIMESTAMP DEFAULT NOW()
);

-- Kartlar
CREATE TABLE kartlar (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deste_id         UUID REFERENCES desteler(id) ON DELETE CASCADE,
    on_yuz           TEXT NOT NULL,     -- soru
    arka_yuz         TEXT NOT NULL,     -- cevap
    medya_url        TEXT,              -- resim/ses varsa
    etiketler        TEXT[],            -- ['python', 'veri yapıları']
    olusturma_tarihi TIMESTAMP DEFAULT NOW()
);

-- FSRS Kart Durumları (her kullanıcı × kart için ayrı)
CREATE TABLE kart_durumlari (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kullanici_id   UUID REFERENCES kullanicilar(id) ON DELETE CASCADE,
    kart_id        UUID REFERENCES kartlar(id) ON DELETE CASCADE,

    -- FSRS alanları
    due            TIMESTAMP DEFAULT NOW(),  -- sonraki tekrar zamanı
    stability      FLOAT DEFAULT 0,          -- hafıza gücü
    difficulty     FLOAT DEFAULT 0,          -- kart zorluğu (0–1)
    elapsed_days   INT DEFAULT 0,            -- son tekrardan geçen gün
    scheduled_days INT DEFAULT 0,            -- planlanan aralık
    reps           INT DEFAULT 0,            -- toplam tekrar sayısı
    lapses         INT DEFAULT 0,            -- unutulma sayısı
    state          SMALLINT DEFAULT 0,       -- 0:New 1:Learning 2:Review 3:Relearning
    last_review    TIMESTAMP,                -- son tekrar zamanı

    UNIQUE(kullanici_id, kart_id)
);

-- Tekrar Geçmişi
CREATE TABLE tekrar_gecmisi (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kullanici_id    UUID REFERENCES kullanicilar(id) ON DELETE CASCADE,
    kart_id         UUID REFERENCES kartlar(id) ON DELETE CASCADE,
    rating          SMALLINT NOT NULL,   -- 1:Again 2:Hard 3:Good 4:Easy
    cevap_suresi_ms INT,                 -- kaç ms'de cevapladı (AI için önemli)
    onceki_state    SMALLINT,
    yeni_state      SMALLINT,
    scheduled_days  INT,
    tarih           TIMESTAMP DEFAULT NOW()
);

-- Kullanıcı İstatistikleri (AI analiz)
CREATE TABLE kullanici_istatistik (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kullanici_id   UUID REFERENCES kullanicilar(id) ON DELETE CASCADE,
    tarih          DATE UNIQUE,
    calisilan_kart INT DEFAULT 0,
    dogru_sayisi   INT DEFAULT 0,
    yanlis_sayisi  INT DEFAULT 0,
    toplam_sure_sn INT DEFAULT 0,   -- günlük çalışma süresi
    streak_gun     INT DEFAULT 0    -- kaç gün üst üste çalıştı
);

-- ── Index'ler ─────────────────────────────────────────────────

-- En sık kullanılacak sorgu: bugün tekrar edilecek kartlar
CREATE INDEX idx_kart_durum_due
    ON kart_durumlari(kullanici_id, due);

-- Deste bazlı kart listesi
CREATE INDEX idx_kartlar_deste
    ON kartlar(deste_id);

-- Deste → kart → kart_durumu join zinciri için composite index
-- (1b sorgusunu hızlandırır: deste filtreli due kartlar)
CREATE INDEX idx_kartlar_deste_id
    ON kartlar(deste_id, id);

-- Tekrar geçmişi sorguları
CREATE INDEX idx_gecmis_kullanici
    ON tekrar_gecmisi(kullanici_id, tarih);
