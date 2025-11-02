// EnvManagerTests.swift
// SPMManifestToolTests

import Foundation
import Testing
@testable import SPMManifestTool

// MARK: - Mock Environment Provider

final class MockEnvironmentProvider: EnvironmentProvider, @unchecked Sendable {
    private var environment: [String: String] = [:]
    private let lock = NSLock()

    func value(forKey key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return environment[key]
    }

    func set(_ value: String, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        environment[key] = value
    }

    func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        environment.removeValue(forKey: key)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        environment.removeAll()
    }
}

// MARK: - Tests

@Suite("EnvManager Tests")
struct EnvManagerTests {

    @Test("Boolean environment variable parsing - true value")
    @MainActor
    func testBooleanParsingTrue() {
        let mock = MockEnvironmentProvider()
        mock.set("1", forKey: "TEST_BOOL")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envBoolValue(rawKey: "TEST_BOOL", searchInDomain: false)
        #expect(result == true)

        mock.clear()
    }

    @Test("Boolean environment variable parsing - false value")
    @MainActor
    func testBooleanParsingFalse() {
        let mock = MockEnvironmentProvider()
        mock.set("0", forKey: "TEST_BOOL")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envBoolValue(rawKey: "TEST_BOOL", searchInDomain: false)
        #expect(result == false)

        mock.clear()
    }

    @Test("Boolean environment variable parsing - invalid value")
    @MainActor
    func testBooleanParsingInvalid() {
        let mock = MockEnvironmentProvider()
        mock.set("invalid", forKey: "TEST_BOOL")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envBoolValue(rawKey: "TEST_BOOL", default: true, searchInDomain: false)
        #expect(result == true) // Falls back to default

        mock.clear()
    }

    @Test("Boolean environment variable - default value")
    @MainActor
    func testBooleanDefaultValue() {
        let mock = MockEnvironmentProvider()

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envBoolValue(rawKey: "NONEXISTENT", default: true, searchInDomain: false)
        #expect(result == true)

        mock.clear()
    }

    @Test("Integer environment variable parsing")
    @MainActor
    func testIntegerParsing() {
        let mock = MockEnvironmentProvider()
        mock.set("2024", forKey: "TEST_INT")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envIntValue(rawKey: "TEST_INT", searchInDomain: false)
        #expect(result == 2024)

        mock.clear()
    }

    @Test("Integer environment variable - invalid value")
    @MainActor
    func testIntegerParsingInvalid() {
        let mock = MockEnvironmentProvider()
        mock.set("not-a-number", forKey: "TEST_INT")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envIntValue(rawKey: "TEST_INT", default: 42, searchInDomain: false)
        #expect(result == 42) // Falls back to default

        mock.clear()
    }

    @Test("Integer environment variable - default value")
    @MainActor
    func testIntegerDefaultValue() {
        let mock = MockEnvironmentProvider()

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envIntValue(rawKey: "NONEXISTENT", default: 100, searchInDomain: false)
        #expect(result == 100)

        mock.clear()
    }

    @Test("String environment variable parsing")
    @MainActor
    func testStringParsing() {
        let mock = MockEnvironmentProvider()
        mock.set("/usr/local/bin", forKey: "TEST_PATH")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envStringValue(rawKey: "TEST_PATH", searchInDomain: false)
        #expect(result == "/usr/local/bin")

        mock.clear()
    }

    @Test("String environment variable - default value")
    @MainActor
    func testStringDefaultValue() {
        let mock = MockEnvironmentProvider()

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envStringValue(rawKey: "NONEXISTENT", default: "/default/path", searchInDomain: false)
        #expect(result == "/default/path")

        mock.clear()
    }

    @Test("String environment variable - optional (no default)")
    @MainActor
    func testStringOptional() {
        let mock = MockEnvironmentProvider()

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.envStringValue(rawKey: "NONEXISTENT", searchInDomain: false)
        #expect(result == nil)

        mock.clear()
    }

    @Test("Domain registration and search")
    @MainActor
    func testDomainSearch() {
        let mock = MockEnvironmentProvider()
        mock.set("domain-value", forKey: "TESTDOMAIN_MY_VAR")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)
        manager.register(domain: "TestDomain")

        let result = manager.envStringValue(rawKey: "MY_VAR", searchInDomain: true)
        #expect(result == "domain-value")

