import SwiftUI

struct ExpandableDescriptionView: View {
    let description: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text(description)
                    .font(.body)
                    .lineLimit(isExpanded ? nil : 3)
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

#Preview {
    ExpandableDescriptionView(description: "This is a long description that needs to be expanded to show all the content. It might contain multiple paragraphs and details about the item.")
}
