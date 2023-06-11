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
        //writeToPipe(content: flow.metaData.debugDescription)
        if let tcpflow = flow as? NEAppProxyTCPFlow {
            
            //tcpflow.localEndpoint
            
            tcpflow.readData{ data, error in
                if let error = error{
                    os_log("QQQ - error reading TCP Data")
                }
                
                if let data = data {
                    // serialize
                   /* let tcpPacket = TCPPacket.with {
                        $0.sourceAddress = tcpflow.
                        $0.destinationAddress = (tcpflow.remoteEndpoint as! NWHostEndpoint).hostname
                        $0.sourcePort = UInt32(tcpflow.sourceEndpoint?.port ?? 0)
                        $0.destinationPort = (tcpflow.remoteEndpoint as! NWHostEndpoint).port
                        $0.payload = data
                    }
                                    
                    if let serializedData = serializeTCPPacket(packet: tcpPacket) {
                        // Send the serializedData over the Unix pipe
                        writeToPipe(content: serializedData)
                    }*/
                    
                    os_log("QQQ - flow handled - %{public}@",data as CVarArg)
                    
                } else {
                    os_log("QQQ - No data received")
                }
            }
            //writeToPipe(content: flow.metaData.debugDescription)
        }
        else if let udpflow = flow as? NEAppProxyUDPFlow
        {
            os_log("QQQ - udpflow handled - %{public}@", udpflow.metaData.debugDescription)
            
            udpflow.readDatagrams { datagrams, endpoints, error in
                guard let datagrams = datagrams, let endpoints = endpoints, error == nil else {
                    os_log("QQQ - error reading UDP Data")
                    udpflow.closeReadWithError(nil)
                    return
                }
                
                for (index, datagram) in datagrams.enumerated() {
                    guard let endpoint = endpoints[index] as? NWHostEndpoint else { continue }
                    let localEndpoint = udpflow.localEndpoint as! NWHostEndpoint
                    
                    os_log("QQQ - first part datagram - %{public}@", datagram. as CVarArg)
                    os_log("QQQ - REMOTEHOSTNAME - %{public}@",udpflow.remoteHostname! as CVarArg)
                    os_log("QQQ - LOCALENDPOINT - %{public}@",localEndpoint as CVarArg)
                    
                    /*let udpPacket = UDPPacket.with {
                        $0.sourceAddress = datagram[0..<15]
                        $0.destinationAddress = udpflow.remoteHostname ?? ""
                        $0.sourcePort = UInt32(localEndpoint.port) ?? 8080
                        $0.destinationPort = UInt32(endpoint.port) ?? 8080
                        $0.payload = datagram
                    }
                                    
                    if let serializedData = self.serializeUDPPacket(packet: udpPacket) {
                        // Send the serializedData over the Unix pipe
                        self.writeToPipe(content: serializedData)
                    }
                     */
                    os_log("QQQ - flow handled - %{public}@",datagram as CVarArg)
                    
                }
            }
        }
        else
        {
            os_log("QQQ - flow handled - %{public}@",flow.metaData.debugDescription)
            //writeToPipe(content: flow.metaData.debugDescription)
        }
        return false //in this case the packet should be discarded by the system
    }
    
    func writeToPipe(content: Data) {
        os_log("QQQ - I'm inside writeToPipe, I'm writing on \(self.pipe!)")
        let handler = FileHandle(forWritingAtPath: self.pipe!)
        //let secData = content.data(using: .utf8)
        handler?.write(content)
        handler?.closeFile()
    }
    
    public func checkIPFormat(ip: String) -> Bool{
        let ipAddrPattern = "^(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|[1-9])\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)$"
        let regex = try? NSRegularExpression(pattern: ipAddrPattern, options: .caseInsensitive)
        if let matches = regex?.matches(in: ip, options: [], range: NSMakeRange(0, (ip as NSString).length)){
            return matches.count>0
        }
        return false
    }
    
    // MARK: serialize / deserialize
    
    // Serialize and deserialize TCP packets
    func serializeTCPPacket(packet: TCPPacket) -> Data? {
        do {
            return try packet.serializedData()
        } catch {
            print("Failed to serialize TCP packet: \(error)")
            return nil
        }
    }

    func deserializeTCPPacket(data: Data) -> TCPPacket? {
        do {
            return try TCPPacket(serializedData: data)
        } catch {
            print("Failed to deserialize TCP packet: \(error)")
            return nil
        }
    }

    // Serialize and deserialize UDP packets
    func serializeUDPPacket(packet: UDPPacket) -> Data? {
        do {
            return try packet.serializedData()
        } catch {
            print("Failed to serialize UDP packet: \(error)")
            return nil
        }
    }

    func deserializeUDPPacket(data: Data) -> UDPPacket? {
        do {
            return try UDPPacket(serializedData: data)
        } catch {
            print("Failed to deserialize UDP packet: \(error)")
            return nil
        }
    }
}

