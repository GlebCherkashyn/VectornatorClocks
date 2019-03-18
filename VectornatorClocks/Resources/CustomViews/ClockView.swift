//
//  ClockView.swift
//  VectornatorClocks
//
//  Created by Gleb Cherkashyn on 17.03.2019.
//  Copyright © 2019 Gleb Cherkashyn. All rights reserved.
//

import UIKit

class ClockView: UIView {
    
    // MARK: - Properties -
    private var dial = CAShapeLayer()
    private var secondsPointer = CAShapeLayer()
    private var minutesPointer = CAShapeLayer()
    private var hoursPointer = CAShapeLayer()
    private var shadowLayer = CALayer()
    private var numbersLayer = CALayer()
    private var bgImageView = UIImageView()
    
    private var hours: CGFloat = 0
    private var minutes: CGFloat = 0
    private var seconds: CGFloat = 0
    
    private var centerPoint: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    private var radius: CGFloat {
        return bounds.midX
    }
    
    private var dialPath: CGPath {
        return UIBezierPath(ovalIn: bounds).cgPath
    }
    
    // MARK: - Life cycle -
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    // MARK: - Clock configuration -
    override func layoutSubviews() {
        super.layoutSubviews()
        
        /*
         All drawings are performed in layoutSubviews to avoid issues with view's size
         */
        let components = NSCalendar.current.dateComponents([.second, .hour, .minute], from: Date())
        seconds = CGFloat(components.second!)
        minutes = CGFloat(components.minute!)
        hours = CGFloat(components.hour! % 12)
        
        // Configuring shadow
        shadowLayer.shadowPath = dialPath
        shadowLayer.shadowOpacity = 1
        shadowLayer.shadowRadius = 10
        shadowLayer.shadowOffset = .zero
        shadowLayer.shadowColor = UIColor.black.cgColor
        
        // Configuring background
        bgImageView.frame = bounds
        let imageMask = CAShapeLayer()
        imageMask.path = dialPath
        bgImageView.layer.mask = imageMask
        bgImageView.subviews.forEach { $0.removeFromSuperview() }
        let darkBlur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: darkBlur)
        blurView.frame = bgImageView.bounds
        bgImageView.addSubview(blurView)
        
        // Configuring dial
        dial.path = dialPath
        dial.strokeColor = UIColor.black.cgColor
        dial.fillColor = UIColor.clear.cgColor
        
        drawNumbers()
        
        // Configuring pointers
        configurePointer(&secondsPointer, width: 4, length: bounds.midX - 40)
        secondsPointer.strokeColor = UIColor.white.cgColor
        
        configurePointer(&hoursPointer, width: 6, length: bounds.midX - 80)
        hoursPointer.strokeColor = UIColor.red.cgColor
        
        configurePointer(&minutesPointer, width: 5, length: bounds.midX - 60)
        minutesPointer.strokeColor = UIColor.lightGray.cgColor
        
        setPointersAnimations()
    }
    
    // MARK: - Private functions -
    private func drawNumbers() {
        numbersLayer.bounds = bounds
        numbersLayer.position = centerPoint
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let image = renderer.image { canvas in
            let context = canvas.cgContext
            
            /*
             Shifting and rotating context every time to get correct number position
             */
            for number in 1...12 {
                context.translateBy(x: centerPoint.x, y: centerPoint.y)
                let oneHourSectorAngle = CGFloat.pi * 2 / 12
                context.rotate(by: oneHourSectorAngle)
                context.translateBy(x: -centerPoint.x, y: -centerPoint.y)
                draw(number: number)
            }
        }
        
        numbersLayer.contents = image.cgImage
    }
    
    private func draw(number: Int) {
        
        let string = "\(number)" as NSString
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Orbitron-Bold", size: 20)!,
                          NSAttributedString.Key.foregroundColor: UIColor.white]
        let size = string.size(withAttributes: attributes)
        let borderGapY: CGFloat = 10
        string.draw(at: CGPoint(x: bounds.width/2 - size.width/2, y: borderGapY), withAttributes: attributes)
    }
    
    private func setup() {
        
        // Adding shadow to the bottom of clock
        layer.addSublayer(shadowLayer)
        
        // Adding background image with blur effect
        bgImageView.image = UIImage(named: "fi-0")
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.layer.masksToBounds = true
        
        addSubview(bgImageView)
        
        // Composing main elements
        layer.addSublayer(dial)
        layer.addSublayer(numbersLayer)
        layer.addSublayer(hoursPointer)
        layer.addSublayer(minutesPointer)
        layer.addSublayer(secondsPointer)
    }
    
    private func setPointersAnimations() {
        
        let secondsFromValue = degrees2radians(seconds * 360.0 / 60.0)
        let secondsAnimation = defaultPointerAnimation(with: secondsFromValue,
                                                       duration: 60)
        secondsPointer.add(secondsAnimation, forKey: "seconds")
        
        let minute = minutes + seconds / 60
        let minutesFromValue = degrees2radians(minute * 360 / 60)
        let minutesAnimation = defaultPointerAnimation(with: minutesFromValue,
                                                       duration: 60 * 60)
        minutesPointer.add(minutesAnimation, forKey: "minutes")
        
        let hour = hours + minutes / 60
        let hoursFromValue = degrees2radians(hour * 360 / 12)
        let hoursAnimation = defaultPointerAnimation(with: hoursFromValue,
                                                     duration: 12 * 60 * 60)
        hoursPointer.add(hoursAnimation, forKey: "hours")
    }
    
    private func configurePointer(_ pointer: inout CAShapeLayer, width: CGFloat, length: CGFloat) {
        let arrowPath = buildPointer(width: width, length: length)
        pointer.path = arrowPath.cgPath
        pointer.position = centerPoint
        pointer.lineWidth = width
        pointer.lineCap = .round
    }
    
    /*
     Helper fucntion to draw clock pointer.
     */
    private func buildPointer(width: CGFloat, length: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: .zero)
        let endPoint = CGPoint(x: 0, y: -length)
        path.addLine(to: endPoint)
        
        return path
    }
    
    /*
     Helpers function to build pointer animation.
     Rotates the pointer 360 degrees or 2pi in radians
     */
    private func defaultPointerAnimation(with fromValue: CGFloat,
                                         duration: Double) -> CABasicAnimation {
        
        // Helper variable to change clock speed
        let speedRatio: Double = 1
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.repeatCount = .greatestFiniteMagnitude
        animation.fromValue = fromValue
        animation.duration = duration / speedRatio
        animation.toValue = CGFloat.pi * 2 + fromValue
        return animation
    }
    
    func degrees2radians(_ number: CGFloat) -> CGFloat {
        return number * .pi / 180
    }
}
