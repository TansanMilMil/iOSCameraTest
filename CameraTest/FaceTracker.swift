//
//  FaceTracker.swift
//  CameraTest
//
//  Created by 對馬大 on 2020/08/30.
//  Copyright © 2020 對馬大. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public class FaceTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    //  使用するカメラをフロントカメラに設定
    let videoDevice = AVCaptureDevice.default(_: .builtInWideAngleCamera, for: AVMediaType.video, position: .front)
    var videoOutput = AVCaptureVideoDataOutput()
    var view: UIView
    private var findface: (_ arr: Array<CGRect>) -> Void
    let imageState: UILabel
    var detectFaceCount: Int = 0
    
    required init (viewForDisplay: UIView, findface: @escaping (_ arr: Array<CGRect>) -> Void, imageState: UILabel) {
        self.view = viewForDisplay
        self.findface = findface
        self.imageState = imageState
        super.init()
        self.initialize()
    }
    
    /** 初期処理 */
    private func initialize() {
        // カメラ映像の登録
        do {
            let videoInput = try AVCaptureDeviceInput(device: self.videoDevice!) as AVCaptureDeviceInput
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_32BGRA)]
        
        // 毎フレーム実行するデリゲート登録
        let queue: DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.captureSession.addOutput(self.videoOutput)
        
        // カメラ映像を描写するViewを指定
        let videoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.addSublayer(videoLayer)
        
        // カメラ向きを定義
        for connection in self.videoOutput.connections {
            let conn = connection
            if conn.isVideoOrientationSupported {
                conn.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        
        self.captureSession.startRunning()
        
        AudioServicesPlaySystemSound(1113)
    }
    
    /** BufferをUIImageへ変換 */
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
        let imageRef = context!.makeImage()
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        return resultImage
    }
    
    /** カメラ映像を取得 */
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.sync(execute: {
            // 映像をBufferからCIImageへ変換
            let image: UIImage = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            let ciimage: CIImage! = CIImage(image: image)
            
            // 顔を検知する。処理速度を重視し、精度は低く設定。
            let detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            let faces = detector.features(in: ciimage)
            
            // facesに顔として認識した画像が格納される
            if faces.count == 0 {
                detectFaceCount = 0
                self.imageState.text = "正面を向いて顔をカメラに写してください"
                return
            } else if faces.count == 1 {
                var _ : CIFaceFeature = CIFaceFeature()
                for feature in faces {
                    let face = feature as! CIFaceFeature
                    if (!face.hasMouthPosition) {
                        self.imageState.text = "カメラには顔全体を写してください(口が写っていない)"
                        return
                    }
                    if (!face.hasFaceAngle) {
                        self.imageState.text = "カメラには正面を向いた顔を写してください(角度がおかしい)"
                        return
                    }
                    if (!face.hasLeftEyePosition) {
                        self.imageState.text = "カメラには顔全体を写してください(左目が写っていない)"
                        return
                    }
                    if (!face.hasRightEyePosition) {
                        self.imageState.text = "カメラには顔全体を写してください(右目が写っていない)"
                        return
                    }
                    if (face.leftEyeClosed) {
                        self.imageState.text = "両目を開いてください(左目が閉じている)"
                        return
                    }
                    if (face.rightEyeClosed) {
                        self.imageState.text = "両目を開いてください(右目が閉じている)"
                        return
                    }
                }
                detectFaceCount += 1
                self.imageState.text = "顔を検知しました。そのままお待ちください。(\(detectFaceCount))"
            } else if faces.count >= 2 {
                detectFaceCount = 0
                self.imageState.text = "カメラには１人の顔だけが写るようにしてください"
                return
            }
            return
        })
    }
}
