//
//  InstanceSocialClient.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation
import OSLog

@MainActor
class InstanceSocialClient {
    private let logger = Logger.client.instanceSocial
    private let authorization = "Bearer \(AppConfig.InstanceSocial.token)"
    private let listEndpoint =
        "https://instances.social/api/1.0/instances/list?count=1000&include_closed=false&include_dead=false&min_active_users=500"
    private let searchEndpoint =
        "https://instances.social/api/1.0/instances/search"

    private let urlSession: URLSession
    private let decoder: JSONDecoder

    struct Response: Decodable {
        let instances: [InstanceSocial]
    }

    init() {
        self.urlSession = .shared
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetchInstances(keyword: String) async -> [InstanceSocial] {
        let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        let endpoint =
            keyword.isEmpty ? listEndpoint : searchEndpoint + "?q=\(keyword)"

        guard let url = URL(string: endpoint) else {
            logger.error("Invalid URL: \(endpoint)")
            return []
        }

        var request = URLRequest(url: url)
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                return []
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("HTTP error: \(httpResponse.statusCode)")
                return []
            }

            let result = try decoder.decode(Response.self, from: data)
            return result.instances.sorted(by: keyword)

        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            return []
        }
    }
}

extension Array where Element == InstanceSocial {
    fileprivate func sorted(by keyword: String) -> Self {
        let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        var newArray = self

        // Sort by users count
        newArray.sort { (lhs: InstanceSocial, rhs: InstanceSocial) in
            guard
                let lhsNumber = Int(lhs.users),
                let rhsNumber = Int(rhs.users)
            else { return false }

            return lhsNumber > rhsNumber
        }

        // Sort by statuses count
        newArray.sort { (lhs: InstanceSocial, rhs: InstanceSocial) in
            guard
                let lhsNumber = Int(lhs.statuses),
                let rhsNumber = Int(rhs.statuses)
            else { return false }

            return lhsNumber > rhsNumber
        }

        // Sort by keyword match if provided
        if !keyword.isEmpty {
            newArray.sort { (lhs: InstanceSocial, rhs: InstanceSocial) in
                if lhs.name.contains(keyword),
                    !rhs.name.contains(keyword)
                {
                    return true
                }
                return false
            }
        }

        return newArray
    }
}
