//
//  TokenCacheManager.swift
//  Screen Fare
//
//  Manages bidirectional caching for ApplicationToken and ActivityCategoryToken
//  encoding/decoding to avoid repeated JSON operations
//
//  ## Purpose
//  - Cache decoded tokens (Data → Token) for quick lookups
//  - Cache encoded tokens (Token → Data) for quick encoding
//  - LRU eviction when cache exceeds size limit
//  - Improve performance when checking temporary unlocks
//

import Foundation
import FamilyControls
import ManagedSettings

class TokenCacheManager {
    // MARK: - Properties

    // Cache for decoded tokens to avoid repeated JSON decoding
    // Limited to 100 entries to prevent unbounded growth
    private var decodedAppTokenCache: [Data: ApplicationToken] = [:]
    private var decodedCategoryTokenCache: [Data: ActivityCategoryToken] = [:]

    // Reverse cache: Token → Data (for encoding operations)
    private var encodedAppTokenCache: [ApplicationToken: Data] = [:]
    private var encodedCategoryTokenCache: [ActivityCategoryToken: Data] = [:]

    private let maxCacheSize = 100

    // MARK: - App Token Methods

    /// Decode app token with caching
    func decodeAppToken(from data: Data) -> ApplicationToken? {
        if let cached = decodedAppTokenCache[data] {
            return cached
        }

        guard let decoded = try? JSONDecoder().decode(ApplicationToken.self, from: data) else {
            return nil
        }

        cacheAppToken(decoded, for: data)
        return decoded
    }

    /// Encode app token with caching
    func encodeAppToken(_ token: ApplicationToken) -> Data? {
        if let cached = encodedAppTokenCache[token] {
            return cached
        }

        guard let encoded = try? JSONEncoder().encode(token) else {
            return nil
        }

        cacheAppToken(token, for: encoded)
        return encoded
    }

    /// Add decoded app token to cache with size limit enforcement
    private func cacheAppToken(_ token: ApplicationToken, for data: Data) {
        decodedAppTokenCache[data] = token
        encodedAppTokenCache[token] = data  // Bidirectional cache
        trimCachesIfNeeded()
    }

    // MARK: - Category Token Methods

    /// Decode category token with caching
    func decodeCategoryToken(from data: Data) -> ActivityCategoryToken? {
        if let cached = decodedCategoryTokenCache[data] {
            return cached
        }

        guard let decoded = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data) else {
            return nil
        }

        cacheCategoryToken(decoded, for: data)
        return decoded
    }

    /// Encode category token with caching
    func encodeCategoryToken(_ token: ActivityCategoryToken) -> Data? {
        if let cached = encodedCategoryTokenCache[token] {
            return cached
        }

        guard let encoded = try? JSONEncoder().encode(token) else {
            return nil
        }

        cacheCategoryToken(token, for: encoded)
        return encoded
    }

    /// Add decoded category token to cache with size limit enforcement
    private func cacheCategoryToken(_ token: ActivityCategoryToken, for data: Data) {
        decodedCategoryTokenCache[data] = token
        encodedCategoryTokenCache[token] = data  // Bidirectional cache
        trimCachesIfNeeded()
    }

    // MARK: - Cache Management

    /// Clear all token caches completely
    func clearTokenCaches() {
        decodedAppTokenCache.removeAll()
        decodedCategoryTokenCache.removeAll()
        encodedAppTokenCache.removeAll()
        encodedCategoryTokenCache.removeAll()
    }

    /// Trim caches if they exceed max size (LRU-style: remove oldest entries)
    private func trimCachesIfNeeded() {
        if decodedAppTokenCache.count > maxCacheSize {
            // Remove oldest 20% of entries
            let removeCount = maxCacheSize / 5
            let keysToRemove = Array(decodedAppTokenCache.keys.prefix(removeCount))
            keysToRemove.forEach { data in
                if let token = decodedAppTokenCache.removeValue(forKey: data) {
                    // Also remove from reverse cache
                    encodedAppTokenCache.removeValue(forKey: token)
                }
            }
            print("[TokenCacheManager] Trimmed app token cache: \(keysToRemove.count) entries removed")
        }

        if decodedCategoryTokenCache.count > maxCacheSize {
            // Remove oldest 20% of entries
            let removeCount = maxCacheSize / 5
            let keysToRemove = Array(decodedCategoryTokenCache.keys.prefix(removeCount))
            keysToRemove.forEach { data in
                if let token = decodedCategoryTokenCache.removeValue(forKey: data) {
                    // Also remove from reverse cache
                    encodedCategoryTokenCache.removeValue(forKey: token)
                }
            }
            print("[TokenCacheManager] Trimmed category token cache: \(keysToRemove.count) entries removed")
        }
    }
}
