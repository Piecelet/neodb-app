//
//  InstanceViewModel.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import SwiftUI
import Perception

@Perceptible final class InstanceViewModel: ObservableObject {
    private var fetchTask: Task<Void, Never>?
    private var client: NetworkClient?
    private let versionIdentifier = "neodb"
    
    var isLoading = false
    var instanceInfo: MastodonInstance?
    var error: Error?
    var showIncompatibleAlert = false
    
    var isCompatible: Bool {
        guard let instance = instanceInfo else { return false }
        return instance.version.localizedCaseInsensitiveContains(versionIdentifier)
    }
    
    var incompatibleReason: String {
        guard let instance = instanceInfo else { return "" }
        return """
            This instance (\(instance.title)) is not compatible with NeoDB.
            
            Reason: This instance is running \(instance.version), which is not a NeoDB server.
            
            Please choose a NeoDB instance or enter a valid NeoDB server address.
            """
    }
    
    func updateSearchText(_ text: String) {
        // Cancel previous task if exists
        fetchTask?.cancel()
        showIncompatibleAlert = false
        
        guard text.contains(".") else {
            instanceInfo = nil
            error = nil
            return
        }
        
        isLoading = true
        
        // Create new task for fetching instance info
        fetchTask = Task { @MainActor in
            do {
                client = NetworkClient(instance: text)
                guard let client = client else { return }
                
                let instance = try await client.fetch(InstanceEndpoint.instance(), type: MastodonInstance.self)
                
                if !Task.isCancelled {
                    instanceInfo = instance
                    error = nil
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    instanceInfo = nil
                }
            }
            
            isLoading = false
        }
    }
} 
