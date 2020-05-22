//
//  AssetWrite.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/18.
//  Copyright © 2020 chen liang. All rights reserved.
//

import UIKit
import AVFoundation

class AssetWrite: NSObject {
    
    //MARK: -- porps
    var duration: Float64 = 0
    let outPutFile: String!
    var videoSettings: [String: Any]?
    var audioSettings: [String: Any]?
    var videoPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var writer: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?
    
    //MARK: -- init
    init(videoSettings: [String: Any]?,
         audioSettings:[String: Any]?,
         outPutFile: String) {
        self.videoSettings = videoSettings
        self.outPutFile = outPutFile
        self.audioSettings = audioSettings
        super.init()
    }
    
    //MARK: -- priavet methid
    func configAssetWrite() -> Void {
        self.writer = try? AVAssetWriter.init(url: URL.init(string: outPutFile)!, fileType: .mp4)
        self.writer?.shouldOptimizeForNetworkUse = true
    }
    
    //MARK: -- public method
    func addVideoInput() -> Void {
        self.videoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: self.videoSettings)
        self.videoInput?.expectsMediaDataInRealTime = false
        if self.writer?.canAdd(videoInput!) ?? false {
            self.writer?.add(videoInput!)
        }
    }
    
    func configPixelBufferAdaptor(by videoCompsition: AVVideoComposition) -> Void {
        let pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: videoCompsition.renderSize.width,
            kCVPixelBufferHeightKey: videoCompsition.renderSize.height,
            "IOSurfaceOpenGLESTextureCompatibility":true,
            "IOSurfaceOpenGLESFBOCompatibility": true] as [AnyHashable : Any]
        self.videoPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor.init(assetWriterInput: self.videoInput!, sourcePixelBufferAttributes: pixelBufferAttributes as? [String : Any])
    }
    
    func configPixelBufferAdaptor(by settings:[String: Any]) -> Void {
        let width = settings[AVVideoWidthKey] as? Int
        let height = settings[AVVideoHeightKey] as? Int
        let pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width ?? 0,
            kCVPixelBufferHeightKey: height ?? 0,
            "IOSurfaceOpenGLESTextureCompatibility":true,
            "IOSurfaceOpenGLESFBOCompatibility": true] as [AnyHashable : Any]
        self.videoPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor.init(assetWriterInput: self.videoInput!, sourcePixelBufferAttributes: pixelBufferAttributes as? [String: Any])
    }
    
    func addAuidoInput() -> Void {
        self.audioInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: self.audioSettings)
        self.audioInput?.expectsMediaDataInRealTime = false
        if self.writer?.canAdd(audioInput!) ?? false {
            self.writer?.add(audioInput!)
        }
    }
    
}
