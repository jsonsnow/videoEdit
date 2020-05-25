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
    let compoundBtn: UIButton = UIButton.init(type: .custom)
    var export: AssetExportSession?
    var saExports: SDAVAssetExportSession?
    var videoEdit: VideoEdit?
    
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
        
        compoundBtn.frame = generateBtn.frame.offsetBy(dx: 0, dy: generateBtn.frame.size.height + 30)
        compoundBtn.backgroundColor = .red
        compoundBtn.addTarget(self, action: #selector(compound), for: .touchUpInside)
        view.addSubview(compoundBtn)
        // Do any additional setup after loading the view.
    }
    
    @objc func compound() {
        let time = Int64(Date.init().timeIntervalSince1970 * 1000)
        var output = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
        output = output + "/\(time)_output.mp4"
        let audioUrl = Bundle.main.path(forResource: "Amy Deasismont - Heartbeats", ofType: "mp3")!
        let videoUrl = Bundle.main.path(forResource: "1590316208497_output", ofType: "mp4")!
        let videoAsset = AVAsset.init(url: URL.init(fileURLWithPath: videoUrl))
        let timeRange = videoAsset.tracks(withMediaType: .video).first!.timeRange
        let videoRead = AssetRead.init(asset: videoAsset, timeRange: timeRange, videoComposition: nil, videoSettings: AssetExportSession.videoSettings(by: videoAsset))
        try? videoRead.configWithAssets(videoAsset)
        let audioAsset = AVAsset.init(url: URL.init(fileURLWithPath: audioUrl))
        let audioRead = AssetRead.init(asset: audioAsset, timeRange: timeRange, videoComposition: nil, videoSettings: nil)
        try? audioRead.configWithAssets(audioAsset)
        videoEdit = VideoEdit.init()
        videoEdit?.outputURL = URL.init(fileURLWithPath: output)
        videoEdit?.addAssetRead(videoRead)
        videoEdit?.addAssetRead(audioRead)
        videoEdit?.startComposition()
    }
    
    @objc func clickGenerat() {
        let time = Int64(Date.init().timeIntervalSince1970 * 1000)
        var output = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
        output = output + "/\(time)_output.mp4"
        let target = URL.init(fileURLWithPath: output)
        let imageOne = Bundle.main.path(forResource: "771590299251_.pic", ofType: "jpg")!
        let imageTwo = Bundle.main.path(forResource: "781590299252_.pic", ofType: "jpg")!
        let imageThree = Bundle.main.path(forResource: "791590299253_.pic", ofType: "jpg")!
        let imageFouer = Bundle.main.path(forResource: "801590299254_.pic", ofType: "jpg")!
        let imageFive = Bundle.main.path(forResource: "811590299255_.pic", ofType: "jpg")!
        let imageSix = Bundle.main.path(forResource: "821590299256_.pic", ofType: "jpg")!
        let imageSeven = Bundle.main.path(forResource: "831590299257_.pic", ofType: "jpg")!
        let imageEight = Bundle.main.path(forResource: "841590299258_.pic", ofType: "jpg")!
        let imageNine = Bundle.main.path(forResource: "851590299259_.pic", ofType: "jpg")!
        let images = [UIImage.init(named: imageOne)!,
                      UIImage.init(named: imageTwo)!,
        UIImage.init(named: imageThree)!,
        UIImage.init(named: imageFouer)!,
        UIImage.init(named: imageFive)!,
        UIImage.init(named: imageSix)!,
        UIImage.init(named: imageSeven)!,
        UIImage.init(named: imageEight)!,UIImage.init(named: imageNine)!]
        let settings = [AVVideoWidthKey: 1080,
                        AVVideoHeightKey: 1440,
                        AVVideoCodecKey: AVVideoCodecType.h264] as [String : Any]
        
        let imageTrack = ImageTrack.init(images: images, frame: 10, settings:settings , outputFile: target.absoluteString)
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

