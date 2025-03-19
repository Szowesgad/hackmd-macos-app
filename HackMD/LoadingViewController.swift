import Cocoa

class LoadingViewController: NSViewController {
    
    private var containerView: NSView!
    private var logoImageView: NSImageView!
    private var progressIndicator: NSProgressIndicator!
    private var statusLabel: NSTextField!
    
    // Callback do wywoływania po zakończeniu animacji
    var onLoadingComplete: (() -> Void)?
    
    // Status ładowania
    private var loadingStatus = "Inicjalizacja aplikacji..."
    
    override func loadView() {
        // Tworzenie głównego widoku
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        view.wantsLayer = true
        
        if #available(macOS 10.14, *) {
            view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        } else {
            view.layer?.backgroundColor = NSColor.white.cgColor
        }
        
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start animacji ładowania
        startLoadingAnimation()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Symulacja procesu ładowania
        simulateLoading()
    }
    
    private func setupUI() {
        // Tworzenie kontenera na elementy
        containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Logo aplikacji
        logoImageView = NSImageView()
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = NSImage(named: "AppIcon")
        logoImageView.imageScaling = .scaleProportionallyUpOrDown
        containerView.addSubview(logoImageView)
        
        // Wskaźnik postępu
        progressIndicator = NSProgressIndicator()
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .regular
        progressIndicator.isIndeterminate = true
        containerView.addSubview(progressIndicator)
        
        // Etykieta statusu
        statusLabel = NSTextField(labelWithString: loadingStatus)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alignment = .center
        statusLabel.font = NSFont.systemFont(ofSize: 14)
        containerView.addSubview(statusLabel)
        
        // Ustawienie ograniczeń
        NSLayoutConstraint.activate([
            // Kontener wycentrowany w widoku
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 200),
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            logoImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Wskaźnik postępu
            progressIndicator.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            progressIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Etykieta statusu
            statusLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])
    }
    
    private func startLoadingAnimation() {
        progressIndicator.startAnimation(nil)
        
        // Animacja logoImageView (pulsowanie)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            logoImageView.animator().alphaValue = 0.6
        }) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1.5
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.logoImageView.animator().alphaValue = 1.0
            }) {
                // Powtórz animację jeśli widok jest nadal widoczny
                if self.view.window != nil {
                    self.startLoadingAnimation()
                }
            }
        }
    }
    
    // Symulacja procesu ładowania z opóźnieniem
    private func simulateLoading() {
        // Sekwencja kroków ładowania z odpowiednimi opóźnieniami
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateStatus("Sprawdzanie aktualizacji...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.updateStatus("Inicjalizacja WebView...")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateStatus("Konfiguracja interfejsu...")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.updateStatus("Prawie gotowe...")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.finishLoading()
                        }
                    }
                }
            }
        }
    }
    
    // Aktualizacja tekstu statusu
    private func updateStatus(_ status: String) {
        loadingStatus = status
        statusLabel.stringValue = status
    }
    
    // Zakończenie procesu ładowania
    private func finishLoading() {
        // Zatrzymanie animacji
        progressIndicator.stopAnimation(nil)
        
        // Animacja zanikania
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            view.animator().alphaValue = 0
        }) {
            // Wywołanie callbacku po zakończeniu animacji
            self.onLoadingComplete?()
        }
    }
}
