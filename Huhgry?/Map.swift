// Map.swift
// Huhgry? Map Interface
import SwiftUI
import MapKit
import Combine

// MARK: - Mock Models & Data
struct LikedPlace: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let confidenceMetric: Int // 0 - 100
    let customTags: [String]
    let groupIDs: [String] // Groups that also liked this place
    let visited: Bool
}

struct FriendGroup: Identifiable, Hashable {
    let id: String
    let name: String
}

class MapViewModel: ObservableObject {
    @Published var allPlaces: [LikedPlace] = [
        LikedPlace(
            name: "Lau Pa Sat Hotpot",
            coordinate: CLLocationCoordinate2D(latitude: 1.2806, longitude: 103.8504),
            confidenceMetric: 94,
            customTags: ["hotpot", "supper"],
            groupIDs: ["group_1", "group_2"],
            visited: true
        ),
        LikedPlace(
            name: "Tiong Bahru Bakery",
            coordinate: CLLocationCoordinate2D(latitude: 1.2848, longitude: 103.8325),
            confidenceMetric: 90,
            customTags: ["pasta", "cafe"],
            groupIDs: ["group_1"],
            visited: false
        ),
        LikedPlace(
            name: "Joo Chiat Cafe",
            coordinate: CLLocationCoordinate2D(latitude: 1.3090, longitude: 103.9015),
            confidenceMetric: 88,
            customTags: ["cafe", "brunch"],
            groupIDs: ["group_2"],
            visited: true
        ),
        LikedPlace(
            name: "Bugis Pasta Bar",
            coordinate: CLLocationCoordinate2D(latitude: 1.3006, longitude: 103.8560),
            confidenceMetric: 95,
            customTags: ["pasta", "date night"],
            groupIDs: ["group_1", "group_2"],
            visited: false
        )
    ]
    @Published var availableGroups: [FriendGroup] = [
        FriendGroup(id: "group_1", name: "Weekend Foodies"),
        FriendGroup(id: "group_2", name: "Late Night Crew")
    ]
    @Published var selectedTags: Set<String> = []
    @Published var selectedGroup: FriendGroup? = nil
    @Published var visitedFilter: Bool? = nil // nil = all, true = visited only, false = locked only

    @Published var isSearchPresented: Bool = false
    @Published var searchQuery: String = ""

    // Mock searchable restaurants; in a real app, replace with Places API
    let allSearchableRestaurants: [LikedPlace] = [
        LikedPlace(name: "Lau Pa Sat Hotpot", coordinate: CLLocationCoordinate2D(latitude: 1.2806, longitude: 103.8504), confidenceMetric: 0, customTags: [], groupIDs: [], visited: false),
        LikedPlace(name: "Tiong Bahru Bakery", coordinate: CLLocationCoordinate2D(latitude: 1.2848, longitude: 103.8325), confidenceMetric: 0, customTags: [], groupIDs: [], visited: false),
        LikedPlace(name: "Joo Chiat Cafe", coordinate: CLLocationCoordinate2D(latitude: 1.3090, longitude: 103.9015), confidenceMetric: 0, customTags: [], groupIDs: [], visited: false),
        LikedPlace(name: "Bugis Pasta Bar", coordinate: CLLocationCoordinate2D(latitude: 1.3006, longitude: 103.8560), confidenceMetric: 0, customTags: [], groupIDs: [], visited: false)
    ]

    var availableTags: [String] {
        Array(Set(allPlaces.flatMap { $0.customTags })).sorted()
    }
    var lockedCount: Int { allPlaces.filter { !$0.visited }.count }
    var totalCount: Int { allPlaces.count }
    
    var filteredPlaces: [LikedPlace] {
        allPlaces.filter { place in
            let tagMatch = selectedTags.isEmpty || selectedTags.isSubset(of: Set(place.customTags))
            let groupMatch = selectedGroup == nil || place.groupIDs.contains(selectedGroup!.id)
            let visitedMatch: Bool = {
                if let vf = visitedFilter { return place.visited == vf }
                return true
            }()
            return tagMatch && groupMatch && visitedMatch
        }
    }

