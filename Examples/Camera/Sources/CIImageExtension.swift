//
//  CIImageExtension.swift
//  Camera
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import CoreImage
import Foundation
import UIKit

private enum Error: Swift.Error {
    case failed(reason: String)
}

extension CIImage {
    func renderUIImage() throws -> UIImage {
        if let cgImage {
            return UIImage(cgImage: cgImage)
        }

        guard let cgImage = CIContext().createCGImage(self, from: extent) else {
            throw Error.failed(reason: "Failed to create CGImage")
        }

        return UIImage(cgImage: cgImage)
    }
}
