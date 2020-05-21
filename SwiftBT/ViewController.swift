//
//  ViewController.swift
//  SwiftBT
//
//  Created by 黃仕杰 on 2018/5/17.
//  Copyright © 2018年 BT. All rights reserved.
//



/*
    param:peripheral
        [<CBPeripheral:
            0x10540f030,
            identifier = BFE521D5-6150-3DDC-8CEC-D5F95AD79785,
            name = HC-08,
            state = disconnected>]
            ###centralManager.connect(connectPeripherial, options: nil);
            ###centralManager.cancelPeripheralConnection(connectPeripherial);
 
    param:service
        <   CBService:0x105d6fb80,
            isPrimary = YES,
            UUID = Device Information>
 
        <   CBService:0x105d32bb0,
            isPrimary = YES,
            UUID = FFE0>    ###主要的
 
    param:characteristic
        <   CBCharacteristic: 0x101bc1620,
            UUID = System ID,
            properties = 0x2,
            value = (null),
            notifying = NO  >  ###uuidString=2A23,2A24..等等
 
        <   CBCharacteristic: 0x101bca7a0,
            UUID = FFE1,
            properties = 0x1E,
            value = (null),
            notifying = NO  >  ###uuidString=FFE1 主要的
            ###Send
 

    param:charDictionary[:]
        "FFE1":
        <
            CBCharacteristic: 0x101bca7a0,
            UUID = FFE1, properties = 0x1E,
            value = (null),
            notifying = NO
        >
 */

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    @IBOutlet var textStatus: UITextView!;
    @IBOutlet var tableView: UITableView!;
    @IBOutlet var switchMatch: UISwitch!;
    @IBOutlet var feildData: UITextField!;
    
    var peripherals = Array<CBPeripheral>();
    
    enum SendDataError: Error{
        case CharacteristicNotFound;
    }
    
    var centralManager: CBCentralManager!;
    var connectPeripherial: CBPeripheral!;
    var charDictionary = [String: CBCharacteristic]();
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = DispatchQueue.global();
        centralManager = CBCentralManager(delegate: self, queue: queue);
    }
    
    func socketFormat(_ str: String) -> String{
        let first = "ws";
        let end = "jie";
        var StringFormat: String = "";
        StringFormat = first+"#"+"1#"+str+"#"+end+"\n";
        
        return StringFormat;
    }
    
    ///================================================================================
    ///是否配對
    func isPaired() -> Bool{
        let user = UserDefaults.standard;
        if let uuidString = user.string(forKey: "KEY_PERIPHERAL_UUID"){
            let uuid = UUID(uuidString: uuidString);
            let list = centralManager.retrievePeripherals(withIdentifiers: [uuid!]);
            print("___已經配對過___")
            print("______________")
            
            if(list.count > 0){
                connectPeripherial = list.first!;
                connectPeripherial.delegate = self;
                return true
            }
        }
        return false
    }
    
    ///================================================================================
    ///1 method : 有沒有開啟藍芽
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //print("=====1 method=====");
        txtInsert("=====1 method=====");
        
        switch central.state {
        case .unknown:
            txtInsert("CBCentralManagerStateUnknown");
        case .resetting:
            txtInsert("CBCentralManagerStateResetting");
        case .unsupported:
            txtInsert("CBCentralManagerStateUnsupported");
        case .unauthorized:
            txtInsert("CBCentralManagerStateUnauthorized");
        case .poweredOff:
            txtInsert("CBCentralManagerStatePoweredOff");
        case .poweredOn:
            txtInsert("CBCentralManagerStatePoweredOn");
        }
        
        guard central.state == .poweredOn else {
            return;
        }
        
        txtInsert("isPaired: \(isPaired())");
        
        if (isPaired()){
            //觸發 3 method
            centralManager.connect(connectPeripherial, options: nil);
        }else{
            //觸發 2 method
            centralManager.scanForPeripherals(withServices: nil, options: nil);
        }
    }
    
    
    ///================================================================================
    ///2 method : 掃描藍牙
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        txtInsert("=====2 method=====");
        txtInsert("找到藍牙裝置:\(String(describing: peripheral.name))");
        
        guard peripheral.name != nil else {
            return
        }
        
        guard peripheral.name?.range(of: "HC") != nil else {
            return
        }
        
        peripherals.append(peripheral);
        print(peripherals);
        
        //停止掃描
        central.stopScan();
        
        DispatchQueue.main.async {
            self.tableView.reloadData();
        }
        
        //儲存周邊藍牙的UUID
        let user = UserDefaults.standard;
        user.set(peripheral.identifier.uuidString, forKey: "KEY_PERIPHERAL_UUID");
        user.synchronize();
        
        connectPeripherial = peripheral;
        connectPeripherial.delegate = self;
        
        //已配對觸發 3 method
        centralManager.connect(connectPeripherial, options: nil);
    }
    
    ///================================================================================
    ///3 method :
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        txtInsert("=====3 method=====");
        
        charDictionary = [:];
        //觸發 4 method
        peripheral.discoverServices(nil);
    }
    
    ///================================================================================
    ///4 method :
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        txtInsert("=====4 method=====");
        
        guard error == nil else {
            txtInsert("4 method ERROR ::: \(String(describing: error))");
            return
        }
        
        for service in peripheral.services!{
            //觸發 5 method
            print("SERVICE")
            print(service)
            connectPeripherial.discoverCharacteristics(nil, for: service);
        }
    }
    
    ///================================================================================
    ///5 method :
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        txtInsert("=====5 method=====");
        
        guard error == nil else {
            txtInsert("5 method ERROR ::: \(String(describing: error))");
            return
        }
        
        for characteristic in service.characteristics!{
            print("characteristic")
            print(characteristic)
            let uuidString = characteristic.uuid.uuidString;
            if uuidString == "AAA2"{
                let uuidString = characteristic.uuid.uuidString;
                charDictionary[uuidString] = characteristic;
                txtInsert("找到: \(uuidString)");
                
                peripheral.readValue(for: characteristic);
            }
        }
        
        print(charDictionary)
        
        
    }
    
    ///================================================================================
    ///取得 Peripheral 送過來的資料
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        print("receice peripheral data")
        guard error == nil else{
            txtInsert(error! as! String);
            return
        }
        
        if characteristic.uuid.uuidString == "FFE1"{
            let data = characteristic.value! as NSData;
            DispatchQueue.main.async {
                var string = String(data: data as Data, encoding: .utf8)!;
                string = ">" + string;
                self.txtInsert(string);
            }
        }
    }
    
    ///================================================================================
    ///將資料傳送到 Peripheral
    func sendData(_ data: Data, uuidString: String, writeType: CBCharacteristicWriteType)
        
        
        throws {
        guard let characteristic = charDictionary[uuidString] else {
            throw SendDataError.CharacteristicNotFound;
        }
        print(characteristic)
        connectPeripherial.writeValue(data,
                                      for: characteristic,
                                      type: writeType);
    }
    
    @IBAction func btnSendClick(_ sender: Any) {
        if self.feildData.text != ""{
            let string = socketFormat(feildData.text!);
            do{
                try sendData(string.data(using: .utf8)!,
                             uuidString: "AAA2",
                             writeType: .withoutResponse);
            }catch{
                txtInsert("sendData ERROR ::: \(error)");
            }
        }
        
    }
    ///================================================================================
    ///如果 Peripheral端有respones時
    func peripheral(_ peripheral: CBPeripheral,didWriteValueFor characteristic: CBCharacteristic,error: Error?) {
        if error != nil{
            txtInsert("寫出資料錯誤: \(String(describing: error))");
        }
    }
    
    ///================================================================================
    ///斷線處理
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        txtInsert("連線中斷 isPaires: \(isPaired())");
        
        if isPaired(){
            centralManager.connect(connectPeripherial, options: nil);
        }
    }
    
    ///================================================================================
    ///解配對
    func unPair(){
        let user = UserDefaults.standard;
        user.removeObject(forKey: "KEY_PERIPHERAL_UUID");
        user.synchronize();
        centralManager.cancelPeripheralConnection(connectPeripherial);
        /*
            若對方也是iOS或Mac時 , 解配對需要進設定手動解配 , 否則無法徹底解配
        */
    }
    
    @IBAction func btnUnpairClick(_ sender: Any) {
        unPair();
    }
    
    
    ///================================================================================
    ///配對
    @IBAction func switchChangeClick(_ sender: UISwitch) {
        print("------charDictionary------")
        print(charDictionary)
        //let char = charDictionary["2A29"]!;
        //connectPeripherial.setNotifyValue(sender.isOn, for: char);
    }
    
    ///================================================================================
    ///清除viewStatus
    @IBAction func btnClearClick(_ sender: Any) {
        self.textStatus.text = "";
        self.peripherals.removeAll();
    }
    
    ///================================================================================
    ///textview insert
    func txtInsert(_ str: String){
        DispatchQueue.main.async {
            self.textStatus.insertText(str + "\n");
        }
    }
}


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        
        let peripheral = peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
}

extension ViewController: UITextFieldDelegate{
    //--------------------------------------------------------------------
    // 觸控到螢幕,超出keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true);
    }
    
    //--------------------------------------------------------------------
    // 觸控到鍵盤return,在keyboard內
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        feildData.resignFirstResponder();
        
        return(true);
    }
}

