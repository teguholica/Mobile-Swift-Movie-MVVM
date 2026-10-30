//
//  PersonView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct PersonView: View {
    @State private var viewModel: PersonViewModel
    @State private var isBiographyExpanded = false
    @State private var fullBiographyHeight: CGFloat = 0
    @State private var limitedBiographyHeight: CGFloat = 0
    private let fallbackName: String
    private let fallbackProfilePath: String?

    public init(
        personId: Int,
        name: String,
        profilePath: String? = nil,
        viewModel: PersonViewModel? = nil
    ) {
        if let viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            let repository = MovieRepositoryImpl.shared
            let useCase = GetPersonProfileUseCase(repository: repository)
            _viewModel = State(
                initialValue: PersonViewModel(
                    personId: personId,
                    getPersonProfileUseCase: useCase
                )
            )
        }
        self.fallbackName = name
        self.fallbackProfilePath = profilePath
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                sectionPicker

                switch viewModel.state {
                case .loading:
                    LoadingView(message: "Loading person...")
                        .frame(maxWidth: .infinity, minHeight: 240)
                case .error(let message):
                    ErrorView(message: message) {
                        Task {
                            await viewModel.fetchProfile()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                case .loaded(let profile):
                    loadedContent(profile)
                }
            }
            .padding(.bottom, 40)
        }
        .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchProfile()
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            profileImage(viewModel.profile?.profilePath ?? fallbackProfilePath)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
                    .lineLimit(2)

                if let department = viewModel.profile?.knownForDepartment, !department.isEmpty {
                    Text(department)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CinemaTokens.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var sectionPicker: some View {
        Picker("Section", selection: $viewModel.selectedTab) {
            ForEach(PersonViewModel.Tab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .accessibilityLabel("Person sections")
    }

    @ViewBuilder
    private func loadedContent(_ profile: PersonProfile) -> some View {
        switch viewModel.selectedTab {
        case .info:
            infoContent(profile)
        case .film:
            filmContent(profile)
        }
    }

    @ViewBuilder
    private func infoContent(_ profile: PersonProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let birthday = PersonDateFormatting.mediumDate(from: profile.birthday) {
                infoRow(
                    label: "Born",
                    value: datedValue(
                        birthday,
                        age: PersonDateFormatting.age(from: profile.birthday)
                    )
                )
            }

            if let deathday = PersonDateFormatting.mediumDate(from: profile.deathday) {
                infoRow(
                    label: "Died",
                    value: datedValue(
                        deathday,
                        age: PersonDateFormatting.ageAtDeath(
                            birthday: profile.birthday,
                            deathday: profile.deathday
                        )
                    )
                )
            }

            if let placeOfBirth = profile.placeOfBirth, !placeOfBirth.isEmpty {
                infoRow(label: "Birthplace", value: placeOfBirth)
            }

            if !profile.biography.isEmpty {
                biographySection(profile.biography)
            }

            if hasNoProfileDetails(profile) {
                Text("No profile information available.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func filmContent(_ profile: PersonProfile) -> some View {
        if profile.credits.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 10) {
                ForEach(profile.credits) { credit in
                    NavigationLink(destination: MovieDetailView(movieId: credit.id)) {
                        PersonCreditRowView(credit: credit)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens movie details")
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(CinemaTokens.Colors.textMuted)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(CinemaTokens.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func biographySection(_ biography: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Biography")
                .font(.headline.weight(.bold))
                .foregroundStyle(CinemaTokens.Colors.textPrimary)

            Text(biography)
                .font(.subheadline)
                .foregroundStyle(CinemaTokens.Colors.textSecondary)
                .lineSpacing(5)
                .lineLimit(isBiographyExpanded ? nil : 5)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    limitedBiographyHeight = height
                }
                .background(
                    Text(biography)
                        .font(.subheadline)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { height in
                            fullBiographyHeight = height
                        }
                )

            if isBiographyExpanded || isTruncated {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isBiographyExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isBiographyExpanded ? "Show Less" : "Read More")
                            .font(.caption.weight(.semibold))
                        Image(systemName: isBiographyExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(CinemaTokens.Colors.gold)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func datedValue(_ date: String, age: Int?) -> String {
        guard let age else { return date }
        return "\(date) (age \(age))"
    }

    private var isTruncated: Bool {
        fullBiographyHeight > limitedBiographyHeight + 0.5
    }

    private func hasNoProfileDetails(_ profile: PersonProfile) -> Bool {
        (profile.birthday?.isEmpty ?? true)
            && (profile.deathday?.isEmpty ?? true)
            && (profile.placeOfBirth?.isEmpty ?? true)
            && profile.biography.isEmpty
    }

    private func profileImage(_ path: String?) -> some View {
        ZStack {
            CinemaTokens.Colors.elevated

            if let path, let url = TMDBConfig.imageURL(path: path, size: "w342") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(CinemaTokens.Colors.textMuted)
                    }
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }

    private var displayName: String {
        guard let name = viewModel.profile?.name, !name.isEmpty else {
            return fallbackName
        }
        return name
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "film")
                .font(.system(size: 36))
                .foregroundStyle(CinemaTokens.Colors.textMuted)

            Text("No movies found")
                .font(.headline.weight(.bold))
                .foregroundStyle(CinemaTokens.Colors.textPrimary)

            Text("This person has no acting credits available.")
                .font(.subheadline)
                .foregroundStyle(CinemaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 20)
    }
}
