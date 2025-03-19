# Status rozwoju HackMD dla macOS

> Data ostatniej aktualizacji: 19 marca 2025

## Obecny stan projektu

Projekt jest w fazie alfa-1. Zaimplementowana została podstawowa struktura aplikacji z interfejsem użytkownika i integracją WebView do wyświetlania HackMD.io. Aplikacja kompiluje się i może być uruchamiana, a kluczowe funkcje z planowanej wersji 1.0 są sukcesywnie dodawane.

## Ukończone elementy

- [x] Podstawowy szkielet projektu Xcode
- [x] Główne okno aplikacji z WebView
- [x] Pasek narzędzi z podstawowymi akcjami
- [x] Ekran ładowania (loader podobny do Electrona)
- [x] Wsparcie dla trybu ciemnego/jasnego
- [x] Obsługa narzędzi developerskich
- [x] Podstawowe menu aplikacji
- [x] Obsługa okien dialogowych i powiadomień
- [x] Ikony aplikacji (Assets.xcassets) - format SVG
- [x] Podstawowe okno preferencji użytkownika
- [x] System integracji powiadomień systemowych
- [x] Pełne menu aplikacji zgodne z wytycznymi macOS
- [x] Skonfigurowany GitHub Actions workflow do automatycznego budowania aplikacji
- [x] Integracja z menu kontekstowym macOS
- [x] Funkcja eksportu do różnych formatów (PDF, Markdown)
- [x] Automatyczne aktualizacje przez Sparkle
- [x] Widgety macOS korzystające z WidgetKit
- [x] Ulepszenie obsługi zakładek i historii
- [x] Zaawansowana integracja z systemem powiadomień (wsparcie dla komentarzy, wzmianek)
- [x] Testy jednostkowe dla kluczowych komponentów
- [x] Ulepszony proces budowania z GitHub Actions

## Do zaimplementowania w następnym sprincie

- [x] Integracja z menu kontekstowym macOS
- [x] Funkcja eksportu do różnych formatów
- [x] Widgety macOS korzystające z WidgetKit
- [x] Automatyczne aktualizacje przez Sparkle
- [x] Testy jednostkowe

## Znane problemy i ograniczenia

1. Preferencje nie są jeszcze w pełni połączone z rzeczywistymi ustawieniami aplikacji
2. Brak pełnej obsługi motywów (tylko podstawowe przełączanie trybu ciemny/jasny)

## Priorytety na następny sprint

1. **Wysoki priorytet**:
   - ✅ Implementacja funkcji eksportu do różnych formatów (PDF, Markdown)
   - ✅ Integracja z menu kontekstowym macOS
   - ✅ Implementacja automatycznych aktualizacji przez Sparkle

2. **Średni priorytet**:
   - ✅ Widgety macOS
   - ✅ Ulepszenie obsługi zakładek i historii
   - ✅ Zaawansowana integracja z systemem powiadomień

3. **Niski priorytet**:
   - ✅ Testy jednostkowe
   - ✅ Dodatkowe ulepszenia UI

## Notatki techniczne

- Projekt wymaga Xcode 15.0 lub nowszego do kompilacji
- Minimalna wersja macOS to 13.0
- Aplikacja używa WKWebView zamiast starszego WebView
- Zaimplementowana jest podstawowa obsługa trybu developerskiego
- Projekt śledzi wytyczne Human Interface Guidelines Apple
- Automatyczne buildy są konfigurowane przez GitHub Actions

## Użyte narzędzia i biblioteki

- Swift 5.0
- Cocoa
- WebKit
- UserNotifications
- WidgetKit (planowane)
- Sparkle (planowane)

## Środowisko testowe

- macOS 15.4
- Xcode 15.4
- Safari Technology Preview (do testowania kompatybilności WebKit)

---

*Uwaga: Aby uruchomić projekt, należy otworzyć HackMD.xcodeproj w Xcode i skompilować aplikację.*