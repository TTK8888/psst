//
//  CloudKitManager.swift
//  psst
//
//  Created by Taraaf Khalidi on 28/12/2025.
//

import Foundation
import CloudKit
import UIKit

final class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private var database: CKDatabase {container.publicCloudDatabase}
    
    private init() {
        container = CKContainer(identifier: AppConstants.cloudKitContainer)
    }
    
    func uploadNote(image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let data = image.pngData() else {
            completion(false)
            return
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("upload.png")
        
        do {
            try data.write(to: tempURL)
        } catch {
            print("CloudKitManager: Failed to write to temp file - \(error.localizedDescription)")
            completion(false)
            return
        }
        
        let record = CKRecord(recordType: "Note")
        record["coupleID"] = AppConstants.coupleID
        record["timestamp"] = Date()
        record["image"] = CKAsset(fileURL: tempURL)
        
        database.save(record) {
            _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKit Manager: Upload Failed - \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("CloudKit Manager: Upload Successful")
                    completion(true)
                }
            }
        }
    }
}
