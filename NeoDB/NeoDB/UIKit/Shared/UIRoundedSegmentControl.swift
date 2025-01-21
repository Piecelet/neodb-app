//
//  UIRoundedSegmentControl.swift
//  NeoDB
//
//  Created by citron on 1/21/25.
//

import UIKit
import SwiftUI

class BackgroundContainerView: UIView {
    private let blurEffect = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(blurEffect)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurEffect.frame = bounds
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
        blurEffect.layer.cornerRadius = bounds.height / 2
        blurEffect.layer.masksToBounds = true
    }
}

class UIRoundedSegmentControl: UISegmentedControl {
    private let backgroundContainer = BackgroundContainerView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundContainer.frame = bounds
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
    
    override init(items: [Any]?) {
        super.init(items: items)
        setupAppearance()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }
    
    private func setupAppearance() {
        // Add background container behind everything
        insertSubview(backgroundContainer, at: 0)
        
        // Style configuration
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]
        
        setTitleTextAttributes(normalTextAttributes, for: .normal)
        setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        // Set background appearance
        backgroundColor = .clear
        selectedSegmentTintColor = .white.withAlphaComponent(0.15)
        
        // Remove segment dividers
        setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }
}

// MARK: - SwiftUI Wrapper
struct RoundedSegmentedPickerView<T: Hashable>: UIViewRepresentable {
    @Binding var selection: T
    let options: [T]
    let titleForOption: (T) -> String
    
    init(selection: Binding<T>, options: [T], titleForOption: @escaping (T) -> String) {
        self._selection = selection
        self.options = options
        self.titleForOption = titleForOption
    }
    
    func makeUIView(context: Context) -> UIRoundedSegmentControl {
        let segmentedControl = UIRoundedSegmentControl(items: options.map(titleForOption))
        
        // Set initial selection
        if let index = options.firstIndex(of: selection) {
            segmentedControl.selectedSegmentIndex = index
        }
        
        segmentedControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.segmentedControlValueChanged(_:)),
            for: .valueChanged
        )
        
        return segmentedControl
    }
    
    func updateUIView(_ segmentedControl: UIRoundedSegmentControl, context: Context) {
        if let index = options.firstIndex(of: selection) {
            segmentedControl.selectedSegmentIndex = index
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: RoundedSegmentedPickerView
        
        init(_ parent: RoundedSegmentedPickerView) {
            self.parent = parent
        }
        
        @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
            parent.selection = parent.options[sender.selectedSegmentIndex]
        }
    }
}

// MARK: - Convenience Extensions
extension RoundedSegmentedPickerView where T: CustomStringConvertible {
    init(selection: Binding<T>, options: [T]) {
        self.init(selection: selection, options: options) { $0.description }
    }
}

