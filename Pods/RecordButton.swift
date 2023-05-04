//
//  RecordButton.swift
//  Instant
//
//  Created by Samuel Beek on 21/06/15.
//  Copyright (c) 2015 Samuel Beek. All rights reserved.
//

@objc public enum RecordButtonState : Int {
    case recording, idle, hidden;
}

@objc open class RecordButton : SwiftyCamButton {
    
    @IBInspectable
    open var buttonColor: UIColor! = .lightGray {
        didSet {
            circleLayer.backgroundColor = buttonColor.cgColor
            circleBorder.borderColor = buttonColor.cgColor
        }
    }
    
    @IBInspectable
    open var progressColor: UIColor!  = .red {
        didSet {
            gradientMaskLayer.colors = [progressColor.cgColor, progressColor.cgColor]
        }
    }
    
    fileprivate var buttonProgressTimer : Timer?
    
    /// Closes the circle and hides when the RecordButton is finished
    open var closeWhenFinished: Bool = false
    
    open var buttonState : RecordButtonState = .idle {
        didSet {
            switch buttonState {
            case .idle:
                self.alpha = 1.0
                currentProgress = 0
                setProgress(0)
                setRecording(false)
            case .recording:
                self.alpha = 1.0
                setRecording(true)
            case .hidden:
                self.alpha = 0
            }
        }
        
    }
    
    fileprivate var circleLayer: CALayer!
    fileprivate var circleBorder: CALayer!
    fileprivate var progressLayer: CAShapeLayer!
    fileprivate var gradientMaskLayer: CAGradientLayer!
    fileprivate var currentProgress: CGFloat = 0
    
