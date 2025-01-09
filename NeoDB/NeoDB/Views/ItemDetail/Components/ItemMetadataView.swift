import SwiftUI

struct ItemMetadataView: View {
    let metadata: [(label: String, value: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(metadata, id: \.label) { item in
                if !item.value.isEmpty {
                    HStack(alignment: .top) {
                        Text(item.label)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(item.value)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ItemMetadataView(metadata: [
        ("Director", "Christopher Nolan"),
        ("Year", "2023"),
        ("Genre", "Drama, Thriller"),
        ("Duration", "180 minutes")
    ])
} 