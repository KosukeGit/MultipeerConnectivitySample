//
//  ViewController.swift
//  MultipeerConnectivitySample
//
//  Created by x13089xx on 2016/07/10.
//  Copyright © 2016年 Kosuke Nakamura. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var selectedImage: UIImage?
    var changer: Bool = false
    
    let serviceType = "id-number"  // ピア検索の際にアドバタイズされているサービスを識別するためのプロパティ
    
    var browser : MCBrowserViewController!  // Advertiserを見つけて接続を確立する
    var assistant : MCAdvertiserAssistant!  //　自身を周囲に知らせる
    var session : MCSession!  // P2P通信のセッションをコントロールする
    var peerID: MCPeerID!  // ピアの識別子を表す
    
    @IBOutlet var sendImage: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userName = UIDevice.currentDevice().name  // デバイスの名前に設定
        
        self.peerID = MCPeerID(displayName: userName)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        self.browser = MCBrowserViewController(serviceType:serviceType, session:self.session)
        self.browser.delegate = self;
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType, discoveryInfo:nil, session:self.session)
        
        self.assistant.start()  // 周囲のデバイスに通信可能だと知らせる
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     * Imageボタンを押した時
     */
    @IBAction func selectImage(sender: AnyObject) {
        
        if changer == false {
            
            pickImageFromLibrary()  // 写真を選択する
            
        } else {
            
            let imageData = UIImageJPEGRepresentation(self.selectedImage!, 1.0)  // 選択した写真をNSData型に変換
            var error: NSError?
            
            do {
                // データ送信
                try self.session.sendData(imageData!, toPeers: self.session.connectedPeers, withMode: MCSessionSendDataMode.Unreliable)
            } catch let error2 as NSError {
                error = error2
            }
            
            if error != nil {
                print("Error sending data: \(error?.localizedDescription)", terminator: "")
            }
            // ボタンの表示を変える（Send -> Image）
            changer = false
            sendImage.setTitle("Image", forState: .Normal)
            sendImage.setTitleColor(UIColor.blueColor(), forState: .Normal)
            
        }
    }
    
    /**
     * ライブラリから写真を選択する
     */
    func pickImageFromLibrary() {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            // 写真ライブラリ表示用のViewControllerを宣言
            let controller = UIImagePickerController()
            
            controller.delegate = self  // 許可
            
            // controllerをカメラロールで表示（カメラの場合は.Camera）
            controller.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
            // controllerの表示をpresentViewControllerにする
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    /**
     * 写真を選択した際に呼ばれるメソッド
     */
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // 画像
        if info[UIImagePickerControllerOriginalImage] != nil {
            // didFinishPickingMediaWithInfoを通して渡された情報をUIImageにキャストし、selectedImageに入れる
            self.selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        
        // 写真選択後にカメラロール表示ViewControllerを引っ込める動作
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        // ボタンの表示を変える（Image -> Send）
        changer = true
        sendImage.setTitle("Send", forState: .Normal)
        sendImage.setTitleColor(UIColor.orangeColor(), forState: .Normal)
    }
    
    /**
     * Browseボタンを押した時
     */
    @IBAction func showBrowser(sender: AnyObject) {
        self.presentViewController(self.browser, animated: true, completion: nil)  // browserに画面遷移
    }
    
    /**
     * Doneボタンを押した時
     */
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)  // 戻る
    }
    
    /**
     * Cancellボタンを押した時
     */
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)  // 戻る
    }
    
    /**
     * NSDataを受信、保存
     */
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        dispatch_async(dispatch_get_main_queue()) {
            
            print("\(data)")  // 確認
            
            // アラート表示設定(スタイルはAlert)
            let alertController: UIAlertController = UIAlertController(title: "確認", message: "受け取った写真を保存しますか？", preferredStyle: UIAlertControllerStyle.Alert)
            
            // OKの場合
            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:{
                action in if UIImage(data: data) != nil {
                    let receivedImage = UIImage(data: data)  // UIImage型に変換
                    UIImageWriteToSavedPhotosAlbum(receivedImage!, self, nil, nil)  // カメラロールに保存
                }
            })
            
            // キャンセルの場合
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.Cancel, handler:{
                action in return
            })
            
            alertController.addAction(defaultAction)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
    }
    
}