    var searchResults: [LikedPlace] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return allSearchableRestaurants.filter { $0.name.lowercased().contains(q.lowercased()) }
    }

    func addPlacePin(_ place: LikedPlace, visited: Bool) {
        let new = LikedPlace(
            name: place.name,
            coordinate: place.coordinate,
            confidenceMetric: 0,
            customTags: [],
            groupIDs: [],
            visited: visited
        )
        allPlaces.append(new)
    }
    func addTags(_ tags: [String], to placeID: UUID) {
        guard let idx = allPlaces.firstIndex(where: { $0.id == placeID }) else { return }
        let existing = allPlaces[idx]
        let merged = Array(Set(existing.customTags + tags)).sorted()
        allPlaces[idx] = LikedPlace(
            name: existing.name,
            coordinate: existing.coordinate,
            confidenceMetric: existing.confidenceMetric,
            customTags: merged,
            groupIDs: existing.groupIDs,
            visited: existing.visited
        )
    }
}

// MARK: - Main Map View
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        )
    )
    @State private var selectedPlace: LikedPlace? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. Interactive Map View
            Map(position: $position) {
                ForEach(viewModel.filteredPlaces) { place in
                    Annotation("", coordinate: place.coordinate) {
                        ConfidencePinView(confidence: place.confidenceMetric, visited: place.visited)
                            .onTapGesture { selectedPlace = place }
                    }
                }
            }
            .mapControls {
                MapCompass()
                
            }
            .ignoresSafeArea()
            
            // 2. Top Control Overlay (Group & Tag Filter Buttons)
            HStack {
                // Group Menu
                Menu {
                    Group {
                        Button(action: { viewModel.selectedGroup = nil }) {
                            HStack { Text("All Places (Personal)"); if viewModel.selectedGroup == nil { Image(systemName: "checkmark") } }
                        }
                        Divider()
                        ForEach(viewModel.availableGroups) { group in
                            Button(action: { viewModel.selectedGroup = group }) {
                                HStack { Text(group.name); if viewModel.selectedGroup?.id == group.id { Image(systemName: "checkmark") } }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.3.fill")
                        Text(viewModel.selectedGroup?.name ?? "Groups").font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                Spacer()
                // Tag Menu with locked/total counter above
                Menu {
                    Group {
                        Button(action: { viewModel.selectedTags.removeAll(); viewModel.visitedFilter = nil }) {
                            HStack { Text("All Tags"); if viewModel.selectedTags.isEmpty && viewModel.visitedFilter == nil { Image(systemName: "checkmark") } }
                        }
                        Button(action: { viewModel.visitedFilter = false }) {
                            HStack {
                                Text("All Locked")
                                if viewModel.visitedFilter == false { Image(systemName: "checkmark") }
                            }
                        }
                        Button(action: { viewModel.visitedFilter = true }) {
                            HStack {
                                Text("All Unlocked")
                                if viewModel.visitedFilter == true { Image(systemName: "checkmark") }
                            }
                        }
                        Divider()
                        ForEach(viewModel.availableTags, id: \.self) { tag in
                            Button(action: {
                                if viewModel.selectedTags.contains(tag) {
                                    viewModel.selectedTags.remove(tag)
                                } else {
                                    viewModel.selectedTags.insert(tag)
                                }
                            }) {
                                HStack { Text("#\(tag)"); if viewModel.selectedTags.contains(tag) { Image(systemName: "checkmark") } }
                            }
                        }
                    }
                }
                label: {
                    VStack(spacing: 6) {
                        Button(action: { 
                            if viewModel.visitedFilter == false { viewModel.visitedFilter = nil } else { viewModel.visitedFilter = false }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                Text("\(viewModel.lockedCount)/\(viewModel.totalCount)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                            Text(viewModel.selectedTags.isEmpty ? "Tags" : viewModel.selectedTags.map { "#\($0)" }.sorted().joined(separator: ", "))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // 3. Bottom-left Search Button
            VStack {
                Spacer()
                HStack {
                    Button(action: { viewModel.isSearchPresented = true }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .padding(.leading, 16)
                    Spacer()
                }
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailSheet(place: place, onRemove: {
                if let idx = viewModel.allPlaces.firstIndex(where: { $0.id == place.id }) {
                    viewModel.allPlaces.remove(at: idx)
                }
                selectedPlace = nil
            })
            .environmentObject(viewModel)
            .presentationDetents([.fraction(0.5), .large])
        }
        .sheet(isPresented: $viewModel.isSearchPresented) {
            SearchSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Red Confidence Pin View
struct ConfidencePinView: View {
    let confidence: Int
    let visited: Bool
    var body: some View {
        let accent = visited ? Color.blue : Color.gray
        VStack(spacing: 0) {
            // Red Pin Badge with Confidence %
            HStack(spacing: 4) {
                if confidence == 0 {
                    if visited {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    if !visited {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("\(confidence)%")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(accent)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            // Pin Pointer Triangle
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundColor(accent)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }
}

// MARK: - Selected Place Action Sheet
struct PlaceDetailSheet: View {
    let place: LikedPlace
    var onRemove: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(place.name)
                            .font(.title2).bold()
                        if place.confidenceMetric > 0 {
                            Text("\(place.confidenceMetric)% Match")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(place.visited ? Color.blue : Color.gray)
                                .cornerRadius(10)
                        }
                    }
                }
                Spacer()
                Button(role: .destructive) {
                    onRemove?()
                } label: {
                    Text("Remove Pin")
                        .font(.callout.weight(.bold))
                }
            }
            
            QuadrantImageView()
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if place.confidenceMetric == 0 {
                AddTagsInline(place: place)
            }
            
            HStack {
                ForEach(place.customTags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: viewMenu) {
                HStack {
                    Image(systemName: "menucard")
                    Text("View Menu").bold()
                }
                .font(.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(place.visited ? Color.blue : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if place.visited {
                Button(action: viewReceiptHistory) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Receipt History & Review").bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
            }
            
            // Get Directions Button
            Button(action: openInAppleMaps) {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Get Directions").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
        }
        .padding(20)
    }
    
    private func openInAppleMaps() {
        let placemark = MKPlacemark(coordinate: place.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func viewMenu() {
        // TODO: Implement menu viewing action
        print("View Menu tapped for: \(place.name)")
    }

    private func viewReceiptHistory() {
        // TODO: Implement receipt history & review view
        print("Receipt History & Review tapped for: \(place.name)")
    }
}

struct QuadrantImageView: View {
    // Placeholder images; replace with real images when available
    private let images: [String] = ["fork.knife", "takeoutbag.and.cup.and.straw.fill", "cup.and.saucer.fill", "leaf"]
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let halfW = size.width / 2
            let halfH = size.height / 2
            ZStack {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        quadrant(images[0])
                            .frame(width: halfW - 1, height: halfH - 1)
                        quadrant(images[1])
                            .frame(width: halfW - 1, height: halfH - 1)
                    }
                    HStack(spacing: 2) {
                        quadrant(images[2])
                            .frame(width: halfW - 1, height: halfH - 1)
                        quadrant(images[3])
                            .frame(width: halfW - 1, height: halfH - 1)
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func quadrant(_ systemName: String) -> some View {
        ZStack {
            Color.gray.opacity(0.15)
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(12)
                .foregroundStyle(.secondary)
        }
    }
}

struct SearchSheet: View {
    @ObservedObject var viewModel: MapViewModel

    @State private var pendingPlace: LikedPlace? = nil
    @State private var showVisitedPrompt: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search restaurants", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.words)
                }
                .padding(12)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(12)
                .padding([.horizontal, .top])

                // Results
                List {
                    ForEach(viewModel.searchResults) { place in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(place.name)
                                    .font(.body)
                                Text("Lat: \(String(format: "%.4f", place.coordinate.latitude)), Lon: \(String(format: "%.4f", place.coordinate.longitude))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Add Pin") {
                                pendingPlace = place
                                showVisitedPrompt = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .listStyle(.plain)
                .confirmationDialog("Have you visited this place before?", isPresented: $showVisitedPrompt, titleVisibility: .visible) {
                    Button("Yes, I've visited") {
                        if let p = pendingPlace {
                            viewModel.addPlacePin(p, visited: true)
                        }
                        viewModel.isSearchPresented = false
                        viewModel.searchQuery = ""
                        pendingPlace = nil
                    }
                    Button("No, not yet") {
                        if let p = pendingPlace {
                            viewModel.addPlacePin(p, visited: false)
                        }
                        viewModel.isSearchPresented = false
                        viewModel.searchQuery = ""
                        pendingPlace = nil
                    }
                    Button("Cancel", role: .cancel) { pendingPlace = nil }
                }
            }
            .navigationTitle("Add a Place")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { viewModel.isSearchPresented = false } } }
        }
    }
}

struct AddTagsInline: View {
    @EnvironmentObject var viewModel: MapViewModel
    let place: LikedPlace
    @State private var isPresenting: Bool = false
    @State private var input: String = ""

    var body: some View {
        HStack {
            Spacer()
            Button(action: { isPresenting = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "tag.badge.plus")
                    Text("Add Tags").bold()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $isPresenting) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add tags (comma-separated)")
                        .font(.headline)
                    TextField("e.g. spicy, ramen, lunch", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    Spacer()
                }
                .padding()
                .navigationTitle("Add Tags")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresenting = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let tags = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                            viewModel.addTags(tags, to: place.id)
                            isPresenting = false
                            input = ""
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MapView()
}
