import XCTest
@testable import tchat

final class RateLimiterTests: XCTestCase {
    
    func testRateLimitAllowsInitialMessages() async {
        let limiter = RateLimiter()
        let userId = UUID()
        
        // Should allow first 10 messages quickly
        for _ in 0..<10 {
            let allowed = await limiter.checkLimit(for: userId)
            XCTAssertTrue(allowed)
        }
    }
    
    func testRateLimitBlocksExcessiveMessages() async {
        let limiter = RateLimiter()
        let userId = UUID()
        
        // Burst through all tokens
        for _ in 0..<15 {
            _ = await limiter.checkLimit(for: userId)
        }
        
        // Next message should be blocked
        let allowed = await limiter.checkLimit(for: userId)
        XCTAssertFalse(allowed)
    }
    
    func testRateLimitTokenRefill() async throws {
        let config = RateLimiter.RateLimitConfig(
            messagesPerSecond: 10,
            messagesPerMinute: 100,
            burstSize: 5
        )
        let limiter = RateLimiter(config: config)
        let userId = UUID()
        
        // Use all tokens
        for _ in 0..<5 {
            _ = await limiter.checkLimit(for: userId)
        }
        
        // Should be blocked
        let blockedCheck = await limiter.checkLimit(for: userId)
        XCTAssertFalse(blockedCheck)
        
        // Wait for refill (0.2 seconds = 2 tokens at 10/sec)
        try await Task.sleep(for: .milliseconds(200))
        
        // Should have 2 tokens available now
        let check1 = await limiter.checkLimit(for: userId)
        XCTAssertTrue(check1)
        let check2 = await limiter.checkLimit(for: userId)
        XCTAssertTrue(check2)
        let check3 = await limiter.checkLimit(for: userId)
        XCTAssertFalse(check3)
    }
    
    func testDifferentUsersIndependentLimits() async {
        let limiter = RateLimiter()
        let user1 = UUID()
        let user2 = UUID()
        
        // User 1 uses all tokens
        for _ in 0..<15 {
            _ = await limiter.checkLimit(for: user1)
        }
        
        let user1Check = await limiter.checkLimit(for: user1)
        XCTAssertFalse(user1Check)
        
        // User 2 should still have tokens
        let user2Check = await limiter.checkLimit(for: user2)
        XCTAssertTrue(user2Check)
    }
    
    func testReset() async {
        let limiter = RateLimiter()
        let userId = UUID()
        
        // Use all tokens
        for _ in 0..<20 {
            _ = await limiter.checkLimit(for: userId)
        }
        
        let checkBefore = await limiter.checkLimit(for: userId)
        XCTAssertFalse(checkBefore)
        
        // Reset
        await limiter.reset(for: userId)
        
        // Should be allowed again
        let checkAfter = await limiter.checkLimit(for: userId)
        XCTAssertTrue(checkAfter)
    }
}
