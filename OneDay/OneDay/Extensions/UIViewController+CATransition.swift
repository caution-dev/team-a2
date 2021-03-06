//
//  UIViewController+CATransition.swift
//  OneDay
//
//  Created by juhee on 20/02/2019.
//  Copyright © 2019 teamA2. All rights reserved.
//

import UIKit

extension UIViewController {
    /**
     UIViewController의 뷰에 fade Transition을 추가한다.
     
     - Parameters:
        - duration : fade duration. 기본값은 0.2
     */
    func addFadeTransition(duration: CFTimeInterval = 0.2) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = CATransitionType.fade
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        
        guard let window = view.window else { return }
        window.layer.add(transition, forKey: kCATransition)
    }
}
