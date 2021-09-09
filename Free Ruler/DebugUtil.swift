//
//  DebugUtil.swift  v.0.2.0
//  SwiftUtilBiP
//
//  Created by Rudolf Farkas on 23.07.19.
//  Copyright © 2019 Rudolf Farkas. All rights reserved.
//

import Foundation

extension NSObject {
    /// Print current class and function names, optionally info
    ///
    /// - Example:
    ///     printClassAndFunc(info: "mouseTickY=\(mouseTickY) label=\(label)")
    ///
    /// - Note: Printing is enabled by DEBUG constant which is normally absent from release builds.
    ///
    /// - Requires: to be called from a subclass of NSObject
    ///
    /// - Parameters:
    ///  - info: information string; a leading "@" will be replaced by the call time
    ///  - fnc: current function (default value is the caller)
    func printClassAndFunc(info inf_: String = "", fnc fnc_: String = #function) {
        #if DEBUG
        var info = inf_
        if inf_.first == "@" { info = "\(Date()) \(inf_.dropFirst())"}
        print("---- \(String(describing: type(of: self))).\(fnc_)", info)
        #endif
    }
}
