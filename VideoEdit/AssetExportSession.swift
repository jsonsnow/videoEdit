//
//  AssetExportSession.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/18.
//  Copyright © 2020 chen liang. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class AssetExportSession: NSObject {

    typealias ExportSampleBufferHandler = (_ from: CVPixelBuffer, _ to: UnsafeMutablePointer<CVPixelBuffer?>, _ time: CMTime) -> Bool
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
        self.timeRange = CMTimeRange.init(start: .zero, duration: self.asset.duration)
        self.reader = AssetRead.init(asset: self.asset, timeRange: CMTimeRange.init(start: .zero, end: self.asset.duration), videoComposition: nil, videoSettings: videoSettings)
        self.writer = AssetWrite.init(asset: self.asset, videoSettings: videoSettings, audioSettings: audioSettings, outPutFile: outputFile)
        super.init()
    }
    
    deinit {
        print("asset expot dealloc")
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
            self.writer.videoInput?.requestMediaDataWhenReady(on: self.inputQueue!, using: {
                if let output = self.reader.videoOutput, let input = self.writer.videoInput {
                    if !self.encodeReadySamplesFromOutput(output, to: input) {
                        self.serialQueue?.sync {
                            videoCompleted = true
                            if audioCompleted {
                                self.finish()
                            }
                        }
                    }
                }
            })
        }
        if self.reader.audioOutput != nil {
            self.writer.audioInput?.requestMediaDataWhenReady(on: self.inputQueue!, using: {
                if let output = self.reader.audioOutput, let input = self.writer.audioInput {
                    if !(self.encodeReadySamplesFromOutput(output, to: input)) {
                        self.serialQueue?.sync {
                            audioCompleted = true
                            if videoCompleted {
                                self.finish()
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
                        handled = self.customBufferHandler?(pixelBuffer, &renderBuffer, lastSamplePresentationTime) ?? false
                        if handled {
                            if !(self.writer.videoPixelBufferAdaptor?.append(renderBuffer!, withPresentationTime: lastSamplePresentationTime) ?? false) {
                                error = true
                            }
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
    
    @discardableResult
    @objc static func exportAssetWithUrl(_ url: String, targetFile: String, handler: @escaping ExportCompletionHandler) -> AssetExportSession {
        let time = Int64(Date.init().timeIntervalSince1970 * 1000)
        let asset = AVAsset.init(url: URL.init(fileURLWithPath: url))
        let export = AssetExportSession.init(asset: asset, videoSettings: videoSettings(by: asset), audioSettings: audioSettings(), outputFile: targetFile)
        export.exportAsynchronouslyWithCompletionHandler {
            handler()
            let end = Int64(Date.init().timeIntervalSince1970 * 1000)
            if export.writer.writer!.status == .completed {
                print("video asset duration:\(asset.duration.seconds), export complete and cost time: \(Float(end - time)/1000)")
            }
        }
        export.customBufferHandler = {(buffer, render, time) -> Bool in
            if time.seconds == 0 {
//                let image = CLWaterBridgeFile.imageFromPix(byCI: buffer)
//                WatermarkManager.manager.encodeWatermarkByImage(image) { (res, waterImage) in
//                    //let pixel = CLWaterBridgeFile.imagToPixel(byCI: waterImage!)
//                    WatermarkManager.manager.decodeWatermarkByImage(waterImage!)
//                    let pixelto = export.pixelByImage(waterImage!)
//                    render.pointee = pixelto
//                }
                return true
               
            } else {
                return false
            }
            //export.cover.image = image
            
        }
        return export
    }
}
//CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//CIContext *temporaryContext = [CIContext contextWithOptions:nil];
//CGImageRef videoImage = [temporaryContext
//                   createCGImage:ciImage
//                   fromRect:CGRectMake(0, 0,
//                          CVPixelBufferGetWidth(pixelBuffer),
//                          CVPixelBufferGetHeight(pixelBuffer))];
//
//UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
//CGImageRelease(videoImage);
//return uiImage;

///- (CVPixelBufferRef)imagToPixelByCI:(UIImage *)image {
//    // 1. Create a CIImage with the underlying CGImage encapsulated by the UIImage (referred to as 'image'):
//    UIGraphicsBeginImageContext(image.size);
//    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
//
//    // 2. Create a CIContext:
//
//    CIContext *ciContext = [CIContext contextWithCGContext:UIGraphicsGetCurrentContext() options:nil];
//
//    // 3. Render the CIImage to a CVPixelBuffer (referred to as 'outputBuffer'):
//    NSDictionary *options = @{
//                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
//                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
//                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
//                              };
//    CVPixelBufferRef pxbuffer = NULL;
//
//    CGFloat frameWidth = CGImageGetWidth(image.CGImage);
//    CGFloat frameHeight = CGImageGetHeight(image.CGImage);
//
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                          frameWidth,
//                                          frameHeight,
//                                          kCVPixelFormatType_32BGRA,
//                                          (__bridge CFDictionaryRef) options,
//                                          &pxbuffer);
//    [ciContext render:inputImage toCVPixelBuffer:pxbuffer];
//    //CVPixelBufferRelease(pxbuffer);
//    UIGraphicsEndImageContext();
//    return pxbuffer;
//}

extension AssetExportSession {
    func imageByPixel(_ pixel: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage.init(cvPixelBuffer: pixel)
        let temporaryContext = CIContext.init(options: nil)
        let cgImage = temporaryContext.createCGImage(ciImage, from: CGRect.init(x: 0, y: 0, width: CVPixelBufferGetWidth(pixel), height: CVPixelBufferGetHeight(pixel)))
        let res = UIImage.init(cgImage: cgImage!)
        return res
    }
    
    func pixelByImage(_ image: UIImage) -> CVPixelBuffer {
        UIGraphicsBeginImageContext(image.size)
        let inputImage = CIImage.init(image: image)!
        let context = CIContext.init(cgContext: UIGraphicsGetCurrentContext()!, options: nil)
        let options = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: NSDictionary.init()
            ] as [CFString : Any]
        let width = image.size.width
        let height = image.size.height
        var pixel: CVPixelBuffer?
        let _ = CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, options as CFDictionary, &pixel)
        context.render(inputImage, to: pixel!)
        UIGraphicsEndImageContext()
        return pixel!
    
    }
}

extension AssetExportSession {
    static func videoSettings(by asset: AVAsset) -> [String: Any] {
        let videoTrack = asset.tracks(withMediaType: .video).first!
        let bitsrate = videoTrack.estimatedDataRate
        let transform = videoTrack.preferredTransform
        let videoAngleInDegree  = Double(atan2(transform.b, transform.a)) * 180 / Double.pi;
        var width = videoTrack.naturalSize.width
        var height = videoTrack.naturalSize.height
        if videoAngleInDegree == 90 || videoAngleInDegree == -90 {
            let temp = width
            width = height
            height = temp
        }
        var videoSettings: [String: Any]!
        if #available(iOS 11.0, *) {
            videoSettings = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey:[
                    AVVideoAverageBitRateKey: bitsrate,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoExpectedSourceFrameRateKey: 25,
                    AVVideoMaxKeyFrameIntervalKey: 25
                ],
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
                ] as [String : Any]
        } else {
            videoSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey:[
                AVVideoAverageBitRateKey: bitsrate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: 25,
                AVVideoMaxKeyFrameIntervalKey: 25
            ],
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
            ] as [String : Any]
        }
        return videoSettings
    }
    
    static func audioSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey:2,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 96000]
    }

}
