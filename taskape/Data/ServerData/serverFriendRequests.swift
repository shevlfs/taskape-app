






import Alamofire
import Foundation
import SwiftData
import SwiftDotenv

func searchUsers(query: String, limit: Int = 10) async -> [UserSearchResult]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    let request = SearchUsersRequest(
        query: query,
        limit: limit,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/searchUsers",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(SearchUsersResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                return response.users
            } else {
                print("Search failed: \(response.message ?? "Unknown error")")
                return nil
            }
        case .failure(let error):
            print("Failed to search users: \(error.localizedDescription)")
            return nil
        }
    }
}

func sendFriendRequest(receiverId: String) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken"),
        let userId = UserDefaults.standard.string(forKey: "user_id")
    else {
        print("No auth token or user ID found")
        return false
    }

    let request = SendFriendRequestRequest(
        sender_id: userId,
        receiver_id: receiverId,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/sendFriendRequest",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(SendFriendRequestResponse.self)
        .response

        switch result.result {
        case .success(let response):
            return response.success
        case .failure(let error):
            print(
                "Failed to send friend request: \(error.localizedDescription)")
            return false
        }
    }
}

func respondToFriendRequest(requestId: String, response: String) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken"),
        let userId = UserDefaults.standard.string(forKey: "user_id")
    else {
        print("No auth token or user ID found")
        return false
    }


    if response != "accept" && response != "reject" {
        print("Invalid response: must be 'accept' or 'reject'")
        return false
    }

    let request = RespondToFriendRequestRequest(
        request_id: requestId,
        user_id: userId,
        response: response,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/respondToFriendRequest",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(RespondToFriendRequestResponse.self)
        .response

        switch result.result {
        case .success(let response):
            return response.success
        case .failure(let error):
            print(
                "Failed to respond to friend request: \(error.localizedDescription)"
            )
            return false
        }
    }
}

func getUserFriends(userId: String) async -> [Friend]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    do {
        struct GetUserFriendsResponse: Codable {
            let success: Bool
            let friends: [Friend]
            let message: String?
        }

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/friends",
            method: .get,
            headers: ["Authorization": token]
        )
        .validate()
        .serializingDecodable(GetUserFriendsResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                return response.friends
            } else {
                print(
                    "Failed to get user friends: \(response.message ?? "Unknown error")"
                )
                return nil
            }
        case .failure(let error):
            print("Failed to get user friends: \(error.localizedDescription)")
            return nil
        }
    }
}

func getFriendRequests(type: String) async -> [FriendRequest]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken"),
        let userId = UserDefaults.standard.string(forKey: "user_id")
    else {
        print("No auth token or user ID found")
        return nil
    }


    if type != "incoming" && type != "outgoing" {
        print("Invalid request type: must be 'incoming' or 'outgoing'")
        return nil
    }

    do {
        struct GetFriendRequestsResponse: Codable {
            let success: Bool
            let requests: [FriendRequest]
            let message: String?
        }

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/friendRequests?type=\(type)",
            method: .get,
            headers: ["Authorization": token]
        )
        .validate()
        .serializingDecodable(GetFriendRequestsResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                return response.requests
            } else {
                print(
                    "Failed to get friend requests: \(response.message ?? "Unknown error")"
                )
                return nil
            }
        case .failure(let error):
            print(
                "Failed to get friend requests: \(error.localizedDescription)")
            return nil
        }
    }
}
