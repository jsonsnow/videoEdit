//
//  AssetRead.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/18.
//  Copyright © 2020 chen liang. All rights reserved.
//

import UIKit
import AVFoundation

class AssetRead: NSObject {
    
    //MARK: -- porps
    let asset: AVAsset!
    var timeRange: CMTimeRange!
    var duration: Float64 = 0
    var videoSettings: [String: Any]?
    var videoComposition: AVVideoComposition?
    var reader: AVAssetReader?
    var videoOutput: AVAssetReaderVideoCompositionOutput?
    var audioOutput: AVAssetReaderAudioMixOutput?
    
    //MARK: -- init
    init(asset: AVAsset, timeRange: CMTimeRange, videoComposition: AVVideoComposition?, videoSettings: [String: Any]?) {
        self.asset = asset
        self.timeRange = timeRange
        self.videoSettings = videoSettings
        self.videoComposition = videoComposition
        super.init()
    }
    
    //MARK: -- private method
    func configWithAssets(_ asset: AVAsset) throws {
        do {
            try reader = AVAssetReader.init(asset: asset)
        } catch let error {
            throw error
        }
        self.reader?.timeRange = self.timeRange
        if self.timeRange.duration.isValid && !self.timeRange.duration.isPositiveInfinity {
            self.duration = CMTimeGetSeconds(self.timeRange.duration)
        } else {
            duration = CMTimeGetSeconds(self.asset.duration)
        }
        configVideoOutput(by: asset)
        configAudioOutput(by: asset)
    }
    
    private func configVideoOutput(by asset: AVAsset) {
        let videoTracks = self.asset.tracks(withMediaType: .video)
        if videoTracks.count > 0 {
            self.videoOutput = AVAssetReaderVideoCompositionOutput.init(videoTracks: videoTracks, videoSettings: nil)
            self.videoOutput?.alwaysCopiesSampleData = false
            if videoComposition != nil {
                self.videoOutput?.videoComposition = self.videoComposition
            } else {
                self.videoOutput?.videoComposition = self.buildDefaultVideoComposition()
            }
            if reader?.canAdd(videoOutput!) ?? false {
                reader?.add(videoOutput!)
            }
        }
    }
    
    private func configAudioOutput(by asset: AVAsset) {
        let audioTracks = self.asset.tracks(withMediaType: .audio)
        if audioTracks.count > 0 {
            self.audioOutput = AVAssetReaderAudioMixOutput.init(audioTracks: audioTracks, audioSettings: nil)
            self.audioOutput?.alwaysCopiesSampleData = false
            if self.reader?.canAdd(audioOutput!) ?? false {
                self.reader?.add(audioOutput!)
            } else {
                self.audioOutput = nil
            }
        }
    }
    
    private func buildDefaultVideoComposition() -> AVVideoComposition? {
        let videoComposition = AVMutableVideoComposition.init()
        let videoTrack = self.asset.tracks(withMediaType: .video).first
        var trackFrameRate: Float = 0
        if let settings = videoSettings {
            let videoCompressProperties = settings[AVVideoCompressionPropertiesKey] as? [String: Any]
            if videoCompressProperties != nil {
                let frameRate = videoCompressProperties?[AVVideoAverageNonDroppableFrameRateKey] as? NSNumber
                if frameRate != nil {
                    trackFrameRate = frameRate!.floatValue
                }
            }
            
        } else {
            trackFrameRate = videoTrack?.nominalFrameRate ?? 0
        }
        if trackFrameRate == 0 {
            trackFrameRate = 30
        }
        videoComposition.frameDuration = CMTime.init(value: 1, timescale: CMTimeScale(trackFrameRate))
        let targetWidth = self.videoSettings![AVVideoWidthKey] as? NSNumber
        let targetHeight = self.videoSettings![AVVideoHeightKey] as? NSNumber
        var natureSize = videoTrack!.naturalSize
        var targetSize: CGSize?
        var transform = videoTrack!
            .preferredTransform
        let rect = CGRect.init(origin: .zero, size: natureSize)
        let transformedRect = rect.applying(transform);
        transform.tx = transform.tx - transformedRect.origin.x
        transform.ty = transform.ty - transformedRect.origin.y
        if (transform.ty == -560) {
            transform.ty = 0;
        }
        if (transform.tx == -560) {
            transform.tx = 0;
        }
        let videoAngleInDegree = atan2(transform.b, transform.a)
        if videoAngleInDegree == 90 || videoAngleInDegree == -90 {
            let width = natureSize.width
            natureSize.width = natureSize.height
            natureSize.height = width
        }
        if targetWidth != nil && targetHeight != nil {
            targetSize = CGSize.init(width: Double(truncating: targetWidth!), height: Double(truncating: targetHeight!))
        } else {
            targetSize = natureSize
        }
        videoComposition.renderSize = natureSize
        var ratio: Float
        let xratio: Float = Float(targetSize!.width / natureSize.width)
        let yratio: Float = Float(targetSize!.height / natureSize.height)
        ratio = Float.minimum(xratio, yratio)
        
        let postWidth: Float = Float(natureSize.width) * ratio
        let postHeight: Float = Float(natureSize.height) * ratio
        let transx = (Float(targetSize!.width) - postWidth)/2
        let transy = (Float(targetSize!.height) - postHeight)/2
        var matrix = CGAffineTransform.init(translationX: CGFloat(transx/xratio), y: CGFloat(transy/yratio))
        matrix = matrix.scaledBy(x: CGFloat(ratio/xratio), y: CGFloat(ratio/yratio))
        transform = transform.concatenating(matrix)
        
        let passThroughInstruction = AVMutableVideoCompositionInstruction.init()
        passThroughInstruction.timeRange = CMTimeRange.init(start: .zero, duration: self.asset.duration)
        let passThroughLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack!)
        passThroughLayer.setTransform(transform, at: .zero)
        passThroughInstruction.layerInstructions = [passThroughLayer]
        videoComposition.instructions = [passThroughInstruction]
        return videoComposition
    }
    
    //MARK: -- public method

}
