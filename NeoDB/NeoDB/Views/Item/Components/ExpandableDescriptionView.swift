import SwiftUI

struct ExpandableDescriptionView: View {
    let description: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            Text(description)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)

            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Text(isExpanded ? "Show Less" : "Read More")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    ExpandableDescriptionView(
        description:
            "This is a long description that needs to be expanded to show all the content. It might contain multiple paragraphs and details about the item."
    )
}
