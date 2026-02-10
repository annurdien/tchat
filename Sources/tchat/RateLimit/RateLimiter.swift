import Foundation

actor RateLimiter {
    private let config: RateLimitConfig
    private var buckets: [UUID: TokenBucket] = [:]
    
    struct RateLimitConfig: Sendable {
        var messagesPerSecond: Int = 10
        var messagesPerMinute: Int = 100
        var burstSize: Int = 15
    }
    
    private struct TokenBucket {
        var tokens: Double
        var lastRefill: Date
        let maxTokens: Double
        let refillRate: Double
        
        init(maxTokens: Int, refillRate: Double) {
            self.tokens = Double(maxTokens)
            self.lastRefill = Date()
            self.maxTokens = Double(maxTokens)
            self.refillRate = refillRate
        }
        
        mutating func tryConsume() -> Bool {
            refill()
            
            if tokens >= 1.0 {
                tokens -= 1.0
                return true
            }
            return false
        }
        
        mutating func refill() {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastRefill)
            let newTokens = elapsed * refillRate
            
            tokens = min(maxTokens, tokens + newTokens)
            lastRefill = now
        }
    }
    
    init(config: RateLimitConfig = RateLimitConfig()) {
        self.config = config
    }
    
    func checkLimit(for userId: UUID) async -> Bool {
        
        if buckets[userId] == nil {
            buckets[userId] = TokenBucket(
                maxTokens: config.burstSize,
                refillRate: Double(config.messagesPerSecond)
            )
        }
        
        
        return buckets[userId]!.tryConsume()
    }
    
    func recordActivity(for userId: UUID) async {
        _ = await checkLimit(for: userId)
    }
    
    func cleanup() async {
        let now = Date()
        buckets = buckets.filter { (_, bucket) in
            
            now.timeIntervalSince(bucket.lastRefill) < 300
        }
    }
    
    func reset(for userId: UUID) async {
        buckets.removeValue(forKey: userId)
    }
}

actor ConnectionRateLimiter {
    private var attempts: [String: [Date]] = [:]
    private let maxAttemptsPerMinute = 5
    
    func checkConnection(from ip: String) async -> Bool {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        
        if var ipAttempts = attempts[ip] {
            ipAttempts = ipAttempts.filter { $0 > oneMinuteAgo }
            
            
            if ipAttempts.count >= maxAttemptsPerMinute {
                return false
            }
            
            
            ipAttempts.append(now)
            attempts[ip] = ipAttempts
        } else {
            
            attempts[ip] = [now]
        }
        
        return true
    }
    
    func cleanup() async {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        
        for (ip, ipAttempts) in attempts {
            let recent = ipAttempts.filter { $0 > oneMinuteAgo }
            if recent.isEmpty {
                attempts.removeValue(forKey: ip)
            } else {
                attempts[ip] = recent
            }
        }
    }
}
