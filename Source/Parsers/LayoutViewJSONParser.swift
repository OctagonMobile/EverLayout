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

class LayoutViewJSONParser: NSObject , LayoutViewParser
{
    // Example view model JSON
    /*
     id: "elementName:SuperClass",
     constraints: {
        "top:left:right:bottom":"s"
     },
     properties: {
        "backgroundColor" :"orange",
        "cornerRadius" : "10"
     },
     "views":[
        ...
     ]
     */
    
    // View Keys
    public static let KEY_ID : String = "id"
    public static let KEY_CONSTRAINTS : String = "constraints"
    public static let KEY_PROPERTIES : String = "properties"
    public static let KEY_D_PROPERTIES : String = "dProperties"
    public static let KEY_SUBVIEWS : String = "views"
    public static let KEY_Z_INDEX : String = "z-index"
    public static let KEY_TEMPLATE : String = "template"
    
    // Modifier characters
    public static let MOD_NEW_ELEM : Character = "!"
    public static let MOD_SUPERCLASS : Character = ":"
    
    private func parseSource (source : Any?) -> (viewId : String , viewData : [String: JSON])?
    {
        guard let source = source as? (String , [String : JSON]) else { return nil }
        
        return (viewId : source.0 , viewData : source.1)
    }
    
    /// Parses the entire id string from the view model
    ///
    /// - Parameter source: raw view model data
    /// - Returns: Entire view id as a string
    private func rawViewId (source: Any?) -> String?
    {
        guard let source = self.parseSource(source: source as Any) else { return nil }
        
        return source.viewId
    }
    
    func view (source: Any?) -> ELViewModel?
    {
        guard let source = self.parseSource(source: source) else { return nil }
        
        return ELViewModel(rawData: (source.viewId , source.viewData), parser: LayoutViewJSONParser())
    }
    
    /// Parses only the view name from the view id in the view model
    ///
    /// - Parameter source: raw view model data
    /// - Returns: Only the view name as a string
    func viewId (source: Any?) -> String?
    {
        guard var id = self.rawViewId(source: source) else { return nil }
        
        // The id is responsible for declaring if an element is new and if the element subclasses a UIView subclass.
        // We need to parse the id to only return the id of the view
        if id.first == LayoutViewJSONParser.MOD_NEW_ELEM { id.removeFirst() }
        
        if let index = id.firstIndex(of: LayoutViewJSONParser.MOD_SUPERCLASS)
        {
            id = id.substring(to: index)
        }
        
        return id
    }
    
    func viewSuperClass (source: Any?) -> UIView.Type?
    {
        guard let id = self.rawViewId(source: source) else { return nil }
        
        // The id may or may not contain info on a superclass for which this view must subclass
        // The superlcass is only valid if this view is marked as a newElement
        if self.isNewElement(source: source) == true , let index = id.firstIndex(of: LayoutViewJSONParser.MOD_SUPERCLASS)
        {
            let className = id.substring(from: id.index(after: index))
            
            return NSClassFromString(className) as? UIView.Type
        }
        
        return nil
    }
    
    /// Determines if view already exists in the host or is to be created
    ///
    /// - Parameter source: raw view model data
    /// - Returns: bool
    func isNewElement (source: Any?) -> Bool
    {
        guard let id = self.rawViewId(source: source) else { return false }
        
        return id.first == LayoutViewJSONParser.MOD_NEW_ELEM
    }
    
    /// Parse view properties
    ///
    /// - Parameter source: raw view model data
    /// - Returns: Array of EverLayoutViewProperties
    func viewProperties (source: Any?) -> [ELViewProperty?]?
    {
        guard let source = self.parseSource(source: source) else { return nil }
        guard let jsonData = source.viewData[LayoutViewJSONParser.KEY_PROPERTIES]?.dictionary else { return nil }
        
        return jsonData.map({ (key , value) -> ELViewProperty? in
            guard let value = value.string else { return nil }
            
            return ELViewProperty(rawData: (key , value) , parser : LayoutPropertyJSONParser())
        })
    }
    
    /// Parse constraints
    ///
    /// - Parameter source: raw view model data
    /// - Returns: Array of EverLayoutConstraints
    func viewConstraints (source: Any?) -> [ELConstraintModel?]?
    {
        guard let source = self.parseSource(source: source) else { return nil }
        guard let jsonData = source.viewData[LayoutViewJSONParser.KEY_CONSTRAINTS]?.dictionary else { return nil }

        var constraints : [ELConstraintModel?] = []
        
        for (lhs , rhs) in jsonData {
            // rhs can either be a string, for a shorthand arugment, a dictionary for a comprehensive
            // argument, or an array of either
            if let rhs = rhs.array {
                for argument in rhs {
                    if let argument = argument.string {
                        // Use shorthand parser
                        constraints.append(ELConstraintModel(rawData: (lhs , argument), parser: LayoutConstraintJSONShorthandParser()))
                    } else if let argument = argument.dictionary {
                        // Use comprehensive parser
                        constraints.append(ELConstraintModel(rawData: (lhs , argument), parser: LayoutConstraintJSONComprehensiveParser()))
                    }
                }
            } else if let rhs = rhs.string {
                // Use shorthand parser
                constraints.append(ELConstraintModel(rawData: (lhs , rhs), parser: LayoutConstraintJSONShorthandParser()))
            } else if let rhs = rhs.dictionary {
                // Use comprehensive parser
                constraints.append(ELConstraintModel(rawData: (lhs , rhs), parser: LayoutConstraintJSONComprehensiveParser()))
            }
        }
        
        return constraints
    }
    
    /// Get the z-index of this view
    ///
    /// - Parameter source: raw view model data
    /// - Returns: z-index of view as Int
    func viewZIndex (source: Any?) -> Int
    {
        guard let source = self.parseSource(source: source) else { return 0 }
        guard let zIndex = source.viewData[LayoutViewJSONParser.KEY_Z_INDEX]?.string else { return 0 }
        
        return Int(zIndex ) ?? 0
    }
    
    /// Parse subviews
    ///
    /// - Parameter source: raw view model data
    /// - Returns: Dictionary of subviews, with a String key for the view ID and the value is the view data
    func subviews(source: Any?) -> [ELViewModel?]?
    {
        guard let source = self.parseSource(source: source) else { return nil }
        guard let subviewData = source.viewData[LayoutViewJSONParser.KEY_SUBVIEWS]?.dictionary else { return nil }
        
        var subviews : [ELViewModel?] = []
        
        for subview in subviewData
        {
            if let validData = subview.value.dictionary
            {
                subviews.append(ELViewModel(rawData: (subview.key , validData), parser: LayoutViewJSONParser()))
            }
        }
        
        return subviews
    }
    
    /// Returns the name of any sublayouts that should be applied to this view as a template
    ///
    /// - Parameter source: raw view model data
    /// - Returns: Array of sub layout names
    func templateLayout(source: Any?) -> [String]? {
        guard let source = self.parseSource(source: source) else { return nil }
        let templates = source.viewData[LayoutViewJSONParser.KEY_TEMPLATE]
        
        if let templates = templates?.array {
            return templates.map({ (jsonItem) -> String in
                return jsonItem.string ?? ""
            })
        } else if let templates = templates?.string {
            return [templates]
        } else {
            return nil
        }
    }
}







