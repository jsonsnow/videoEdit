//
//  VideoCompress.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/16.
//  Copyright © 2020 chen liang. All rights reserved.
//

import UIKit
import AVFoundation

class VideoCompress: NSObject {

    var asset: AVAsset?
    var reader: AVAssetReader?
    var videoOutput: AVAssetReaderVideoCompositionOutput?
    var audioOutput: AVAssetReaderAudioMixOutput?
    var write: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?
    var videoPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    var inputQueue: DispatchQueue?
    var outPut: URL!
    var timeRange: CMTimeRange!
    
    var _error: Error?
    var duration: TimeInterval = 0
    var lastSamplePresentationTime: CMTime = .zero
    
    
    func exportAsync(handler: ()->Void) -> Void {
        
        
        do {
            try self.reader = AVAssetReader.init(asset: asset!)
            try self.write = AVAssetWriter.init(url: outPut, fileType: .mp4)
        } catch  {
            return
        }
        self.reader?.timeRange = timeRange
        self.reader?.shouldGroupAccessibilityChildren = true
        self.write?.metadata = []
        
        let videoTracks = self.asset?.tracks(withMediaType: .video)
        duration = CMTimeGetSeconds(self.timeRange.duration)
        duration = CMTimeGetSeconds(self.asset!.duration)
        if let _videoTrack = videoTracks, _videoTrack.count > 0 {
            self.videoOutput = AVAssetReaderVideoCompositionOutput.init(videoTracks: _videoTrack, videoSettings: nil)
            self.videoOutput?.alwaysCopiesSampleData = false
            if self.reader?.canAdd(videoOutput!) ?? false {
                self.reader?.add(videoOutput!)
            }
            
            self.videoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: nil)
            self.videoInput?.expectsMediaDataInRealTime = false
            if self.write?.canAdd(videoInput!) ?? false {
                self.write?.add(videoInput!)
            }
            let pixelBufferAttributes = [
                kCVPixelBufferPixelFormatTypeKey:kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey: videoOutput!.videoComposition!.renderSize.width,
                kCVPixelBufferHeightKey: videoOutput!.videoComposition!.renderSize.height,
                "IOSurfaceOpenGLESTextureCompatibility": true,
                "IOSurfaceOpenGLESFBOCompatibility": true
                ] as [AnyHashable : Any]
            self.videoPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor.init(assetWriterInput: self.videoInput!, sourcePixelBufferAttributes: pixelBufferAttributes as? [String : Any])
        }
        
        let audioTracks = self.asset?.tracks(withMediaType: .audio)
        if let _audioTracks = audioTracks, _audioTracks.count > 0 {
            self.audioOutput = AVAssetReaderAudioMixOutput.init(audioTracks: _audioTracks, audioSettings: nil)
            self.audioOutput?.alwaysCopiesSampleData = false
            self.audioOutput?.audioMix = nil
            if self.reader?.canAdd(self.audioOutput!) ?? false {
                self.reader?.add(audioOutput!)
            } else {
                self.audioOutput = nil
            }
        }
        if self.audioOutput != nil {
            self.audioInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: nil)
            self.audioInput?.expectsMediaDataInRealTime = false
            if self.write?.canAdd(audioInput!) ?? false {
                write?.add(audioInput!)
            }
        }
        
        self.write?.startWriting()
        self.reader?.startReading()
        self.write?.startSession(atSourceTime: timeRange.start)
        
        self.inputQueue = DispatchQueue.init(label: "xxxxx")
        if videoTracks!.count > 0 {
            self.videoInput?.requestMediaDataWhenReady(on: self.inputQueue!, using: {
                
            })
        }
        self.audioInput?.requestMediaDataWhenReady(on: inputQueue!, using: {
            
        })
        
    }
    
    func cancelExport() -> Void {
        if self.inputQueue != nil {
            inputQueue?.async {
                self.write?.cancelWriting()
                self.reader?.cancelReading()
            }
        }
    }
    
    func reset() -> Void {
        _error = nil
        self.reader = nil
        self.videoOutput = nil
        self.audioOutput = nil
        self.write = nil
        self.videoInput = nil
        self.videoPixelBufferAdaptor = nil
        self.audioInput = nil
        self.inputQueue = nil
        
    }
}
