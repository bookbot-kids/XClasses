//
//  UIView.swift
//  XClasses
//
//  Created by Adrian on 13/10/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Nuke

/// Button contains its related ViewModel.
class Button: UIButton, ViewModelManagerDelegate {
    var viewModel: ViewModelDelegate!

    func assignViewModelToView(viewModel: ViewModelDelegate) {
        self.viewModel = viewModel

    }
    
    // TODO: set property map image and property map label in IB
//    @IBInspectable public var propertyMapImage:String? {
//        get {
//            if let object = objc_getAssociatedObject(self, &stringTagHandle) as? String {
//                return object
//            }
//            return nil
//        }
//        set {
//            objc_setAssociatedObject(self, &stringTagHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
}

/// ImageView contains its related ViewModel.
class ImageView: UIImageView, ViewModelManagerDelegate {
    var viewModel: ViewModelDelegate!
}

private var propertyMapHandle: UInt8 = 0

/// Contains useful properties for IB.
extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable public var propertyMap: String? {
        get {
            if let object = objc_getAssociatedObject(self, &propertyMapHandle) as? String {
                return object
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &propertyMapHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Works in a similar way to viewWithTag: to find mapped views
    func view(withPropertyMap map: String) -> UIView? {
        if propertyMap == map {
            return self
        }

        for view in subviews {
            if let matchingSubview = view.view(withPropertyMap: map) {
                return matchingSubview
            }
        }

        return nil
    }
    
    /// Finds Subviews with property maps and sets their attributes based on the ViewModel
    func map(viewModel: ViewModelDelegate) -> [String: UIView] {
        // Return what you map
        var mappedViews: [String: UIView] = [:]
        if let map = propertyMap, let value = viewModel.viewProperty(forKey: map) {
            mappedViews[map] = self
            magic(withValue: value)
        }

        for view in subviews {
            mappedViews.merge(view.map(viewModel: viewModel)) { (current, _) in current }
        }
        
        return mappedViews
    }
    
    /// Looks for Image Views, Labels (and eventually Buttons) with set Property Maps, and uses the property value in the corresponding model to set the label and/or image.
    func magic(withValue value: Any) {
        // Set image in UIImageView to url with Nuke
        // TODO: Set image from bundle resource
        if let imageView = self as? UIImageView {
            if let stringValue = value as? String, stringValue.isValidUrl, let imageURL = URL(string: stringValue) {
                Nuke.loadImage(with: imageURL, options: ImageLoadingOptions(placeholder: UIImage(named: "Placeholder"), transition: .fadeIn(duration: 0.15)), into: imageView)
            }
        }

        // Set label text
        if let labelView = self as? UILabel, let stringValue = value as? String {
            labelView.text = stringValue
            // TODO: If label is attributed, convert text to attributed from html
        }
        
        // TODO: Set button image and text
    }
}

/// Gesture to highlight non-button view on tap
class HighlightTapGestureRecognizer: UITapGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.view?.alpha = 0.4
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.view?.alpha = 1.0
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.view?.alpha = 1.0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        self.view?.alpha = 1.0
    }
}
