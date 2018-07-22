//
//  main.swift
//  Icon
//
//  Created by Kazuya Ueoka on 2017/02/19.
//  Copyright © 2017年 fromKK. All rights reserved.
//

import Foundation
import CoreGraphics
import Cocoa
import AppKit

let sizes: [Int] = [20, 29, 40, 58, 60, 76, 152, 80, 87, 120, 180, 167]

//---------------------------------------

let fileManager: FileManager = FileManager.default
let currentPath: String = String(format: "file://%@", fileManager.currentDirectoryPath)
let arguments: [String] = CommandLine.arguments

guard arguments.indices.contains(1) else {
    print("fileName not found...")
    exit(0)
}

var dir: String = "Icons"
if arguments.indices.contains(2) {
    dir = arguments[2]
}

let fileName: String = arguments[1]
guard var url: URL = URL(string: currentPath) else {
    print("url cannot create...")
    exit(0)
}

var result: URL = url.appendingPathComponent(dir)
if !fileManager.fileExists(atPath: result.path) {
    do {
        try fileManager.createDirectory(at: result, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("create directory failed... \(result)")
        exit(0)
    }
}

url.appendPathComponent(fileName)

guard fileManager.fileExists(atPath: url.path) else {
    print("file not exist...")
    exit(0)
}

let image: NSImage = NSImage(byReferencing: url)

func resize(image: NSImage, size destSize: CGSize) -> NSImage? {
    guard let data: Data = image.tiffRepresentation else {
        return nil
    }
    
    guard let bitmapImageRep: NSBitmapImageRep = NSBitmapImageRep(data: data) else {
        return nil
    }
    guard let cgImage: CGImage = bitmapImageRep.cgImage else {
        return nil
    }
    
    let width: Int = Int(destSize.width)
    let height: Int = Int(destSize.height)
    let bitsPerComponent: Int = 8
    let bytesPerRow: Int = Int(4) * width
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    guard let bitmapContext: CGContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
        return nil
    }
    
    let bitmapRect: CGRect = CGRect(origin: CGPoint.zero, size: destSize)
    bitmapContext.draw(cgImage, in: bitmapRect)
    
    guard let newImage: CGImage = bitmapContext.makeImage() else {
        return nil
    }
    return NSImage(cgImage: newImage, size: destSize)
}

func writeToFile(image: NSImage, url: URL) {
    guard let _data: Data = image.tiffRepresentation, let png = NSBitmapImageRep(data: _data) else {
        print(#function, #line, "data get failed")
        return
    }
    
    guard let data = png.representation(using: .png, properties: [:]) else {
        print(#function, "png convert failed")
        return
    }
    
    do {
        try data.write(to: url, options: Data.WritingOptions.atomicWrite)
        print("saved: \(url)")
    } catch {
        print("file save failed: \(url)")
    }
}

let pathExtension: String = String(format: ".%@", url.pathExtension)
sizes.forEach { (length: Int) in
    let filename: String = url.lastPathComponent.replacingOccurrences(of: pathExtension, with: String(format: "_\(length).%@", url.pathExtension))
    let outputURL: URL = result.appendingPathComponent(filename)
    let size: NSSize = NSSize(width: length, height: length)
    guard let resizedImage: NSImage = resize(image: image, size: size) else {
        return
    }
    writeToFile(image: resizedImage, url: outputURL)
}
