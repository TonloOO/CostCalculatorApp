//
//  ImageSaver.swift
//  CostCalculatorApp
//
//  Extracted from CalculationDetailView.swift
//

import UIKit

final class ImageSaver: NSObject {
    private static var activeSavers: [ImageSaver] = []

    private let completion: (Bool) -> Void

    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init()
    }

    func saveToAlbum(image: UIImage) {
        ImageSaver.activeSavers.append(self)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(handleSaveResult(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func handleSaveResult(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completion(error == nil)
        ImageSaver.activeSavers.removeAll { $0 === self }
    }
}
