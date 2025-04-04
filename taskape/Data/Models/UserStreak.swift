import Alamofire
import Combine
import Foundation
import SwiftData
import SwiftDotenv

struct UserStreak {
    let currentStreak: Int
    let longestStreak: Int
    let lastCompletedDate: Date?
    let streakStartDate: Date?

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        streakStartDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
        self.streakStartDate = streakStartDate
    }

    var isActive: Bool {
        guard let lastDate = lastCompletedDate else { return false }

        let calendar = Calendar.current
        let now = Date()

        let components = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: lastDate),
            to: calendar.startOfDay(for: now)
        )

        return components.day ?? Int.max <= 1
    }

    var daysSinceLastCompleted: Int? {
        guard let lastDate = lastCompletedDate else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: lastDate),
            to: calendar.startOfDay(for: now)
        )

        return components.day
    }

    var streakDuration: Int? {
        guard let startDate = streakStartDate, let lastDate = lastCompletedDate
        else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: startDate),
            to: calendar.startOfDay(for: lastDate)
        )

        return (components.day ?? 0) + 1
    }

    static func fromResponse(_ response: UserStreakResponse) -> UserStreak {
        let dateFormatter = ISO8601DateFormatter()

        var lastCompletedDate: Date? = nil
        if let dateString = response.last_completed_date {
            lastCompletedDate = dateFormatter.date(from: dateString)
        }

        var streakStartDate: Date? = nil
        if let dateString = response.streak_start_date {
            streakStartDate = dateFormatter.date(from: dateString)
        }

        return UserStreak(
            currentStreak: response.current_streak,
            longestStreak: response.longest_streak,
            lastCompletedDate: lastCompletedDate,
            streakStartDate: streakStartDate
        )
    }
}

func getUserStreak(userId: String) async -> UserStreak? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    do {
        let headers: HTTPHeaders = [
            "Authorization": token,
        ]

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/streak",
            method: .get,
            headers: headers
        )
        .validate().responseString {
            value in print(value)
        }
        .serializingDecodable(UserStreakResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                return UserStreak.fromResponse(response)
            } else {
                print(
                    "failed to fetch user streak: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print("failed to fetch user streak: \(error.localizedDescription)")
            return nil
        }
    }
}
