//
//  ConnectionOption.swift
//  Memcached
//
//  Created by 林達也 on 2016/01/11.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation

public protocol ConnectionOption {

    var configuration: String { get }
}

public protocol ServerConnectionOption: ConnectionOption {
    
    var host: String { get }
    var port: UInt16 { get }
    var weight: Float? { get }
}

public struct ConnectionOptions: ConnectionOption {
    
    let _options: [ConnectionOption]
    
    public var configuration: String {
        return _options
            .map { $0.configuration }
            .joinWithSeparator(" ")
    }
    
    public init(options: [ConnectionOption]) {
        _options = options
    }
}

public extension ServerConnectionOption {
    
    var port: UInt16 {
        return 11211
    }
    
    var weight: Float? {
        return nil
    }
    
    var configuration: String {
        let weightVal: String = weight != nil ? "/\(weight!)" : ""
        return "--SERVER=\(host):\(port)\(weightVal)"
    }
}
