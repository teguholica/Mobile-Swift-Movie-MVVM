//
//  TMDBNetworkService.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol TMDBNetworkServiceProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T
}

public enum NetworkError: LocalizedError, Equatable {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Respon server tidak valid."
        case .httpError(let statusCode):
            return "Server mengembalikan kode status \(statusCode)."
        case .decodingError(let message):
            return "Gagal memproses data: \(message)"
        case .unknown(let message):
            return message
        }
    }
}

public final class TMDBNetworkService: TMDBNetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        self.decoder = decoder
    }

    public func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        let request = try endpoint.makeURLRequest()
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
}
