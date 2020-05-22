//
//  ImageTrack.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/22.
//  Copyright © 2020 chen liang. All rights reserved.
//

import UIKit
import AVFoundation

class ImageTrack: NSObject {

    var seconsPerframe: Int = 10
    var setting: [String: Any]?
    var images: [UIImage]!
    var outputFile: String!
    let inputQueue: DispatchQueue = DispatchQueue.init(label: "writeQueue")
    
    init(images:[UIImage], frame: Int, settings:[String: Any], outputFile: String) {
        self.images = images
        self.setting = settings
        self.seconsPerframe = frame
        self.outputFile = outputFile
        super.init()
    }
    
    func generateTrak(with completeHandler: @escaping AssetExportSession.ExportCompletionHandler) -> Void {
        let write = AssetWrite.init(videoSettings: nil, audioSettings: nil, outPutFile: outputFile)
        write.configAssetWrite()
        write.addVideoInput()
        write.configPixelBufferAdaptor(by: setting!)
        write.writer?.startWriting()
        write.writer?.startSession(atSourceTime: .zero)
        var frame = 0
        write.videoInput?.requestMediaDataWhenReady(on: inputQueue, using: {
            while write.videoInput?.isReadyForMoreMediaData ?? false {
                if self.images.count * self.seconsPerframe >= frame {
                    write.videoInput?.markAsFinished()
                    write.writer?.finishWriting {
                        DispatchQueue.main.async {
                            completeHandler()
                        }
                    }
                }
                break
            }
            var buffer: CVPixelBuffer?
            let index = frame/10
            buffer = pixelByImage(self.images[index])
            if write.videoPixelBufferAdaptor?.append(buffer!, withPresentationTime: CMTime.init(value: CMTimeValue(frame), timescale: 10)) ?? false {
                print("append success")
            } else {
                print("append failed")
            }
            frame += 1
        })
    }
}
