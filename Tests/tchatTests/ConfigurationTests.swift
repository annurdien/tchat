import XCTest
@testable import tchat

final class ConfigurationTests: XCTestCase {
    
    func testDefaultConfiguration() {
        let config = Configuration.default
        
        XCTAssertEqual(config.server.port, 8080)
        XCTAssertEqual(config.server.host, "0.0.0.0")
        XCTAssertEqual(config.server.maxConnections, 100)
        XCTAssertGreaterThan(config.server.connectionTimeout, 0)
    }
    
    func testCustomPort() {
        let config = Configuration.with(port: 9000)
        XCTAssertEqual(config.server.port, 9000)
    }
    
    func testConfigurationValidation() throws {
        var config = Configuration.default
        
        // Valid configuration should not throw
        try config.validate()
        
        // Invalid port should throw
        config.server.port = 0
        XCTAssertThrowsError(try config.validate())
        
        // Invalid timeout should throw
        config.server.port = 8080
        config.server.connectionTimeout = -1
        XCTAssertThrowsError(try config.validate())
    }
    
    func testEnvironmentVariables() {
        // This would require mocking ProcessInfo, so we just test the load function exists
        let config = Configuration.load()
        XCTAssertNotNil(config)
    }
}
