//
//  CustomLayer.swift
//  BrokenAnimation
//
//  Created by Michał Śmiałko on 20/10/2021.
//

import Foundation
import CoreGraphics
import UIKit

class CustomLayer: CALayer {
    
    @NSManaged var progress: CGFloat
    
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        let l = layer as! CustomLayer
        super.init(layer: layer)
        
        print("Copy. \(progress) \(l.progress)")
        self.progress = l.progress
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override class func needsDisplay(forKey key: String) -> Bool {
        let needsDisplayKeys = ["progress"]
        if needsDisplayKeys.contains(key) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }
    
    override class func defaultValue(forKey key: String) -> Any? {
        if key == "progress" { return CGFloat(0.0) }
        return super.defaultValue(forKey: key)
    }
    
    override func action(forKey event: String) -> CAAction? {
        if event == "progress" {
            let anim: CABasicAnimation = CABasicAnimation(keyPath: event)
            anim.fromValue = presentation()?.progress ?? 0.0
            return anim
        }
        return super.action(forKey: event)
    }
    
    override func draw(in ctx: CGContext) {
        // Save / restore ctx
        ctx.saveGState()
        defer { ctx.restoreGState() }
        
        print("Draw. \(progress)")
        
        // Draw progress bar
        ctx.move(to: .zero)
        ctx.addLine(to: CGPoint(x: bounds.size.width * progress,
                                y: bounds.size.height * progress))
        ctx.setStrokeColor(UIColor.red.cgColor)
        ctx.setLineWidth(20)
        ctx.strokePath()
        
        // Draw text
        let str = NSAttributedString(string: "Bor: \(borderWidth) | Pr: \(progress)",
                                     attributes: [.foregroundColor : UIColor.red.cgColor,
                                                  .font : UIFont.systemFont(ofSize: 25)])
        let line = CTLineCreateWithAttributedString(str)
        let stringRect = CTLineGetImageBounds(line, ctx)
        ctx.textPosition = CGPoint(x: bounds.midX - stringRect.width / 2,
                                   y: bounds.midY - stringRect.height / 2)
        CTLineDraw(line, ctx)
    }
}
