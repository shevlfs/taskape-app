






import Alamofire
import Foundation
import SwiftDotenv
import SwiftUI

func uploadImage(_ image: UIImage) async throws -> String {
    let apiKey: String = Dotenv["IAPIKEY"]!.stringValue
    let endpoint: String = Dotenv["IAPIENDPOINT"]!.stringValue

    guard let imageData = image.jpegData(compressionQuality: 0.7) else {
        debugPrint(#function, "Couldn't convert image to data")
        throw URLError(.badURL)
    }

    let parameters: [String: Any] = [
        "key": apiKey
    ]

    return try await withCheckedThrowingContinuation { continuation in
        AF.upload(
            multipartFormData: { multipartFormData in
                for (key, value) in parameters {
                    if let data = "\(value)".data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    }
                }
                multipartFormData.append(
                    imageData,
                    withName: "image",
                    fileName: "profile.jpg",
                    mimeType: "image/jpeg"
                )
            }, to: endpoint
        )
        .responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any],
                    let data = json["data"] as? [String: Any],
                    let medium = data["thumb"] as? [String: Any],
                    let url = medium["url"] as? String
                {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            case .failure(let error):
                print("error: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
}
