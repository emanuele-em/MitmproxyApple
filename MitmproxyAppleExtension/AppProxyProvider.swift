import NetworkExtension
import os.log
import Foundation

@available(OSX 11.0, *)
class AppProxyProvider: NEAppProxyProvider {
    var pipe: String? = nil

    override func startProxy(options: [String : Any]?, completionHandler: @escaping (Error?) -> Void) {        
        os_log("QQQ - Proxy started with these options: %{public}@", options as! CVarArg)
        let vendorData = options?["VendorData"] as? Dictionary<String, Any>
        //let ports = vendorData?["ports"] as! [String]
        let tunnelRemoteAddress = vendorData?["tunnelRemoteAddress"] as! String
        
        /*let networkRules = ports.map { port -> NENetworkRule in
            let remoteNetwork = NWHostEndpoint(hostname: "0.0.0.0", port: port)
            
            return NENetworkRule(remoteNetwork: remoteNetwork,
                                                   remotePrefix: 0,
                                                   localNetwork: nil,
                                                   localPrefix: 0,
                                                   protocol: .TCP,
                                                   direction: .outbound)
        }
         */

        let proxySettings = NETunnelNetworkSettings(tunnelRemoteAddress: tunnelRemoteAddress)
        //proxySettings.includedNetworkRules = networkRules
        
        setTunnelNetworkSettings(proxySettings) { error in
            if let applyError = error {
                os_log("QQQ - Failed to apply tunnel settings settings: %{public}@", applyError.localizedDescription)
            }
            completionHandler(error)
        }
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        os_log("QQQ -  stopProxy")
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        guard let messageString = String(data: messageData, encoding: String.Encoding.utf8) else {
                    completionHandler?(nil)
                    return
                }
        
        os_log("QQQ - message data: %{public}@", messageString)
        // receive and set the pipe path
        self.pipe = messageString
        
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
    
    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        writeToPipe(content: flow.metaData.debugDescription)
        if let tcpflow = flow as? NEAppProxyTCPFlow
        {
            os_log("QQQ - tcpflow handled - %{public}@",tcpflow.metaData.debugDescription)
            os_log("QQQ - tcpflow remoteEndpoint - %{public}@",tcpflow.remoteEndpoint)
            flow.open(withLocalEndpoint: <#T##NWHostEndpoint?#>, completionHandler: <#T##(Error?) -> Void#>)
            writeToPipe(content: flow.metaData.debugDescription)
        }
        else if let udpflow = flow as? NEAppProxyUDPFlow
        {
            os_log("QQQ - udpflow handled - %{public}@", udpflow.metaData.debugDescription)
            
            let handler = FileHandle(forWritingAtPath: "/var/folders/1d/lnc_h3ld1rz9n466xsfyb4rr0000gn/T/.tmp3CLh1O/test.pipe")
            let secData = udpflow.metaData.debugDescription.data(using: .utf8)
            if let secData = secData {
                handler?.write(secData)
                os_log("QQQ - written on pipe")
            } else {
                os_log("QQQ - problem writing on pipe")
            }
        }
        else
        {
            os_log("QQQ - flow handled - %{public}@",flow.metaData.debugDescription)
            writeToPipe(content: flow.metaData.debugDescription)
        }
        return true
    }
    
    func writeToPipe(content: String) {
        os_log("QQQ - I'm inside writeToPipe, I'm writing on \(self.pipe!)")
        let handler = FileHandle(forWritingAtPath: self.pipe!)
        let secData = content.data(using: .utf8)
        if let secData = secData {
            handler?.write(secData)
        }
        handler?.closeFile()
    }
}

