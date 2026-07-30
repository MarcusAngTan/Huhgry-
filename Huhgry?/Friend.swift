//
//  Friend.swift
//  Huhgry?
//
//  Social meal-streak feature (hackathon MVP).
//  Mock data only — no backend, camera, or push notifications.
//
//  HOW THIS FILE IS ORGANISED
//  1. Models          — data shapes (user, group, post, comment)
//  2. Streak helpers  — Singapore timezone / day keys / evening window
//  3. FriendsStore    — in-memory “database” + actions the UI calls
//  4. Root + Home     — Friends tab entry, dashboard, search, empty state
//  5. Create Group    — pick mock usernames
//  6. Group Feed      — Setlog-style photo bubbles + streak UI
//  7. Camera + Post   — mock shutter that inserts a sample meal image
//  8. Comments        — local Instagram-like threads
//  9. Previews
//
//  WIRING: In TinderSwipe.swift, the Friends tab shows FriendsRootView().
//

import SwiftUI
import UIKit

// MARK: - Models

/// A person in the Friends feature (mock profile).
struct FriendUser: Identifiable, Hashable {
    let id: String
    var username: String
    var displayName: String
    /// Soft avatar tint so we don’t need real profile photos yet.
    var avatarColor: Color
    var isCurrentUser: Bool = false
}

/// A private streak group (size 2…5). A 1:1 streak is just a group of 2.
/// Named `StreakGroup` (not FriendGroup) because Map.swift already defines a simpler FriendGroup.
struct StreakGroup: Identifiable, Hashable {
    let id: String
    var name: String
    var memberIDs: [String]
    var adminID: String
    var streakCount: Int
    var createdAt: Date
}

/// One meal photo posted into a group.
struct MealPost: Identifiable, Hashable {
    let id: String
    var groupID: String
    var authorID: String
    /// Asset catalog name (e.g. "Image5") — mock “camera” picks these.
    var imageName: String
    var createdAt: Date
}

/// Instagram-style comment. `parentCommentID` is set when this is a reply.
struct MealComment: Identifiable, Hashable {
    let id: String
    var postID: String
    var authorID: String
    var text: String
    var createdAt: Date
    var parentCommentID: String? = nil
}

// MARK: - Streak helpers (Singapore time)

/// All streak math uses Asia/Singapore so the “day” matches the product rules.
enum StreakClock {
    static let singapore = TimeZone(identifier: "Asia/Singapore")!

