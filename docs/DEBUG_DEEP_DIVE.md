# Szczegółowe procedury debugowania HackMD dla macOS

Ten dokument zawiera zaawansowane techniki debugowania, które uzupełniają podstawowe instrukcje zawarte w [DEBUGGING.md](./DEBUGGING.md).

## Spis treści

1. [Zaawansowane debugowanie WebKit](#zaawansowane-debugowanie-webkit)
2. [Debugowanie wydajności i optymalizacja](#debugowanie-wydajności-i-optymalizacja)
3. [Analiza problemów z pamięcią](#analiza-problemów-z-pamięcią)
4. [Debugowanie widgetów WidgetKit](#debugowanie-widgetów-widgetkit)
5. [Debugowanie i profilowanie komunikacji sieciowej](#debugowanie-i-profilowanie-komunikacji-sieciowej)
6. [Debugowanie automatycznych aktualizacji Sparkle](#debugowanie-automatycznych-aktualizacji-sparkle)

## Zaawansowane debugowanie WebKit

WebView jest głównym komponentem aplikacji. Poniższe techniki umożliwiają głębsze debugowanie WebKit.

### Komunikacja ze stroną przez JavaScript Console

WebView wykonuje kod JavaScript na stronie HackMD. Możesz użyć następujących technik dla interaktywnego debugowania:

```swift
// Wstrzyknięcie konsoli debugującej
let debugScript = """
(function() {
    const debugDiv = document.createElement('div');
    debugDiv.id = 'hackmd-macos-debug';
    debugDiv.style.position = 'fixed';
    debugDiv.style.bottom = '0';
    debugDiv.style.left = '0';
    debugDiv.style.right = '0';
    debugDiv.style.background = 'rgba(0,0,0,0.8)';
    debugDiv.style.color = 'white';
    debugDiv.style.fontFamily = 'monospace';
    debugDiv.style.zIndex = '9999';
    debugDiv.style.maxHeight = '150px';
    debugDiv.style.overflow = 'auto';
    debugDiv.style.padding = '10px';
    debugDiv.style.display = 'none';
    
    const toggleButton = document.createElement('button');
    toggleButton.textContent = 'Debug';
    toggleButton.style.position = 'fixed';
    toggleButton.style.bottom = '10px';
    toggleButton.style.right = '10px';
    toggleButton.style.zIndex = '10000';
    toggleButton.addEventListener('click', () => {
        debugDiv.style.display = debugDiv.style.display === 'none' ? 'block' : 'none';
    });
    
    window.nativeDebug = {
        log: function(msg) {
            const line = document.createElement('div');
            line.textContent = new Date().toISOString() + ': ' + msg;
            debugDiv.appendChild(line);
            debugDiv.scrollTop = debugDiv.scrollHeight;
            window.webkit.messageHandlers.debugMessage.postMessage({type: 'log', content: msg});
        },
        clear: function() {
            debugDiv.innerHTML = '';
        }
    };
    
    document.body.appendChild(debugDiv);
    document.body.appendChild(toggleButton);
    
    // Zastąp console.log
    const originalConsoleLog = console.log;
    console.log = function() {
        originalConsoleLog.apply(console, arguments);
        const args = Array.from(arguments).map(arg => {
            if (typeof arg === 'object') return JSON.stringify(arg);
            return String(arg);
        });
        window.nativeDebug.log(args.join(' '));
    };
})();
"""

// Wstrzyknij skrypt po załadowaniu strony
webView.evaluateJavaScript(debugScript) { result, error in
    if let error = error {
        print("Error injecting debug console: \(error)")
    } else {
        print("Debug console injected")
    }
}
```

### Dostęp do głębszych ustawień WebKit

Niektóre ustawienia WebKit są dostępne tylko poprzez klucze prywatne:

```swift
// Włączenie szczegółowego logowania WebKit
webConfiguration.preferences.setValue(true, forKey: "logsPageMessagesToSystemConsoleEnabled")

// Dostęp do ustawień inspekcji
webView.perform(Selector(("_setAllowsRemoteInspection:")), with: true)
webView.perform(Selector(("_setRemoteInspectionPort:")), with: 9222)

// Debugowanie komunikacji IPC
UserDefaults.standard.register(defaults: ["WebKit_webProcessDebugLevelForIPC": 3])
```

### Przechwytywanie zdarzeń DOM

Monitorowanie zdarzeń DOM może pomóc zrozumieć interakcje użytkownika:

```swift
let domObserver = """
(function() {
    const observer = new MutationObserver(mutations => {
        for (const mutation of mutations) {
            if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                for (const node of mutation.addedNodes) {
                    if (node.nodeType === Node.ELEMENT_NODE && node.matches('.editor-toolbar, .CodeMirror')) {
                        console.log('HackMD editor detected:', node);
                        window.webkit.messageHandlers.editorDetected.postMessage({
                            type: node.className,
                            id: node.id
                        });
                    }
                }
            }
        }
    });
    
    observer.observe(document.body, { 
        childList: true, 
        subtree: true 
    });
    
    console.log('DOM observer started');
})();
"""

webView.evaluateJavaScript(domObserver) { result, error in
    if let error = error {
        print("Error setting up DOM observer: \(error)")
    }
}
```

## Debugowanie wydajności i optymalizacja

### Profilowanie gorących ścieżek

Xcode Instruments pozwala na identyfikację wolnych fragmentów kodu:

1. Uruchom aplikację z profilowaniem (Product > Profile)
2. Wybierz "Time Profiler"
3. Ustaw interwał próbkowania na 1ms dla większej dokładności
4. Przeprowadź operacje, które chcesz profilować
5. Analizuj wyniki, szukając "gorących ścieżek" (hot paths)

### Optymalizacja pobierania początkowego

Dla szybszego startu aplikacji:

```swift
func optimizeInitialLoading() {
    // Wstępne ładowanie zasobów
    let preloadURLs = [
        "https://hackmd.io/main.css",
        "https://hackmd.io/vendor.js",
        "https://hackmd.io/main.js"
    ]
    
    for urlString in preloadURLs {
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { _, _, _ in
                // Zasoby zostały dodane do cache
            }.resume()
        }
    }
    
    // Optymalizacja konfiguracji WebView
    let preferences = WKWebpagePreferences()
    preferences.allowsContentJavaScript = true
    webConfiguration.defaultWebpagePreferences = preferences
    
    // Wyłącz funkcje nieużywane w aplikacji
    webConfiguration.preferences.setValue(false, forKey: "allowsPictureInPictureMediaPlayback")
    
    // Konfiguracja pamięci podręcznej
    let websiteDataStore = WKWebsiteDataStore.default()
    websiteDataStore.httpCookieStore.getAllCookies { cookies in
        print("Preloaded cookies: \(cookies.count)")
    }
}
```

### Debugowanie animacji i UI

Dla problemów z renderowaniem UI:

```swift
// Wizualizacja warstw
(view.layer as? CALayer)?.borderWidth = 1.0
(view.layer as? CALayer)?.borderColor = NSColor.red.cgColor

// Debugowanie odświeżania
CATransaction.begin()
CATransaction.setDisableActions(true)
// Wykonaj zmiany UI
CATransaction.commit()

// Sprawdzenie rysowania
NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: nil, queue: nil) { notification in
    if let view = notification.object as? NSView {
        print("View frame changed: \(view)")
    }
}
```

## Analiza problemów z pamięcią

### Wykrywanie wycieków z Instruments

Poza standardowym narzędziem "Leaks", możesz użyć bardziej zaawansowanych technik:

```swift
// Dla celów debugowania, można dodać wywołanie deinit
deinit {
    print("\(self) was deallocated")
}

// Śledzenie obiektów
class DebugTracker {
    static var objects = [String: WeakRef]()
    
    static func track(object: AnyObject, name: String) {
        objects[name] = WeakRef(object: object)
    }
    
    static func printStatus() {
        for (name, ref) in objects {
            print("\(name): \(ref.object != nil ? "still alive" : "deallocated")")
        }
    }
}

class WeakRef {
    weak var object: AnyObject?
    init(object: AnyObject) {
        self.object = object
    }
}

// Użycie
DebugTracker.track(object: webViewController, name: "webViewController")
// Później
DebugTracker.printStatus()
```

### Śledzenie alokacji

Aby śledzić alokacje pamięci w czasie rzeczywistym:

```swift
class MemoryTracker {
    static var startMemory: mach_vm_size_t = 0
    
    static func startTracking() {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<natural_t>.size)
        let result: kern_return_t = task_info(
            mach_task_self_,
            task_flavor_t(TASK_VM_INFO),
            &taskInfo,
            &count
        )
        
        if result == KERN_SUCCESS {
            startMemory = taskInfo.phys_footprint
            print("Starting memory tracking. Current usage: \(Double(startMemory) / 1024.0 / 1024.0) MB")
        }
    }
    
    static func checkMemoryUsage(label: String) {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<natural_t>.size)
        let result: kern_return_t = task_info(
            mach_task_self_,
            task_flavor_t(TASK_VM_INFO),
            &taskInfo,
            &count
        )
        
        if result == KERN_SUCCESS {
            let currentMemory = taskInfo.phys_footprint
            let diffMB = Double(currentMemory - startMemory) / 1024.0 / 1024.0
            print("\(label): Memory change: \(diffMB) MB, Total: \(Double(currentMemory) / 1024.0 / 1024.0) MB")
        }
    }
}

// Użycie
MemoryTracker.startTracking()
// Po wykonaniu operacji
MemoryTracker.checkMemoryUsage(label: "After loading main page")
```

## Debugowanie widgetów WidgetKit

### Symulacja danych dla widgetów

```swift
// W samej aplikacji, generowanie testowych danych
func generateTestDataForWidget() {
    let testNotes = [
        ["id": "test1", "title": "Test Note 1", "lastEdited": Date(), "previewText": "Sample text...", "collaborators": 3],
        ["id": "test2", "title": "Test Note 2", "lastEdited": Date().addingTimeInterval(-3600), "previewText": "Another text...", "collaborators": 1],
        ["id": "test3", "title": "Test Note 3", "lastEdited": Date().addingTimeInterval(-7200), "previewText": "Third sample...", "collaborators": 0]
    ]
    
    if let sharedDefaults = UserDefaults(suiteName: "group.com.szowesgad.hackmd") {
        do {
            let data = try JSONSerialization.data(withJSONObject: testNotes)
            sharedDefaults.set(data, forKey: "recentNotes")
            print("Test data for widget generated")
        } catch {
            print("Error generating test data: \(error)")
        }
    }
}
```

### Debugowanie obiegu czasowego widgetu

```swift
// W pliku Timeline Provider widgetu:
func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> ()) {
    print("Widget requested timeline at \(Date())")
    let currentDate = Date()
    
    // Dodaj szczegółowe logi
    if context.isPreview {
        print("Timeline requested for preview")
    }
    
    print("Widget family: \(context.family)")
    print("Display size: \(context.displaySize)")
    
    // Pobierz dane i utwórz wpisy
    var entries: [NoteEntry] = []
    
    // Symuluj odświeżanie co 15 minut
    for minuteOffset in stride(from: 0, to: 60, by: 15) {
        let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
        print("Creating entry for date: \(entryDate)")
        
        let notes = WidgetDataProvider.shared.getRecentNotes()
        print("Got \(notes.count) notes for widget")
        
        let entry = NoteEntry(
            date: entryDate,
            notes: notes,
            configuration: ConfigurationIntent()
        )
        entries.append(entry)
    }
    
    // Utwórz linię czasu
    let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
    print("Next widget update scheduled for: \(nextUpdateDate)")
    
    let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
    completion(timeline)
}
```

## Debugowanie i profilowanie komunikacji sieciowej

### Monitorowanie żądań sieciowych WebView

Aby zrozumieć komunikację między WebView a serwerami:

```swift
// Rozszerz WKNavigationDelegate
func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let url = navigationAction.request.url {
        print("Navigating to: \(url.absoluteString)")
        // Log headers
        if let headers = navigationAction.request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        // Log HTTP method
        print("Method: \(navigationAction.request.httpMethod ?? "GET")")
        // Log body if present
        if let body = navigationAction.request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }
    decisionHandler(.allow)
}

// Obsługa odpowiedzi
func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    print("Auth challenge for: \(challenge.protectionSpace.host)")
    completionHandler(.performDefaultHandling, nil)
}

func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    print("Received redirect for navigation: \(String(describing: webView.url))")
}
```

### Symulacja wolnego połączenia

Aby testować zachowanie aplikacji przy słabym połączeniu:

```swift
// W AppDelegate dodaj metodę
func simulatePoorNetworkConditions() {
    // Pobierz aktualny URLSession configuration
    let configuration = URLSessionConfiguration.default
    
    // Ustaw limity szybkości (w bajtach na sekundę)
    configuration.httpMaximumConnectionsPerHost = 1
    configuration.timeoutIntervalForRequest = 60
    configuration.timeoutIntervalForResource = 120
    
    // Sztuczne opóźnienie
    print("Simulating poor network conditions...")
    
    // Wstrzyknij JavaScript do symulacji opóźnień
    let slowNetworkScript = """
    (function() {
        const originalFetch = window.fetch;
        window.fetch = function(input, init) {
            return new Promise((resolve, reject) => {
                console.log('Intercepted fetch for: ' + input);
                setTimeout(() => {
                    originalFetch(input, init)
                        .then(resolve)
                        .catch(reject);
                }, 2000); // 2-second delay
            });
        };
        
        const originalXHROpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url, ...rest) {
            console.log('Intercepted XHR for: ' + url);
            const xhr = this;
            originalXHROpen.apply(xhr, [method, url, ...rest]);
            
            const originalSend = xhr.send;
            xhr.send = function(...sendArgs) {
                setTimeout(() => {
                    originalSend.apply(xhr, sendArgs);
                }, 2000); // 2-second delay
            };
        };
        
        console.log('Network slowdown simulation active');
    })();
    """
    
    webView.evaluateJavaScript(slowNetworkScript) { result, error in
        if let error = error {
            print("Error setting up network simulation: \(error)")
        } else {
            print("Network slowdown simulation active")
        }
    }
}
```

## Debugowanie automatycznych aktualizacji Sparkle

### Testowanie aktualizacji lokalnie

```swift
// W AppDelegate
func setupSparkleForDebugging() {
    if let updater = SUUpdater.shared() {
        // Ustaw URL do localnego serwera testowego
        updater.feedURL = URL(string: "http://localhost:8000/appcast.xml")
        
        // Włącz szczegółowe logowanie
        UserDefaults.standard.set(true, forKey: "SUDebugLogging")
        
        // Dodaj nasłuchiwanie na zdarzenia aktualizacji
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sparkleDidFindUpdate(_:)),
            name: NSNotification.Name("SUUpdaterDidFindValidUpdateNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sparkleDidNotFindUpdate(_:)),
            name: NSNotification.Name("SUUpdaterDidNotFindUpdateNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sparkleDidFinishInstalling(_:)),
            name: NSNotification.Name("SUUpdaterDidFinishLoadingApplicationNotification"),
            object: nil
        )
    }
}

@objc func sparkleDidFindUpdate(_ notification: Notification) {
    if let updater = notification.object as? SUUpdater,
       let appcast = updater.value(forKey: "driver")?.value(forKey: "appcast"),
       let item = appcast.value(forKey: "items") as? [Any], !item.isEmpty {
        print("Sparkle found update: \(item[0])")
    }
}

@objc func sparkleDidNotFindUpdate(_ notification: Notification) {
    print("Sparkle did not find update")
}

@objc func sparkleDidFinishInstalling(_ notification: Notification) {
    print("Sparkle finished installing update")
}

// Uruchom lokalny serwer do testów
func startLocalUpdateServer() {
    let task = Process()
    task.launchPath = "/usr/bin/python3"
    task.arguments = ["-m", "http.server", "8000"]
    task.currentDirectoryPath = "/path/to/updates/directory" // Ścieżka do katalogu z appcast.xml
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    task.launch()
    
    print("Local update server started at http://localhost:8000")
}
```

### Generowanie appcast.xml dla testów

```swift
func generateTestAppcast() {
    let appcastContent = """
    <?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
        <channel>
            <title>HackMD Updates</title>
            <link>http://localhost:8000/appcast.xml</link>
            <description>Most recent changes with links to updates.</description>
            <language>en</language>
            <item>
                <title>Version 1.1.0</title>
                <description>
                    <![CDATA[
                        <h2>What's New:</h2>
                        <ul>
                            <li>Test update for debugging</li>
                            <li>More features</li>
                            <li>Bug fixes</li>
                        </ul>
                    ]]>
                </description>
                <pubDate>Tue, 19 Mar 2025 12:00:00 +0000</pubDate>
                <enclosure url="http://localhost:8000/HackMD-1.1.0.zip"
                        sparkle:version="1.1.0"
                        sparkle:shortVersionString="1.1.0"
                        type="application/octet-stream"
                        length="12345678" />
            </item>
        </channel>
    </rss>
    """
    
    do {
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let testDir = docsDir.appendingPathComponent("UpdatesTest")
        
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        let appcastPath = testDir.appendingPathComponent("appcast.xml")
        try appcastContent.write(to: appcastPath, atomically: true, encoding: .utf8)
        
        print("Generated test appcast.xml at: \(appcastPath.path)")
        print("Now run: cd \"\(testDir.path)\" && python3 -m http.server 8000")
    } catch {
        print("Error generating test appcast: \(error)")
    }
}
```

---

## Narzędzia zaawansowanego debugowania

### LLDB niestandardowe komendy

Dodaj te polecenia do pliku `~/.lldbinit` dla zaawansowanego debugowania:

```
# Wyświetlanie hierarchii NSView
command regex dump_view_hierarchy 's/(.+)/expression -l objc -O -- [%1 _subtreeDescription]/'

# Pobieranie informacji o WebView
command regex dump_webview 's/(.+)/expression -l objc -O -- [%1 _debugDescription]/'

# Sprawdź retainy
command regex refs 's/(.+)/expression -l objc -O -- CFGetRetainCount((CFTypeRef)%1)/'

# Wyświetlanie UserDefaults
command alias dump_defaults expression -l objc -O -- [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]

# Podgląd pileicji w czasie rzeczywistym 
command alias show_view expression -o -- (void)NSApp.windows[0].contentView.window.orderFront(nil)
```

### Skrypty monitorujące

Utwórz plik `monitor.swift` i skopiuj poniższą zawartość:

```swift
#!/usr/bin/swift

import Foundation

// Monitorowanie procesu HackMD
let taskName = "HackMD"
let task = Process()
task.launchPath = "/usr/bin/top"
task.arguments = ["-l", "0", "-stats", "pid,command,cpu,mem", "-pid", "\(ProcessInfo.processInfo.processIdentifier)"]

let pipe = Pipe()
task.standardOutput = pipe
task.launch()

let fileHandle = pipe.fileHandleForReading
fileHandle.readabilityHandler = { handle in
    let data = handle.availableData
    if let output = String(data: data, encoding: .utf8) {
        print(output)
    }
}

// Uruchom główną pętlę
RunLoop.main.run()
```

Użyj go przez:
```bash
chmod +x monitor.swift
./monitor.swift
```

### Debug Menu

Dodaj ukryte menu debugowania w aplikacji:

```swift
// Dodaj do setupApplicationMenu w AppDelegate.swift
private func setupDebugMenu() {
    #if DEBUG
    let debugMenu = NSMenu(title: "Debug")
    let debugMenuItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
    debugMenuItem.submenu = debugMenu
    
    // Dodaj opcje debugowania
    let memoryInfoItem = NSMenuItem(title: "Print Memory Info", action: #selector(printMemoryInfo), keyEquivalent: "m")
    memoryInfoItem.keyEquivalentModifierMask = [.command, .option, .shift]
    memoryInfoItem.target = self
    debugMenu.addItem(memoryInfoItem)
    
    let simulatePoorNetworkItem = NSMenuItem(title: "Simulate Poor Network", action: #selector(simulatePoorNetwork), keyEquivalent: "n")
    simulatePoorNetworkItem.keyEquivalentModifierMask = [.command, .option, .shift]
    simulatePoorNetworkItem.target = self
    debugMenu.addItem(simulatePoorNetworkItem)
    
    let generateTestWidgetDataItem = NSMenuItem(title: "Generate Test Widget Data", action: #selector(generateTestWidgetData), keyEquivalent: "w")
    generateTestWidgetDataItem.keyEquivalentModifierMask = [.command, .option, .shift]
    generateTestWidgetDataItem.target = self
    debugMenu.addItem(generateTestWidgetDataItem)
    
    let testSparkleItem = NSMenuItem(title: "Test Sparkle Update", action: #selector(testSparkleUpdate), keyEquivalent: "u")
    testSparkleItem.keyEquivalentModifierMask = [.command, .option, .shift]
    testSparkleItem.target = self
    debugMenu.addItem(testSparkleItem)
    
    mainMenu.addItem(debugMenuItem)
    #endif
}
```