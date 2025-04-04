import Alamofire
import Foundation
import SwiftData
import SwiftDotenv
import SwiftUI

struct CreateGroupRequest: Codable {
    let creator_id: String
    let group_name: String
    let description: String
    let color: String
    let token: String
}

struct CreateGroupResponse: Codable {
    let success: Bool
    let group_id: String?
    let message: String?
}

struct GetGroupTasksRequest: Codable {
    let requester_id: String
    let token: String
}

struct GetGroupTasksResponse: Codable {
    let success: Bool
    let tasks: [TaskResponse]
    let message: String?
}

struct InviteToGroupRequest: Codable {
    let group_id: String
    let inviter_id: String
    let invitee_id: String
    let token: String
}

struct InviteToGroupResponse: Codable {
    let success: Bool
    let invite_id: String?
    let message: String?
}

struct AcceptGroupInviteRequest: Codable {
    let invite_id: String
    let user_id: String
    let accept: Bool
    let token: String
}

struct AcceptGroupInviteResponse: Codable {
    let success: Bool
    let message: String?
}

struct KickUserFromGroupRequest: Codable {
    let group_id: String
    let admin_id: String
    let user_id: String
    let token: String
}

struct KickUserFromGroupResponse: Codable {
    let success: Bool
    let message: String?
}

struct GroupInvitation: Codable {
    let id: String
    let group_id: String
    let group_name: String
    let inviter_id: String
    let inviter_handle: String
    let created_at: String
}

struct GroupMember: Codable {
    let id: String
    let handle: String
    let profile_picture: String
    let color: String
    let role: String
}

func createGroup(
    creatorId: String, name: String, description: String, color: String
) async -> String? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    let request = CreateGroupRequest(
        creator_id: creatorId,
        group_name: name,
        description: description,
        color: color,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/createGroup",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(CreateGroupResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                return response.group_id
            } else {
                print(
                    "failed to create group: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print("failed to create group: \(error.localizedDescription)")
            return nil
        }
    }
}

func getGroupTasks(groupId: String, requesterId: String) async -> [taskapeTask]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    do {
        let headers: HTTPHeaders = [
            "Authorization": token,
        ]

        var urlComponents = URLComponents(
            string:
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/groups/\(groupId)/tasks"
        )
        urlComponents?.queryItems = [
            URLQueryItem(name: "requester_id", value: requesterId),
        ]

        guard let url = urlComponents?.url else {
            print("invalid url components")
            return nil
        }

        let result = await AF.request(
            url,
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(GetGroupTasksResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                let tasks = response.tasks.map { convertToLocalTask($0) }
                return tasks
            } else {
                print(
                    "failed to fetch group tasks: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print("failed to fetch group tasks: \(error.localizedDescription)")
            return nil
        }
    }
}

func inviteToGroup(groupId: String, inviterId: String, inviteeId: String) async
    -> String?
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    let request = InviteToGroupRequest(
        group_id: groupId,
        inviter_id: inviterId,
        invitee_id: inviteeId,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/inviteToGroup",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(InviteToGroupResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                return response.invite_id
            } else {
                print(
                    "failed to invite user to group: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print(
                "failed to invite user to group: \(error.localizedDescription)")
            return nil
        }
    }
}

func respondToGroupInvite(inviteId: String, userId: String, accept: Bool) async
    -> Bool
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }

    let request = AcceptGroupInviteRequest(
        invite_id: inviteId,
        user_id: userId,
        accept: accept,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/acceptGroupInvite",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(AcceptGroupInviteResponse.self)
        .response

        switch result.result {
        case let .success(response):
            return response.success
        case let .failure(error):
            print(
                "failed to respond to group invite: \(error.localizedDescription)"
            )
            return false
        }
    }
}

func kickUserFromGroup(groupId: String, adminId: String, userId: String) async
    -> Bool
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }

    let request = KickUserFromGroupRequest(
        group_id: groupId,
        admin_id: adminId,
        user_id: userId,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/kickUserFromGroup",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(KickUserFromGroupResponse.self)
        .response

        switch result.result {
        case let .success(response):
            return response.success
        case let .failure(error):
            print(
                "failed to kick user from group: \(error.localizedDescription)")
            return false
        }
    }
}