    /// Calendar locked to SGT — use this whenever you ask “what day is it?”
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = singapore
        return cal
    }

    /// Stable string like "2026-07-28" for comparing “did they post today?”
    static func dayKey(for date: Date = Date()) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// True during the 6–8pm SGT anxiety / reminder window.
    static func isEveningWindow(now: Date = Date(), forceEvening: Bool = false) -> Bool {
        if forceEvening { return true }
        let hour = calendar.component(.hour, from: now)
        return hour >= 18 && hour < 20
    }

    /// Seconds until midnight SGT (used for the countdown label).
    static func secondsUntilMidnight(from now: Date = Date()) -> TimeInterval {
        let startOfDay = calendar.startOfDay(for: now)
        guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }
        return max(0, nextMidnight.timeIntervalSince(now))
    }

    static func countdownLabel(from now: Date = Date()) -> String {
        let total = Int(secondsUntilMidnight(from: now))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - FriendsStore (mock backend)

/// In-memory store shared by the Friends UI.
/// `@Observable` means SwiftUI views refresh automatically when properties change.
@Observable
final class FriendsStore {
    // Product caps (premium unlimited comes later).
    static let maxGroupsPerUser = 3
    static let maxMembersPerGroup = 5

    /// Sample meal images already in Assets.xcassets.
    static let sampleMealImages = [
        "Image1", "Image2", "Image3", "Image4",
        "Image5", "Image6", "Image7", "Image8"
    ]

    var users: [FriendUser]
    var groups: [StreakGroup]
    var posts: [MealPost]
    var comments: [MealComment]

    /// Hackathon demo: pretend it is 6–8pm SGT so the countdown is visible anytime.
    var forceEveningDemo = false

    /// Hackathon demo: show a one-line in-app “nudge” banner.
    var showEveningBanner = false

    var currentUserID: String { users.first(where: { $0.isCurrentUser })?.id ?? "you" }

    var currentUser: FriendUser {
        users.first(where: { $0.isCurrentUser })
            ?? FriendUser(id: "you", username: "you", displayName: "You", avatarColor: .orange, isCurrentUser: true)
    }

    // MARK: Init + seed data

    init() {
        // Soft brand-adjacent colors (warm food tones, not purple defaults).
        let you = FriendUser(id: "you", username: "you", displayName: "You", avatarColor: Color(red: 0.90, green: 0.45, blue: 0.25), isCurrentUser: true)
        let maya = FriendUser(id: "maya", username: "maya.eats", displayName: "Maya", avatarColor: Color(red: 0.85, green: 0.35, blue: 0.30))
        let ken = FriendUser(id: "ken", username: "ken.bites", displayName: "Ken", avatarColor: Color(red: 0.40, green: 0.65, blue: 0.45))
        let rina = FriendUser(id: "rina", username: "rina.nom", displayName: "Rina", avatarColor: Color(red: 0.95, green: 0.65, blue: 0.35))
        let jay = FriendUser(id: "jay", username: "jay.crumbs", displayName: "Jay", avatarColor: Color(red: 0.55, green: 0.45, blue: 0.35))

        self.users = [you, maya, ken, rina, jay]

        let now = Date()
        // 1:1 group — both already posted today (happy demo).
        let duo = StreakGroup(
            id: "g-duo",
            name: "Maya & You",
            memberIDs: [you.id, maya.id],
            adminID: you.id,
            streakCount: 12,
            createdAt: now.addingTimeInterval(-86400 * 12)
        )
        // Larger group — Ken has NOT posted yet (anxiety / “who’s left”).
        let crew = StreakGroup(
            id: "g-crew",
            name: "Lunch Crew",
            memberIDs: [you.id, ken.id, rina.id, jay.id],
            adminID: you.id,
            streakCount: 7,
            createdAt: now.addingTimeInterval(-86400 * 7)
        )

        self.groups = [duo, crew]

        // Posts: today for duo (both); crew missing Ken.
        self.posts = [
            // Duo: Maya posted; You have NOT — post to save the 12-day streak.
            MealPost(id: "p1", groupID: duo.id, authorID: maya.id, imageName: "Image5", createdAt: now.addingTimeInterval(-3600 * 3)),
            // Crew: everyone except You posted — you’re the only one left (anxiety demo).
            MealPost(id: "p3", groupID: crew.id, authorID: rina.id, imageName: "Image6", createdAt: now.addingTimeInterval(-3600 * 4)),
            MealPost(id: "p4", groupID: crew.id, authorID: jay.id, imageName: "Image3", createdAt: now.addingTimeInterval(-3600 * 2)),
            MealPost(id: "p5", groupID: crew.id, authorID: ken.id, imageName: "Image4", createdAt: now.addingTimeInterval(-3600)),
            // Yesterday’s post so the chat isn’t empty of history
            MealPost(id: "p6", groupID: duo.id, authorID: you.id, imageName: "Image2", createdAt: now.addingTimeInterval(-86400 - 7200)),
            MealPost(id: "p7", groupID: crew.id, authorID: you.id, imageName: "Image7", createdAt: now.addingTimeInterval(-86400 - 3600))
        ]

        self.comments = [
            MealComment(id: "c1", postID: "p1", authorID: you.id, text: "That looks CRAZY 🔥", createdAt: now.addingTimeInterval(-3500)),
            MealComment(id: "c2", postID: "p1", authorID: maya.id, text: "of course la", createdAt: now.addingTimeInterval(-3400), parentCommentID: "c1"),
            MealComment(id: "c3", postID: "p3", authorID: jay.id, text: "Where is this??", createdAt: now.addingTimeInterval(-3000))
        ]
    }

    // MARK: Lookups

    func user(id: String) -> FriendUser? {
        users.first { $0.id == id }
    }

    func group(id: String) -> StreakGroup? {
        groups.first { $0.id == id }
    }

    func groupsForCurrentUser() -> [StreakGroup] {
        groups.filter { $0.memberIDs.contains(currentUserID) }
    }

    func posts(for groupID: String) -> [MealPost] {
        posts
            .filter { $0.groupID == groupID }
            .sorted { $0.createdAt < $1.createdAt } // chat order: oldest → newest
    }

    func comments(for postID: String) -> [MealComment] {
        comments
            .filter { $0.postID == postID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func searchUsers(query: String) -> [FriendUser] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return users.filter { !$0.isCurrentUser } }
        return users.filter {
            !$0.isCurrentUser &&
            ($0.username.lowercased().contains(q) || $0.displayName.lowercased().contains(q))
        }
    }

    /// Users you can still add when creating a group.
    func availableMembersForNewGroup() -> [FriendUser] {
        users.filter { !$0.isCurrentUser }
    }

    // MARK: Streak status

    func hasPostedToday(userID: String, in groupID: String, on day: String = StreakClock.dayKey()) -> Bool {
        posts.contains { post in
            post.groupID == groupID
                && post.authorID == userID
                && StreakClock.dayKey(for: post.createdAt) == day
        }
    }

    func membersWhoPostedToday(in group: StreakGroup) -> [FriendUser] {
        group.memberIDs.compactMap { user(id: $0) }.filter { hasPostedToday(userID: $0.id, in: group.id) }
    }

    func membersWhoHaveNotPostedToday(in group: StreakGroup) -> [FriendUser] {
        group.memberIDs.compactMap { user(id: $0) }.filter { !hasPostedToday(userID: $0.id, in: group.id) }
    }

    func currentUserHasPostedToday(in groupID: String) -> Bool {
        hasPostedToday(userID: currentUserID, in: groupID)
    }

    /// Dog beside a bubble: happy if that author already posted today in this group.
    func dogIsHappy(for authorID: String, in groupID: String) -> Bool {
        hasPostedToday(userID: authorID, in: groupID)
    }

    /// True when every member has posted today (group streak is safe).
    func groupStreakSatisfiedToday(_ group: StreakGroup) -> Bool {
        membersWhoHaveNotPostedToday(in: group).isEmpty
    }

    // MARK: Actions

    @discardableResult
    func createGroup(name: String, memberIDs: [String]) -> StreakGroup? {
        // Enforce free-tier caps in the UI + here.
        guard groupsForCurrentUser().count < Self.maxGroupsPerUser else { return nil }

        var members = Array(Set(memberIDs + [currentUserID]))
        guard members.count >= 2, members.count <= Self.maxMembersPerGroup else { return nil }

        let group = StreakGroup(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "New Group"
                : name.trimmingCharacters(in: .whitespacesAndNewlines),
            memberIDs: members,
            adminID: currentUserID,
            streakCount: 0,
            createdAt: Date()
        )
        groups.insert(group, at: 0)
        return group
    }

    /// Post a meal into one group, or broadcast the same photo to every group you’re in.
    func postMeal(imageName: String, toGroupIDs groupIDs: [String]) {
        let uniqueIDs = Array(Set(groupIDs))
        let now = Date()
        var triggeredNearMiss = false

        for gid in uniqueIDs {
            guard let index = groups.firstIndex(where: { $0.id == gid }) else { continue }
            let alreadyPosted = hasPostedToday(userID: currentUserID, in: gid)
            // Snapshot who still needs to post *before* we add yours.
            let waitingBefore = membersWhoHaveNotPostedToday(in: groups[index]).map(\.id)

            let post = MealPost(
                id: UUID().uuidString,
                groupID: gid,
                authorID: currentUserID,
                imageName: imageName,
                createdAt: now
            )
            posts.append(post)

            // First post today + you were last one out → bump streak.
            if !alreadyPosted, waitingBefore.contains(currentUserID) {
                let stillWaiting = membersWhoHaveNotPostedToday(in: groups[index])
                if stillWaiting.isEmpty {
                    groups[index].streakCount += 1
                    if StreakClock.isEveningWindow(forceEvening: forceEveningDemo) {
                        triggeredNearMiss = true
                    }
                }
            }
        }

        if triggeredNearMiss {
            showEveningBanner = true
        }
    }

    func addComment(postID: String, text: String, parentCommentID: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let comment = MealComment(
            id: UUID().uuidString,
            postID: postID,
            authorID: currentUserID,
            text: trimmed,
            createdAt: Date(),
            parentCommentID: parentCommentID
        )
        comments.append(comment)
    }

    func leaveGroup(_ groupID: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        var group = groups[index]
        group.memberIDs.removeAll { $0 == currentUserID }
        if group.memberIDs.isEmpty {
            groups.remove(at: index)
            posts.removeAll { $0.groupID == groupID }
        } else {
            if group.adminID == currentUserID, let newAdmin = group.memberIDs.first {
                group.adminID = newAdmin
            }
            groups[index] = group
        }
    }

    func kickMember(userID: String, from groupID: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        var group = groups[index]
        guard group.adminID == currentUserID, userID != currentUserID else { return }
        group.memberIDs.removeAll { $0 == userID }
        groups[index] = group
    }

    /// Demo helper: reset a group streak to 0 (pitch “someone missed a day”).
    func demoResetStreak(for groupID: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[index].streakCount = 0
    }
}

// MARK: - Root (Friends tab entry)

/// Swap this in for the Friends placeholder in `TinderSwipe`.
struct FriendsRootView: View {
    @State private var store = FriendsStore()

    var body: some View {
        NavigationStack {
            FriendsHomeView()
        }
        .environment(store)
    }
}

// MARK: - Home

struct FriendsHomeView: View {
    @Environment(FriendsStore.self) private var store
    @State private var searchText = ""
    @State private var showCreateGroup = false
    @State private var showCamera = false
    @State private var cameraTargetGroupID: String? = nil

    private var myGroups: [StreakGroup] { store.groupsForCurrentUser() }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            friendsBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    searchField

                    if store.showEveningBanner || (store.forceEveningDemo && needsAnyPostToday) {
                        eveningBanner
                    }

                    if myGroups.isEmpty {
                        FriendsEmptyStateView { showCreateGroup = true }
                    } else {
                        // Streaks + groups are one list: streak count + dog live on each row.
                        groupsSection
                    }

                    if !searchText.isEmpty {
                        profileResults
                    }

                    Spacer(minLength: 88)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            floatingCameraButton
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        store.forceEveningDemo.toggle()
                        if store.forceEveningDemo { store.showEveningBanner = true }
                    } label: {
                        Label(
                            store.forceEveningDemo ? "Demo evening: ON" : "Demo evening: OFF",
                            systemImage: "moon.stars"
                        )
                    }
                    Button("Create group") { showCreateGroup = true }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
                .environment(store)
        }
        .sheet(isPresented: $showCamera) {
            MockCameraView(defaultGroupID: cameraTargetGroupID)
                .environment(store)
        }
    }

    private var needsAnyPostToday: Bool {
        myGroups.contains { !store.currentUserHasPostedToday(in: $0.id) }
    }

    // MARK: Home sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Keep the streak alive!")
                .font(.title3.weight(.bold))
            Text("Post one meal photo a day with your groups.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search usernames", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var eveningBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("Dinner window — don’t break it")
                    .font(.subheadline.weight(.semibold))
                Text("Streak ends in \(StreakClock.countdownLabel()). Someone’s waiting on you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button("OK") { store.showEveningBanner = false }
                .font(.caption.weight(.semibold))
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your groups")
                    .font(.headline)
                Spacer()
                Button {
                    showCreateGroup = true
                } label: {
                    Label("New", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
                .disabled(myGroups.count >= FriendsStore.maxGroupsPerUser)
            }

            ForEach(myGroups) { group in
                NavigationLink(value: group.id) {
                    GroupRowView(group: group)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: String.self) { groupID in
            if store.group(id: groupID) != nil {
                GroupFeedView(groupID: groupID)
            }
        }
    }

    private var profileResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profiles")
                .font(.headline)
            ForEach(store.searchUsers(query: searchText)) { user in
                HStack(spacing: 12) {
                    AvatarView(user: user, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text("@\(user.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var floatingCameraButton: some View {
        Button {
            cameraTargetGroupID = nil
            showCamera = true
        } label: {
            Image(systemName: "camera.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Post a meal photo")
    }
}

// MARK: - Empty state

struct FriendsEmptyStateView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)
            Text("No groups yet")
                .font(.title3.weight(.bold))
            Text("Create a group (or a duo) to start a meal streak.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onCreate) {
                Text("Create a group")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Group row (streak count + dog status baked in)

struct GroupRowView: View {
    @Environment(FriendsStore.self) private var store
    let group: StreakGroup

    /// Happy dog once *you* have posted today; sad until then.
    private var hasPostedToday: Bool {
        store.currentUserHasPostedToday(in: group.id)
    }

    private var waiting: [FriendUser] {
        store.membersWhoHaveNotPostedToday(in: group)
    }

    private var showCountdown: Bool {
        StreakClock.isEveningWindow(forceEvening: store.forceEveningDemo) && !hasPostedToday
    }

    var body: some View {
        HStack(spacing: 12) {
            // Streak number replaces the old person SF Symbol.
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text("\(group.streakCount)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText())
            }
            .accessibilityLabel("\(group.streakCount)-day streak")

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if waiting.isEmpty {
                    Text("\(group.memberIDs.count) members · everyone posted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Waiting on \(waiting.map(\.displayName).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if showCountdown {
                    Text("Ends in \(StreakClock.countdownLabel())")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer(minLength: 0)

            // Dog replaces the old gray status dot.
            Image(hasPostedToday ? "happy dog" : "sad dog")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .accessibilityLabel(hasPostedToday ? "Happy dog — you posted today" : "Sad dog — post to keep the streak")

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Create Group

struct CreateGroupView: View {
    @Environment(FriendsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIDs: Set<String> = []
    @State private var errorMessage: String?

    /// You + selected friends cannot exceed max members.
    private var maxSelectable: Int { FriendsStore.maxMembersPerGroup - 1 }

    var body: some View {
        NavigationStack {
            List {
                Section("Group name") {
                    TextField("e.g. Late Night Makan", text: $name)
                }

                Section {
                    ForEach(store.availableMembersForNewGroup()) { user in
                        Button {
                            toggle(user.id)
                        } label: {
                            HStack {
                                AvatarView(user: user, size: 32)
                                VStack(alignment: .leading) {
                                    Text(user.displayName)
                                        .foregroundStyle(.primary)
                                    Text("@\(user.username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedIDs.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIDs.contains(user.id) ? Color.accentColor : .secondary)
                            }
                        }
                    }
                } header: {
                    Text("Pick friends (\(selectedIDs.count)/\(maxSelectable))")
                } footer: {
                    Text("1:1 streaks are just a group of 2. Max \(FriendsStore.maxMembersPerGroup) people. You can join up to \(FriendsStore.maxGroupsPerUser) groups.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("New group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else if selectedIDs.count < maxSelectable {
            selectedIDs.insert(id)
        }
    }

    private func create() {
        if store.groupsForCurrentUser().count >= FriendsStore.maxGroupsPerUser {
            errorMessage = "Free plan: max \(FriendsStore.maxGroupsPerUser) groups."
            return
        }
        guard let _ = store.createGroup(name: name, memberIDs: Array(selectedIDs)) else {
            errorMessage = "Couldn’t create group. Check member count."
            return
        }
        dismiss()
    }
}

// MARK: - Group Feed (Setlog-style photo bubbles)

struct GroupFeedView: View {
    @Environment(FriendsStore.self) private var store
    let groupID: String

    @State private var showCamera = false
    @State private var selectedPost: MealPost?
    @State private var showInfo = false
    @State private var celebrateStreak = false
    @State private var lastSeenStreak: Int?

    private var group: StreakGroup? { store.group(id: groupID) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            friendsBackground

            if let group {
                VStack(spacing: 0) {
                    StreakHeaderView(group: group)
                    PostedStatusBar(group: group)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(store.posts(for: groupID)) { post in
                                    PhotoBubbleView(post: post, groupID: groupID) {
                                        selectedPost = post
                                    }
                                    .id(post.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .padding(.bottom, 88)
                        }
                        .onChange(of: store.posts.count) { _, _ in
                            if let last = store.posts(for: groupID).last {
                                withAnimation(.smooth(duration: 0.35)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: group.streakCount) { oldValue, newValue in
                            if newValue > (lastSeenStreak ?? oldValue) {
                                celebrateStreak = true
                            }
                            lastSeenStreak = newValue
                        }
                        .onAppear {
                            lastSeenStreak = group.streakCount
                        }
                    }
                }

                Button {
                    showCamera = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(Color.accentColor, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            } else {
                Text("Group not found")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(group?.name ?? "Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showInfo = true } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            MockCameraView(defaultGroupID: groupID)
                .environment(store)
        }
        .sheet(item: $selectedPost) { post in
            CommentsView(post: post)
                .environment(store)
        }
        .sheet(isPresented: $showInfo) {
            if let group {
                GroupInfoView(group: group)
                    .environment(store)
            }
        }
        .overlay {
            if celebrateStreak {
                StreakCelebrationOverlay(streak: group?.streakCount ?? 0) {
                    celebrateStreak = false
                }
            }
        }
    }
}

// MARK: - Streak header + status

struct StreakHeaderView: View {
    @Environment(FriendsStore.self) private var store
    let group: StreakGroup

    var body: some View {
        let userMissing = !store.currentUserHasPostedToday(in: group.id)
        let showCountdown = StreakClock.isEveningWindow(forceEvening: store.forceEveningDemo) && userMissing

        HStack {
            Label("\(group.streakCount)-day streak", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .contentTransition(.numericText())

            Spacer()

            if showCountdown {
                Text("Ends in \(StreakClock.countdownLabel())")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

struct PostedStatusBar: View {
    @Environment(FriendsStore.self) private var store
    let group: StreakGroup

    var body: some View {
        let posted = store.membersWhoPostedToday(in: group)
        let waiting = store.membersWhoHaveNotPostedToday(in: group)

        VStack(alignment: .leading, spacing: 8) {
            if waiting.isEmpty {
                Text("Everyone’s in for today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            } else {
                Text(waiting.count == 1
                      ? "\(waiting[0].displayName) is the only one left"
                      : "Still waiting: \(waiting.map(\.displayName).joined(separator: ", "))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(group.memberIDs, id: \.self) { id in
                        if let user = store.user(id: id) {
                            let done = posted.contains(where: { $0.id == id })
                            VStack(spacing: 4) {
                                AvatarView(user: user, size: 34)
                                    .overlay {
                                        Circle()
                                            .stroke(done ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                                    }
                                Text(done ? "✓" : "…")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(done ? Color.accentColor : .secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground).opacity(0.45))
    }
}

// MARK: - Photo bubble

struct PhotoBubbleView: View {
    @Environment(FriendsStore.self) private var store
    let post: MealPost
    let groupID: String
    var onTapComments: () -> Void

    private var author: FriendUser? { store.user(id: post.authorID) }
    private var isMine: Bool { post.authorID == store.currentUserID }
    private var happy: Bool { store.dogIsHappy(for: post.authorID, in: groupID) }
    private var commentCount: Int { store.comments(for: post.id).count }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isMine {
                AvatarView(user: author, size: 28)
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 6) {
                if let author, !isMine {
                    Text(author.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                // Photo “bubble” — rounded chat media, Setlog-inspired.
                Button(action: onTapComments) {
                    mealImage
                        .frame(width: 210, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Text(post.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Button(action: onTapComments) {
                        Label("\(commentCount)", systemImage: "bubble.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Small dog to the right of each bubble (mood = posted today?).
            Image(happy ? "happy dog" : "sad dog")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityLabel(happy ? "Happy dog — posted today" : "Sad dog — not posted today")

            if isMine {
                AvatarView(user: author, size: 28)
            } else {
                Spacer(minLength: 8)
            }
        }
    }

    @ViewBuilder
    private var mealImage: some View {
        // Falls back to a gradient if an asset name is missing.
        if UIImage(named: post.imageName) != nil {
            Image(post.imageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.35),
                        Color.orange.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "fork.knife")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}

// MARK: - Mock camera

struct MockCameraView: View {
    @Environment(FriendsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// When opened from a group, default to that group; nil = pick / broadcast from home.
    var defaultGroupID: String?

    @State private var capturedImageName: String?
    @State private var broadcastAll = false
    @State private var flash = false

    private var myGroupIDs: [String] { store.groupsForCurrentUser().map(\.id) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)

                    if let capturedImageName, UIImage(named: capturedImageName) != nil {
                        Image(capturedImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    } else if capturedImageName != nil {
                        placeholderPreview
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.85))
                            Text("Mock camera — always works in Simulator")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    if flash {
                        Color.white.opacity(0.7)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .frame(height: 360)
                    }
                }
                .padding(.horizontal, 20)

                if capturedImageName == nil {
                    Button(action: mockShutter) {
                        Circle()
                            .strokeBorder(.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                            .overlay(Circle().fill(.white).frame(width: 58, height: 58))
                    }
                    .accessibilityLabel("Take photo")
                } else {
                    VStack(spacing: 14) {
                        if defaultGroupID == nil || myGroupIDs.count > 1 {
                            Toggle("Post to all my groups", isOn: $broadcastAll)
                                .padding(.horizontal, 24)
                        }

                        HStack(spacing: 12) {
                            Button("Retake") {
                                capturedImageName = nil
                            }
                            .buttonStyle(.bordered)

                            Button("Post") {
                                post()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.accentColor)
                        }
                    }
                }

                Spacer()
            }
            .padding(.top, 12)
            .background(friendsBackground)
            .navigationTitle("Post a meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var placeholderPreview: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor, Color.orange.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white)
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func mockShutter() {
        // Brief white flash, then drop in a random sample asset.
        withAnimation(.easeOut(duration: 0.08)) { flash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeIn(duration: 0.15)) { flash = false }
            capturedImageName = FriendsStore.sampleMealImages.randomElement() ?? "Image1"
        }
    }

    private func post() {
        guard let capturedImageName else { return }
        let targets: [String]
        if broadcastAll {
            targets = myGroupIDs
        } else if let defaultGroupID {
            targets = [defaultGroupID]
        } else {
            targets = myGroupIDs // from home with no toggle → all groups
        }
        guard !targets.isEmpty else { return }
        store.postMeal(imageName: capturedImageName, toGroupIDs: targets)
        dismiss()
    }
}

// MARK: - Comments

struct CommentsView: View {
    @Environment(FriendsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let post: MealPost

    @State private var draft = ""
    @State private var replyTo: MealComment?

    private var thread: [MealComment] { store.comments(for: post.id) }
    private var roots: [MealComment] { thread.filter { $0.parentCommentID == nil } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Post preview at top
                if UIImage(named: post.imageName) != nil {
                    Image(post.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                }

                List {
                    if roots.isEmpty {
                        Text("No comments yet — say something nice.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(roots) { comment in
                            CommentRow(comment: comment, depth: 0) {
                                replyTo = comment
                            }
                            ForEach(replies(to: comment.id)) { reply in
                                CommentRow(comment: reply, depth: 1) {
                                    replyTo = reply
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)

                dividerComposer
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func replies(to parentID: String) -> [MealComment] {
        thread.filter { $0.parentCommentID == parentID }
    }

    private var dividerComposer: some View {
        VStack(spacing: 8) {
            if let replyTo, let user = store.user(id: replyTo.authorID) {
                HStack {
                    Text("Replying to \(user.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Cancel") { self.replyTo = nil }
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 10) {
                TextField(replyTo == nil ? "Add a comment…" : "Write a reply…", text: $draft)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    store.addComment(postID: post.id, text: draft, parentCommentID: replyTo?.id)
                    draft = ""
                    replyTo = nil
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }
}

struct CommentRow: View {
    @Environment(FriendsStore.self) private var store
    let comment: MealComment
    let depth: Int
    var onReply: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if depth > 0 {
                Color.clear.frame(width: 18)
            }
            AvatarView(user: store.user(id: comment.authorID), size: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(store.user(id: comment.authorID)?.displayName ?? "User")
                        .font(.caption.weight(.semibold))
                    Text(comment.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(comment.text)
                    .font(.subheadline)
                Button("Reply", action: onReply)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Group info (leave / kick — light)

struct GroupInfoView: View {
    @Environment(FriendsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let group: StreakGroup

    var body: some View {
        NavigationStack {
            List {
                Section("Members") {
                    ForEach(group.memberIDs, id: \.self) { id in
                        if let user = store.user(id: id) {
                            HStack {
                                AvatarView(user: user, size: 32)
                                VStack(alignment: .leading) {
                                    Text(user.displayName)
                                    Text(id == group.adminID ? "Admin" : "@\(user.username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if group.adminID == store.currentUserID && !user.isCurrentUser {
                                    Button("Kick", role: .destructive) {
                                        store.kickMember(userID: user.id, from: group.id)
                                    }
                                    .font(.caption.weight(.semibold))
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Leave group", role: .destructive) {
                        store.leaveGroup(group.id)
                        dismiss()
                    }
                    Button("Demo: reset streak to 0") {
                        store.demoResetStreak(for: group.id)
                    }
                }
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Celebration overlay

struct StreakCelebrationOverlay: View {
    let streak: Int
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 12) {
                Image("happy dog")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                Text("Streak saved!")
                    .font(.title3.weight(.bold))
                Text("You’re on a \(streak)-day run.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Nice", action: onDismiss)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

// MARK: - Shared chrome

struct AvatarView: View {
    let user: FriendUser?
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill((user?.avatarColor ?? .gray).opacity(0.85))
            Text(initials)
                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(user?.displayName ?? "User")
    }

    private var initials: String {
        let name = user?.displayName ?? "?"
        return String(name.prefix(1)).uppercased()
    }
}

/// Matches the soft accent wash used on Explore.
private var friendsBackground: some View {
    LinearGradient(
        colors: [
            Color(.systemBackground),
            Color.accentColor.opacity(0.08),
            Color(.systemBackground)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
}

// MARK: - Previews

#Preview("Friends Home") {
    FriendsRootView()
}

#Preview("Group Feed") {
    NavigationStack {
        GroupFeedView(groupID: "g-crew")
    }
    .environment(FriendsStore())
}

#Preview("Create Group") {
    CreateGroupView()
        .environment(FriendsStore())
}
