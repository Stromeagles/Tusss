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
      color: Color(0xFF00D4FF),
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
        'assets/data/microbiology_parasitology.json',
      ],
    ),
    SubjectModule(
      id: 'patoloji',
      name: 'Patoloji',
      shortLabel: 'Patolo',
      icon: Icons.science_rounded,
      color: Color(0xFF9B2C2C),
      assetPaths: [
        'assets/data/pathology_module.json',
        'assets/data/pathology_hemo_immuno.json',
        'assets/data/pathology_neo_sys1.json',
        'assets/data/pathology_sys2.json',
        'assets/data/pathology_sys3.json',
        'assets/data/pathology_sys4.json',
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
