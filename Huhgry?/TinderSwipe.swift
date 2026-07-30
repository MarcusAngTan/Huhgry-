//
//  TinderSwipe.swift
//  Huhgry?
//
//  Self-contained Tinder-style restaurant swipe prototype.
//  Open the canvas with #Preview to iterate without touching the rest of the app.
//

import SwiftUI

// MARK: - Model

private struct SwipeRestaurant: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rating: Double
    let reviewCount: Int
    let price: String
    let cuisine: String
    let distance: String
    let openingStatus: String
    let description: String
    let imageColors: [Color]
    let symbolName: String
    let imageNames: [String]?
    let reviews: [String]

    init(
        id: UUID = UUID(),
        name: String,
        rating: Double,
        reviewCount: Int,
        price: String,
        cuisine: String,
        distance: String,
        openingStatus: String,
        description: String,
        imageColors: [Color],
        symbolName: String,
        imageNames: [String]? = nil,
        reviews: [String] = []
    ) {
        self.id = id
        self.name = name
        self.rating = rating
        self.reviewCount = reviewCount
        self.price = price
        self.cuisine = cuisine
        self.distance = distance
        self.openingStatus = openingStatus
        self.description = description
        self.imageColors = imageColors
        self.symbolName = symbolName
        self.imageNames = imageNames
        self.reviews = reviews
    }

    /// Match confidence 0...1 derived from rating for the matrix logo.
    var confidence: Double {
        min(1, max(0, (rating - 3.5) / 1.5))
    }
}

// MARK: - Filters

private struct SwipeFilters {
    var maxDistanceKm: Double = 5
    var parking: Bool = false
    var is24Hour: Bool = false
    var openingNow: Bool = false
    var wheelchairAid: Bool = false

    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    /// Number of currently applied filters (distance counts only when narrowed).
    var activeFilterCount: Int {
        var count = 0
        if maxDistanceKm < 5 { count += 1 }
        if parking { count += 1 }
        if is24Hour { count += 1 }
        if openingNow { count += 1 }
        if wheelchairAid { count += 1 }
        return count
    }

    /// Mock availability: prototype-only estimate that shrinks as more
    /// filters are applied. Not backed by real restaurant data.
    var availableCount: Int {
        let base = 78
        var remaining = Double(base)
        // Each active toggle roughly cuts the pool.
        for _ in 0..<activeFilterCount {
            remaining *= 0.62
        }
        return max(3, Int(remaining.rounded()))
    }
}

// MARK: - Mock Data

