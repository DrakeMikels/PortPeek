//
//  UpdateChecker.swift
//  PortPeek
//

import Foundation

enum UpdateCheckResult {
    case updateAvailable(currentVersion: String?, latestVersion: String, releaseURL: URL)
    case upToDate(currentVersion: String, latestVersion: String)
    case aheadOfLatest(currentVersion: String, latestVersion: String)
}

enum UpdateCheckError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case malformedReleaseTag(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "GitHub returned an invalid response."
        case .httpError(let statusCode):
            return "GitHub returned HTTP \(statusCode) while checking for updates."
        case .malformedReleaseTag(let tag):
            return "The latest release tag '\(tag)' could not be parsed."
        }
    }
}

final class UpdateChecker {
    private let latestReleaseURL = URL(string: "https://api.github.com/repos/DrakeMikels/PortPeek/releases/latest")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func checkForUpdates() async throws -> UpdateCheckResult {
        let release = try await fetchLatestRelease()
        let latestVersion = try normalizedVersion(from: release.tagName)
        let currentVersion = currentVersionString()

        guard let currentVersion else {
            return .updateAvailable(
                currentVersion: nil,
                latestVersion: latestVersion,
                releaseURL: release.htmlURL
            )
        }

        switch currentVersion.compare(latestVersion, options: [.numeric, .caseInsensitive]) {
        case .orderedAscending:
            return .updateAvailable(
                currentVersion: currentVersion,
                latestVersion: latestVersion,
                releaseURL: release.htmlURL
            )
        case .orderedDescending:
            return .aheadOfLatest(currentVersion: currentVersion, latestVersion: latestVersion)
        case .orderedSame:
            return .upToDate(currentVersion: currentVersion, latestVersion: latestVersion)
        }
    }

    private func fetchLatestRelease() async throws -> LatestReleaseResponse {
        var request = URLRequest(url: latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("PortPeek", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateCheckError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw UpdateCheckError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(LatestReleaseResponse.self, from: data)
    }

    private func currentVersionString() -> String? {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        for candidate in [shortVersion, buildVersion] {
            let normalized = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !normalized.isEmpty {
                return normalized
            }
        }

        return nil
    }

    private func normalizedVersion(from tag: String) throws -> String {
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let normalized = version.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw UpdateCheckError.malformedReleaseTag(tag)
        }
        return normalized
    }
}

private struct LatestReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
