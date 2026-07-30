//
//  OnboardingView.swift
//  Huhgry?
//
//  Self-contained onboarding & account creation flow.
//

import SwiftUI

// MARK: - Models

private enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case createAccount
    case filterPreferences
    case filterPriority
    case completion

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .createAccount: "Create Account"
        case .filterPreferences: "Filters"
        case .filterPriority: "Priorities"
        case .completion: "Done"
        }
    }
}

private enum PasswordField: Hashable {
    case password
    case confirmPassword
}

private enum PersonalizationFilter: String, CaseIterable, Identifiable {
    case price = "Price"
    case ratings = "Ratings"
    case cdc = "CDC"
    case petFriendly = "Pet Friendly"
    case gst = "Inc./Exc. GST"
    case reservationsOnly = "Reservations Only"
    case airConditioning = "AC or not"
    case dietary = "Dietary"
    case repeatPlace = "Repeat place?"
    case friendVisitBefore = "Friend visit before"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .price: "dollarsign.circle"
        case .ratings: "star.fill"
        case .cdc: "creditcard"
        case .petFriendly: "pawprint.fill"
        case .gst: "doc.text"
        case .reservationsOnly: "calendar.badge.clock"
        case .airConditioning: "thermometer.snowflake"
        case .dietary: "leaf"
        case .repeatPlace: "arrow.triangle.2.circlepath"
        case .friendVisitBefore: "person.2.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .price: "Preferred price range"
        case .ratings: "Minimum rating you’ll accept"
        case .cdc: "CDC voucher acceptance"
        case .petFriendly: "Bring pets along?"
        case .gst: "GST display preference"
        case .reservationsOnly: "Booking requirement"
        case .airConditioning: "Air-conditioned seating"
        case .dietary: "Dietary needs"
        case .repeatPlace: "Okay revisiting spots?"
        case .friendVisitBefore: "Prefer places friends have tried"
        }
    }
}

private enum PriceTier: String, CaseIterable, Identifiable {
    case any = "Any"
    case budget = "$"
    case moderate = "$$"
    case upscale = "$$$"
    case fine = "$$$$"

    var id: String { rawValue }
}

private enum PreferenceChoice: String, CaseIterable, Identifiable {
    case noPreference = "No Pref"
    case yes = "Yes"
    case no = "No"

    var id: String { rawValue }
}

private enum GSTPreference: String, CaseIterable, Identifiable {
    case noPreference = "No Pref"
    case inclusive = "Inc. GST"
    case exclusive = "Exc. GST"

    var id: String { rawValue }
}

private enum ACPreference: String, CaseIterable, Identifiable {
    case noPreference = "No Pref"
    case required = "Must have AC"
    case preferAC = "Prefer AC"
    case noAC = "No AC"

    var id: String { rawValue }
}

private enum DietaryOption: String, CaseIterable, Identifiable {
    case any = "Any"
    case halal = "Halal"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case kosher = "Kosher"

    var id: String { rawValue }
}

private struct FilterPreferences {
    var price: PriceTier = .any
    var minimumRating: Double = 3.5
    var cdc: PreferenceChoice = .noPreference
    var petFriendly: PreferenceChoice = .noPreference
    var gst: GSTPreference = .noPreference
    var reservationsOnly: PreferenceChoice = .noPreference
    var airConditioning: ACPreference = .noPreference
    var dietary: Set<DietaryOption> = [.any]
    var repeatPlace: PreferenceChoice = .noPreference
    var friendVisitBefore: PreferenceChoice = .noPreference
}

private struct OnboardingFormData {
    var username = ""
    var password = ""
    var confirmPassword = ""
    var filters = FilterPreferences()
    var filterPriority: [PersonalizationFilter] = PersonalizationFilter.allCases
}

// MARK: - OnboardingView

struct OnboardingView: View {
    var onFinished: (() -> Void)?

    @State private var currentPage: OnboardingPage = .welcome
    @State private var formData = OnboardingFormData()
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var navigationDirection: NavigationDirection = .forward
    @FocusState private var focusedField: PasswordField?

    private enum NavigationDirection {
        case forward, backward
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                if showsHeader {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ZStack {
                    pageContent
                        .id(currentPage)
                        .transition(pageTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.smooth(duration: 0.35), value: currentPage)
            }
        }
        .tint(Color.accentColor)
    }