private enum MockRestaurants {
    static let all: [SwipeRestaurant] = [
        SwipeRestaurant(
            name: "Sushi House",
            rating: 4.8,
            reviewCount: 342,
            price: "$$",
            cuisine: "Japanese",
            distance: "1.2 km",
            openingStatus: "Open until 10 PM",
            description: "Known for fresh sashimi, handmade sushi and a cosy atmosphere popular with students.",
            imageColors: [
                Color(red: 0.95, green: 0.45, blue: 0.40),
                Color(red: 0.98, green: 0.72, blue: 0.55),
                Color(red: 0.55, green: 0.75, blue: 0.70),
                Color(red: 0.90, green: 0.55, blue: 0.50)
            ],
            symbolName: "fish"
        ),
        SwipeRestaurant(
            name: "Seoul Kitchen",
            rating: 4.6,
            reviewCount: 218,
            price: "$$",
            cuisine: "Korean",
            distance: "0.8 km",
            openingStatus: "Open until 11 PM",
            description: "Sizzling BBQ, bubbling jjigae and late-night comfort food with a lively open kitchen.",
            imageColors: [
                Color(red: 0.85, green: 0.30, blue: 0.25),
                Color(red: 0.95, green: 0.60, blue: 0.30),
                Color(red: 0.70, green: 0.35, blue: 0.30),
                Color(red: 0.90, green: 0.50, blue: 0.40)
            ],
            symbolName: "flame",
            imageNames: ["Image1", "Image2", "Image3", "Image4"],
            reviews:[
                    "Amazing BBQ and super friendly staff!",
                    "The kimchi stew is a must-try.",
                    "Great late-night spot with lively vibes."
                ]
        ),
        SwipeRestaurant(
            name: "Nonna's Table",
            rating: 4.9,
            reviewCount: 511,
            price: "$$$",
            cuisine: "Italian",
            distance: "2.1 km",
            openingStatus: "Open until 9:30 PM",
            description: "Handmade pasta, wood-fired pizza and a warm trattoria vibe perfect for date night.",
            imageColors: [
                Color(red: 0.75, green: 0.55, blue: 0.30),
                Color(red: 0.85, green: 0.35, blue: 0.25),
                Color(red: 0.55, green: 0.65, blue: 0.40),
                Color(red: 0.90, green: 0.70, blue: 0.45)
            ],
            symbolName: "fork.knife",
            imageNames: ["Image5", "Image6", "Image7", "Image8"]
        ),
        SwipeRestaurant(
            name: "Green Bowl",
            rating: 4.5,
            reviewCount: 167,
            price: "$",
            cuisine: "Cafe",
            distance: "0.5 km",
            openingStatus: "Open until 8 PM",
            description: "Bright salads, grain bowls and cold-pressed juices for a quick healthy reset between classes.",
            imageColors: [
                Color(red: 0.40, green: 0.70, blue: 0.45),
                Color(red: 0.55, green: 0.80, blue: 0.55),
                Color(red: 0.90, green: 0.75, blue: 0.35),
                Color(red: 0.35, green: 0.60, blue: 0.50)
            ],
            symbolName: "leaf"
        ),
        SwipeRestaurant(
            name: "Spice Route",
            rating: 4.7,
            reviewCount: 289,
            price: "$$",
            cuisine: "Indian",
            distance: "1.7 km",
            openingStatus: "Open until 10:30 PM",
            description: "Fragrant curries, tandoor-fresh naan and generous thalis that fill the room with aroma.",
            imageColors: [
                Color(red: 0.90, green: 0.50, blue: 0.20),
                Color(red: 0.85, green: 0.25, blue: 0.20),
                Color(red: 0.95, green: 0.70, blue: 0.30),
                Color(red: 0.70, green: 0.40, blue: 0.25)
            ],
            symbolName: "takeoutbag.and.cup.and.straw"
        )
    ]
}

// MARK: - Main Screen

