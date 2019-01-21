#!/usr/bin/env swift

import Foundation
import QuartzCore
import AppKit

let args = CommandLine.arguments
if args.count <= 2 {
    exit(1);
}

let dataValue = args[1]
let imagePath = args[2]

public enum CorrectionLevel : String {
    case L = "L"
    case M = "M"
    case Q = "Q"
    case H = "H"
}

var backgroundColor: NSColor = NSColor.white
var foregroundColor: NSColor = NSColor.black
var correctionLevel: CorrectionLevel = .M

private func outputImageFromFilter(filter:CIFilter) -> CIImage? {
    if #available(OSX 10.10, *) {
        return filter.outputImage
    } else {
        return filter.value(forKey: "outputImage") as? CIImage ?? nil
    }
}

private func imageWithImageFilter(inputImage:CIImage) -> CIImage? {
    if let colorFilter = CIFilter(name: "CIFalseColor") {
        colorFilter.setDefaults()
        colorFilter.setValue(inputImage, forKey: "inputImage")
        colorFilter.setValue(CIColor(cgColor: foregroundColor.cgColor), forKey: "inputColor0")
        colorFilter.setValue(CIColor(cgColor: backgroundColor.cgColor), forKey: "inputColor1")
        return outputImageFromFilter(filter: colorFilter)
    }
    return nil
}

func createImage(value:String, size:CGSize) -> NSImage? {
    let stringData = value.data(using: String.Encoding.isoLatin1, allowLossyConversion: true)
    if let qrFilter = CIFilter(name: "CIQRCodeGenerator") {
        qrFilter.setDefaults()
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")
        
        guard let filterOutputImage = outputImageFromFilter(filter: qrFilter) else { return nil }
        guard let outputImage = imageWithImageFilter(inputImage: filterOutputImage) else { return nil }
        return createNonInterpolatedImageFromCIImage(image: outputImage, size: size)
    }
    return nil
}

func createNonInterpolatedImageFromCIImage(image:CIImage, size:CGSize) -> NSImage? {
    guard let cgImage = CIContext().createCGImage(image, from: image.extent) else { return nil }
    let newImage = NSImage(size: size)
    newImage.lockFocus()
    let contextPointer = NSGraphicsContext.current!.graphicsPort
    var context:CGContext?
    
    if #available(OSX 10.10, *) {
        //OSX >= 10.10 supports CGContext property
        context = NSGraphicsContext.current?.cgContext
    } else {
        context = unsafeBitCast(contextPointer, to: CGContext.self)
    }
    
    guard let graphicsContext = context else { return nil }
    graphicsContext.interpolationQuality = CGInterpolationQuality.none
    graphicsContext.setShouldAntialias(false)
    
    graphicsContext.draw(cgImage, in: graphicsContext.boundingBoxOfClipPath)
    newImage.unlockFocus()
    return newImage
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

let image: NSImage? = createImage(value: dataValue, size: CGSize(width: 200, height: 200))

let destinationURL = URL.init(fileURLWithPath: imagePath)

if FileManager.default.fileExists(atPath: destinationURL.path) {
    try FileManager.default.removeItem(at: destinationURL)
}

_ = image?.pngWrite(to: destinationURL, options: .withoutOverwriting)
