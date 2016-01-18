//
//  MemcachedTests.swift
//  MemcachedTests
//
//  Created by 林達也 on 2016/01/11.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import Memcached


struct Options: ServerConnectionOption {
    
    var host: String = "localhost"
}


class MemcachedTests: QuickSpec {
    
    var conn: Connection!
    
    override func spec() {
        beforeEach {
            let pool = ConnectionPool(options: Options())
            self.conn = try! pool.connection()
            try! self.conn.flush()
        }
        describe("memcached") {
            context("getter") {
                it("has no value before setting") {
                    do {
                        let val = try self.conn.stringForKey("key")
                        expect(val).to(beNil())
                    } catch {
                        XCTFail()
                    }
                }
                it("has value, when you set the value") {
                    do {
                        try self.conn.set("test", forKey: "key")
                        let val = try self.conn.stringForKey("key")
                        expect(val).to(equal("test"))
                    } catch {
                        XCTFail()
                    }
                }
                it("has no value, if value is expired") {
                    do {
                        try self.conn.set("test", forKey: "key", expire: 1)
                        expect(try self.conn.stringForKey("key")).to(equal("test"))
                        expect(try self.conn.stringForKey("key")).toEventually(beNil(), timeout: 1.1)
                    } catch {
                        XCTFail()
                    }
                }
            }
            
            context("remove") {
                it("has no value after removing") {
                    do {
                        try self.conn.set("test", forKey: "key")
                        expect(try self.conn.stringForKey("key")).to(equal("test"))
                        try self.conn.remove(forKey: "key")
                        expect(try self.conn.stringForKey("key")).to(beNil())
                    } catch {
                        XCTFail()
                    }
                }
            }
        }
    }
}
