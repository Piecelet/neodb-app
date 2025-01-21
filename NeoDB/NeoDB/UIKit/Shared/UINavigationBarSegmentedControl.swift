import SwiftUI
import UIKit

class NavigationBarSegmentedControl: UISegmentedControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }
    
    override init(items: [Any]?) {
        super.init(items: items)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }
    
    private func setupAppearance() {
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ]
        
        setTitleTextAttributes(normalTextAttributes, for: .normal)
        setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        backgroundColor = .clear
        selectedSegmentTintColor = .tertiarySystemBackground
        
        // Remove segment dividers
        setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

struct NavigationBarSegmentedView<T: Hashable>: UIViewRepresentable {
    @Binding var selection: T
    let options: [T]
    let titleForOption: (T) -> String
    
    init(selection: Binding<T>, options: [T], titleForOption: @escaping (T) -> String) {
        self._selection = selection
        self.options = options
        self.titleForOption = titleForOption
    }
    
    func makeUIView(context: Context) -> NavigationBarSegmentedControl {
        let control = NavigationBarSegmentedControl(items: options.map(titleForOption))
        
        if let index = options.firstIndex(of: selection) {
            control.selectedSegmentIndex = index
        }
        
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.segmentedControlValueChanged(_:)),
            for: .valueChanged
        )
        
        // Add swipe gestures
        let leftSwipe = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSwipe(_:))
        )
        leftSwipe.direction = .left
        
        let rightSwipe = UISwipeGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSwipe(_:))
        )
        rightSwipe.direction = .right
        
        control.addGestureRecognizer(leftSwipe)
        control.addGestureRecognizer(rightSwipe)
        
        return control
    }
    
    func updateUIView(_ control: NavigationBarSegmentedControl, context: Context) {
        if let index = options.firstIndex(of: selection) {
            control.selectedSegmentIndex = index
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NavigationBarSegmentedView
        
        init(_ parent: NavigationBarSegmentedView) {
            self.parent = parent
        }
        
        @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
            parent.selection = parent.options[sender.selectedSegmentIndex]
        }
        
        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            guard let control = gesture.view as? UISegmentedControl else { return }
            
            let currentIndex = control.selectedSegmentIndex
            let lastIndex = parent.options.count - 1
            
            switch gesture.direction {
            case .left where currentIndex < lastIndex:
                control.selectedSegmentIndex = currentIndex + 1
                parent.selection = parent.options[currentIndex + 1]
            case .right where currentIndex > 0:
                control.selectedSegmentIndex = currentIndex - 1
                parent.selection = parent.options[currentIndex - 1]
            default:
                break
            }
        }
    }
} 