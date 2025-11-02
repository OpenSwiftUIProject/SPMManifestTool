// EnvManager.swift
// SPMManifestTool

import Foundation

#if canImport(PackageDescription)
import PackageDescription
#endif

// MARK: - Environment Provider Protocol

/// Protocol for accessing environment variables
/// This allows for testing with mock environments
public protocol EnvironmentProvider {
    func value(forKey key: String) -> String?
}

#if canImport(PackageDescription)
/// Default environment provider using PackageDescription.Context
@MainActor
public struct PackageContextEnvironmentProvider: EnvironmentProvider {
    public init() {}

    public func value(forKey key: String) -> String? {
        Context.environment[key]
    }
}
#endif

/// Process environment provider for testing
public struct ProcessEnvironmentProvider: EnvironmentProvider {
    public init() {}

    public func value(forKey key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }
}

// MARK: - Env Manager

@MainActor
public final class EnvManager {
    public static let shared = EnvManager()

    private var domains: [String] = []
    private var environmentProvider: EnvironmentProvider

    #if canImport(PackageDescription)
    private init() {
        self.environmentProvider = PackageContextEnvironmentProvider()
    }
    #else
    private init() {
        self.environmentProvider = ProcessEnvironmentProvider()
    }
    #endif

    /// Set a custom environment provider (useful for testing)
    public func setEnvironmentProvider(_ provider: EnvironmentProvider) {
        self.environmentProvider = provider
    }

    public func register(domain: String) {
        domains.append(domain)
    }

    public func withDomain<T>(_ domain: String, perform: () throws -> T) rethrows -> T {
        domains.append(domain)
        defer { domains.removeAll { $0 == domain } }
        return try perform()
    }

    private func envValue<T>(
        rawKey: String,
        default defaultValue: T?,
        searchInDomain: Bool,
        parser: (String) -> T?
    ) -> T? {
        func parseEnvValue(_ key: String) -> (String, T)? {
            guard let value = environmentProvider.value(forKey: key) else {
                return nil
            }
            guard let result = parser(value) else {
                return nil
            }
            return (value, result)
        }
        let keys: [String] = searchInDomain
            ? domains.map { "\($0.uppercased())_\(rawKey)" }
            : [rawKey]
        for key in keys {
            if let (value, result) = parseEnvValue(key) {
                print("[Env] \(key)=\(value) -> \(result)")
                return result
            }
        }
        let primaryKey = keys.first ?? rawKey
        if let defaultValue {
            print("[Env] \(primaryKey) not set -> \(defaultValue)(default)")
        }
        return defaultValue
    }

    public func envBoolValue(rawKey: String, default defaultValue: Bool? = nil, searchInDomain: Bool) -> Bool? {
        envValue(rawKey: rawKey, default: defaultValue, searchInDomain: searchInDomain) { value in
            switch value {
            case "1": true
            case "0": false
            default: nil
            }
        }
    }

    public func envIntValue(rawKey: String, default defaultValue: Int? = nil, searchInDomain: Bool) -> Int? {
        envValue(rawKey: rawKey, default: defaultValue, searchInDomain: searchInDomain) { Int($0) }
    }

    public func envStringValue(rawKey: String, default defaultValue: String? = nil, searchInDomain: Bool) -> String? {
        envValue(rawKey: rawKey, default: defaultValue, searchInDomain: searchInDomain) { $0 }
    }
}

// MARK: - Convenience Functions

@MainActor
public func envBoolValue(_ key: String, default defaultValue: Bool = false, searchInDomain: Bool = true) -> Bool {
    EnvManager.shared.envBoolValue(rawKey: key, default: defaultValue, searchInDomain: searchInDomain)!
}

@MainActor
public func envIntValue(_ key: String, default defaultValue: Int = 0, searchInDomain: Bool = true) -> Int {
    EnvManager.shared.envIntValue(rawKey: key, default: defaultValue, searchInDomain: searchInDomain)!
}

@MainActor
public func envStringValue(_ key: String, default defaultValue: String, searchInDomain: Bool = true) -> String {
    EnvManager.shared.envStringValue(rawKey: key, default: defaultValue, searchInDomain: searchInDomain)!
}

@MainActor
public func envStringValue(_ key: String, searchInDomain: Bool = true) -> String? {
    EnvManager.shared.envStringValue(rawKey: key, searchInDomain: searchInDomain)
}
