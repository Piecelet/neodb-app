import SwiftUI

struct ItemDetailViewContainer: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @EnvironmentObject private var router: Router
    
    init(itemDetailService: ItemDetailService) {
        _viewModel = StateObject(wrappedValue: ItemDetailViewModel(itemDetailService: itemDetailService))
    }
    
    var body: some View {
        ItemDetailView(viewModel: viewModel)
            .onAppear {
                // Load item details
                if let item = router.itemToLoad {
                    viewModel.loadItem(item: item)
                    router.itemToLoad = nil // Clear stored item
                }
            }
    }
}

#Preview {
    ItemDetailViewContainer(itemDetailService: ItemDetailService(authService: AuthService()))
        .environmentObject(Router())
} 