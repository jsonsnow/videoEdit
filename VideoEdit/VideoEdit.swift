//
//  VideoEdit.swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/14.
//  Copyright © 2020 chen liang. All rights reserved.
//

import Foundation
import AVFoundation

class VideoEdit {
    let composition = AVMutableComposition.init()
    var outputURL: URL?
    
    func addAssetRead(_ assetRead: AssetRead) -> Void {
        if assetRead.videoOutput != nil {
            let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: .zero)
            try? videoTrack?.insertTimeRange(assetRead.timeRange, of: assetRead.videoOutput!.videoTracks.first!, at: .zero)
        }
        if assetRead.audioOutput != nil {
            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: .zero)
            try? audioTrack?.insertTimeRange(assetRead.timeRange, of: assetRead.audioOutput!.audioTracks.first!, at: .zero)
        }
    }
    
    func startComposition() -> Void {
        let export = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        export?.shouldOptimizeForNetworkUse = true
        export?.outputFileType = .mp4
        export?.outputURL = outputURL
        export?.exportAsynchronously {
            print("\(export?.status.rawValue)")
        }
    }
    
    func test(url: String) -> Void {
        let startTime = 0;
        let endTime = 30;
        let asset = AVURLAsset.init(url: URL.init(fileURLWithPath: url))
//        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: .zero)
//        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: .zero)
        asset.metadata.forEach { (item) in
            
        }
        
        //asset no audio track
        if asset.tracks(withMediaType: .audio).count == 0 {
            
        }
        let startCropTime = CMTime.init(seconds: Double(startTime), preferredTimescale: 600)
        var endCropTime = CMTime.init(seconds: Double(endTime), preferredTimescale: 600)
        if endTime == 0 {
            endCropTime = CMTime.init(seconds: asset.duration.seconds, preferredTimescale: asset.duration.timescale)
        }
        
        if asset.tracks(withMediaType: .audio).count > 0 {
            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: .zero)
            let audioAssetTrack = asset.tracks(withMediaType: .audio).first!
            try? audioTrack?.insertTimeRange(CMTimeRange.init(start: startCropTime, end: endCropTime), of: audioAssetTrack, at: .zero)
            let backMusicAsset = AVAsset.init(url: URL.init(string: "xxx")! )
            let videoAudioMixTools = AVMutableAudioMix.init()
            let firstAudioParam = AVMutableAudioMixInputParameters.init(track: audioTrack)
            firstAudioParam.setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: CMTimeRange.init(start: startCropTime, end: endCropTime))
            firstAudioParam.trackID = audioTrack!.trackID
            videoAudioMixTools.inputParameters = [firstAudioParam]
            
        }
        
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: .zero)
        let videoAssetTrack = asset.tracks(withMediaType: .video).first!
        try? videoTrack?.insertTimeRange(CMTimeRange.init(start: startCropTime, end: endCropTime), of: videoAssetTrack, at: .zero)
        let mainInstruction = AVMutableVideoCompositionInstruction.init()
        mainInstruction.timeRange = CMTimeRange.init(start: .zero, end:     videoTrack!.timeRange.duration)
        
        let videolayerInstrcution = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack!)
        
        let trans = videoAssetTrack.preferredTransform.scaledBy(x: 1, y: 1)
        videolayerInstrcution.setTransform(trans, at: .zero)
        mainInstruction.layerInstructions = [videolayerInstrcution]
        
       
        
        let exporter = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = true
        let gett = AVAssetImageGenerator.init(asset: asset)
        gett.generateCGImagesAsynchronously(forTimes: [NSValue.init(time: CMTime.init(value: 0, timescale: 600))]) { (time, image, end, resut, error) in
            
        }
        //exporter?.audioMix =
        //exporter?.videoComposition = mainInstruction
        
        
    }
}