struct TinderSwipe: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case friends = "Friends"
        case explore = "Explore"
        case profile = "Profile"
        case map = "Map"
        
        var id: String { rawValue }
        
        var symbolName: String {
            switch self {
            case .friends: "person.2.fill"
            case .explore: "fork.knife"
            case .profile: "person.fill"
            case .map: "map.fill"
            }
        }
    }
    
    @State private var restaurants: [SwipeRestaurant] = MockRestaurants.all
    @State private var selectedTab: Tab = .explore
    @State private var detailRestaurant: SwipeRestaurant?
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingOut = false
    @State private var reviewsRestaurant: SwipeRestaurant?
    @State private var showFilters = false
    @State private var filters = SwipeFilters()

    private let swipeThreshold: CGFloat = 120
    private let maxVisibleCards = 3
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            background

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .explore:
                        exploreTab
                    case .map:
                        MapView()
                    case .friends:
                        // Social meal streaks — implementation lives in Friend.swift
                        FriendsRootView()
                    case .profile:
                        PlaceholderTab(
                            title: "Profile",
                            systemImage: "person.fill",
                            message: "Your saved prefs & likes — coming soon for the demo."
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomNav
            }

            if selectedTab == .explore {
                if showFilters {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.smooth(duration: 0.25)) {
                                showFilters = false
                            }
                        }
                        .transition(.opacity)
                }

                VStack(alignment: .trailing, spacing: 10) {
                    topBar

                    if showFilters {
                        FilterDropdownPanel(filters: $filters)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top).combined(with: .scale(scale: 0.96, anchor: .topTrailing))),
                                    removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing))
                                )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .zIndex(40)
            }
        }
        .sheet(item: $reviewsRestaurant) { restaurant in
            ReviewsSheet(restaurant: restaurant)
        }
        .sheet(item: $detailRestaurant) { restaurant in
            RestaurantDetailSheet(restaurant: restaurant)
        }
    }

    private var exploreTab: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 52)

            Spacer(minLength: 8)

            cardArea
                .padding(.horizontal, 20)

            Spacer(minLength: 8)
        }
    }

    // MARK: Background

    private var background: some View {
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

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            brandLogo
            Spacer()
            filterMenu
        }
    }

    private var brandLogo: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 90, height: 80)
            .opacity(1.5)
            .accessibilityLabel("Huhgry? logo")
    }

    private var filterMenu: some View {
        Button {
            withAnimation(.smooth(duration: 0.25)) {
                showFilters.toggle()
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title3.weight(.semibold))
                .foregroundStyle(showFilters || filters.hasActiveFilters ? Color.accentColor : .primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(showFilters || filters.hasActiveFilters
                              ? Color.accentColor.opacity(0.15)
                              : Color(.secondarySystemBackground))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            showFilters || filters.hasActiveFilters
                            ? Color.accentColor.opacity(0.35)
                            : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter")
        .accessibilityAddTraits(showFilters ? .isSelected : [])
    }

    // MARK: Card Area

    @ViewBuilder
    private var cardArea: some View {
        if restaurants.isEmpty {
            emptyState
                .frame(maxWidth: .infinity)
                .frame(height: 480)
        } else {
            ZStack {
                ForEach(Array(visibleRestaurants.enumerated()), id: \.element.id) { index, restaurant in
                    let isTop = index == visibleRestaurants.count - 1
                    let depth = visibleRestaurants.count - 1 - index

                    RestaurantCard(restaurant: restaurant)
                        .scaleEffect(isTop ? 1 : 1 - CGFloat(depth) * 0.04)
                        .offset(y: isTop ? 0 : CGFloat(depth) * 12)
                        .opacity(isTop ? 1 : 0.95 - Double(depth) * 0.08)
                        .offset(isTop ? dragOffset : .zero)
                        .rotationEffect(isTop ? .degrees(Double(dragOffset.width) / 20) : .zero)
                        .overlay {
                            if isTop {
                                swipeOverlay
                            }
                        }
                        .zIndex(Double(index))
                        .allowsHitTesting(isTop && !isAnimatingOut)
                        .gesture(isTop ? swipeGesture : nil)
                        .onTapGesture {
                            guard isTop, !isAnimatingOut else { return }
                            detailRestaurant = restaurant
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 480)
        }
    }

    private var visibleRestaurants: [SwipeRestaurant] {
        Array(restaurants.prefix(maxVisibleCards).reversed())
    }

    private var swipeOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.green.opacity(likeOpacity * 0.18))

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.red.opacity(nopeOpacity * 0.18))

            VStack {
                HStack {
                    Text("LIKE")
                        .font(.title.bold())
                        .tracking(2)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.green, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(-12))
                        .opacity(likeOpacity)
                        .padding(20)

                    Spacer()
                }

                Spacer()
            }

            VStack {
                HStack {
                    Spacer()

                    Text("NOPE")
                        .font(.title.bold())
                        .tracking(2)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.red, lineWidth: 3)
                        )
                        .rotationEffect(.degrees(12))
                        .opacity(nopeOpacity)
                        .padding(20)
                }

                Spacer()
            }
        }
        .allowsHitTesting(false)
    }

    private var likeOpacity: Double {
        Double(max(0, min(1, dragOffset.width / swipeThreshold)))
    }

    private var nopeOpacity: Double {
        Double(max(0, min(1, -dragOffset.width / swipeThreshold)))
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimatingOut else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimatingOut else { return }
                let width = value.translation.width
                let height = value.translation.height

                // Horizontal like/nope
                if abs(width) > abs(height) {
                    if width > swipeThreshold {
                        completeSwipe(liked: true)
                        return
                    } else if width < -swipeThreshold {
                        completeSwipe(liked: false)
                        return
                    }
                }

                // Vertical swipe up to show reviews
                let upThreshold: CGFloat = -120 // negative height = upward drag
                if height < upThreshold {
                    if let top = visibleRestaurants.last {
                        // Present a reviews sheet for the top restaurant
                        reviewsRestaurant = top
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        dragOffset = .zero
                    }
                    return
                }

                // Otherwise, snap back
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    dragOffset = .zero
                }
            }
    }

    // MARK: Actions

    private var actionButtons: some View {
        HStack(spacing: 48) {
            Button {
                completeSwipe(liked: false)
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .foregroundStyle(.red)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(.systemBackground)))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    .overlay(Circle().strokeBorder(Color.red.opacity(0.25), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .disabled(restaurants.isEmpty || isAnimatingOut)
            .opacity(restaurants.isEmpty ? 0.4 : 1)
            .accessibilityLabel("Reject")

            Button {
                completeSwipe(liked: true)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.pink)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(.systemBackground)))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    .overlay(Circle().strokeBorder(Color.pink.opacity(0.25), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .disabled(restaurants.isEmpty || isAnimatingOut)
            .opacity(restaurants.isEmpty ? 0.4 : 1)
            .accessibilityLabel("Like")
        }
    }

    private func completeSwipe(liked: Bool) {
        guard !restaurants.isEmpty, !isAnimatingOut else { return }
        isAnimatingOut = true

        let direction: CGFloat = liked ? 1 : -1
        withAnimation(.easeIn(duration: 0.28)) {
            dragOffset = CGSize(width: direction * 700, height: dragOffset.height + 40)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if !restaurants.isEmpty {
                restaurants.removeFirst()
            }
            dragOffset = .zero
            isAnimatingOut = false
        }
    }

    private func resetDeck() {
        withAnimation(.smooth(duration: 0.35)) {
            restaurants = MockRestaurants.all
            dragOffset = .zero
            isAnimatingOut = false
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)

            Text("You're all caught up!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("You've swiped through every restaurant nearby. Start again to keep exploring.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                resetDeck()
            } label: {
                Text("Start Again")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.55))
        )
    }

    // MARK: Bottom Nav

    private var bottomNav: some View {
            HStack {
                ForEach(Tab.allCases) { tab in
                    Button {
                        withAnimation(.smooth(duration: 0.25)) {
                            selectedTab = tab
                            showFilters = false
                        }
                    } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
        )
    }
}

