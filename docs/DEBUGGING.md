# Instrukcja debugowania aplikacji HackMD dla macOS

Ten dokument zawiera informacje potrzebne do debugowania aplikacji HackMD dla macOS.

## Spis treści

1. [Narzędzia do debugowania](#narzędzia-do-debugowania)
2. [Konfiguracja środowiska deweloperskiego](#konfiguracja-środowiska-deweloperskiego)
3. [Debugowanie WebView](#debugowanie-webview)
4. [Debugowanie widgetów](#debugowanie-widgetów)
5. [Debugowanie powiadomień](#debugowanie-powiadomień)
6. [Rozwiązywanie typowych problemów](#rozwiązywanie-typowych-problemów)
7. [Procedury testowe](#procedury-testowe)

## Narzędzia do debugowania

Aplikacja HackMD dla macOS oferuje kilka narzędzi pomocnych przy debugowaniu:

### Wbudowane narzędzia

- **Narzędzia deweloperskie WebView**: Dostępne przez menu View > Toggle Developer Tools (⌘⌥I)
- **Log konsoli**: Dostępny przez Console.app na macOS
- **Xcode Debugger**: Standardowe narzędzie debugowania przy uruchamianiu z Xcode

### Zewnętrzne narzędzia

- **Safari Technology Preview**: Pomoce przy debugowaniu WebKit/WebView
- **Network Link Conditioner**: Do testowania wydajności aplikacji przy różnych warunkach sieciowych
- **Instruments**: Do profilowania wydajności i śledzenia wycieków pamięci

## Konfiguracja środowiska deweloperskiego

### Wymagania

- macOS 13.0 lub nowszy
- Xcode 15.0 lub nowszy
- Opcjonalnie: Safari Technology Preview

### Ustawienia dla debugowania

1. Otwórz projekt w Xcode
2. Przejdź do Product > Scheme > Edit Scheme
3. W sekcji "Run", ustaw następujące opcje:
   - **Environment Variables**:
     - `HACKMD_DEBUG=1` - włącza szczegółowe logowanie
     - `HACKMD_WEBVIEW_DEBUG=1` - włącza dodatkowe logowanie WebView
     - `HACKMD_MOCK_API=1` - używa zamockowanych danych zamiast rzeczywistego API (do testów)

## Debugowanie WebView

WebView jest kluczowym komponentem aplikacji i może wymagać specjalnego podejścia do debugowania.

### Włączanie trybu deweloperskiego

```swift
// Aplikacja ma domyślnie włączony tryb deweloperski, ale można go kontrolować zmienną:
let isDeveloperModeEnabled = true
```

### Dostęp do narzędzi deweloperskich

1. Uruchom aplikację
2. Naciśnij ⌘⌥I lub wybierz z menu View > Toggle Developer Tools
3. W narzędziach deweloperskich możesz:
   - Debugować JavaScript
   - Sprawdzać strukturę DOM
   - Monitorować żądania sieciowe
   - Sprawdzać lokalny storage

### Wstrzykiwanie kodu JavaScript

Aby przetestować interakcje JavaScript, możesz wstrzyknąć własny kod:

```swift
webView.evaluateJavaScript("console.log('Debug message'); document.body.style.backgroundColor = 'lightblue';") { (result, error) in
    if let error = error {
        print("Error: \(error)")
    }
}
```

### Debugowanie komunikacji JS <-> Swift

Komunikacja między JavaScript a Swift odbywa się przez mechanizm WKScriptMessageHandler:

1. Dodanie obserwatora wiadomości w Swift:
```swift
userContentController.add(self, name: "debugMessage")
```

2. Wysłanie wiadomości z JavaScript:
```javascript
window.webkit.messageHandlers.debugMessage.postMessage({type: "debug", content: "Test message"});
```

3. Obsługa wiadomości w Swift:
```swift
func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == "debugMessage", let body = message.body as? [String: Any] {
        print("Received JS message: \(body)")
    }
}
```

## Debugowanie widgetów

Widgety macOS wymagają specjalnego podejścia do debugowania.

### Konfiguracja środowiska testowego

1. W Xcode, wybierz schemat widgetu zamiast głównej aplikacji
2. Możesz wybrać "Run" z poziomu pliku głównego widgetu, aby uruchomić podgląd

### Debugowanie danych widgetu

Widget korzysta z danych z UserDefaults z określoną grupą aplikacji:

```swift
let userDefaults = UserDefaults(suiteName: "group.com.szowesgad.hackmd")
```

Aby debugować te dane:
```swift
if let data = userDefaults?.data(forKey: "recentNotes") {
    print("Widget data: \(data)")
    // Decode and inspect
}
```

### Śledzenie aktualizacji linii czasu widgetu

Aktualizacje widgetu można śledzić dodając logi:

```swift
print("Timeline requested at: \(Date())")
print("Next update scheduled at: \(nextUpdateDate)")
```

## Debugowanie powiadomień

### Testowanie lokalnych powiadomień

Aby przetestować lokalne powiadomienia:

1. Upewnij się, że przyznano odpowiednie uprawnienia
2. Użyj następującego kodu do wysłania testowego powiadomienia:

```swift
func sendTestNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Test notification"
    content.body = "This is a test notification for debugging"
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
    let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling notification: \(error)")
        }
    }
}
```

### Sprawdzanie statusu powiadomień

```swift
UNUserNotificationCenter.current().getNotificationSettings { settings in
    print("Notification settings: \(settings)")
    print("Authorization status: \(settings.authorizationStatus.rawValue)")
}
```

### Debugowanie akcji powiadomień

Aby debugować akcje powiadomień, dodaj logi:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("Notification received: \(response.notification.request.identifier)")
    print("Action: \(response.actionIdentifier)")
    print("User info: \(response.notification.request.content.userInfo)")
    
    // Handle appropriately
    completionHandler()
}
```

## Rozwiązywanie typowych problemów

### Problem 1: WebView nie ładuje treści

**Rozwiązanie:**
1. Sprawdź połączenie internetowe
2. Sprawdź, czy adres URL jest poprawny
3. Sprawdź logi konsoli pod kątem błędów sieciowych
4. Sprawdź uprawnienia aplikacji (Info.plist)

**Kod diagnostyczny:**
```swift
webView.navigationDelegate = self
// ...
func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    print("Navigation error: \(error)")
}
```

### Problem 2: Wycieki pamięci

**Rozwiązanie:**
1. Użyj Instruments z profilem "Leaks"
2. Sprawdź cykle retain (szczególnie z delegatami i closures)
3. Sprawdź zarządzanie pamięcią przy dodawaniu/usuwaniu obserwatorów

**Miejsca, które należy sprawdzić:**
- Obserwatory WebView
- Delegaci i handlery powiadomień
- Zarządzanie tablicami i kolekcjami

### Problem 3: Niezadowalająca wydajność WebView

**Rozwiązanie:**
1. Użyj Instruments z profilem "Time Profiler"
2. Ogranicz renderowanie ciężkich elementów
3. Zminimalizuj komunikację JS <-> Swift
4. Sprawdź poniższy kod optymalizacji:

```swift
// Optymalizacja renderowania
let preferences = WKWebpagePreferences()
preferences.allowsContentJavaScript = true
webConfiguration.defaultWebpagePreferences = preferences

// Wyłącz funkcje nieużywane w aplikacji
webConfiguration.preferences.setValue(false, forKey: "allowsPictureInPictureMediaPlayback")
```

### Problem 4: Błędy synchronizacji danych z widgetami

**Rozwiązanie:**
1. Sprawdź, czy identyfikator grupy aplikacji jest poprawny
2. Upewnij się, że format danych jest spójny
3. Dodaj obsługę błędów przy kodowaniu/dekodowaniu:

```swift
do {
    let encodedData = try JSONEncoder().encode(notes)
    sharedDefaults?.set(encodedData, forKey: "recentNotes")
} catch {
    print("Error encoding widget data: \(error)")
}
```

## Procedury testowe

### Test wydajności ogólnej

1. Uruchom aplikację z włączonymi narzędziami Instruments (Product > Profile)
2. Wybierz profil "Time Profiler"
3. Wykonaj te czynności:
   - Załaduj główną stronę
   - Otwórz 5 różnych notatek
   - Przełącz między zakładkami
   - Eksportuj dokument
4. Sprawdź wyniki w Instruments, szukając operacji zajmujących dużo czasu

### Test funkcjonalności eksportu

1. Uruchom aplikację w trybie debugowania
2. Otwórz dowolną notatkę z treścią
3. Użyj funkcji eksportu do PDF i Markdown
4. Sprawdź wygenerowane pliki
5. Szukaj błędów w konsoli

### Test powiadomień

1. Włącz tryb debugowania powiadomień `HACKMD_NOTIFICATION_DEBUG=1`
2. Zarejestruj kategorie i uruchom testowe powiadomienia
3. Sprawdź, czy powiadomienia są wyświetlane poprawnie
4. Przetestuj akcje powiadomień

### Test obsługi błędów

1. Wyłącz internet podczas korzystania z aplikacji
2. Spróbuj załadować treść
3. Sprawdź, czy obsługa błędów działa poprawnie
4. Włącz internet i sprawdź, czy aplikacja odzyskuje funkcjonalność

## Zgłaszanie błędów

Jeśli znajdziesz błąd, który wymaga poprawy:

1. Sprawdź, czy błąd jest powtarzalny
2. Zbierz następujące informacje:
   - Logi z konsoli
   - Kroki do odtworzenia
   - Wersja systemu macOS
   - Wersja aplikacji
3. Otwórz nowe zgłoszenie na GitHub z zebranymi informacjami