//
//  KeyboardObserver.swift
//  BleChat
//
//  Created by Jean-Jacques Wacksman.
//  Copyright © 2019 Air France - KLM. All rights reserved.
//

import SwiftUI

class KeyboardObserver: ObservableObject {
    static let shared = KeyboardObserver()
    
    var duration = 0.0
    var curve = UIView.AnimationOptions.curveEaseInOut
    @Published var height = CGFloat(0)
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            curve = UIView.AnimationOptions(rawValue: curveRaw)
            let y = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.origin.y ?? UIScreen.main.bounds.height
            height = max(0, UIScreen.main.bounds.height - y)
            duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
        }
    }
}