// MARK: - Placeholder Tabs

private struct PlaceholderTab: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Restaurant Card
private struct ReviewsSheet: View {
    let restaurant: SwipeRestaurant
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                let topThree = Array(restaurant.reviews.prefix(3))
                if topThree.isEmpty {
                    Text("No reviews yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(topThree, id: \.self) { review in
                        Text(review)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("\(restaurant.name) Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Filter Dropdown

private struct FilterDropdownPanel: View {
    @Binding var filters: SwipeFilters

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Filters")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text("\(filters.availableCount) available")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color.accentColor.opacity(0.12))
                    )
                    .animation(.smooth(duration: 0.25), value: filters.availableCount)
                    .accessibilityLabel("\(filters.availableCount) restaurants available")
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Distance", systemImage: "location")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(distanceLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText())
                }

                Slider(value: $filters.maxDistanceKm, in: 0.5...10, step: 0.5)
                    .tint(Color.accentColor)
            }

            Divider()
                .opacity(0.5)

            FilterToggleRow(
                title: "Parking",
                systemImage: "parkingsign",
                isOn: $filters.parking
            )

            FilterToggleRow(
                title: "24 hour",
                systemImage: "moon.stars",
                isOn: $filters.is24Hour
            )

            FilterToggleRow(
                title: "Opening Now",
                systemImage: "clock",
                isOn: $filters.openingNow
            )

            FilterToggleRow(
                title: "Wheelchair aid",
                systemImage: "figure.roll",
                isOn: $filters.wheelchairAid
            )
        }
        .padding(16)
        .frame(width: 280, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 1)
        )
    }

    private var distanceLabel: String {
        if filters.maxDistanceKm < 10 {
            return String(format: "%.1f km", filters.maxDistanceKm)
        }
        return "10+ km"
    }
}

