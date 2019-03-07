//
//  BaseSlidingViewController.swift
//  OneDay
//
//  Created by 정화 on 11/02/2019.
//  Copyright © 2019 teamA2. All rights reserved.
//

import UIKit

class BaseSlidingViewController: UIViewController, UIGestureRecognizerDelegate {
    private struct ViewTag {
        static let snapshot = 1
    }
    
    private let baseMainView: UIView = {
        let view = UIView()
        view.backgroundColor = .doBlue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let baseSideView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let blurCoverView: UIView = {
        let blur = UIVisualEffectView()
        blur.backgroundColor = UIColor(white: 0, alpha: 0.2)
        blur.alpha = 0
        blur.effect = UIBlurEffect(style: .dark)
        blur.translatesAutoresizingMaskIntoConstraints = false
        return blur
    }()
    
    // MARK: Variables
    
    private var isMenuOpened = false
    private var isStatusBarHidden = false
    
    private var baseMainViewLeadingConstraint: NSLayoutConstraint!
    private var baseMainViewTrailingConstraint: NSLayoutConstraint!
   
    private let sideViewWidth = Constants.sideWidth
    
    private var statusBarAnimator = UIViewPropertyAnimator()
    
    override var prefersStatusBarHidden: Bool {
        return self.isStatusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setupViewControllers()
        setupGesture()
    }
    
    // MARK: GestureRecognizer

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
        ) -> Bool {
        if touch.view?.superview?.superview is UITableViewCell {
            return false
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return false
    }
    
    var startPoint: CGPoint = CGPoint.zero
    
    private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss))
        blurCoverView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapDismiss() {
        closeMenu()
    }
    
    // MARK: Pan Gesture
    
    /**
     팬 제스쳐 이벤트에 대한 메소드입니다.
     - 팬 제스쳐의 진행률에 따라 baseMainViewLeftConstraint와 baseMainViewRightConstraint의 값이 변합니다.
     - 두 컨스트레인트가 변하면서 뷰 컨트롤러가 좌에서 우로 트랜지션됩니다.
     */
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        var distance = translation.x
        
        distance = isMenuOpened ? distance+sideViewWidth : distance
        distance = min(sideViewWidth, distance)
        distance = max(0, distance)
        
        let progress = distance/sideViewWidth // 0.0 ~ 1
        baseMainViewLeadingConstraint.constant = distance
        baseMainViewTrailingConstraint.constant = distance
        blurCoverView.alpha = progress
        
        panGestureState(progress, of: gesture)
    }
    
    /**
     제스처의 상태와 진행률에 따라 화면이 사용자와 상호작용합니다.
     - case. began:
        - 상태 바를 보여줄 것인지 결정합니다. 그리고 statusBarAnimator의 상태를 Active 상태로 옮깁니다.
        - 슬라이드 메뉴가 닫혀 있는 상태라면, 현재 화면에 보여지고 있는 뷰와 동일한 스냅샷을 뷰에 추가합니다.
     - case. changed:
        - 진행률에 따라 상태 바 애니메이션을 진행합니다.
     - case. ended:
        - 상태 바의 애니메이션을 멈춥니다.
        - 패닝이 진행된 거리나, 속도 정보를 기반으로, 슬라이드 메뉴를 열리게 할 것인지, 닫히게 할 것인지 결정합니다.
     */
    private func panGestureState(_ progress: CGFloat, of gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            isStatusBarHidden = !isStatusBarHidden
            
            statusBarAnimator = UIViewPropertyAnimator(
                duration: 0.1,
                curve: .easeOut,
                animations: {
                    self.setNeedsStatusBarAppearanceUpdate()
            })
            statusBarAnimator.startAnimation()
            statusBarAnimator.pauseAnimation()
            
            if !isMenuOpened {
                addMainViewSnapshotView()
            }
            
        case .changed:
            statusBarAnimator.fractionComplete = isStatusBarHidden ? progress : 1-progress
            
        case .ended:
            statusBarAnimator.stopAnimation(true)
            handleEnded(gesture: gesture)
        default:
            ()
        }
    }
    
    private func addMainViewSnapshotView() {
        guard let snapshotView = baseMainView.snapshotView(afterScreenUpdates: false) else { return }
        snapshotView.tag = ViewTag.snapshot
        
        baseMainView.addSubview(snapshotView)
        snapshotView.topAnchor.constraint(equalTo: baseMainView.topAnchor).isActive = true
        snapshotView.leadingAnchor.constraint(equalTo: baseMainView.leadingAnchor).isActive = true
        snapshotView.trailingAnchor.constraint(equalTo: baseMainView.trailingAnchor).isActive = true
        snapshotView.bottomAnchor.constraint(equalTo: baseMainView.bottomAnchor).isActive = true
        
        snapshotView.addSubview(blurCoverView)
        blurCoverView.topAnchor.constraint(equalTo: baseMainView.topAnchor).isActive = true
        blurCoverView.leadingAnchor.constraint(equalTo: baseMainView.leadingAnchor).isActive = true
        blurCoverView.trailingAnchor.constraint(equalTo: baseMainView.trailingAnchor).isActive = true
        blurCoverView.bottomAnchor.constraint(equalTo: baseMainView.bottomAnchor).isActive = true
        
        let height = UIScreen.main.bounds.height
        blurCoverView.layer.shadowColor = UIColor.black.cgColor
        blurCoverView.layer.shadowOpacity = 1
        blurCoverView.layer.shadowOffset = CGSize.zero
        blurCoverView.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 6, height: height)).cgPath
        blurCoverView.layer.masksToBounds = true
    }
    
    private func handleEnded(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let threshold: CGFloat = 500 // 제스쳐 방향으로 애니메이션을 완료시키는 임계 속도입니다.
        
        if isMenuOpened {
            if abs(velocity.x) > threshold || abs(translation.x) > sideViewWidth/2 {
                closeMenu()
            } else {
                openMenu()
            }
        } else {
            if velocity.x > threshold || translation.x > sideViewWidth/2 {
                openMenu()
            } else {
                closeMenu()
            }
        }
    }
    
    /**
     - openMenu()가 호출되면 슬라이드 메뉴가 열립니다.
     - 상태바의 상태는 이미 true이지만, 애니메이션을 끝까지 진행시키기 위해서 상태를 다시 바꾸어줍니다.
     - setNeedsStatusBarAppearanceUpdate() 함수는 상태바의 어트리뷰트가 변화 했을 때 작동합니다.
        따라서, 상태를 바꾸어 주지 않을 경우 상태바가 애니메이션 진행률 만큼만 화면에 보일 수 있습니다.
     - 뷰의 컨스트레인트를 모두 에니메이션의 완료 지점으로 지정해줍니다.
     */
    private func openMenu() {
        isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        isMenuOpened = true
        
        baseMainViewLeadingConstraint.constant = sideViewWidth
        baseMainViewTrailingConstraint.constant = sideViewWidth
        performTransitionAnimation()
    }
    
    private func closeMenu() {
        isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()

        isMenuOpened = false
        baseMainViewLeadingConstraint.constant = 0
        baseMainViewTrailingConstraint.constant = 0

        removeSnapShotView()
        performTransitionAnimation()
    }
    
    private func removeSnapShotView() {
        if let viewWithSnapshotTag = self.view.viewWithTag(ViewTag.snapshot) {
            viewWithSnapshotTag.removeFromSuperview()
        }
    }
    
    private func performTransitionAnimation() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: .curveEaseOut,
            animations: {
                self.blurCoverView.alpha = self.isMenuOpened ? 1 : 0
                self.view.layoutIfNeeded()
        },
            completion: nil)
    }
    
    private func setupViews() {
        view.addSubview(baseMainView)
        baseMainView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        baseMainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        baseMainViewTrailingConstraint = baseMainView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        baseMainViewTrailingConstraint.isActive = true
        baseMainViewLeadingConstraint = baseMainView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        baseMainViewLeadingConstraint.isActive = true
        
        view.addSubview(baseSideView)
        baseSideView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        baseSideView.trailingAnchor.constraint(equalTo: baseMainView.safeAreaLayoutGuide.leadingAnchor).isActive = true
        baseSideView.bottomAnchor.constraint(equalTo: baseMainView.bottomAnchor).isActive = true
        baseSideView.widthAnchor.constraint(equalToConstant: sideViewWidth).isActive = true
    }
    
    private func setupViewControllers() {
        guard let mainViewController: MainTabBarViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "tabMain") as? MainTabBarViewController
            else {
                return
        }
        
        let sideViewController = SideMenuViewController()
        
        guard let mainView = mainViewController.view else { return }
        guard let sideView = sideViewController.view else { return }
        
        mainView.translatesAutoresizingMaskIntoConstraints = false
        sideView.translatesAutoresizingMaskIntoConstraints = false
        
        baseMainView.addSubview(mainView)
        mainView.leadingAnchor.constraint(equalTo: baseMainView.leadingAnchor).isActive = true
        mainView.trailingAnchor.constraint(equalTo: baseMainView.trailingAnchor).isActive = true
        mainView.bottomAnchor.constraint(equalTo: baseMainView.bottomAnchor).isActive = true
        mainView.topAnchor.constraint(equalTo: baseMainView.topAnchor).isActive = true
        
        baseSideView.addSubview(sideView)
        sideView.leadingAnchor.constraint(equalTo: baseSideView.leadingAnchor).isActive = true
        sideView.trailingAnchor.constraint(equalTo: baseSideView.trailingAnchor).isActive = true
        sideView.topAnchor.constraint(equalTo: baseSideView.topAnchor).isActive = true
        sideView.bottomAnchor.constraint(equalTo: baseSideView.bottomAnchor).isActive = true
        
        addChild(mainViewController)
        addChild(sideViewController)
    }
}
