//
//  BLETwoWayPeripheral.swift
//  PlanetNineGateway
//
//  Created by Zach Babb on 2/6/19.
//  Copyright © 2019 Planet Nine. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLETwoWayPeripheral: NSObject, CBPeripheralManagerDelegate {
    
    var manager: CBPeripheralManager
    var services: [CBService]
    var characteristics: [CBCharacteristic]
    var readCallback: ((CBCharacteristic) -> String)?
    var writeCallback: ((String, CBCentral) -> Void)?
    var notifyCallback: ((CBCharacteristic) -> String)?
    var centrals: [CBCentral]
    
    override init() {
        manager = CBPeripheralManager()
        services = [CBService]()
        characteristics = [CBCharacteristic]()
        centrals = [CBCentral]()
        
        super.init()
        manager.delegate = self

    }
    
    init(readCallback: @escaping (CBCharacteristic) -> String, writeCallback: @escaping (String, CBCentral) -> Void, notifyCallback: @escaping (CBCharacteristic) -> String) {
        manager = CBPeripheralManager()
        services = [CBService]()
        characteristics = [CBCharacteristic]()
        centrals = [CBCentral]()
        
        super.init()
        manager.delegate = self
        self.readCallback = readCallback
        self.writeCallback = writeCallback
        self.notifyCallback = notifyCallback
    }
    
    func setCallbacks(readCallback: @escaping (CBCharacteristic) -> String, writeCallback: @escaping (String, CBCentral) -> Void, notifyCallback: @escaping (CBCharacteristic) -> String) {
        self.readCallback = readCallback
        self.writeCallback = writeCallback
        self.notifyCallback = notifyCallback
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOff:
            print("Off")
        case .poweredOn:
            print("peripheral powered on")
            createServicesAndStartAdvertising()
        case .resetting:
            print("Resetting")
        case .unauthorized:
            print("Unauthorized")
        case .unknown:
            print("Unknown")
        case .unsupported:
            print("Unsupported")
        default:
            print("Got to the default somehow")
        }
    }
    
    func createServicesAndStartAdvertising() {
        let service = CBMutableService(type: BLEServices().twoWay, primary: true)
        let readCharacteristic = CBMutableCharacteristic(type: BLECharacteristics().readMagicGateway, properties: .read, value: nil, permissions: .readable)
        let writeCharacteristic = CBMutableCharacteristic(type: BLECharacteristics().write, properties: .write, value: nil, permissions: .writeable)
        let notifyCharacteristic = CBMutableCharacteristic(type: BLECharacteristics().notify, properties: .notify, value: nil, permissions: .readable)
        
        characteristics.append(readCharacteristic)
        characteristics.append(writeCharacteristic)
        characteristics.append(notifyCharacteristic)
        
        service.characteristics = characteristics
        services.append(service)
        
        manager.add(service)
        
        print("advertising: \(service.uuid)")
        
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid], CBAdvertisementDataLocalNameKey: "TwoWay"])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Could not start advertising")
            print(error)
            return
        }
        print("Started advertising!")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Did receive read request")
        let responseString = readCallback!(request.characteristic)
        print(responseString)
        print(responseString.count)
        let response = responseString.data(using: .utf8)
        request.value = response!
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Did receive write request")
        for request in requests {
            print("foo")
            print(request.value)
            print(String(data: request.value!, encoding: .utf8)!)
            print("bar")
            self.writeCallback!(String(data: request.value!, encoding: .utf8) ?? "", request.central)
        }
//        var valueString = ""
//        for request in requests {
//            print(request)
//            do {
//            } catch {
//                print(error)
//            }
//            /*guard*/ let value = request.value
//            valueString = String(data: value!, encoding: .utf8)!
//            let vss = String(bytes: value!, encoding: .utf8)
//            let vs = String(data: value!, encoding: .ascii)
//            let nlvs = String(data: value!, encoding: .nonLossyASCII)
//            //let cString = String(cString: Array(value!))
//            //else {
//                print("oof")
//                print(value)
//                print(vss)
//                print(vs)
//                print(nlvs)
//                print(valueString)
//                continue
//            //}
//            print("valueString is: \(valueString)")
//            peripheral.respond(to: request, withResult: .success)
//        }
        //writeCallback!(valueString, requests[0].central)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Got a notification subscription")
    }
    
    func notifySubscribedCentral(update: String, central: CBCentral) {
        let updateData = update.data(using: .utf8)!
        manager.updateValue(updateData, for: self.characteristics[2] as! CBMutableCharacteristic, onSubscribedCentrals: [central])
    }

    
}