private struct FilterToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
    }
}

// MARK: - Confidence Matrix Logo

private struct ConfidenceMatrixLogo: View {
    let confidence: Double

    private let cellSize: CGFloat = 9
    private let spacing: CGFloat = 2

    var body: some View {
        HStack(spacing: 6) {
            matrix
                .accessibilityHidden(true)

            Text(percentLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.accentColor.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence \(percentLabel)")
    }

    private var matrix: some View {
        let filled = filledCellCount
        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                cell(isFilled: filled >= 1)
                cell(isFilled: filled >= 2)
            }
            HStack(spacing: spacing) {
                cell(isFilled: filled >= 3)
                cell(isFilled: filled >= 4)
            }
        }
    }

    private func cell(isFilled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(isFilled ? Color.accentColor : Color.accentColor.opacity(0.18))
            .frame(width: cellSize, height: cellSize)
    }

    private var filledCellCount: Int {
        let clamped = min(1, max(0, confidence))
        return Int((clamped * 4).rounded(.up)).clamped(to: 0...4)
    }

    private var percentLabel: String {
        "\(Int((min(1, max(0, confidence)) * 100).rounded()))%"
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private struct RestaurantCard: View {
    let restaurant: SwipeRestaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let topHeight: CGFloat = 400

            imageGrid
                .frame(height: topHeight)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    Text(restaurant.name)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    ConfidenceMatrixLogo(confidence: restaurant.confidence)
                }

                Text("\(restaurant.price) • \(restaurant.cuisine) • \(restaurant.distance)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(restaurant.openingStatus)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)

                Text(restaurant.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 1)
        )
    }
    
    private var imageGrid: some View {
        let colors = restaurant.imageColors
        let spacing: CGFloat = 2
        
        return GeometryReader { geo in
            // Two rows: height = (totalHeight - spacingBetweenRows) / 2
            let cellHeight = (geo.size.height - spacing) / 2
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: spacing),
                    GridItem(.flexible(), spacing: spacing)
                ],
                spacing: spacing
            ) {
                ForEach(0..<4, id: \.self) { index in
                    ZStack {
                        if let names = restaurant.imageNames, names.indices.contains(index) {
                            Image(names[index])
                                .resizable()
                                .scaledToFill()
                        } else {
                            (colors.indices.contains(index) ? colors[index] : Color.gray)
                                .overlay {
                                    Image(systemName: restaurant.symbolName)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .symbolRenderingMode(.hierarchical)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: cellHeight)
                    .clipped()
                }
            }
        }
        .clipped()
    }
}

// MARK: - Detail Sheet

private struct RestaurantDetailSheet: View {
    let restaurant: SwipeRestaurant
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailImageGrid
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text(restaurant.name)
                            .font(.largeTitle.bold())

                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", restaurant.rating))
                                .font(.headline)
                            Text("• \(restaurant.reviewCount) reviews")
                                .foregroundStyle(.secondary)
                        }

                        Text("\(restaurant.price) • \(restaurant.cuisine) • \(restaurant.distance)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        Label(restaurant.openingStatus, systemImage: "clock")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)

                        Divider()
                            .padding(.vertical, 4)

                        Text("About")
                            .font(.headline)

                        Text(restaurant.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var detailImageGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ],
            spacing: 4
        ) {
            ForEach(0..<4, id: \.self) { index in
                ZStack {
                    if let names = restaurant.imageNames, names.indices.contains(index) {
                        Image(names[index])
                            .resizable()
                            .scaledToFill()
                    } else {
                        (restaurant.imageColors.indices.contains(index)
                         ? restaurant.imageColors[index]
                         : Color.gray)
                        Image(systemName: restaurant.symbolName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 108)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}


#Preview {
    TinderSwipe()
}
