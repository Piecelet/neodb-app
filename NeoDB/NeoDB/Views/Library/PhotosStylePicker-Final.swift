import SwiftUI

protocol TitleProvider {
	var title: String { get }
}

extension ColorScheme {
	var dual: ColorScheme {
		switch self {
		case .light: return .dark
		case .dark: return .light
		}
	}
}

struct FrameKey: PreferenceKey {
	static var defaultValue: CGRect { .zero }
	
	static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
		value = nextValue()
	}
}

extension View {
	func onFrameChange(
		in coordinateSpace: CoordinateSpace,
		_ onChange: @escaping (CGRect) -> ()
	) -> some View {
		overlay {
			GeometryReader { proxy in
				Color.clear.preference(key: FrameKey.self, value: proxy.frame(in: coordinateSpace))
			}
			.onPreferenceChange(FrameKey.self, perform: onChange)
		}
	}
}

typealias PhotosStylePickerItem = TitleProvider & Hashable

struct PhotosStylePicker<Item: PhotosStylePickerItem>: View {
	var label: LocalizedStringKey
	@Binding var selectedItem: Item
	var items: [Item]
	
	private let coordinateSpaceName = "PhotosStylePicker"
	@State private var frames: [Item: CGRect] = [:]
	
	@Environment(\.colorScheme) private var colorScheme
	
	init(label: LocalizedStringKey, selectedItem: Binding<Item>, items: [Item]) {
		self.label = label
		self._selectedItem = selectedItem
		self.items = items
	}
	
	var body: some View {
		HStack(spacing: 0) {
			ForEach(items, id: \.self) { item in
				Button(action: { selectedItem = item }) {
					Text(item.title.capitalized)
						.font(.callout.weight(.semibold))
						.lineLimit(1)
						.foregroundStyle(foregroundStyle(for: item))
						.environment(\.colorScheme, colorScheme(for: item))
						.padding(.horizontal)
						.padding(.vertical, 5)
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.plain)
				.onFrameChange(in: .named(coordinateSpaceName)) {
					frames[item] = $0
				}
			}
		}
		.background {
			if let frame = frames[selectedItem] {
				Capsule()
					.fill(.thinMaterial.opacity(0.5))
					.environment(\.colorScheme, colorScheme.dual)
					.frame(width: frame.size.width, height: frame.size.height)
					.position(CGPoint(x: frame.midX, y: frame.midY))
					.animation(.interactiveSpring(), value: selectedItem)
			}
		}
		.coordinateSpace(name: coordinateSpaceName)
		.padding(5)
		.environment(\.colorScheme, colorScheme)
		.background(.thinMaterial, in: Capsule())
		.accessibilityRepresentation {
			Picker(
				label,
				selection: $selectedItem
			) {
				ForEach(items, id: \.self) { item in
					Text(item.title)
						.tag(item)
				}
			}
		}
	}
	
	func colorScheme(for item: Item) -> ColorScheme {
		if item == selectedItem {
			return .dark
		} else {
			return colorScheme
		}
	}
	
	func foregroundStyle(for item: Item) -> Color {
		if item == selectedItem {
			return .primary
		} else {
			return .secondary
		}
	}
}