    override public init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.addTarget(self, action: #selector(RecordButton.didTouchDown), for: .touchDown)
        self.addTarget(self, action: #selector(RecordButton.didTouchUp), for: .touchUpInside)
        self.addTarget(self, action: #selector(RecordButton.didTouchUp), for: .touchUpOutside)
        
        self.drawButton()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addTarget(self, action: #selector(RecordButton.didTouchDown), for: .touchDown)
        self.addTarget(self, action: #selector(RecordButton.didTouchUp), for: .touchUpInside)
        self.addTarget(self, action: #selector(RecordButton.didTouchUp), for: .touchUpOutside)
        
        self.drawButton()
    }
    
    
    fileprivate func drawButton() {
        
        self.backgroundColor = UIColor.clear
        let layer = self.layer
        circleLayer = CALayer()
        circleLayer.backgroundColor = buttonColor.cgColor
        
        let size: CGFloat = self.frame.size.width / 1.5
        circleLayer.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        circleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        circleLayer.position = CGPoint(x: self.bounds.midX,y: self.bounds.midY)
        circleLayer.cornerRadius = size / 2
        layer.insertSublayer(circleLayer, at: 0)
        
        circleBorder = CALayer()
        circleBorder.backgroundColor = UIColor.clear.cgColor
        circleBorder.borderWidth = 3
        circleBorder.borderColor = buttonColor.cgColor
        circleBorder.bounds = CGRect(x: 0, y: 0, width: self.bounds.size.width - 1.5, height: self.bounds.size.height - 1.5)
        circleBorder.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        circleBorder.position = CGPoint(x: self.bounds.midX,y: self.bounds.midY)
        circleBorder.cornerRadius = self.frame.size.width / 2
        layer.insertSublayer(circleBorder, at: 0)
        
        let startAngle: CGFloat = CGFloat(Double.pi) + CGFloat(Double.pi / 2)
        let endAngle: CGFloat = CGFloat(Double.pi) * 3 + CGFloat(Double.pi / 2)
        let centerPoint: CGPoint = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
        gradientMaskLayer = self.gradientMask()
        progressLayer = CAShapeLayer()
        progressLayer.path = UIBezierPath(arcCenter: centerPoint, radius: self.frame.size.width / 2 - 7, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
        progressLayer.backgroundColor = UIColor.clear.cgColor
        progressLayer.fillColor = nil
        progressLayer.strokeColor = UIColor.black.cgColor
        progressLayer.lineWidth = 3.0
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = 0.0
        gradientMaskLayer.mask = progressLayer
        //layer.insertSublayer(gradientMaskLayer, at: 0)
        layer.addSublayer(gradientMaskLayer)
    }
    
    fileprivate func setRecording(_ recording: Bool) {
        
        let duration: TimeInterval = 0.15
        circleLayer.contentsGravity = CALayerContentsGravity(rawValue: "center")
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = recording ? 1.0 : 0.88
        scale.toValue = recording ? 0.88 : 1
        scale.duration = duration
        scale.fillMode = CAMediaTimingFillMode.forwards
        scale.isRemovedOnCompletion = false
        
        let color = CABasicAnimation(keyPath: "backgroundColor")
        color.duration = duration
        color.fillMode = CAMediaTimingFillMode.forwards
        color.isRemovedOnCompletion = false
        color.toValue = recording ? progressColor.cgColor : buttonColor.cgColor
        
        let circleAnimations = CAAnimationGroup()
        circleAnimations.isRemovedOnCompletion = false
        circleAnimations.fillMode = CAMediaTimingFillMode.forwards
        circleAnimations.duration = duration
        circleAnimations.animations = [scale, color]
        
        let borderColor: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        borderColor.duration = duration
        borderColor.fillMode = CAMediaTimingFillMode.forwards
        borderColor.isRemovedOnCompletion = false
        borderColor.toValue = recording ? UIColor(red: 0.83, green: 0.86, blue: 0.89, alpha: 1).cgColor : buttonColor
        
        let borderScale = CABasicAnimation(keyPath: "transform.scale")
        borderScale.fromValue = recording ? 1.0 : 0.88
        borderScale.toValue = recording ? 0.88 : 1.0
        borderScale.duration = duration
        borderScale.fillMode = CAMediaTimingFillMode.forwards
        borderScale.isRemovedOnCompletion = false
        
        let borderAnimations = CAAnimationGroup()
        borderAnimations.isRemovedOnCompletion = false
        borderAnimations.fillMode = CAMediaTimingFillMode.forwards
        borderAnimations.duration = duration
        borderAnimations.animations = [borderColor, borderScale]
        
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = recording ? 0.0 : 1.0
        fade.toValue = recording ? 1.0 : 0.0
        fade.duration = duration
        fade.fillMode = CAMediaTimingFillMode.forwards
        fade.isRemovedOnCompletion = false
        
        circleLayer.add(circleAnimations, forKey: "circleAnimations")
        progressLayer.add(fade, forKey: "fade")
        circleBorder.add(borderAnimations, forKey: "borderAnimations")
        
    }
    
    fileprivate func gradientMask() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.locations = [0.0, 1.0]
        let topColor = progressColor
        let bottomColor = progressColor
        if  let safeTopColor = topColor,
            let safeBottomColor = bottomColor {
            gradientLayer.colors = [safeTopColor.cgColor, safeBottomColor.cgColor]
        }
        else {
            gradientLayer.colors = [UIColor.black.cgColor, UIColor.darkGray.cgColor]
        }
        return gradientLayer
    }
    
    override open func layoutSubviews() {
        if  circleLayer != nil {
            circleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            circleLayer.position = CGPoint(x: self.bounds.midX,y: self.bounds.midY)
        }
        if  circleBorder != nil {
            circleBorder.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            circleBorder.position = CGPoint(x: self.bounds.midX,y: self.bounds.midY)
        }
        super.layoutSubviews()
    }
    
    @objc open func didTouchDown(){
        self.buttonState = .recording
    }
    
    @objc open func didTouchUp() {
        if(closeWhenFinished) {
            self.setProgress(1)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.buttonState = .hidden
            }, completion: { completion in
                self.setProgress(0)
            })
        } else {
            self.buttonState = .idle
        }
    }
    
    @objc open func updateProgress() {
        
        guard let validDelegate = delegate else { return }
        
        let newProgress = currentProgress + CGFloat(0.05 / validDelegate.setMaxiumVideoDuration())
        setProgress(newProgress)
        
        /*if  newProgress >= 1 {
            buttonProgressTimer?.invalidate()
        }*/
    }
    
    /**
     Set the relative length of the circle border to the specified progress
     
     - parameter newProgress: the relative lenght, a percentage as float.
     */
    open func setProgress(_ newProgress: CGFloat) {
        progressLayer.strokeEnd = newProgress
        currentProgress = newProgress
    }
    
    // MARK: - Overriding SwiftyCamButton timer methods to stop buttonProgressTimer at the same time
    
    override func startTimer() {
        super.startTimer()
        buttonProgressTimer = Timer.scheduledTimer(
            timeInterval: 0.05,
            target: self,
            selector: #selector(RecordButton.updateProgress),
            userInfo: nil,
            repeats: true
        )
    }
    
    override func invalidateTimer() {
        super.invalidateTimer()
        buttonProgressTimer?.invalidate()
        buttonProgressTimer = nil
        setProgress(0)
        buttonState = .idle
        print("SwiftyCamRecordButton - Record Button Progress Timer was invalidated")
    }
}

