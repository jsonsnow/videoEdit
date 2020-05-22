//
//  ViewController.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/14.
//  Copyright © 2020 chen liang. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    let btn: UIButton = UIButton.init(type: .custom)
    let generateBtn: UIButton = UIButton.init(type: .custom)
    var export: AssetExportSession?
    var saExports: SDAVAssetExportSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btn.frame = CGRect.init(x: 30, y: 100, width: view.bounds.width - 60, height: 60)
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(clickExprostSession), for: .touchUpInside)
        view.addSubview(btn)
        
        generateBtn.frame = btn.frame.offsetBy(dx: 0, dy: btn.frame.size.height + 30)
        generateBtn.backgroundColor = .red
        generateBtn.addTarget(self, action: #selector(clickGenerat), for: .touchUpInside)
        view.addSubview(generateBtn)
        // Do any additional setup after loading the view.
    }
    
    @objc func clickGenerat() {
        let time = Int64(Date.init().timeIntervalSince1970 * 1000)
        var output = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
        output = output + "/\(time)_output.mp4"
        let target = URL.init(fileURLWithPath: output)
        let imageOne = Bundle.main.path(forResource: "i1589683249_5974_8", ofType: "jpg")!
        let imageTwo = Bundle.main.path(forResource: "1", ofType: "jpg")!
        let images = [UIImage.init(named: imageOne)!, UIImage.init(named: imageTwo)!]
        let imageTrack = ImageTrack.init(images: images, frame: 10, settings: [AVVideoWidthKey: 680, AVVideoHeightKey: 680], outputFile: target.absoluteString)
        imageTrack.generateTrak {
            print(target)
        }
        
    }
    
    @objc func clickExprostSession() {
        print("sssss")
        let time = Int64(Date.init().timeIntervalSince1970 * 1000)
        let url = Bundle.main.path(forResource: "o1589009287_5188_1", ofType: "mp4")!
        let asset = AVAsset.init(url: URL.init(fileURLWithPath: url))
        var output = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
        output = output + "/\(time)_output.mp4"
        let target = URL.init(fileURLWithPath: output)
        let export = AssetExportSession.init(asset: asset, videoSettings: videoSettings(by: asset), audioSettings: audioSettings(), outputFile: target.absoluteString)
        export.exportAsynchronouslyWithCompletionHandler {
            print("xxx")
        }
        self.export = export
        print(output)
//        let videoTrack = asset.tracks(withMediaType: .video).first!
//        let export = SDAVAssetExportSession.init(asset: asset)!
//        export.timeRange = videoTrack.timeRange
//        export.videoSettings = self.videoSettings(by: asset)
//        export.audioSettings = self.audioSettings()
//        export.outputURL = target
//        export.outputFileType = AVFileType.mp4.rawValue
//        export.exportAsynchronously {
//            print("\(export.status.rawValue)")
//        }
//        self.saExports = export
        
        
        
    }
    
    func videoSettings(by asset: AVAsset) -> [String: Any] {
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
        let videoSettings = [
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
        return videoSettings
    }
    
    func audioSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey:2,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 96000]
    }


}

