import SwiftUI

struct ItemDetailViewContainer: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @EnvironmentObject private var router: Router
    let id: String?
    let category: ItemCategory?
    
    init(itemDetailService: ItemDetailService, id: String? = nil, category: ItemCategory? = nil) {
        _viewModel = StateObject(wrappedValue: ItemDetailViewModel(itemDetailService: itemDetailService))
        self.id = id
        self.category = category
    }
    
    var body: some View {
        ItemDetailView(viewModel: viewModel)
            .onAppear {
                // Load item details
                if let item = router.itemToLoad {
                    viewModel.loadItem(item: item)
                    router.itemToLoad = nil // Clear stored item
                } else if let id = id, let category = category {
                    viewModel.loadItem(id: id, category: category)
                }
            }
    }
}

#Preview {
    ItemDetailViewContainer(itemDetailService: ItemDetailService(authService: AuthService()))
        .environmentObject(Router())
} 