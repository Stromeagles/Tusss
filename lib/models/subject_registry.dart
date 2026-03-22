import 'package:flutter/material.dart';

/// Uygulamaya kayıtlı tüm ders modülleri.
/// Yeni bir branş eklemek için sadece bu listeye bir [SubjectModule] girdisi ekleyin
/// ve assets/data/ klasörüne JSON dosya(lar)ını koyun — başka hiçbir şeyi değiştirmeniz gerekmez.
class SubjectModule {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String shortLabel;

  /// Bir branşın tüm JSON dosyalarının listesi.
  /// Aynı dersin birden fazla bölümü tek modül altında toplanabilir.
  final List<String> assetPaths;

  const SubjectModule({
    required this.id,
    required this.name,
    required this.assetPaths,
    required this.icon,
    required this.color,
    required this.shortLabel,
  });
}

class SubjectRegistry {
  SubjectRegistry._();

  static const List<SubjectModule> modules = [
    SubjectModule(
      id: 'mikrobiyoloji',
      name: 'Mikrobiyoloji',
      shortLabel: 'Mikro',
      icon: Icons.biotech_rounded,
      color: Color(0xFF79C0FF),
      assetPaths: [
        'assets/data/microbiology_ch1.json',
        'assets/data/microbiology_ch2_toxins.json',
        'assets/data/microbiology_ch3_sterilization_vaccines.json',
        'assets/data/microbiology_ch4_staining_media.json',
        'assets/data/microbiology_ch5_6_antibiotics.json',
        'assets/data/microbiology_immuno_module.json',
        'assets/data/microbiology_gram_pos_cocci.json',
        'assets/data/microbiology_gram_pos_bacilli.json',
        'assets/data/microbiology_mycobacteria.json',
        'assets/data/microbiology_gram_neg_basics.json',
        'assets/data/microbiology_enterics.json',
        'assets/data/microbiology_gram_neg_other.json',
        'assets/data/microbiology_gram_neg_zoonotic.json',
        'assets/data/microbiology_anaerobes_spirochetes_chlamydia.json',
        'assets/data/microbiology_viro_intro.json',
        'assets/data/microbiology_virology_dna.json',
        'assets/data/microbiology_virology_rna.json',
        'assets/data/microbiology_mycology.json',
        'assets/data/microbiology_mycology_final.json',
        'assets/data/microbiology_parasitology.json',
        'assets/data/microbiology_bact_cocci.json',
        'assets/data/microbiology_bact_gramneg_part1.json',
        'assets/data/microbiology_bact_gramneg_part2.json',
        'assets/data/microbiology_bact_myco_part1.json',
        'assets/data/microbiology_bact_others.json',
        'assets/data/microbiology_bact_spores.json',
        'assets/data/microbiology_virology_myco_intro.json',
        'assets/data/microbiology_virology_part1.json',
        'assets/data/microbiology_virology_part2.json',
        // ── 500 Yeni Kart (TUS 2023-2025) ──────────────────────────────
        'assets/data/microbiology_batch1A.json',
        'assets/data/microbiology_batch1B.json',
        'assets/data/microbiology_batch1C.json',
        'assets/data/microbiology_batch1D.json',
        'assets/data/microbiology_batch2A.json',
        'assets/data/microbiology_batch2B.json',
        'assets/data/microbiology_batch2C.json',
        'assets/data/microbiology_batch3A.json',
        'assets/data/microbiology_batch3B.json',
        'assets/data/microbiology_batch4A.json',
        'assets/data/microbiology_prof_200.json',
        // ── 200 Mikrobiyoloji Sorusu (Soru Bankası) ────────────────────
        'assets/data/mikrobiyoloji_200_soru.json',
      ],
    ),
    SubjectModule(
      id: 'patoloji',
      name: 'Patoloji',
      shortLabel: 'Patolo',
      icon: Icons.science_rounded,
      color: Color(0xFFF78166),
      assetPaths: [
        'assets/data/pathology_module.json',
        'assets/data/pathology_hemo_immuno.json',
        'assets/data/pathology_neo_sys1.json',
        'assets/data/pathology_sys2.json',
        'assets/data/pathology_sys3.json',
        'assets/data/pathology_sys4.json',
        // ── 500 High-Yield TUS Patoloji Kartları ────────────────────────
        'assets/data/pathology_batch1A.json', // GİS 50 kart
        'assets/data/pathology_batch1B.json', // GİS son + Hücre Hasarı 50 kart
        'assets/data/pathology_batch2A.json', // Neoplazi 46 kart
        'assets/data/pathology_batch2B.json', // Solunum + Üriner 33 kart
        'assets/data/pathology_batch3A.json', // Kas İskelet + İmmün 33 kart
        'assets/data/pathology_batch3B.json', // Kadın Genital + Meme + Deri 28 kart
        'assets/data/pathology_batch4A.json', // Hepatobilier + İnflamasyon + Hemodinamik 19 kart
        'assets/data/pathology_batch4B.json', // Kardiyovasküler + Hemopoetik + Erkek Genital 20 kart
        'assets/data/pathology_batch5A.json', // Onarım + Endokrin + Sinir Sistemi 22 kart
        'assets/data/pathology_batch5B.json', // Solunum + Hepatobilier + Üriner + İmmün 50 kart
        'assets/data/pathology_batch5C.json', // Meme + Deri + Kadın Genital Ek Kartlar 50 kart
        'assets/data/pathology_batch5D.json', // Hemodinamik + KV + İnflamasyon + Hemopoetik 50 kart
        'assets/data/pathology_batch5E.json', // Karma Yüksek Verimli - 500. Tamamlayıcı 50 kart
        'assets/data/pathology_vaka_100.json', // 100 Vaka Kampı
        // ── 331 Konsolide Patoloji Kartları ────────────────────────
        'assets/data/patoloji_kons_batch1.json', // Konsolide 110 kart
        'assets/data/patoloji_kons_batch2.json', // Konsolide 110 kart
        'assets/data/patoloji_kons_batch3.json', // Konsolide 111 kart
      ],
    ),
    SubjectModule(
      id: 'anatomi',
      name: 'Anatomi',
      shortLabel: 'Anatom',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFFFF9E7D),
      assetPaths: [
        'assets/data/anatomi_200_soru.json',
        'assets/data/anatomi_batch1.json',
        'assets/data/anatomi_batch2.json',
        'assets/data/anatomi_batch3.json',
      ],
    ),
  ];

  static SubjectModule? findById(String id) {
    try {
      return modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
