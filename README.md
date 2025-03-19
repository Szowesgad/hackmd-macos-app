# HackMD dla macOS

Natywna aplikacja macOS do obsługi HackMD.io z rozszerzonymi funkcjami developerskimi.

## O projekcie

HackMD dla macOS to natywna aplikacja napisana w Swift, która zapewnia lepsze doświadczenie korzystania z platformy HackMD.io niż standardowa przeglądarka. Aplikacja wykorzystuje WKWebView do wyświetlania zawartości HackMD, jednocześnie dodając natywne funkcje macOS.

## Funkcje

- Natywna integracja z macOS
- Tryb ciemny/jasny zgodny z systemem
- Narzędzia developerskie
- Powiadomienia systemowe z obsługą komentarzy i wzmianek
- Wsparcie dla skrótów klawiszowych
- Menu kontekstowe z dodatkowymi opcjami
- Eksport dokumentów do PDF i Markdown
- Automatyczne aktualizacje przez Sparkle
- Widgety macOS pokazujące ostatnie notatki
- Zaawansowane zarządzanie historią i zakładkami
- Pełne wsparcie dla autoryzacji
- Testowane jednostkowo kluczowe komponenty
- Zautomatyzowany proces budowania z GitHub Actions

## Wymagania systemowe

- macOS 13.0 lub nowszy
- Xcode 15.0 lub nowszy (do kompilacji)

## Instalacja

### Metoda 1: Pobranie aplikacji
1. Przejdź do zakładki [Releases](https://github.com/Szowesgad/hackmd-macos-app/releases)
2. Pobierz najnowszą wersję HackMD.dmg
3. Otwórz plik .dmg i przeciągnij aplikację do folderu Applications

### Metoda 2: Kompilacja ze źródeł
1. Sklonuj repozytorium
2. Otwórz HackMD.xcodeproj w Xcode
3. Skompiluj projekt (⌘+B)
4. Uruchom aplikację (⌘+R)

### Metoda 3: Użycie skryptu budującego
1. Sklonuj repozytorium
2. Uruchom skrypt budujący:
   ```
   cd hackmd-macos-app
   chmod +x tools/build-dmg.sh
   ./tools/build-dmg.sh
   ```
3. Zainstaluj aplikację z utworzonego pliku DMG (w katalogu artifacts)

## Rozwój projektu

Szczegółowy plan rozwoju znajduje się w [ROADMAP.md](docs/ROADMAP.md).
Aktualny status projektu jest opisany w [DEVSTAGE.md](DEVSTAGE.md).

## Narzędzia deweloperskie

Repozytorium zawiera zestaw narzędzi pomocnych podczas pracy nad aplikacją:

- **tools/build-dmg.sh** - Skrypt do budowania aplikacji i tworzenia pliku DMG
- **tools/debug_tools.sh** - Narzędzia do debugowania aplikacji
- **tools/run_mac_tests.sh** - Skrypt do uruchamiania testów jednostkowych

Instrukcje debugowania aplikacji znajdują się w [DEBUGGING.md](docs/DEBUGGING.md) i [DEBUG_DEEP_DIVE.md](docs/DEBUG_DEEP_DIVE.md).

## Współpraca

Jeśli chcesz pomóc w rozwoju projektu, zapoznaj się z [CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Licencja

Ten projekt jest udostępniany na licencji MIT. Szczegóły w pliku LICENSE.
