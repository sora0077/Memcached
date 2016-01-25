//
//  Connection.swift
//  Memcached
//
//  Created by 林達也 on 2016/01/11.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import CMemcached

func throwIfError(mc: UnsafePointer<memcached_st>, _ rc: memcached_return_t) throws {
    
    if !memcached_success(rc) {
        throw Connection.Error.ConnectionError(
            String.fromCString(memcached_strerror(mc, rc)) ??
                String.fromCString(memcached_last_error_message(mc)) ?? ""
        )
    }
}

extension Connection {
    
    public enum Error: ErrorType {
        case ConvertError
        case ConnectionError(String)
    }
    
    private enum Value {
        case String(Swift.String)
        case Data(NSData)

        static let stringFlag: UInt32 = 1
        static let dataFlag: UInt32 = 2
        
        var flags: UInt32 {
            switch self {
            case .String:
                return Value.stringFlag
            case .Data:
                return Value.dataFlag
            }
        }
    }
}

final public class Connection {
    
    private let _pool: ConnectionPool
    private let _mc: UnsafeMutablePointer<memcached_st>
    
    init(memcached: UnsafeMutablePointer<memcached_st>, pool: ConnectionPool) {
        _mc = memcached
        _pool = pool
    }
    
    deinit {
        _pool.pop(_mc)
    }
        
    public var ping: Bool {
        
        guard _mc != nil else { return false }
        
        let rc = memcached_version(_mc)
        return rc == MEMCACHED_SUCCESS
    }
}

extension Connection {
    
    public func stringForKey(key: String) throws -> String? {
        
        switch try valueForKey(key) {
        case .String(let str)?:
            return str
        default:
            return nil
        }
    }
    
    public func dataForKey(key: String) throws -> NSData? {
        
        switch try valueForKey(key) {
        case .Data(let data)?:
            return data
        default:
            return nil
        }
    }
    
    private func valueForKey(key: String) throws -> Value? {
        
        var val_len: Int = 0
        var flags: UInt32 = 0
        var rc: memcached_return = MEMCACHED_MAXIMUM_RETURN
        let val = memcached_get(_mc, key, key.utf8.count, &val_len, &flags, &rc)
        defer {
            free(val)
        }
        
        if rc == MEMCACHED_NOTFOUND {
            return nil
        }
        
        try throwIfError(_mc, rc)
        
        if val == nil {
            return nil
        }
        
        if flags == Value.stringFlag {
            return String.fromCString(val).map(Value.String)
        }
        
        if flags == Value.dataFlag {
            return Value.Data(NSData(bytes: val, length: val_len))
        }
        return nil
    }
}

extension Connection {
    
    public func set(value: String, forKey key: String, expire: Int = 0) throws {
        
        try set(Value.String(value), forKey: key, expire: expire)
    }
    
    public func set(value: NSData, forKey key: String, expire: Int = 0) throws {
       
        try set(Value.Data(value), forKey: key, expire: expire)
    }
    
    private func set(value: Value, forKey key: String, expire: Int = 0) throws {
        
        var rc: memcached_return = MEMCACHED_MAXIMUM_RETURN
        switch value {
        case .String(let str):
            rc = memcached_set(_mc, key, key.utf8.count, str, str.utf8.count, expire, value.flags)
        case .Data(let data):
            rc = memcached_set(_mc, key, key.utf8.count, UnsafePointer(data.bytes), data.length, expire, value.flags)
        }
        
        try throwIfError(_mc, rc)
    }
}

extension Connection {
    
    public func add(value: String, forKey key: String, expire: Int = 0) throws {
        
        try add(Value.String(value), forKey: key, expire: expire)
    }
    
    public func add(value: NSData, forKey key: String, expire: Int = 0) throws {
        
        try add(Value.Data(value), forKey: key, expire: expire)
    }
    
    private func add(value: Value, forKey key: String, expire: Int = 0) throws {
        
        var rc: memcached_return = MEMCACHED_MAXIMUM_RETURN
        switch value {
        case .String(let str):
            rc = memcached_add(_mc, key, key.utf8.count, str, str.utf8.count, expire, value.flags)
        case .Data(let data):
            rc = memcached_add(_mc, key, key.utf8.count, UnsafePointer(data.bytes), data.length, expire, value.flags)
        }
        
        try throwIfError(_mc, rc)
    }
}

extension Connection {
    
    public func replace(value: String, forKey key: String, expire: Int = 0) throws {
        
        try replace(Value.String(value), forKey: key, expire: expire)
    }
    
    public func replace(value: NSData, forKey key: String, expire: Int = 0) throws {
        
        try replace(Value.Data(value), forKey: key, expire: expire)
    }
    
    private func replace(value: Value, forKey key: String, expire: Int = 0) throws {
        
        var rc: memcached_return = MEMCACHED_MAXIMUM_RETURN
        switch value {
        case .String(let str):
            rc = memcached_replace(_mc, key, key.utf8.count, str, str.utf8.count, expire, value.flags)
        case .Data(let data):
            rc = memcached_replace(_mc, key, key.utf8.count, UnsafePointer(data.bytes), data.length, expire, value.flags)
        }
        
        try throwIfError(_mc, rc)
    }
}

extension Connection {

    public func remove(forKey key: String, expire: Int = 0) throws {
        
        let rc = memcached_delete(_mc, key, key.utf8.count, expire)
        try throwIfError(_mc, rc)
    }
    
    public func remove<Sequence: SequenceType where Sequence.Generator.Element == String>(forKeys keys: Sequence, expire: Int = 0) throws {
        
        for key in Set(keys) {
            try remove(forKey: key, expire: expire)
        }
    }
    
    public func remove(forKeys keys: String..., expire: Int = 0) throws {
        
        try remove(forKeys: keys)
    }
    
    public func flush(expire: Int = 0) throws {
        
        let rc = memcached_flush(_mc, expire)
        try throwIfError(_mc, rc)
    }
}

extension Connection {
    
    public func increment(forKey key: String, incr: UInt64 = 1, initial: UInt64 = 1, expire: Int = 0) throws -> UInt64 {
        
        var value: UInt64 = 0
        let rc = memcached_increment_with_initial(_mc, key, key.utf8.count, incr, initial, expire, &value)
        try throwIfError(_mc, rc)
        
        return value
    }
    
    public func decrement(forKey key: String, decr: UInt64 = 1, initial: UInt64 = 0, expire: Int = 0) throws -> UInt64 {
        
        var value: UInt64 = 0
        let rc = memcached_decrement_with_initial(_mc, key, key.utf8.count, decr, initial, expire, &value)
        try throwIfError(_mc, rc)
        
        return value
    }
}