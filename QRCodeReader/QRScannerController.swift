//
//  QRScannerController.swift
//  QRCodeReader
//
//  Created by Simon Ng on 13/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation

class QRScannerController: UIViewController {

    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    
    //設定 AVCaptureSession 物件的輸入給對應的 AVCaptureDevice 來擷取影片
    //執行即時擷取時，使用 AVCaptureSession 物件，並加上影片擷取裝置的輸入。AVCaptureSession 物件是用來協調來自影片輸入裝置至輸出的資料流
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var quCodeFrameView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //取得後置鏡頭來擷取影片
        //要選 .builtInWideAngleCamera (屬於一般的鏡頭)
        if #available(iOS 10.2, *) {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
            
            guard let captureDevice = deviceDiscoverySession.devices.first else {
                print("Failed to get the camera device.")
                return
            }
            
            do {
                //使用 captureDevice 來取得 AVCaptureDeviceInput 類別的實例
                let input = try AVCaptureDeviceInput(device: captureDevice)
                
                //在擷取 session 設定輸入裝置
                captureSession.addInput(input)
                
                //初始化一個 AVCaptureMetadataOutput 物件並將其設定作為擷取 session 的輸出裝置
                let captureMetadataOutput = AVCaptureMetadataOutput()
                captureSession.addOutput(captureMetadataOutput)
                
                //設定委派並使用預設的調度佇列來執行 call back
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                //設定哪一種元資料轉換
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                
                //初始化影片預覽層，並將其作為子層加入 viewPreview 視圖的圖層中
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                
                //開始影片的擷取
                captureSession.startRunning()
                
                //移動訊息標籤與頂部列至上層
                view.bringSubviewToFront(messageLabel)
                view.bringSubviewToFront(topbar)
                
                //初始化 QR Code 框，預設看不見
                createGreenView()
            } catch {
                //假如有錯誤，單純輸出其狀況不再繼續執行
                print(error)
                return
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func createGreenView() {
        quCodeFrameView = UIView()
        
        if let qrCodeFrameView = quCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        //檢查 metadataObjects 陣列為非空值，他至少需包含一個物件
        if metadataObjects.count == 0 {
            quCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected."
            return
        }
        
        //取得元資料 (metadata) 物件
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == .qr {
            //若發現元資料與 QR code 元資料相同，更新狀態標籤的文字並設定邊界
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            quCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.text = metadataObj.stringValue
                
                //導入 QR Code 網址
                let urlString = URL(string: metadataObj.stringValue ?? "")!
                UIApplication.shared.open(urlString, options: [:], completionHandler: nil)
            }
        }
    }
}
