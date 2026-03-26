// ── TUS High-Yield Öncelik Hesaplama ─────────────────────────────────────
// Konu başlığı/branş/chapter'a göre TUS'ta çıkma sıklığına (0-10) göre puan.
// Compute isolate içinden çağrıldığı için top-level pure function olarak tanımlandı.

int _tusPriority(String subject, String chapter, String topic) {
  final text = '$subject $chapter $topic'.toLowerCase();

  bool has(List<String> kws) => kws.any(text.contains);

  // ── 10/10 — TUS'ta en çok çıkan konular ──────────────────────────────
  if (has(['mycobacterium', 'tüberküloz', 'tbc', ' tb ', 'tb\'den'])) return 10;
  if (has(['staphyloco', 'stafiloko', 'staph aureus', 'mrsa', 'altın sarısı'])) return 10;
  if (has(['streptoco', 'streptokok', 'strep pnöm', 's. pyogenes', 's. agalactiae'])) return 10;
  if (has(['neoplazi', 'tümör', 'malign', 'kanser', 'lenfoma', 'lösemi', 'karsinoma',
            'neoplasm', 'tumor'])) return 10;
  if (has(['antibiyotik', 'antibiyo', 'beta-laktam', 'penisilin', 'sefalosporin',
            'karbapenem', 'aminoglikozit', 'makrolid', 'florokinolon', 'vankomisin'])) return 10;

  // ── 9/10 ──────────────────────────────────────────────────────────────
  if (has(['hepatit b', 'hbv', 'hepatit c', 'hcv', 'viral hepatit'])) return 9;
  if (has(['hiv', 'aids', 'retrovirüs', 'retrovirus'])) return 9;
  if (has(['inflamasyon', 'enflamasyon', 'akut inflamasyon', 'kronik inflamasyon'])) return 9;
  if (has(['e. coli', 'escherichia', 'escherichia coli', 'klebsiella', 'enterobakter',
            'enterobacteriaceae'])) return 9;
  if (has(['kranyal sinir', 'kranial sinir', 'kafa çifti', 'n. facialis', 'facial nerve',
            'n. vagus', 'n. trigeminus'])) return 9;
  if (has(['dna replikasyon', 'rna sentezi', 'gen ekspresyon', 'mutasyon mekanizm',
            'genetik bozukluk', 'transkripsiyon', 'translasyon'])) return 9;
  if (has(['miyokard infarktüs', 'koroner', 'iskemik kalp', 'angina pektoris'])) return 9;
  if (has(['hematoloji', 'demir eksikliği', 'b12 eksikliği', 'folat eksikliği',
            'aplastik anemi', 'orak hücre'])) return 9;

  // ── 8/10 ──────────────────────────────────────────────────────────────
  if (has(['clostridium', 'botulizm', 'botulinum', 'tetanoz', 'tetanus',
            'c. difficile'])) return 8;
  if (has(['salmonella', 'shigella', 'tifo', 'dizanteri'])) return 8;
  if (has(['pseudomonas', 'acinetobacter'])) return 8;
  if (has(['kardiyovasküler', 'kalp yetmezliği', 'kalp kapak', 'aort',
            'ateroskleroz'])) return 8;
  if (has(['renal', 'böbrek yetmezliği', 'glomerülonefrit', 'nefrotik',
            'nefritik'])) return 8;
  if (has(['solunum yetmezliği', 'koah', 'astım', 'pnömoni', 'pulmoner'])) return 8;
  if (has(['immün sistem', 'immünoloji', 'immünyetmezlik', 'otoimmün',
            'hipersensitivite', 'alerjik'])) return 8;
  if (has(['brakiyal pleksus', 'pleksus', 'sinir hasarı', 'motor sinir',
            'duyu siniri', 'dermalom'])) return 8;
  if (has(['otonom sinir', 'adrenerjik', 'kolinerjik', 'sempatik', 'parasempatik'])) return 8;
  if (has(['karaciğer patoloji', 'siroz', 'hepatoselüler', 'portal hipertansiyon'])) return 8;
  if (has(['glikoliz', 'krebs', 'glukoneogenez', 'glukoz metabolizma',
            'insülin direnci', 'diyabet tip'])) return 8;
  if (has(['nsaİİ', 'nsaid', 'antienflamatuvar', 'kortikosteroid', 'steroid'])) return 8;
  if (has(['endokrin', 'tiroid hastalık', 'hipertiroidi', 'hipotiroidi',
            'cushing', 'addison'])) return 8;

  // ── 7/10 ──────────────────────────────────────────────────────────────
  if (has(['fungal', 'mantar', 'kandida', 'aspergillus', 'kriptoko', 'dermatofit'])) return 7;
  if (has(['neisseria', 'meningokok', 'gonoko', 'n. meningitidis'])) return 7;
  if (has(['lipid metabolizma', 'kolesterol', 'lipoprotein', 'ateroskleroz oluşum'])) return 7;
  if (has(['protein sentezi', 'amino asit', 'enzim kinetiği'])) return 7;
  if (has(['merkezi sinir sistemi', 'mss', 'beyin', 'nöroloji', 'nöron'])) return 7;
  if (has(['antivirал', 'antiviral'])) return 7;
  if (has(['hemostaz', 'pıhtılaşma', 'tromboz', 'emboli'])) return 7;

  // ── 6/10 ──────────────────────────────────────────────────────────────
  if (has(['parazit', 'protozoa', 'helmint', 'parazitoloji', 'sıtma', 'plasmodium',
            'leishmania', 'toxoplasma'])) return 6;
  if (has(['kas iskelet', 'eklem', 'kemik', 'kıkırdak'])) return 6;
  if (has(['gelişim', 'embriyoloji', 'embriyo'])) return 6;
  if (has(['histoloji', 'doku', 'epitel'])) return 6;

  // ── Branş bazlı varsayılan ────────────────────────────────────────────
  final sub = subject.toLowerCase();
  if (sub.contains('mikrobiyoloji')) return 7;
  if (sub.contains('patoloji'))     return 7;
  if (sub.contains('farmakoloji'))  return 7;
  if (sub.contains('fizyoloji'))    return 6;
  if (sub.contains('biyokimya'))    return 6;
  if (sub.contains('anatomi'))      return 6;
  if (sub.contains('histoloji'))    return 5;
  if (sub.contains('embriyoloji'))  return 5;

  return 5;
}

