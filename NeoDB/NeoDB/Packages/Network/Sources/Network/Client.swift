//
//  Client.swift
//  Network
//
//  Created by citron on 12/24/24.
//

import Foundation
import SwiftUI

public class Client: ObservableObject {
  public enum Version: String {
    case v1
  }
  
  public let server: URL
  public let version: Version
  private let urlSession: URLSession
  private let decoder = JSONDecoder()
  
  public init(server: URL, version: Version = .v1) {
    self.server = server
    self.version = version
    self.urlSession = URLSession.shared
    self.decoder.keyDecodingStrategy = .convertFromSnakeCase
  }
  
  private func makeURL(endpoint: Endpoint) -> URL? {
    var components = URLComponents()
    components.scheme = server.scheme
    components.host = server.host
    components.path = server.path + "/api/\(version.rawValue)/\(endpoint.path())"
    components.queryItems = endpoint.queryItems()
    return components.url
  }
    
  public func fetch<Entity: Codable>(endpoint: Endpoint) async throws -> Entity {
    guard let url = makeURL(endpoint: endpoint) else {
        throw NetworkError.invalidURL
    }
    let (data, response) = try await urlSession.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        throw NetworkError.httpError(statusCode: statusCode)
    }
    
    do {
      return try decoder.decode(Entity.self, from: data)
    } catch {
        throw NetworkError.decodingError(error)
    }
  }
}

public enum NetworkError: Error {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(Error)
}
