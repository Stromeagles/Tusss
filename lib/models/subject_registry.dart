import 'package:flutter/material.dart';

/// Branş kategorisi: TUS sınavındaki Temel / Klinik ayrımı.
enum SubjectCategory { temel, klinik }

/// Uygulamaya kayıtlı tüm ders modülleri.
/// Yeni bir branş eklemek için sadece bu listeye bir [SubjectModule] girdisi ekleyin
/// ve assets/data/ klasörüne JSON dosya(lar)ını koyun — başka hiçbir şeyi değiştirmeniz gerekmez.
class SubjectModule {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String shortLabel;
  final SubjectCategory category;

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
    required this.category,
  });
}

class SubjectRegistry {
  SubjectRegistry._();

  static const List<SubjectModule> modules = [
    // ══════════════════════════════════════════════════════════════════════════
    // TEMEL BİLİMLER
    // ══════════════════════════════════════════════════════════════════════════
    SubjectModule(
      id: 'anatomi',
      name: 'Anatomi',
      shortLabel: 'Anatom',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFFFF9E7D),
      category: SubjectCategory.temel,
      assetPaths: [
        'assets/data/anatomi_200_soru.json',
        'assets/data/anatomi_batch1.json',
        'assets/data/anatomi_batch2.json',
        'assets/data/anatomi_batch3.json',
      ],
    ),
    SubjectModule(
      id: 'fizyoloji',
      name: 'Fizyoloji',
      shortLabel: 'Fizyo',
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFF7CE38B),
      category: SubjectCategory.temel,
      assetPaths: [
        'assets/data/fizyoloji_batch1.json',
      ],
    ),
    SubjectModule(
      id: 'biyokimya',
      name: 'Biyokimya',
      shortLabel: 'Biyok',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFFE0A3FF),
      category: SubjectCategory.temel,
      assetPaths: [],
    ),
    SubjectModule(
      id: 'mikrobiyoloji',
      name: 'Mikrobiyoloji',
      shortLabel: 'Mikro',
      icon: Icons.biotech_rounded,
      color: Color(0xFF79C0FF),
      category: SubjectCategory.temel,
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
      category: SubjectCategory.temel,
      assetPaths: [
        'assets/data/pathology_module.json',
        'assets/data/pathology_hemo_immuno.json',
        'assets/data/pathology_neo_sys1.json',
        'assets/data/pathology_sys2.json',
        'assets/data/pathology_sys3.json',
        'assets/data/pathology_sys4.json',
        // ── 500 High-Yield TUS Patoloji Kartları ────────────────────────
        'assets/data/pathology_batch1A.json',
        'assets/data/pathology_batch1B.json',
        'assets/data/pathology_batch2A.json',
        'assets/data/pathology_batch2B.json',
        'assets/data/pathology_batch3A.json',
        'assets/data/pathology_batch3B.json',
        'assets/data/pathology_batch4A.json',
        'assets/data/pathology_batch4B.json',
        'assets/data/pathology_batch5A.json',
        'assets/data/pathology_batch5B.json',
        'assets/data/pathology_batch5C.json',
        'assets/data/pathology_batch5D.json',
        'assets/data/pathology_batch5E.json',
        'assets/data/pathology_vaka_100.json',
        // ── 331 Konsolide Patoloji Kartları ────────────────────────
        'assets/data/patoloji_kons_batch1.json',
        'assets/data/patoloji_kons_batch2.json',
        'assets/data/patoloji_kons_batch3.json',
      ],
    ),
    SubjectModule(
      id: 'farmakoloji',
      name: 'Farmakoloji',
      shortLabel: 'Farma',
      icon: Icons.medication_rounded,
      color: Color(0xFFFFD166),
      category: SubjectCategory.temel,
      assetPaths: [
        'assets/data/farmakoloji_batch1.json',
      ],
    ),

    // ══════════════════════════════════════════════════════════════════════════
    // KLİNİK BİLİMLER
    // ══════════════════════════════════════════════════════════════════════════
    SubjectModule(
      id: 'dahiliye',
      name: 'Dahiliye',
      shortLabel: 'Dahili',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF56CCF2),
      category: SubjectCategory.klinik,
      assetPaths: [],
    ),
    SubjectModule(
      id: 'pediatri',
      name: 'Pediatri',
      shortLabel: 'Pedia',
      icon: Icons.child_care_rounded,
      color: Color(0xFFFF6B9D),
      category: SubjectCategory.klinik,
      assetPaths: [],
    ),
    SubjectModule(
      id: 'genel_cerrahi',
      name: 'Genel Cerrahi',
      shortLabel: 'Cerrah',
      icon: Icons.content_cut_rounded,
      color: Color(0xFFF2994A),
      category: SubjectCategory.klinik,
      assetPaths: [],
    ),
    SubjectModule(
      id: 'kadin_dogum',
      name: 'Kadın Hastalıkları ve Doğum',
      shortLabel: 'K.Doğum',
      icon: Icons.pregnant_woman_rounded,
      color: Color(0xFFBB6BD9),
      category: SubjectCategory.klinik,
      assetPaths: [],
    ),
    SubjectModule(
      id: 'kucuk_stajlar',
      name: 'Küçük Stajlar',
      shortLabel: 'K.Staj',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF6FCF97),
      category: SubjectCategory.klinik,
      assetPaths: [],
    ),
  ];

  /// Kategoriye göre filtreleme
  static List<SubjectModule> byCategory(SubjectCategory cat) =>
      modules.where((m) => m.category == cat).toList();

  /// Sadece içerik olan modüller (assetPaths boş olmayanlar)
  static List<SubjectModule> get activeModules =>
      modules.where((m) => m.assetPaths.isNotEmpty).toList();

  static SubjectModule? findById(String id) {
    try {
      return modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