        mock.clear()
    }

    @Test("Domain search order - first domain wins")
    @MainActor
    func testDomainSearchOrder() {
        let mock = MockEnvironmentProvider()
        mock.set("first-value", forKey: "FIRST_MY_VAR")
        mock.set("second-value", forKey: "SECOND_MY_VAR")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)
        manager.register(domain: "First")
        manager.register(domain: "Second")

        let result = manager.envStringValue(rawKey: "MY_VAR", searchInDomain: true)
        #expect(result == "first-value")

        mock.clear()
    }

    @Test("Domain search - fallback to raw key with includeFallbackToRawKey")
    @MainActor
    func testDomainSearchFallback() {
        let mock = MockEnvironmentProvider()
        mock.set("raw-value", forKey: "MY_VAR")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)
        manager.register(domain: "TestDomain")
        manager.includeFallbackToRawKey = true // Enable fallback to raw key

        let result = manager.envStringValue(rawKey: "MY_VAR", searchInDomain: true)
        #expect(result == "raw-value")

        mock.clear()
    }

    @Test("Disable domain search")
    @MainActor
    func testDisableDomainSearch() {
        let mock = MockEnvironmentProvider()
        mock.set("domain-value", forKey: "TESTDOMAIN_MY_VAR")
        mock.set("raw-value", forKey: "MY_VAR")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)
        manager.register(domain: "TestDomain")

        let result = manager.envStringValue(rawKey: "MY_VAR", searchInDomain: false)
        #expect(result == "raw-value")

        mock.clear()
    }

    @Test("Temporary domain with withDomain")
    @MainActor
    func testWithDomain() {
        let mock = MockEnvironmentProvider()
        mock.set("temp-value", forKey: "TEMPDOMAIN_MY_VAR")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)

        let result = manager.withDomain("TempDomain") {
            manager.envStringValue(rawKey: "MY_VAR", searchInDomain: true)
        }

        #expect(result == "temp-value")

        // After withDomain, temp domain should be removed
        let afterResult = manager.envStringValue(rawKey: "MY_VAR", default: "default", searchInDomain: true)
        #expect(afterResult == "default")

        mock.clear()
    }

    @Test("withDomain preserves existing domains")
    @MainActor
    func testWithDomainPreservesExisting() {
        let mock = MockEnvironmentProvider()
        mock.set("base-value", forKey: "BASEDOMAIN_MY_VAR")
        mock.set("temp-value", forKey: "TEMPDOMAIN_MY_VAR")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)
        manager.register(domain: "BaseDomain")

        manager.withDomain("TempDomain") {
            // Inside, should find BASEDOMAIN first (registered first)
            let result = manager.envStringValue(rawKey: "MY_VAR", searchInDomain: true)
            #expect(result == "base-value")
        }

        // After, BaseDomain should still work
        let result = manager.envStringValue(rawKey: "MY_VAR", searchInDomain: true)
        #expect(result == "base-value")

        mock.clear()
    }

    @Test("Case sensitivity in domain names")
    @MainActor
    func testDomainCaseSensitivity() {
        let mock = MockEnvironmentProvider()
        mock.set("uppercase-value", forKey: "TESTDOMAIN_MY_VAR")

        let manager = EnvManager.shared
        manager.reset()
        manager.setEnvironmentProvider(mock)
        manager.register(domain: "testdomain") // lowercase

        let result = manager.envStringValue(rawKey: "MY_VAR", searchInDomain: true)
        #expect(result == "uppercase-value") // Should uppercase the domain

        mock.clear()
    }
}

@Suite("EnvManager Convenience Functions Tests")
struct EnvManagerConvenienceFunctionsTests {

    @Test("envBoolValue convenience function")
    @MainActor
    func testEnvBoolValueConvenience() {
        let mock = MockEnvironmentProvider()
        mock.set("1", forKey: "TEST_BOOL")

        EnvManager.shared.reset()
        EnvManager.shared.setEnvironmentProvider(mock)

        let result = envBoolValue("TEST_BOOL", default: false, searchInDomain: false)
        #expect(result == true)

        mock.clear()
    }

    @Test("envIntValue convenience function")
    @MainActor
    func testEnvIntValueConvenience() {
        let mock = MockEnvironmentProvider()
        mock.set("42", forKey: "TEST_INT")

        EnvManager.shared.reset()
        EnvManager.shared.setEnvironmentProvider(mock)

        let result = envIntValue("TEST_INT", default: 0, searchInDomain: false)
        #expect(result == 42)

        mock.clear()
    }

    @Test("envStringValue convenience function with default")
    @MainActor
    func testEnvStringValueConvenienceWithDefault() {
        let mock = MockEnvironmentProvider()
        mock.set("test-value", forKey: "TEST_STRING")

        EnvManager.shared.reset()
        EnvManager.shared.setEnvironmentProvider(mock)

        let result = envStringValue("TEST_STRING", default: "default", searchInDomain: false)
        #expect(result == "test-value")

        mock.clear()
    }

    @Test("envStringValue convenience function without default")
    @MainActor
    func testEnvStringValueConvenienceWithoutDefault() {
        let mock = MockEnvironmentProvider()

        EnvManager.shared.reset()
        EnvManager.shared.setEnvironmentProvider(mock)

        let result = envStringValue("NONEXISTENT", searchInDomain: false)
        #expect(result == nil)

        mock.clear()
    }
}
