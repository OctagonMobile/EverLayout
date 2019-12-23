//  EverLayout
//
//  Copyright (c) 2017 Dale Webster
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

public class ELConstraintModel: ELRawData
{
    public var constraintParser : LayoutConstraintParser!
    
    public var leftSideAttributes : [NSLayoutConstraint.Attribute?]? {
        return self.constraintParser.leftSideAttributes(source: self.rawData)
    }
    public var rightSideAttribute : NSLayoutConstraint.Attribute? {
        return self.constraintParser.rightSideAttribute(source: self.rawData)
    }
    public var constant : ELConstraintConstant {
        return self.constraintParser.constant(source: self.rawData) ?? ELConstraintConstant(value: 0, sign: .positive)
    }
    public var multiplier : ELConstraintMultiplier {
        return self.constraintParser.multiplier(source: self.rawData) ?? ELConstraintMultiplier(value: 1, sign: .multiply)
    }
    public var priority : CGFloat? {
        return self.constraintParser.priority(source: self.rawData)
    }
    public var relation : NSLayoutConstraint.Relation {
        return self.constraintParser.relation(source: self.rawData) ?? .equal
    }
    public var comparableViewReference : String? {
        return self.constraintParser.comparableViewReference(source: self.rawData)
    }
    public var identifier : String? {
        return self.constraintParser.identifier(source: self.rawData)
    }
    public var verticalSizeClass : UIUserInterfaceSizeClass? {
        return self.constraintParser.verticalSizeClass(source: self.rawData) ?? .unspecified
    }
    public var horizontalSizeClass : UIUserInterfaceSizeClass? {
        return self.constraintParser.horizontalSizeClass(source: self.rawData) ?? .unspecified
    }
    
    public init (rawData : Any , parser : LayoutConstraintParser)
    {
        super.init(rawData: rawData)
        
        self.constraintParser = parser
    }
    
    public func establishConstraints (onView view : ELViewModel , withViewIndex viewIndex : ViewIndex , viewEnvironment : NSObject? = nil) {
        guard let target = view.target else { return }
        
        for attr in self.leftSideAttributes ?? [] {
            guard let attr = attr else { continue }
            
            // Properties of the constraints can be changed or inferred to make writing them easier. For this we
            // will use a EverLayoutConstraintContext
            let context = ELConstraintContext(
                _target: target,
                _leftSideAttribute: attr,
                _relation: self.relation,
                _comparableView: (self.comparableViewReference == "super") ? target.superview : viewIndex.view(forKey: self.comparableViewReference ?? "") ?? viewEnvironment?.property(forKey: self.comparableViewReference ?? "") as? UIView,
                _rightSideAttribute: self.rightSideAttribute,
                _constant: self.constant,
                _multiplier: self.multiplier)
            
            // Create the constraint from the context
            let constraint : ELConstraint = ELConstraint(item: context.target, attribute: context.leftSideAttribute, relatedBy: context.relation, toItem: context.comparableView, attribute: context.rightSideAttribute ?? context.leftSideAttribute, multiplier: context.multiplier.value, constant: context.constant.value)
            
            // Constraint priority
            if let priority = self.priority {
                constraint.priority = UILayoutPriority(Float(priority))
            }
            
            // SizeClasses
            constraint.horizontalSizeClass = self.horizontalSizeClass
            constraint.verticalSizeClass = self.verticalSizeClass
            
            // Set active / inactive
            constraint.setActiveForTraitCollection(target.traitCollection)
            
            // Add an identifier to the constraint
            constraint.identifier = self.identifier
            
            // Add the constraint to the root view
//            let constraintTarget = viewIndex.rootView() ?? target.superview ?? target
            
            // Check that these the view and comparable view are in the same hierarchy before
            // adding the constraint as this will cause a crash
            if target.sharesAncestry(withView: context.comparableView ?? target) {
                // Add this constraint to the applied constraints of the ELView
                view.appliedConstraints.append(constraint)
                constraint.isActive = true
            } else {
                if let identifier = self.identifier {
                    ELReporter.default.error(message: "Some views do not share a view ancestry and so this constraint cannot be made. Constraint: \(identifier)")
                } else {
                    ELReporter.default.error(message: "Some views do not share a view ancestry and so this constraint cannot be made. Use constraint identifiers to determine which constraint is causing the problem.")
                }
            }
        }
    }
}






