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
    
    var isLoading = false
    var instanceInfo: MastodonInstance?
    var error: Error?
    
    func updateSearchText(_ text: String) {
        // Cancel previous task if exists
        fetchTask?.cancel()
        
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
