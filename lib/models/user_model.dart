/// Kullanıcı profil modeli — SharedPreferences ile kalıcı hale getirilir.
class UserProfile {
  final String name;
  final int targetScore;
  final String targetBranch;
  final String profileEmoji;
  final int dailyGoal;
  final bool reminderEnabled;
  final DateTime? targetDate;
  final String? profileImagePath;

  const UserProfile({
    this.name = 'KlinDoktor',
    this.targetScore = 60,
    this.targetBranch = 'Henüz Seçilmedi',
    this.profileEmoji = 'T',
    this.dailyGoal = 20,
    this.reminderEnabled = false,
    this.targetDate,
    this.profileImagePath,
  });

  UserProfile copyWith({
    String? name,
    int? targetScore,
    String? targetBranch,
    String? profileEmoji,
    int? dailyGoal,
    bool? reminderEnabled,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? profileImagePath,
    bool clearProfileImage = false,
  }) =>
      UserProfile(
        name: name ?? this.name,
        targetScore: targetScore ?? this.targetScore,
        targetBranch: targetBranch ?? this.targetBranch,
        profileEmoji: profileEmoji ?? this.profileEmoji,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
        profileImagePath: clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'targetScore': targetScore,
        'targetBranch': targetBranch,
        'profileEmoji': profileEmoji,
        'dailyGoal': dailyGoal,
        'reminderEnabled': reminderEnabled,
        'targetDate': targetDate?.toIso8601String(),
        'profileImagePath': profileImagePath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'KlinDoktor',
        targetScore: json['targetScore'] as int? ?? 60,
        targetBranch: json['targetBranch'] as String? ?? 'Henüz Seçilmedi',
        profileEmoji: json['profileEmoji'] as String? ?? 'T',
        dailyGoal: json['dailyGoal'] as int? ?? 20,
        reminderEnabled: json['reminderEnabled'] as bool? ?? false,
        targetDate: json['targetDate'] != null
            ? DateTime.tryParse(json['targetDate'] as String)
            : null,
        profileImagePath: json['profileImagePath'] as String?,
      );

  /// TUS uzmanlık dalları listesi
  static const List<String> branches = [
    'Henüz Seçilmedi',
    'Acil Tıp',
    'Aile Hekimliği',
    'Anatomi',
    'Anesteziyoloji',
    'Beyin Cerrahisi',
    'Biyokimya',
    'Çocuk Cerrahisi',
    'Çocuk Sağlığı',
    'Dermatoloji',
    'Enfeksiyon Hastalıkları',
    'Fiziksel Tıp',
    'Genel Cerrahi',
    'Göğüs Cerrahisi',
    'Göğüs Hastalıkları',
    'Göz Hastalıkları',
    'Histoloji',
    'İç Hastalıkları',
    'Kadın Hastalıkları',
    'Kalp Damar Cerrahisi',
    'Kardiyoloji',
    'KBB',
    'Mikrobiyoloji',
    'Nöroloji',
    'Ortopedi',
    'Patoloji',
    'Plastik Cerrahi',
    'Psikiyatri',
    'Radyoloji',
    'Üroloji',
  ];
}
