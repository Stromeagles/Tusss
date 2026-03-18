import 'package:flutter_test/flutter_test.dart';
import 'package:tus_asistani/models/sm2_model.dart';

void main() {
  group('SM2CardData.initial()', () {
    test('varsayılan easeFactor 2.5 olmalı', () {
      final card = SM2CardData.initial('card_001');
      expect(card.easeFactor, equals(2.5));
    });

    test('varsayılan repetitions 0 olmalı', () {
      final card = SM2CardData.initial('card_001');
      expect(card.repetitions, equals(0));
    });

    test('varsayılan interval 1 olmalı', () {
      final card = SM2CardData.initial('card_001');
      expect(card.interval, equals(1));
    });

    test('cardId doğru atanmalı', () {
      final card = SM2CardData.initial('test_card');
      expect(card.cardId, equals('test_card'));
    });
  });

  group('isDue', () {
    test('geçmiş tarih için true döndürmeli', () {
      final card = SM2CardData(
        cardId: 'card_001',
        nextReviewDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(card.isDue, isTrue);
    });

    test('gelecek tarih için false döndürmeli', () {
      final card = SM2CardData(
        cardId: 'card_001',
        nextReviewDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(card.isDue, isFalse);
    });

    test('bugünün tarihi için true döndürmeli', () {
      final now = DateTime.now();
      final card = SM2CardData(
        cardId: 'card_001',
        nextReviewDate: DateTime(now.year, now.month, now.day),
      );
      expect(card.isDue, isTrue);
    });
  });

  group('computeNext() — doğru yanıt (quality >= 3)', () {
    test('ilk tekrar: repetitions=0 → interval=1, yeni repetitions=1', () {
      final card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 0,
        interval: 1,
        nextReviewDate: DateTime.now(),
      );
      final next = card.computeNext(4);
      expect(next.interval, equals(1));
      expect(next.repetitions, equals(1));
    });

    test('ikinci tekrar: repetitions=1 → interval=6, yeni repetitions=2', () {
      final card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 1,
        interval: 1,
        nextReviewDate: DateTime.now(),
      );
      final next = card.computeNext(4);
      expect(next.interval, equals(6));
      expect(next.repetitions, equals(2));
    });

    test('üçüncü tekrar: repetitions=2 → interval = round(interval * newEF), repetitions=3', () {
      final card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 2,
        interval: 6,
        nextReviewDate: DateTime.now(),
      );
      final next = card.computeNext(4);
      // quality=4: newEF = 2.5 + (0.1 - 1 * (0.08 + 1 * 0.02)) = 2.5 + (0.1 - 0.10) = 2.5
      final expectedInterval = (6 * 2.5).round(); // 15
      expect(next.interval, equals(expectedInterval));
      expect(next.repetitions, equals(3));
    });

    test('mükemmel yanıt (quality=5) ile easeFactor artmalı', () {
      final card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 0,
        interval: 1,
        nextReviewDate: DateTime.now(),
      );
      final next = card.computeNext(5);
      // newEF = 2.5 + (0.1 - 0 * (0.08 + 0 * 0.02)) = 2.5 + 0.1 = 2.6
      expect(next.easeFactor, closeTo(2.6, 0.001));
    });
  });

  group('computeNext() — yanlış yanıt (quality < 3)', () {
    test('quality=0 ile repetitions sıfırlanmalı', () {
      final card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 5,
        interval: 20,
        nextReviewDate: DateTime.now(),
      );
      final next = card.computeNext(0);
      expect(next.repetitions, equals(0));
      expect(next.interval, equals(1));
    });

    test('quality=1 ile repetitions sıfırlanmalı', () {
      final card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 3,
        interval: 15,
        nextReviewDate: DateTime.now(),
      );
      final next = card.computeNext(1);
      expect(next.repetitions, equals(0));
      expect(next.interval, equals(1));
    });

    test('quality=2 ile repetitions sıfırlanmalı', () {
      final card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 2,
        interval: 6,
        nextReviewDate: DateTime.now(),
      );
      final next = card.computeNext(2);
      expect(next.repetitions, equals(0));
      expect(next.interval, equals(1));
    });
  });

  group('easeFactor minimum 1.3', () {
    test('çok düşük quality ile easeFactor 1.3 altına düşmemeli', () {
      // easeFactor'ü zaten minimum sınıra yakın bir kartla başla
      SM2CardData card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 1.3,
        repetitions: 0,
        interval: 1,
        nextReviewDate: DateTime.now(),
      );
      // Birden fazla quality=0 uygulaması ile 1.3'ün altına düşmemeli
      for (int i = 0; i < 10; i++) {
        card = card.computeNext(0);
      }
      expect(card.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('quality=0 ile başlangıç easeFactor 2.5 düşer ama 1.3 altına geçmez', () {
      SM2CardData card = SM2CardData(
        cardId: 'card_001',
        easeFactor: 2.5,
        repetitions: 0,
        interval: 1,
        nextReviewDate: DateTime.now(),
      );
      // quality=0: newEF = 2.5 + (0.1 - 5*(0.08 + 5*0.02)) = 2.5 + (0.1 - 5*0.18) = 2.5 - 0.8 = 1.7
      final next = card.computeNext(0);
      expect(next.easeFactor, greaterThanOrEqualTo(1.3));
    });
  });

  group('toJson / fromJson round-trip', () {
    test('serialize edip deserialize edince aynı değerler olmalı', () {
      final original = SM2CardData(
        cardId: 'round_trip_card',
        easeFactor: 2.3,
        repetitions: 4,
        interval: 10,
        nextReviewDate: DateTime(2026, 6, 15),
      );

      final json = original.toJson();
      final restored = SM2CardData.fromJson(json);

      expect(restored.cardId, equals(original.cardId));
      expect(restored.easeFactor, equals(original.easeFactor));
      expect(restored.repetitions, equals(original.repetitions));
      expect(restored.interval, equals(original.interval));
      expect(restored.nextReviewDate, equals(original.nextReviewDate));
    });

    test('toJson doğru anahtarları içermeli', () {
      final card = SM2CardData.initial('json_key_test');
      final json = card.toJson();

      expect(json.containsKey('cardId'), isTrue);
      expect(json.containsKey('easeFactor'), isTrue);
      expect(json.containsKey('repetitions'), isTrue);
      expect(json.containsKey('interval'), isTrue);
      expect(json.containsKey('nextReviewDate'), isTrue);
    });

    test('easeFactor double olarak serialize edilmeli', () {
      final card = SM2CardData(
        cardId: 'type_test',
        easeFactor: 2.5,
        repetitions: 0,
        interval: 1,
        nextReviewDate: DateTime(2026, 3, 18),
      );
      final json = card.toJson();
      expect(json['easeFactor'], isA<double>());
    });

    test('nextReviewDate ISO 8601 string olarak serialize edilmeli', () {
      final card = SM2CardData(
        cardId: 'date_test',
        easeFactor: 2.5,
        repetitions: 0,
        interval: 1,
        nextReviewDate: DateTime(2026, 3, 18),
      );
      final json = card.toJson();
      expect(json['nextReviewDate'], isA<String>());
      // ISO 8601 formatında parse edilebilmeli
      expect(() => DateTime.parse(json['nextReviewDate'] as String), returnsNormally);
    });
  });
}
