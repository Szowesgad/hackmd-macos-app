# Status rozwoju HackMD dla macOS

> Data ostatniej aktualizacji: 19 marca 2025

## Obecny stan projektu

Projekt jest we wczesnej fazie rozwoju (pre-alpha). Zaimplementowana została podstawowa struktura aplikacji z interfejsem użytkownika i integracją WebView do wyświetlania HackMD.io. Aplikacja kompiluje się i może być uruchamiana, ale brakuje jeszcze części funkcjonalności z planowanej wersji 1.0.

## Ukończone elementy

- [x] Podstawowy szkielet projektu Xcode
- [x] Główne okno aplikacji z WebView
- [x] Pasek narzędzi z podstawowymi akcjami
- [x] Ekran ładowania (loader podobny do Electrona)
- [x] Wsparcie dla trybu ciemnego/jasnego
- [x] Obsługa narzędzi developerskich
- [x] Podstawowe menu aplikacji
- [x] Obsługa okien dialogowych i powiadomień

## Do zaimplementowania w następnym sprincie

- [ ] Ikony aplikacji (Assets.xcassets)
- [ ] Pełna obsługa preferencji użytkownika
- [ ] Widgety macOS korzystające z WidgetKit
- [ ] Integracja z menu kontekstowym macOS
- [ ] Funkcja eksportu do różnych formatów
- [ ] Obsługa systemu powiadomień
- [ ] Automatyczne aktualizacje przez Sparkle
- [ ] Testy jednostkowe

## Znane problemy i ograniczenia

1. Brak ikon aplikacji
2. Brak pełnej obsługi motywów (tylko podstawowe przełączanie trybu ciemny/jasny)
3. Nie zaimplementowano jeszcze systemowych powiadomień
4. Brak menu preferencji
5. Brak widgetów macOS

## Priorytety na następny sprint

1. **Wysoki priorytet**:
   - Implementacja Assets.xcassets z ikonami aplikacji
   - Utworzenie okna preferencji
   - Działający system powiadomień

2. **Średni priorytet**:
   - Integracja z menu kontekstowym
   - Eksport do różnych formatów
   - Automatyczne aktualizacje

3. **Niski priorytet**:
   - Widgety macOS
   - Testy jednostkowe
   - Dodatkowe ulepszenia UI

## Notatki techniczne

- Projekt wymaga Xcode 15.0 lub nowszego do kompilacji
- Minimalna wersja macOS to 13.0
- Aplikacja używa WKWebView zamiast starszego WebView
- Zaimplementowana jest podstawowa obsługa trybu developerskiego
- Projekt śledzi wytyczne Human Interface Guidelines Apple

## Użyte narzędzia i biblioteki

- Swift 5.0
- Cocoa
- WebKit
- UserNotifications (planowane)
- WidgetKit (planowane)
- Sparkle (planowane)

## Środowisko testowe

- macOS 15.4
- Xcode 15.4
- Safari Technology Preview (do testowania kompatybilności WebKit)

---

*Uwaga: Aby uruchomić projekt, należy otworzyć HackMD.xcodeproj w Xcode i skompilować aplikację.*
