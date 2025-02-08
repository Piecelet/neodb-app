//
//  SheetDestination.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/9/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

enum SheetDestination: Identifiable {
    case newStatus
    case editStatus(status: MastodonStatus)
    case replyToStatus(status: MastodonStatus)
    case addToShelf(item: any ItemProtocol, shelfType: ShelfType? = nil, detentLevel: MarkView.DetailLevel = .brief)
    case editShelfItem(mark: MarkSchema, shelfType: ShelfType? = nil, detentLevel: MarkView.DetailLevel = .brief)
    case itemDetails(item: any ItemProtocol)
    case login

    // Store
    case purchase
    case purchaseWithFeature(feature: StoreConfig.Features)
    
    var id: String {
        switch self {
        case .newStatus, .editStatus, .replyToStatus:
            return "statusEditor"
        case .addToShelf, .editShelfItem:
            return "shelfEditor"
        case .itemDetails:
            return "itemDetails"
        case .purchase:
            return "purchase"
        case .purchaseWithFeature:
            return "purchaseWithFeature"
        case .login:
            return "login"
        }
    }
}

// MARK: - Environment Object Wrapper
private struct SheetEnvironmentWrapper<Content: View>: View {
    @EnvironmentObject var accountsManager: AppAccountsManager
    @EnvironmentObject var router: Router
    @EnvironmentObject var storeManager: StoreManager
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(accountsManager)
            .environmentObject(router)
            .environmentObject(storeManager)
    }
}

// MARK: - View Builder
extension SheetDestination {
    @ViewBuilder
    var view: some View {
        SheetEnvironmentWrapper {
            switch self {
            case .newStatus:
                Text("New Status")  // TODO: Implement StatusEditorView
            case .editStatus(let status):
                Text("Edit Status: \(status.id)")  // TODO: Implement StatusEditorView
            case .replyToStatus(let status):
                StatusReplyView(status: status)
            case .addToShelf(let item, let shelfType, let detentLevel):
                MarkView(
                    item: item, shelfType: shelfType,
                    detentLevel: detentLevel
                )
            case .editShelfItem(let mark, let shelfType, let detentLevel):
                MarkView(
                    item: mark.item, mark: mark, shelfType: shelfType,
                    detentLevel: detentLevel
                )
            case .itemDetails(let item):
                ItemDetailsSheet(item: item)
            case .purchase:
                PurchaseView(type: .sheet)
            case .purchaseWithFeature(let feature):
                PurchaseView(type: .sheet, scrollToFeature: feature)
            case .login:
                NavigationStack {
                    InstanceView(isAddingAccount: true)
                }
            }
        }
    }
}

// MARK: - Sheet Presentation
extension View {
    func sheet(for destination: SheetDestination?, onDismiss: (() -> Void)? = nil) -> some View {
        self.sheet(item: Binding(
            get: { destination },
            set: { _ in onDismiss?() }
        )) { destination in
            destination.view
        }
    }
}

