import Foundation
import NetworkExtension
import Security
import AppKit

enum Status {
    case toInstall
    case running
    case disconnected
}

class Proxy {
    var status: Status = .toInstall
    let bundleIdentifier = K.bundleIdentifier
    var appRules = [NEAppRule]()
    var pipe_path: String? = nil
    
    func startTunnel() async {
        do{
            await installManager()
            print("manager is set")
            let manager = await enable()
            let session = manager?.connection as? NETunnelProviderSession
            try session?.startTunnel(options: [:])
            try session?.sendProviderMessage(self.pipe_path!.data(using: .utf8)!)
            updateStatus(to: .running)
            
        } catch {
            print("error: \(error)")
        }
    }
    
    func stopTunnel() async {
            let manager = await getManager()
            manager.connection.stopVPNTunnel()
            await disable()
            updateStatus(to: .disconnected)
    }
    
    func updateRule(_ targetIdentifier: String){
        if targetIdentifier == K.allNetwork{
            self.appRules.removeAll()
        } else {
            let appRule = NEAppRule(signingIdentifier: targetIdentifier, designatedRequirement: "(identifier \"com.google.Chrome\" or identifier \"com.google.Chrome.beta\" or identifier \"com.google.Chrome.dev\" or identifier \"com.google.Chrome.canary\") and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = EQHXZ8M8AV")
            print(getDesignatedRequirement(for: targetIdentifier))
            self.appRules = [appRule]
        }
    }
    
    func getManager() async -> NEAppProxyProviderManager {
        do {
            let managers = try await NEAppProxyProviderManager.loadAllFromPreferences()
            print("there are \(managers.count) managers")
            let appManager = managers.first ?? NEAppProxyProviderManager()
            return appManager
        } catch let error1 {
            print("load error 1: %@", error1.localizedDescription)
            return NEAppProxyProviderManager()
        }
    }
    
    func getDesignatedRequirement(for bundleIdentifier: String) -> String {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            print("Could not find the application with bundle identifier: \(bundleIdentifier)")
            return ""
        }
        
        var appSec: SecStaticCode?
        SecStaticCodeCreateWithPath(appURL as CFURL, [], &appSec)
        
        var requirement: SecRequirement?
        SecCodeCopyDesignatedRequirement(appSec!, [], &requirement)
        
        var requirementString: CFString?
        if SecRequirementCopyString(requirement!, [], &requirementString) == errSecSuccess {
            return requirementString! as String
        } else {
            print("Failed to retrieve the designated requirement string.")
            return ""
        }
    }


    func disable() async{
            let manager = await getManager()
            manager.isEnabled = false
            do{
                try await manager.saveToPreferences()
            } catch {
                print("error saving")
            }
    }
    
    func enable() async -> NEAppProxyProviderManager?{
        let manager = await getManager()
        manager.isEnabled = true
        manager.appRules = self.appRules
        do{
            try await manager.saveToPreferences()
            return manager
        } catch {
            print("error saving")
            return nil
        }
    }
    
    func installManager() async{
            let config = NETunnelProviderProtocol()
            config.providerBundleIdentifier = self.bundleIdentifier
            config.providerConfiguration = K.providerConfiguration
            config.serverAddress = K.serverAddress
        
            let manager = await getManager()
            manager.appRules = self.appRules
            manager.localizedDescription = K.localizedDescription
            manager.protocolConfiguration = config
            do{
                try await manager.saveToPreferences()
            } catch {
                print("error saving: \(error)")
            }
    }
    
    func clearPreferences(){
        NEAppProxyProviderManager.loadAllFromPreferences{ (managers, error) in
            guard error == nil else {
                print("PPPP - load error: %@", error!.localizedDescription)
                return
            }
            
            for manager in managers ?? [] {
                manager.removeFromPreferences(completionHandler: nil)
            }
        }
    }
    
    func updateStatus(to status: Status){
        self.status = status
    }
    
    func proxyButtonString() -> String{
        switch self.status{
        case .running :
            return "Stop"
        default:
            return "Capture"
        }
    }
    
    func setPipePath(withPath path: String){
        self.pipe_path = path
    }
}