//- (void)insertPictureWith:(NSString *)videPath outPath:(NSString *)outPath image:(UIImage *)image;
//{
//    // 1. 获取视频资源`AVURLAsset`。
//    NSURL *videoURL = [NSURL fileURLWithPath:videPath];// 本地文件
//    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
//
//    if (!videoAsset) {
//        return;
//    }
//    CMTime durationTime = videoAsset.duration;//视频的时长
//
//    // 2. 创建自定义合成对象`AVMutableComposition`，我定义它为可变组件。
//    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//
//
//    // 3. 在可变组件中添加资源数据，也就是轨道`AVMutableCompositionTrack`（一般添加2中：音频轨道和视频轨道）
//    // - 视频轨道
//    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
//                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
//    NSArray *videoAssetTraks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
//    if (videoAssetTraks.count == 0) {
//        return;
//    }
//    AVAssetTrack *videoAssetTrack1 = [videoAssetTraks firstObject];
//
//    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, durationTime)
//                        ofTrack:videoAssetTrack1
//                         atTime:kCMTimeZero
//                          error:nil];
//    // - 音频轨道
//    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
//                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
//    NSArray *audioAssetTraks = [videoAsset tracksWithMediaType:AVMediaTypeAudio];
//    if (audioAssetTraks.count == 0) {
//        return;
//    }
//    AVAssetTrack *audioAssetTrack = [audioAssetTraks firstObject];
//    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, durationTime)
//                        ofTrack:audioAssetTrack
//                         atTime:kCMTimeZero
//                          error:nil];
//
//
//    // 6. 创建视频应用层的指令`AVMutableVideoCompositionLayerInstruction` 用户管理视频框架应该如何被应用和组合,也就是说是子视频在总视频中出现和消失的时间、大小、动画等。
//    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//    // - 设置视频层级的一些属性
//    [videolayerInstruction setTransform:videoAssetTrack1.preferredTransform atTime:kCMTimeZero];
//
//
//    // 5. 创建视频组件的指令`AVMutableVideoCompositionInstruction`，这个类主要用于管理应用层的指令。
//    AVMutableVideoCompositionInstruction *mainCompositionIns = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    mainCompositionIns.timeRange = CMTimeRangeMake(kCMTimeZero, durationTime);// 设置视频轨道的时间范围
//    mainCompositionIns.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
//
//    // 4. 创建视频组件`AVMutableVideoComposition`,这个类是处理视频中要编辑的东西。可以设定所需视频的大小、规模以及帧的持续时间。以及管理并设置视频组件的指令
//    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
//    CGSize videoSize = videoAssetTrack1.naturalSize;
//    mainComposition.renderSize = videoSize;
//    mainComposition.instructions = [NSArray arrayWithObject:mainCompositionIns];
//    mainComposition.frameDuration = CMTimeMake(1, 30); // FPS 帧
//
//
//    // --- 插入图片
//    CALayer *animLayer = [CALayer layer];
//
//    [animLayer setContents:(id)[image CGImage]];
//    animLayer.frame = CGRectMake(0, 0, 150, 150);
//
//    NSValue *value1 = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
//    NSValue *value2 = [NSValue valueWithCGPoint:CGPointMake(videoSize.width, videoSize.height/2)];
//    NSValue *value3 = [NSValue valueWithCGPoint:CGPointMake(0, videoSize.height)];
//    NSValue *value4 = [NSValue valueWithCGPoint:CGPointMake(videoSize.width, 0)];
//    NSValue *value5 = [NSValue valueWithCGPoint:CGPointMake(0, videoSize.height/2)];
//    NSValue *value6 = [NSValue valueWithCGPoint:CGPointMake(videoSize.width, videoSize.height)];
//    NSValue *value7 = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
//
//    CAKeyframeAnimation *positionAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
//    positionAnim.values = @[value1,value2,value3,value4,value5,value6,value7];
//    positionAnim.duration = CMTimeGetSeconds(durationTime);
//    positionAnim.beginTime = AVCoreAnimationBeginTimeAtZero;
//    positionAnim.fillMode = kCAFillModeForwards;
//    positionAnim.removedOnCompletion = NO;
//
//    [animLayer addAnimation:positionAnim forKey:@"move"];
//
//
//    CALayer *parentLayer = [CALayer layer];
//    CALayer *videoLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    [parentLayer addSublayer:videoLayer];
//    [parentLayer addSublayer:animLayer];
//
//
//    mainComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//
//
//    // 7. 创建视频导出会话对象`AVAssetExportSession`,主要是根据`videoComposition`去创建一个新的视频，并输出到一个指定的文件路径中去。
//    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
//                                                                      presetName:AVAssetExportPresetHighestQuality];
//    exporter.outputFileType = AVFileTypeQuickTimeMovie;
//    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(durationTime.value - 200, durationTime.timescale));
//    exporter.outputURL = [NSURL fileURLWithPath:outPath];
//    exporter.shouldOptimizeForNetworkUse = YES;
//    exporter.videoComposition = mainComposition;
//
//    [exporter exportAsynchronouslyWithCompletionHandler:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            // 返回主线
//            [self.activityIndicator stopAnimating];
//
//            if (exporter.status == AVAssetExportSessionStatusCompleted) {
//                NSLog(@"合成成功");
//                self.hintLabel.text = @"合成状态提示:合成成功！！！！";
//            }else {
//                NSLog(@"合成失败 ---- -%@",exporter.error);
//                self.hintLabel.text = @"合成状态提示:合成失败！！！！";
//            }
//
//
//
//        });
//    }];
//
//
//
//
//}
//
//// Storyboard关联过来的方法
//- (IBAction)playVideoButtonAction:(id)sender {
//
//    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"TaoLeSi" ofType:@"mp4"];
//
//    NSString *outPath = @"/Users/cgtiger130/Desktop/taolesi_insetPIC.mov";
//
//    [self.activityIndicator startAnimating];
//
//    self.hintLabel.text = @"合成状态提示: 正在合成";
//
//    [self insertPictureWith:videoPath outPath:outPath image:[UIImage imageNamed:@"paopao.png"]];
//
//}

