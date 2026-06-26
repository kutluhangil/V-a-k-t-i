# Vakti — Geliştirme Planı (v1.1, Android odaklı)

Branch: `feature/v1.1-android`. iOS bu turda dokunulmuyor (Play Store önceliği).
DNA korunur: offline-first, reklamsız, login yok, analytics yok, TR+EN.

Her özellik: kod + `dart analyze lib test` temiz + `flutter test` yeşil → commit.

---

## Durum tablosu

| # | Özellik | Öncelik | Durum |
|---|---------|---------|-------|
| A | **Premium Android widget** (yeniden tasarım) | ⭐ yüksek | ✅ |
| B | Streak (günlük seri) | yüksek | ✅ |
| C | in_app_review — "Değerlendir" tile | düşük efor | ✅ |
| D | Arama (tüm kartlarda) | orta | ✅ |
| E | İlgi alanı seçimi → feed önceliklendirme | orta | ✅ |
| F | Bildirim içeriği zenginleştir (günün kartı başlığı) | düşük | ✅ |
| G | Haptics + time-arc mikro animasyon | düşük | ✅ |

**v1.1 turu tamam** — `dart analyze` temiz, 24/24 test, AAB derlendi.
Branch `feature/v1.1-android`. iOS dokunulmadı.

---

## A. Premium Android widget

**Sorun:** mevcut widget tek `LinearLayout`, düz `#14181F` bg, statik 4 metin. Premium değil.

**Hedef tasarım — "golden hour" kart:**
- Golden-hour gradient arkaplan (ink → koyu saffron ton), r20 köşe, ince saffron stroke.
- Sol üstte saffron **time-arc** motif (zaman yayı) — drawable olarak.
- Üst satır: küçük büyük-harf "VAKTİ" kicker + sağda tarih (örn. "26 HAZ").
- Emoji + kategori etiketi (saffron pill).
- Başlık (Fraunces hissi — bold, 2 satır).
- "Ne zaman" satırı (1-2 satır, paper renk).
- Alt: ince ayraç + streak chip ("🔥 3 gün") opsiyonel.
- Responsive: küçük (2×2) ve geniş (4×2) için aynı layout, gravity/maxLines uyumlu.
- Tap → uygulamada o kartı açar (mevcut davranış korunur).

**Dosyalar:**
- `res/drawable/vakti_widget_bg.xml` → gradient + stroke.
- `res/drawable/vakti_widget_arc.xml` → time-arc vektör.
- `res/drawable/vakti_widget_pill.xml` → kategori/streak pill bg.
- `res/layout/vakti_widget.xml` → yeniden düzen.
- `res/values/colors.xml` → marka renkleri (XML'de hardcode yerine).
- `VaktiWidgetProvider.kt` → yeni alanları (category, date, streak) yaz.
- `widget_service.dart` → category/date/streak verisini gönder.
- `vakti_widget_info.xml` → preview + boyut ayarı.

## B. Streak (günlük seri)

- `LocalStore`: `kStreakCount`, `kStreakBest`, `kStreakLastDate` (yyyy-MM-dd).
- `StreakService` + `streakProvider`: uygulama açılışında "bugün" işaretle.
  Ardışık gün → +1; bir gün atlanırsa → 1'e sıfırla; aynı gün → değişmez.
- Feed üstünde küçük streak chip; Settings'te satır; widget'a aktar (A ile bağ).
- Test: ardışık/atlama/aynı-gün mantığı.

## C. in_app_review

- `in_app_review` paketi ekle.
- Settings'e "Uygulamayı değerlendir" tile (ARB `settingsRateApp` zaten var).
- `requestReview()` (uygun değilse `openStoreListing`).

## D. Arama

- Browse üstünde arama alanı → `searchQueryProvider` + `searchResultsProvider`.
- title/primary/secondary içinde (aktif dil) case-insensitive eşleşme.
- Sonuç listesi `FavoriteCard` benzeri; boşsa empty state.
- Test: sorgu filtreler.

## E. İlgi alanı seçimi (kişiselleştirme, local)

- `LocalStore`: `kInterests` (List<String> kategori id).
- Settings'te çoklu seçim (kategori chip'leri).
- `feedTipsProvider`: seçili kategoriler öne sıralanır (deterministik, backend yok).
- Onboarding'e opsiyonel adım (sonra; ilk etap Settings).

## F. Bildirim zenginleştirme

- `reminder_copy` / scheduleDaily: gövdeye günün kartının başlığını koy
  ("Bugün: Zencefil Çayı — sabah aç karnına").

## G. Polish

- Kart geçişinde haptic (`HapticFeedback.selectionClick`).
- TipCard time-arc çizilme animasyonu (TweenAnimationBuilder).

---

## Ertelenenler (bu turda değil — gerekçeli)

- **Content 88→150+**: sağlık içeriği elle, dikkatli yazılmalı (klinik/mutlak iddia
  yasak §13). Otomatik üretim riskli → ayrı içerik turu.
- **Crashlytics/Sentry**: Play Console **Android Vitals** zaten SDK'sız crash raporu
  verir; offline-no-analytics DNA'sını korumak için harici SDK eklenmez.
- **Favoriler → koleksiyonlar**: kapsamlı; arama + ilgi alanından sonra v1.2.
- **Tema varyasyonları**: saffron marka kilidi; AMOLED siyah varyantı v1.2.
- **TTS / sesli okuma, WearOS, topluluk içerik**: v2 büyük bahisler.
- **iOS widget Xcode adımı**: iOS turu ayrı.

---

## Pazarlama (kod-dışı, takip)
- ASO TR+EN listing (`/aso`).
- Mağaza ekran görüntüleri TR+EN.
- 12 tester × 14 gün kapalı test (devam ediyor).
