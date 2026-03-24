# 🏆 ASISTUS - PREMIUM İÇERİK ÜRETİM REHBERİ (MASTER GUIDE)

Bu belge, **AsisTus** uygulamasındaki tüm branşlar (Mikrobiyoloji, Patoloji, Dahiliye, Pediatri vb.) için oluşturulacak soru ve flashkartların **kalite standartlarını** belirler. Hem Claude hem de diğer asistanlar yeni içerik üretirken bu kurallara **kesinlikle** uymalıdır.

---

## 👨‍🏫 1. ANLATIM TARZI (TON VE ÜSLUP)
- **Karakter:** Alanında uzman bir profesör (Örn: Dr. Feyyaz Akay tarzı).
- **Dil:** Samimi ama akademik derinliği olan, öğretici ve "püf noktası" veren bir dil.
- **Hedef:** Öğrencinin sadece ezberlemesini değil, konunun mantığını (patofizyolojisini) kavramasını sağlamak.

---

## 🃏 2. MÜKEMMEL FLASHKART STANDARTLARI
Her flashkart şu 4 öğeyi içermelidir:
1.  **Net Soru:** Tek bir bilgiye odaklanan, kafa karıştırmayan soru.
2.  **Kısa Cevap:** Net ve kesin yanıt.
3.  **Etiket (Tags):** İlgili mikrobiyolojik etken veya klinik tablo adı.
4.  **💡 HİKAYE (Story Hint):** 
    - Mutlaka bir **Mnemonic (Hafıza Teknikleri)** içermeli.
    - Bilgiyi gerçek hayatla veya komik bir kodlamayla bağdaştırmalı.
    - *Örnek: "Protein A = Antikoru ters giydiren hırsız!"*

---

## 🏥 3. MÜKEMMEL KLİNİK VAKA (CASE) STANDARTLARI
Tüm vaka soruları şu yapıda olmalıdır:
1.  **Vaka Senaryosu:** Gerçekçi, TUS formatında, ipuçları içeren paragraf.
2.  **5 Seçenek (A-E):** 
    - Seçenekler birbiriyle uyumlu olmalı.
    - **KESİNLİKLE "İntegronlar" gibi anlamsız sabit şıklar kullanılmamalı.**
    - Çeldiriciler (distractors) konuya yakın diğer hastalıklar veya etkenler olmalıdır.
3.  **Açıklama (Explanation):**
    - **PROFESÖR DEĞERLENDİRMESİ:** Doğru cevabın neden doğru olduğunu açıklar.
    - **🎓 HOCA ÖZETİ:** Yan şıkların neden yanlış olduğunu kısaca belirtir ve "Triad" (üçlemeler) gibi ezber bilgiler verir.
    - **TUS SPOT:** Konuyla ilgili çıkmış veya çıkabilecek 1-2 cümlelik hap bilgi.

---

## 🛠️ 4. ÖRNEK JSON FORMATI (ALTIN STANDART)

### Mükemmel Flashkart Örneği:
```json
{
  "id": "fc-micro-001",
  "question": "S. aureus'un IgG'nin Fc kısmına bağlanan proteini hangisidir?",
  "answer": "Protein A",
  "difficulty": "medium",
  "tags": ["Staph"],
  "story_hint": "💡 HİKAYE: Protein A, antikorun kuyruğunu (Fc) yakalar ve onu ters çevirir. 'Protein A = Antikoru ters giydiren A-jan' diye kodla!"
}
```

### Mükemmel Vaka Sorusu Örneği:
```json
{
  "id": "cc-micro-001",
  "case": "25 yaşında, çiftçilikle uğraşan bir hasta, elinde ağrısız, ortası siyah nekrotik bir yara (eskar) şikayetiyle başvuruyor. Etkenin en önemli virülans faktörü nedir?",
  "options": [
    "A) Polipeptid yapıda kapsül",
    "B) LOS (Lipooligosakkarid)",
    "C) Kolera toksini",
    "D) Protein A",
    "E) M Proteini"
  ],
  "correct_answer": "A) Polipeptid yapıda kapsül",
  "explanation": "PROFESÖR DEĞERLENDİRMESİ: Vakada tarif edilen 'ortası siyah ağrısız eskar' tipik Şarbon (B. anthracis) lezyonudur. Şarbonun en önemli özelliği, bakteriler arasında istisna olarak kapsülünün 'D-Glutamat' (Polipeptid) yapıda olmasıdır.\n\n🎓 HOCA ÖZETİ: D-Glutamat kapsül fagositozu önler. Diğer seçeneklerden LOS Neisseria'da, Protein A S. aureus'ta görülür.\n\n📍 TUS SPOT: Şarbon = Malign Püstül + Polipeptid Kapsül + Medusa Başı Kolonisi.",
  "difficulty": "hard"
}
```

---

## 📌 5. UNUTULMAMASI GEREKENLER
1.  Hiçbir zaman 4 seçenekli soru bırakma, her zaman 5 seçeneğe tamamla.
2.  Tıbbi terminolojiyi doğru kullan ama açıklamaları basitleştirerek anlat.
3.  Hafıza tekniklerine (kodlamalara) içerik içinde ağırlık ver.
4.  Vaka soruları her zaman branşın en güncel ve en çok çıkan spot bilgilerini sormalıdır.
