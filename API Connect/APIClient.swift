//
//  APIClient.swift
//  ATCache
//
//  Created by Avinash Tag on 26/01/2019.
//  Copyright © 2019 Avinash Tag. All rights reserved.
//

import Foundation

enum APIResult<T, U> where U: Error  {
    case success(T)
    case failure(U)
}

enum APIError: Error {
    case requestFailed
    case jsonConversionFailure
    case invalidData
    case responseUnsuccessful
    case jsonParsingFailure
    
    var localizedDescription: String {
        switch self {
        case .requestFailed: return "Request Failed"
        case .invalidData: return "Invalid Data"
        case .responseUnsuccessful: return "Response Unsuccessful"
        case .jsonParsingFailure: return "JSON Parsing Failure"
        case .jsonConversionFailure: return "JSON Conversion Failure"
        }
    }
}

enum GenericResponse {
    struct Result: Codable {
        var message : String?
    }
}

protocol APIClient {
    
    var session: URLSession { get }
    func fetch<T: Decodable>(with request: URLRequest, decode: @escaping (Decodable) -> T?, completion: @escaping (APIResult<T?, APIError>) -> Void)
}

extension APIClient {
    
    typealias JSONTaskCompletionHandler = (Decodable?, APIError?) -> Void
    
    func decodingTask<T: Decodable>(with request: URLRequest, decodingType: T.Type, completionHandler completion: @escaping JSONTaskCompletionHandler) -> URLSessionDataTask {

        let task = session.dataTask(with: request) { data, response, error in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, .requestFailed)
                return
            }
            if let data = data {

                do {
                    let genericModel = try JSONDecoder().decode(decodingType, from: data )
                    completion(genericModel, nil)
                } catch {
                    if httpResponse.statusCode != 200 || httpResponse.statusCode != 201 {
                        do {
                            let genericModel = try JSONDecoder().decode(decodingType, from: data)
                            completion(genericModel, .responseUnsuccessful)
                        } catch {
                            completion(nil, .jsonConversionFailure)
                        }
                    }else{
                        completion(nil, .responseUnsuccessful)
                    }
                }
            } else {
                completion(nil, .invalidData)
            }
        }
        return task
    }
    
    func fetch<T: Decodable>(with request: URLRequest, decode: @escaping (Decodable) -> T?, completion: @escaping (APIResult<T?, APIError>) -> Void) {
        let task = decodingTask(with: request, decodingType: T.self) { (json , error) in

                guard let json = json else {
                    if let error = error {
                        completion(APIResult.failure(error))
                    } else {
                        completion(APIResult.failure(.invalidData))
                    }
                    return
                }
                if let value = decode(json) {
                    completion(.success(value))
                } else {
                    completion(.failure(.jsonParsingFailure))
                }
        }
        task.resume()
    }
}
