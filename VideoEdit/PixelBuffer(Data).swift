//
//  PixelBuffer(Data).swift
//  VideoEdit
//
//  Created by chen liang on 2020/5/22.
//  Copyright © 2020 chen liang. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage

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
