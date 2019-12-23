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

struct ELConstraintContext
{
    private static let INDEPENDANT_ATTRIBUTES : [NSLayoutConstraint.Attribute] = [
        .width , .height
    ]
    private static let PERSPECTIVE_INSET_ATTRIBUTES : [NSLayoutConstraint.Attribute] = [
        .right , .bottom , .width , .height , .rightMargin
    ]
    private static let PERSPECTIVE_OFFSET_ATTRIBUTES : [NSLayoutConstraint.Attribute] = [
        .left , .top , .width , .height
    ]
    
    var _target : UIView
    var _leftSideAttribute : NSLayoutConstraint.Attribute
    var _relation : NSLayoutConstraint.Relation
    var _comparableView : UIView?
    var _rightSideAttribute : NSLayoutConstraint.Attribute?
    var _constant : ELConstraintConstant
    var _multiplier : ELConstraintMultiplier
    
    var target : UIView {
        return self._target
    }
    var leftSideAttribute : NSLayoutConstraint.Attribute {
        return self._leftSideAttribute
    }
    var relation : NSLayoutConstraint.Relation {
        return self._relation
    }
    var comparableView : UIView? {
        if self._comparableView == nil && self.rightSideAttribute != .notAnAttribute
        {
            return self.target.superview
        }
        
        return self._comparableView
    }
    var rightSideAttribute : NSLayoutConstraint.Attribute? {
        if ELConstraintContext.INDEPENDANT_ATTRIBUTES.contains(self.leftSideAttribute) && self._comparableView == nil
        {
            return .notAnAttribute
        }
        
        return self._rightSideAttribute
    }
    var constant : ELConstraintConstant {
        let sign = self._constant.sign
        var value = self._constant.value
        
        // If the constant is to inset and we are using a 'perspective inset' attribute, or offset and we are using 'perspective offset' attributes
        // then we should inverse the constant. Same if it is just a negative value
        if (ELConstraintContext.PERSPECTIVE_INSET_ATTRIBUTES.contains(self.leftSideAttribute) && sign == .inset) || (ELConstraintContext.PERSPECTIVE_OFFSET_ATTRIBUTES.contains(self.leftSideAttribute) && sign == .offset) ||
            (sign == .negative)
        {
            value *= -1
        }
        
        return ELConstraintConstant(value: value, sign: sign)
    }
    var multiplier : ELConstraintMultiplier {
        let sign = self._multiplier.sign
        var value = self._multiplier.value
        
        if sign == .divide
        {
            value = 1 / value
        }
        
        return ELConstraintMultiplier(value: value, sign: sign)
    }
}