// ─────────────────────────────────────────────────────────────────────────────

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String difficulty;
  final String? storyHint;
  final List<String> tags;
  /// TUS High-Yield öncelik puanı (1–10). Topic'ten miras alınır.
  /// Yüksek değer = TUS'ta daha sık çıkan konu → yeni kartlarda öne alınır.
  final int priority;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.difficulty,
    this.storyHint,
    required this.tags,
    this.priority = 5,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json, [int inheritedPriority = 5]) {
    return Flashcard(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      storyHint: json['story_hint']?.toString(),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      priority: (json['priority'] as int?) ?? inheritedPriority,
    );
  }
}

class ClinicalCase {
  final String id;
  final String caseText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  /// TUS High-Yield öncelik puanı (1–10). Topic'ten miras alınır.
  final int priority;

  const ClinicalCase({
    required this.id,
    required this.caseText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.priority = 5,
  });

  /// Soru metninden konu bilgisini cikarir.
  String get topic {
    final match = RegExp(r'Soru:\(([^)]+)\)').firstMatch(caseText);
    return match?.group(1) ?? '';
  }

  /// Konu prefix'i cikarilmis saf soru metni.
  String get cleanText {
    return caseText
        .replaceFirst(RegExp(r'Soru:\([^)]+\)\s*'), '')
        .trim();
  }

  factory ClinicalCase.fromJson(Map<String, dynamic> json, [int inheritedPriority = 5]) {
    return ClinicalCase(
      id: json['id']?.toString() ?? '',
      caseText: (json['case'] ?? json['question'] ?? '').toString(),
      options: json['options'] is List ? List<String>.from(json['options']) : [],
      correctAnswer: json['correct_answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      priority: (json['priority'] as int?) ?? inheritedPriority,
    );
  }
}

class Topic {
  final String id;
  final String subject;
  final String chapter;
  final String topic;
  final String subTopic;
  final String contentSummary;
  final List<Flashcard> flashcards;
  final List<String> tusSpots;
  final List<ClinicalCase> clinicalCases;
  /// TUS High-Yield öncelik puanı (1–10).
  /// JSON'da 'priority' varsa onu kullanır; yoksa konu/branş bazlı otomatik hesaplanır.
  final int priority;

  const Topic({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.subTopic,
    required this.contentSummary,
    required this.flashcards,
    required this.tusSpots,
    required this.clinicalCases,
    this.priority = 5,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    final subject = json['subject']?.toString() ?? '';
    final chapter = json['chapter']?.toString() ?? '';
    final topic   = json['topic']?.toString()   ?? '';

    // JSON'da öncelik varsa kullan, yoksa TUS ağırlık tablosundan hesapla
    final priority = (json['priority'] as int?) ??
        _tusPriority(subject, chapter, topic);

    return Topic(
      id: json['id']?.toString() ?? '',
      subject: subject,
      chapter: chapter,
      topic: topic,
      subTopic: json['sub_topic']?.toString() ?? '',
      contentSummary: json['content_summary']?.toString() ?? '',
      priority: priority,
      // Flashcard ve ClinicalCase'lere topic priority'si miras bırakılır
      flashcards: json['flashcards'] is List
          ? (json['flashcards'] as List)
              .map((fc) => Flashcard.fromJson(fc as Map<String, dynamic>, priority))
              .toList()
          : [],
      tusSpots: json['tus_spots'] is List
          ? List<String>.from(json['tus_spots'])
          : [],
      clinicalCases: json['clinical_cases'] is List
          ? (json['clinical_cases'] as List)
              .map((cc) => ClinicalCase.fromJson(cc as Map<String, dynamic>, priority))
              .toList()
          : [],
    );
  }

  int get totalFlashcards => flashcards.length;
  int get totalCases => clinicalCases.length;
}
