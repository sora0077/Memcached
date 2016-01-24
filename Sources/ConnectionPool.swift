//
//  ConnectionPool.swift
//  Memcached
//
//  Created by 林達也 on 2016/01/11.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import libmemcached

final public class ConnectionPool {
    
    public let options: ConnectionOption
    private var _pool: COpaquePointer?
    
    private var _connections: [Connection] = []
    
    public init(options: ConnectionOption) {
        self.options = options
        _pool = memcached_pool(options.configuration, options.configuration.utf8.count)
    }
    
    public convenience init(options: [String]) {
        self.init(options: ConnectionOptions(options: options.map { StringLiteralConnectionOption(stringLiteral: $0) }))
    }
    
    public convenience init(options: String...) {
        self.init(options: options)
    }
    
    deinit {
        detach()
    }
    
    func detach() {
        
        print("detached")
        
        if let pool = _pool {
            memcached_pool_destroy(pool)
        }
    }
    
    public func connection() throws -> Connection {
        
        var rc: memcached_return = MEMCACHED_MAXIMUM_RETURN
        let mc = memcached_pool_pop(_pool!, false, &rc)
        try throwIfError(mc, rc)
        let conn = Connection(memcached: mc, pool: self)
        return conn
    }

    func pop(mc: UnsafeMutablePointer<memcached_st>) {
        if let pool = _pool {
            memcached_pool_push(pool, mc)
        }
    }
}
 