import SwiftUI

struct RelativeTimeView: View {
    let date: Date
    @State private var relativeTime: String = ""
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let formatter = RelativeDateTimeFormatter()
    
    init(date: Date) {
        self.date = date
        formatter.unitsStyle = .short
    }
    
    var body: some View {
        Text(relativeTime)
            .onAppear {
                updateRelativeTime()
            }
            .onReceive(timer) { _ in
                updateRelativeTime()
            }
    }
    
    private func updateRelativeTime() {
        relativeTime = formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 20) {
        RelativeTimeView(date: Date())
        RelativeTimeView(date: Date().addingTimeInterval(-3600))
        RelativeTimeView(date: Date().addingTimeInterval(-86400))
        RelativeTimeView(date: Date().addingTimeInterval(-604800))
    }
} 