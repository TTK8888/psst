//
//  DrawingService.swift
//  psst
//
//  Created by Taraaf Khalidi on 28/12/2025.
//

import Foundation
import UIKit
import WidgetKit

final class DrawingService {
    static let shared = DrawingService()
    
    func save(image: UIImage, completion: ((Bool) -> Void)? = nil) {
        guard let data = image.pngData() else {
            print("DrawingService: Failed to convert to png")
            completion?(false)
            return
        }
        
        guard let fileURL = getFileURL() else {
            print("DrawingService: Failed to get the file URl")
            completion?(false)
            return
        }
        
        do {
            try data.write(to: fileURL)
            print("DrawingService: Saved to \(fileURL)")
            WidgetCenter.shared.reloadAllTimelines()
            completion?(true)
        } catch {
            print("DrawingService: Failed to save - \(error.localizedDescription)")
            completion?(false)
        }
    }
    
    func loadImage() -> UIImage? {
        guard let fileURL = getFileURL(),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    private func getFileURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            return nil
        }
        return containerURL.appendingPathComponent(AppConstants.noteFileName)
    }
}
