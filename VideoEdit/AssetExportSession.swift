//
//  AssetExportSession.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/18.
//  Copyright © 2020 chen liang. All rights reserved.
//

import UIKit
import AVFoundation

class AssetExportSession: NSObject {

    typealias ExportSampleBufferHandler = (_ from: CVPixelBuffer, _ to: CVPixelBuffer, _ time: CMTime) -> Bool
    typealias ExportCompletionHandler = () -> Void
    
    var asset: AVAsset!
    var reader: AssetRead!
    var writer: AssetWrite!
    var lastSamplePresentationTime: CMTime = .zero
    var timeRange: CMTimeRange!
    var progress: Float = 0
    var duration: Float64 = 0
    var customBufferHandler: ExportSampleBufferHandler?
    var completionHandler: ExportCompletionHandler?
    var inputQueue: DispatchQueue?
    var serialQueue: DispatchQueue?
    
    
    init(asset: AVAsset, videoSettings: [String: Any]?, audioSettings:[String: Any], outputFile: String) {
        self.asset = asset
        self.timeRange = CMTimeRange.init(start: .zero, end: self.asset.duration)
        self.reader = AssetRead.init(asset: self.asset, timeRange: CMTimeRange.init(start: .zero, end: self.asset.duration), videoComposition: nil, videoSettings: videoSettings)
        self.writer = AssetWrite.init(asset: self.asset, videoSettings: videoSettings, audioSettings: audioSettings, outPutFile: outputFile)
        super.init()
    }
    
    func exportAsynchronouslyWithCompletionHandler(_ handler: @escaping ExportCompletionHandler) -> Void {
        do {
            try self.reader.configWithAssets(self.asset)
            self.writer.configAssetWrite()
        } catch  {
            return
        }
        self.completionHandler = handler
        if self.reader.videoOutput != nil {
            self.writer.addVideoInput()
            self.writer.configPixelBufferAdaptor(by: self.reader.videoOutput!.videoComposition!)
        }
        if self.reader.audioOutput != nil {
            self.writer.addAuidoInput()
        }
        self.writer.writer?.startWriting()
        self.reader.reader?.startReading()
        self.writer.writer?.startSession(atSourceTime: self.timeRange.start)
        self.inputQueue = DispatchQueue.init(label: "VideoEncoderInputQueue")
        self.serialQueue = DispatchQueue.init(label: "com.test.mySerialQueue")
        var videoCompleted = false
        var audioCompleted = false
        if self.writer.videoInput != nil {
            self.writer.videoInput?.requestMediaDataWhenReady(on: self.inputQueue!, using: {[weak self] in
                if let output = self?.reader.videoOutput, let input = self?.writer.videoInput {
                    if !(self?.encodeReadySamplesFromOutput(output, to: input) ?? false) {
                        self?.serialQueue?.sync {
                            videoCompleted = true
                            if audioCompleted {
                                self?.finish()
                            }
                        }
                    }
                }
            })
        }
        if self.reader.audioOutput != nil {
            self.writer.audioInput?.requestMediaDataWhenReady(on: self.inputQueue!, using: {[weak self] in
                if let output = self?.reader.audioOutput, let input = self?.writer.audioInput {
                    if !(self?.encodeReadySamplesFromOutput(output, to: input) ?? false) {
                        self?.serialQueue?.sync {
                            audioCompleted = true
                            if videoCompleted {
                                self?.finish()
                            }
                        }
                    }
                }
            })
        } else {
            audioCompleted = true
        }
    }
    
    func finish() -> Void {
        if self.reader.reader!.status == .cancelled || self.writer.writer!.status == .cancelled {
            return;
        }
        if self.writer.writer!.status == .failed {
            
        } else if (self.reader.reader!.status == .failed) {
            self.writer.writer?.cancelWriting()
            self.complete()
        } else {
            self.writer.writer?.finishWriting(completionHandler: {
                self.complete()
            })
        }
    }
    
    func complete() -> Void {
        if self.writer.writer!.status == .failed || self.reader.reader!.status == .cancelled {
            try? FileManager.default.removeItem(atPath: self.writer.outPutFile)
        }
        self.completionHandler?()
        self.completionHandler = nil
    }
    
    func encodeReadySamplesFromOutput(_ output: AVAssetReaderOutput, to input: AVAssetWriterInput) -> Bool {
        while input.isReadyForMoreMediaData {
            let sampleBuffer = output.copyNextSampleBuffer()
            if sampleBuffer != nil {
                var handled = false
                var error = false
                if reader.reader!.status != .reading || writer.writer!.status != .writing {
                    handled = true
                    error = true
                }
                if !handled && self.reader.videoOutput! == output {
                    lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer!)
                    lastSamplePresentationTime = CMTimeSubtract(lastSamplePresentationTime, timeRange.start)
                    self.progress = reader.duration == 0 ? 1 : Float(lastSamplePresentationTime.seconds/duration)
                    if customBufferHandler != nil {
                        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer!)! as CVPixelBuffer
                        var renderBuffer: CVPixelBuffer?
                        CVPixelBufferPoolCreatePixelBuffer(nil, self.writer.videoPixelBufferAdaptor!.pixelBufferPool!, &renderBuffer)
                        handled = self.customBufferHandler?(pixelBuffer, renderBuffer!, lastSamplePresentationTime) ?? false
                        if self.writer.videoPixelBufferAdaptor?.append(renderBuffer!, withPresentationTime: lastSamplePresentationTime) ?? false {
                            error = true
                        }
                    }
                }
                if !handled && !input.append(sampleBuffer!) {
                    error = true
                }
                if error {
                    return false
                }
            } else {
                input.markAsFinished()
                return false
            }
        }
        return true
    }
}
