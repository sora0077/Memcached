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


class MemcachedTests: QuickSpec {
    
    var conn: Connection!
    
    override func spec() {
        beforeEach {
            let pool = ConnectionPool(options:
                "--SERVER=127.0.0.1",
                "--BINARY-PROTOCOL"
            )
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
            
            context("increment") {
                it("can be increment by one") {
                    do {
                        let val1 = try self.conn.increment(forKey: "key")
                        expect(val1).to(equal(1))
                        
                        let val2 = try self.conn.increment(forKey: "key")
                        expect(val2).to(equal(2))
                    } catch {
                        XCTFail("\(error)")
                    }
                }
            }
            
            context("decrement") {
                it("will be 0, value is not set or underflow") {
                    do {
                        let val = try self.conn.decrement(forKey: "key")
                        expect(val).to(equal(0))
                        
                        let val2 = try self.conn.decrement(forKey: "key")
                        expect(val2).to(equal(0))
                    } catch {
                        XCTFail("\(error)")
                    }
                }
            }
            
            context("increment and decrement") {
                it("is used as below") {
                    do {
                        try self.conn.increment(forKey: "key")
                        try self.conn.increment(forKey: "key")
                        expect(try self.conn.increment(forKey: "key")).to(equal(3))
                        
                        try self.conn.decrement(forKey: "key")
                        try self.conn.decrement(forKey: "key")
                        expect(try self.conn.decrement(forKey: "key")).to(equal(0))
                    } catch {
                        XCTFail("\(error)")
                    }
                }
            }
            
            context("add") {
                it("can add the value, if value not set") {
                    do {
                        try self.conn.add("val", forKey: "key")
                        
                        let val = try self.conn.stringForKey("key")
                        expect(val).to(equal("val"))
                    } catch {
                        XCTFail("\(error)")
                    }
                }
                
                it("has error, if value is already set") {
                    do {
                        try self.conn.set("", forKey: "key")
                        try self.conn.add("val", forKey: "key")
                    } catch let error as Connection.Error {
                        switch error {
                        case .ConnectionError(let str):
                            expect(str).to(equal("CONNECTION DATA EXISTS"))
                        default:
                            XCTFail("\(error)")
                        }
                    } catch {
                        XCTFail("\(error)")
                    }
                }
            }
            
            context("replace") {
                it("has error, if value not set") {
                    do {
                        try self.conn.replace("val", forKey: "key")
                        XCTFail()
                    } catch let error as Connection.Error {
                        switch error {
                        case .ConnectionError(let str):
                            expect(str).to(equal("NOT FOUND"))
                        default:
                            XCTFail("\(error)")
                        }
                    } catch {
                        XCTFail("\(error)")
                    }
                }
                
                it("replaces new value") {
                    do {
                        try self.conn.set("", forKey: "key")
                        try self.conn.replace("val", forKey: "key")
                        
                        let val = try self.conn.stringForKey("key")
                        expect(val).to(equal("val"))
                    } catch {
                        XCTFail("\(error)")
                    }
                }
            }
        }
    }
}
