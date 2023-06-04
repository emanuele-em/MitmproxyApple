struct K {
    static let bundleIdentifier = "com.emanuele.mitmproxyApple.mitmproxyAppleExtension"
    static let providerConfiguration: [String: Any] = ["ports": ["80", "443"], "tunnelRemoteAddress": "127.0.0.1"]
    static let serverAddress = "http://127.0.0.1:8080"
    static let localizedDescription = "proxy"
    
    static let proxyButtonStart = "Capture"
    static let proxyButtonStop = "Pause"
    
    static let allNetwork = "All Network"
}
