import Cocoa
import NetworkExtension
import SystemExtensions

class ViewController: NSViewController {
    
    @IBOutlet weak var pipeLabel: NSTextField!
    @IBOutlet weak var processList: NSPopUpButton!
    @IBOutlet weak var proxyButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var clearButton: NSButton!
    var proxy = Proxy()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        self.proxy.setPipePath(withPath: CommandLine.arguments.last ?? "")
        self.updateRunningApplications()
        self.updateUI()
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    

    @IBAction func proxyButtonPressed(_ sender: Any) {
        Task.init {
            switch self.proxy.status{
            case .running:
                await self.proxy.stopTunnel()
            default:
                await self.proxy.startTunnel()
            }
            self.updateUI()
        }
        
    }
    
    @IBAction func clear(_ sender: Any) {
        proxy.clearPreferences()
        //proxy.disable()
    }
    
    func updateRunningApplications(){
        let running = NSWorkspace.shared.runningApplications
        processList.removeAllItems()
        processList.addItem(withTitle: K.allNetwork)
        for process in running{
            let _identifier = process.bundleIdentifier
            if let identifier = _identifier{
                processList.addItem(withTitle: identifier)
            }
        }
    }
    
    @IBAction func processListClicked(_ sender: NSPopUpButton) {
        processList.selectItem(withTitle: sender.title)
        proxy.updateRule(sender.title)
    }
    
    @IBAction func refreshApplicationsListPressed(_ sender: NSButton) {
        updateRunningApplications()
    }
    
    func initialize() {
        let extensionIdentifier = proxy.bundleIdentifier
        // Start by activating the system extensionf
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }
    
    func updateUI(){
        self.pipeLabel.stringValue = String("Pipe: \(proxy.pipe_path!)")
        proxyButton.title = proxy.proxyButtonString()
        statusLabel.stringValue = String("Status: \(proxy.status)")
        if proxy.status == .toInstall{
            clearButton.isEnabled = false
        } else {
            clearButton.isEnabled = true
        }
    }
    

}


//MARK: OSSystemExtensionActivationRequestDelegate
extension ViewController: OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        guard result == .completed else {
            proxy.status = .toInstall
            return
        }
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        proxy.status = .toInstall
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("Extension %@ requires user approval", request.identifier)
    }

    func request(_ request: OSSystemExtensionRequest,
                 actionForReplacingExtension existing: OSSystemExtensionProperties,
                 withExtension extension: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        return .replace
    }
}
