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
    
    func startTunnel() async {
        do{
            await installManager()
            print("manager is set")
            let manager = await enable()
            try manager?.connection.startVPNTunnel(options: [:])
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
            let designatedRequirement = getDesignatedRequirement(for: targetIdentifier) ?? "identifier \"\(targetIdentifier)\" and anchor apple"
            let appRule = NEAppRule(signingIdentifier: targetIdentifier, designatedRequirement: designatedRequirement)
            self.appRules.append(appRule)
        }
    }
    
    func getManager() async -> NEAppProxyProviderManager {
        do {
            let managers = try await NEAppProxyProviderManager.loadAllFromPreferences()
            let appManager = managers.first ?? NEAppProxyProviderManager()
            return appManager
        } catch let error1 {
            print("load error 1: %@", error1.localizedDescription)
            return NEAppProxyProviderManager()
        }
    }
    
    func getDesignatedRequirement(for bundleIdentifier: String) -> String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            print("Could not find the application with bundle identifier: \(bundleIdentifier)")
            return nil
        }
        
        var appSec: SecStaticCode?
        SecStaticCodeCreateWithPath(appURL as CFURL, [], &appSec)
        
        var requirement: SecRequirement?
        SecCodeCopyDesignatedRequirement(appSec!, [], &requirement)
        
        var requirementString: CFString?
        if SecRequirementCopyString(requirement!, [], &requirementString) == errSecSuccess {
            return requirementString as String?
        } else {
            print("Failed to retrieve the designated requirement string.")
            return nil
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
        do{
            try await manager.saveToPreferences()
            return manager
        } catch {
            print("error saving")
            return nil
        }
    }
    
    func installManager() async{
            let manager = await getManager()
            let config = NETunnelProviderProtocol()
        
            config.providerBundleIdentifier = self.bundleIdentifier
            config.providerConfiguration = K.providerConfiguration
            config.serverAddress = K.serverAddress
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
    
}