    private var showsHeader: Bool {
        currentPage != .welcome && currentPage != .completion
    }

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case .welcome:
            welcomePage
        case .createAccount:
            createAccountPage
        case .filterPreferences:
            filterPreferencesPage
        case .filterPriority:
            filterPriorityPage
        case .completion:
            completionPage
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: navigationDirection == .forward ? .leading : .trailing)
                .combined(with: .opacity)
        )
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

    // MARK: Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text(currentPage.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Color.clear
                    .frame(width: 56, height: 1)
            }

            OnboardingProgressBar(
                currentIndex: currentPage.rawValue,
                total: OnboardingPage.allCases.count
            )
        }
    }

    // MARK: Page 1 – Welcome

    private var welcomePage: some View {
        OnboardingPageContainer {
            Spacer(minLength: 24)

            VStack(spacing: 28) {
                logoPlaceholder

                VStack(spacing: 12) {
                    Text("Swipe Right on Your Next Meal")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    Text("Discover restaurants just with a swipe! Match with meals you’ll actually crave.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 24)

            OnboardingPrimaryButton(title: "Get Started", systemImage: "arrow.right") {
                advance(to: .createAccount)
            }
        }
    }

    private var logoPlaceholder: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 300)
            .accessibilityLabel("Huhgry? logo")
    }

    // MARK: Page 2 – Create Account

    private var createAccountPage: some View {
        OnboardingPageContainer {
            pageIntro(
                title: "Create your account",
                subtitle: "Pick a username and password to get started."
            )

            VStack(spacing: 14) {
                OnboardingTextField(
                    title: "Username",
                    text: $formData.username,
                    systemImage: "person",
                    textContentType: .username,
                    autocapitalization: .never
                )

                OnboardingSecureField(
                    title: "Password",
                    text: $formData.password,
                    isVisible: $isPasswordVisible,
                    focusedField: $focusedField,
                    field: .password
                )

                OnboardingSecureField(
                    title: "Confirm Password",
                    text: $formData.confirmPassword,
                    isVisible: $isConfirmPasswordVisible,
                    focusedField: $focusedField,
                    field: .confirmPassword
                )

                if shouldShowPasswordMismatch {
                    Label("Passwords do not match", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 16)

            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: "arrow.right",
                isEnabled: isCreateAccountValid
            ) {
                focusedField = nil
                advance(to: .filterPreferences)
            }
        }
    }

    private var shouldShowPasswordMismatch: Bool {
        !formData.confirmPassword.isEmpty && formData.password != formData.confirmPassword
    }

    private var isCreateAccountValid: Bool {
        !formData.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !formData.password.isEmpty
            && !formData.confirmPassword.isEmpty
            && formData.password == formData.confirmPassword
    }

    // MARK: Page 3 – Filter Preferences

    private var filterPreferencesPage: some View {
        OnboardingPageContainer(pinFooter: true) {
            pageIntro(
                title: "Personalize your filters",
                subtitle: "Set your preferred matrix for each filter. Scroll through and tune anything that matters to you."
            )

            VStack(spacing: 12) {
                ForEach(PersonalizationFilter.allCases) { filter in
                    FilterPreferenceCard(title: filter.rawValue, systemImage: filter.systemImage, subtitle: filter.subtitle) {
                        filterControl(for: filter)
                    }
                }
            }

            OnboardingPrimaryButton(title: "Next", systemImage: "arrow.right") {
                advance(to: .filterPriority)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func filterControl(for filter: PersonalizationFilter) -> some View {
        switch filter {
        case .price:
            SegmentedChips(options: PriceTier.allCases, selection: $formData.filters.price) { $0.rawValue }

        case .ratings:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: "%.1f+", formData.filters.minimumRating))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .monospacedDigit()

                    Spacer()

                    Text("Minimum rating")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Slider(value: $formData.filters.minimumRating, in: 1...5, step: 0.5)
                    .tint(Color.accentColor)
            }

        case .cdc:
            SegmentedChips(options: PreferenceChoice.allCases, selection: $formData.filters.cdc) { $0.rawValue }

        case .petFriendly:
            SegmentedChips(options: PreferenceChoice.allCases, selection: $formData.filters.petFriendly) { $0.rawValue }

        case .gst:
            SegmentedChips(options: GSTPreference.allCases, selection: $formData.filters.gst) { $0.rawValue }

        case .reservationsOnly:
            SegmentedChips(options: PreferenceChoice.allCases, selection: $formData.filters.reservationsOnly) { $0.rawValue }

        case .airConditioning:
            SegmentedChips(options: ACPreference.allCases, selection: $formData.filters.airConditioning) { $0.rawValue }

        case .dietary:
            FlowLayout(spacing: 8) {
                ForEach(DietaryOption.allCases) { option in
                    SelectableChip(
                        title: option.rawValue,
                        isSelected: formData.filters.dietary.contains(option)
                    ) {
                        toggleDietary(option)
                    }
                }
            }

        case .repeatPlace:
            SegmentedChips(options: PreferenceChoice.allCases, selection: $formData.filters.repeatPlace) { $0.rawValue }

        case .friendVisitBefore:
            SegmentedChips(options: PreferenceChoice.allCases, selection: $formData.filters.friendVisitBefore) { $0.rawValue }
        }
    }

    private func toggleDietary(_ option: DietaryOption) {
        if option == .any {
            formData.filters.dietary = [.any]
            return
        }

        formData.filters.dietary.remove(.any)

        if formData.filters.dietary.contains(option) {
            formData.filters.dietary.remove(option)
            if formData.filters.dietary.isEmpty {
                formData.filters.dietary = [.any]
            }
        } else {
            formData.filters.dietary.insert(option)
        }
    }

    // MARK: Page 4 – Filter Priority

    private var filterPriorityPage: some View {
        OnboardingPageContainer(pinFooter: true) {
            pageIntro(
                title: "Rank what matters most",
                subtitle: "Use the arrows to reorder. 1 is most important, \(formData.filterPriority.count) is least."
            )

            VStack(spacing: 0) {
                ForEach(Array(formData.filterPriority.enumerated()), id: \.element.id) { index, filter in
                    PriorityRow(
                        rank: index + 1,
                        title: filter.rawValue,
                        systemImage: filter.systemImage,
                        canMoveUp: index > 0,
                        canMoveDown: index < formData.filterPriority.count - 1,
                        onMoveUp: { movePriority(from: index, by: -1) },
                        onMoveDown: { movePriority(from: index, by: 1) }
                    )

                    if index < formData.filterPriority.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            OnboardingPrimaryButton(title: "Next", systemImage: "arrow.right") {
                advance(to: .completion)
            }
            .padding(.top, 8)
        }
    }

    private func movePriority(from index: Int, by offset: Int) {
        let destination = index + offset
        guard formData.filterPriority.indices.contains(destination) else { return }

        withAnimation(.smooth(duration: 0.25)) {
            formData.filterPriority.swapAt(index, destination)
        }
    }

    // MARK: Page 5 – Completion

    private var completionPage: some View {
        OnboardingPageContainer {
            Spacer(minLength: 24)

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(.green)
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.bounce, value: currentPage)
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("You're all set!")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Your filters and priorities are ready. Start swiping to find your next meal.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 24)

            OnboardingPrimaryButton(title: "Start Exploring", systemImage: "sparkles") {
                onFinished?()
            }
        }
    }

    // MARK: Shared Helpers

    private func pageIntro(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func advance(to page: OnboardingPage) {
        navigationDirection = .forward
        withAnimation(.smooth(duration: 0.35)) {
            currentPage = page
        }
    }

    private func goBack() {
        guard let previous = OnboardingPage(rawValue: currentPage.rawValue - 1) else { return }
        navigationDirection = .backward
        withAnimation(.smooth(duration: 0.35)) {
            currentPage = previous
        }
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        GeometryReader { proxy in
            let progress = total > 1
                ? CGFloat(currentIndex) / CGFloat(total - 1)
                : 1

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(proxy.size.width * progress, 8))
                    .animation(.smooth(duration: 0.35), value: currentIndex)
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(currentIndex + 1) of \(total)")
    }
}

// MARK: - Page Container

private struct OnboardingPageContainer<Content: View>: View {
    var pinFooter: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    content
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .frame(minHeight: pinFooter ? nil : proxy.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Primary Button

private struct OnboardingPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .fontWeight(.semibold)

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .controlSize(.large)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}

// MARK: - Text Field

private struct OnboardingTextField: View {
    let title: String
    @Binding var text: String
    var systemImage: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)

            TextField(title, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Secure Field

private struct OnboardingSecureField: View {
    let title: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var focusedField: FocusState<PasswordField?>.Binding
    let field: PasswordField

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Group {
                if isVisible {
                    TextField(title, text: $text)
                        .keyboardType(.asciiCapable)
                } else {
                    SecureField(title, text: $text)
                }
            }
            // Avoid .newPassword / .password autofill, which can steal focus after the first character.
            .textContentType(.oneTimeCode)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused(focusedField, equals: field)

            Button {
                isVisible.toggle()
                DispatchQueue.main.async {
                    focusedField.wrappedValue = field
                }
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Filter Preference Card

private struct FilterPreferenceCard<Content: View>: View {
    let title: String
    let systemImage: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Segmented Chips

private struct SegmentedChips<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                SelectableChip(
                    title: title(option),
                    isSelected: selection == option
                ) {
                    selection = option
                }
            }
        }
    }
}

// MARK: - Priority Row

private struct PriorityRow: View {
    let rank: Int
    let title: String
    let systemImage: String
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor, in: Circle())

            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)

            Text(title)
                .font(.body.weight(.semibold))

            Spacer()

            VStack(spacing: 2) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.bold))
                }
                .disabled(!canMoveUp)
                .opacity(canMoveUp ? 1 : 0.25)

                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .disabled(!canMoveDown)
                .opacity(canMoveDown ? 1 : 0.25)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Reorder \(title)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Selectable Chip

private struct SelectableChip: View {
    let title: String
    var systemImage: String? = nil
    let isSelected: Bool
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalWidth = max(totalWidth, x - spacing)
            totalHeight = y + rowHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView()
}

#Preview("Onboarding – Dark") {
    OnboardingView()
        .preferredColorScheme(.dark)
}
