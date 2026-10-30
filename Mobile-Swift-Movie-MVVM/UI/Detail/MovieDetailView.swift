//
//  MovieDetailView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct MovieDetailView: View {
    @State private var viewModel: MovieDetailViewModel
    @State private var isOverviewExpanded: Bool = false
    @State private var favoriteScale: CGFloat = 1.0
    @State private var selectedTrailerPresentation: TrailerPresentation?
    public var onToggleFavorite: (() -> Void)?

    public init(
        movieId: Int,
        viewModel: MovieDetailViewModel? = nil,
        onToggleFavorite: (() -> Void)? = nil
    ) {
        if let viewModel = viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            let repository = MovieRepositoryImpl.shared
            let detailUseCase = GetMovieDetailsUseCase(repository: repository)
            let toggleUseCase = ToggleFavoriteMovieUseCase(repository: repository)
            let checkUseCase = CheckIsFavoriteUseCase(repository: repository)
            let discoverUseCase = DiscoverMoviesByGenreUseCase(repository: repository)
            _viewModel = State(
                initialValue: MovieDetailViewModel(
                    movieId: movieId,
                    getMovieDetailsUseCase: detailUseCase,
                    toggleFavoriteMovieUseCase: toggleUseCase,
                    checkIsFavoriteUseCase: checkUseCase,
                    discoverMoviesByGenreUseCase: discoverUseCase
                )
            )
        }
        self.onToggleFavorite = onToggleFavorite
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView(message: "Loading movie details...")
            case .error(let message):
                ErrorView(message: message) {
                    Task {
                        await viewModel.fetchDetails()
                    }
                }
            case .loaded(let detail):
                detailContentView(detail: detail)
            }
        }
        .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        favoriteScale = 1.3
                    }
                    Task {
                        await viewModel.toggleFavorite()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            favoriteScale = 1.0
                        }
                        onToggleFavorite?()
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(viewModel.isFavorite ? CinemaTokens.Colors.gold : .primary)
                        .scaleEffect(favoriteScale)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Bookmark \(viewModel.movieDetail?.title ?? "movie")")
            }
        }
        .task {
            await viewModel.fetchDetails()
        }
        .sheet(item: $selectedTrailerPresentation) { presentation in
            TrailerSheetView(
                video: presentation.video,
                movieTitle: presentation.title
            )
        }
    }

    private func detailContentView(detail: MovieDetail) -> some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Edge-to-edge Stretchy Backdrop Header
                    GeometryReader { headerGeo in
                        let minY = headerGeo.frame(in: .named("detailScroll")).minY
                        let isStretched = minY > 0
                        let stretchHeight: CGFloat = 340 + (isStretched ? minY : 0)

                        ZStack(alignment: .bottomLeading) {
                            TMDBImageView(
                                path: detail.backdropPath ?? detail.posterPath,
                                size: "original",
                                contentMode: .fill
                            )
                            .frame(width: screenWidth, height: stretchHeight)
                            .clipped()

                            // Progressive gradient blend into canvas
                            LinearGradient(
                                stops: [
                                    .init(color: .black.opacity(0.55), location: 0.0),
                                    .init(color: .clear, location: 0.25),
                                    .init(color: CinemaTokens.Colors.canvas.opacity(0.6), location: 0.65),
                                    .init(color: CinemaTokens.Colors.canvas, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .frame(width: screenWidth, height: stretchHeight)
                        .offset(y: isStretched ? -minY : 0)
                    }
                    .frame(width: screenWidth, height: 340)

                    // Hero title and floating poster
                    HStack(alignment: .bottom, spacing: 16) {
                        TMDBImageView(path: detail.posterPath, size: "w500")
                            .frame(width: 104, height: 156)
                            .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                                    .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)

                        VStack(alignment: .leading, spacing: 6) {
                            if let tagline = detail.tagline, !tagline.isEmpty {
                                Text(tagline)
                                    .font(.caption.weight(.semibold).italic())
                                    .foregroundStyle(CinemaTokens.Colors.gold)
                                    .lineLimit(2)
                            }

                            Text(detail.title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(CinemaTokens.Colors.textPrimary)
                                .lineLimit(3)

                            if let trailer = detail.trailer {
                                Button {
                                    selectedTrailerPresentation = TrailerPresentation(
                                        video: trailer,
                                        title: detail.title
                                    )
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("Watch Trailer")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(CinemaTokens.Colors.crimson)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                                .accessibilityLabel("Watch trailer for \(detail.title)")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -70)

                    // 2. Glassmorphic 3-Pillar Stats Card
                    threePillarStatsCard(detail: detail)

                    // 3. Translucent Genre Capsule Chips
                    if !detail.genres.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(detail.genres) { genre in
                                    Text(genre.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(CinemaTokens.Colors.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(CinemaTokens.Colors.elevated)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // 4. Where to Watch
                    if let providers = detail.providers,
                       providers.link != nil || !providers.groups.isEmpty {
                        WatchProvidersSectionView(providers: providers)
                    }

                    // 5. Cast Row
                    if !detail.cast.isEmpty {
                        castSection(for: detail.cast)
                    }

                    // 6. Storyline Section with Expandable Disclosure
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Storyline")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(CinemaTokens.Colors.textPrimary)

                        let overviewText = detail.overview.isEmpty ? "No synopsis available for this title." : detail.overview
                        let isLongText = overviewText.count > 160

                        Text(overviewText)
                            .font(.subheadline)
                            .foregroundStyle(CinemaTokens.Colors.textSecondary)
                            .lineSpacing(5)
                            .lineLimit(isLongText && !isOverviewExpanded ? 3 : nil)

                        if isLongText {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isOverviewExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(isOverviewExpanded ? "Show Less" : "Read More")
                                        .font(.caption.weight(.semibold))
                                    Image(systemName: isOverviewExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(CinemaTokens.Colors.gold)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 20)

                    // 7. More Like This
                    moreLikeThisSection(for: detail)
                }
                .frame(width: screenWidth)
                .padding(.bottom, 40)
            }
            .coordinateSpace(name: "detailScroll")
            .ignoresSafeArea(edges: .top)
        }
    }

    @ViewBuilder
    private func moreLikeThisSection(for detail: MovieDetail) -> some View {
        if !viewModel.genreSections.isEmpty {
            LazyVStack(alignment: .leading, spacing: 26) {
                ForEach(viewModel.genreSections) { section in
                    horizontalMovieRow(
                        title: "More in \(section.genre.name)",
                        movies: section.movies
                    )
                }
            }
        } else if viewModel.isLoadingRelated && detail.recommendedMovies.isEmpty {
            relatedLoadingPlaceholder
        } else if !detail.recommendedMovies.isEmpty {
            horizontalMovieRow(title: "More Like This", movies: detail.recommendedMovies)
        }
    }

    private func horizontalMovieRow(title: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MORE LIKE THIS")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(CinemaTokens.Colors.gold)

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movieId: movie.id, onToggleFavorite: onToggleFavorite)) {
                            relatedMovieCard(for: movie)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var relatedLoadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MORE LIKE THIS")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(CinemaTokens.Colors.gold)

                Text("Loading Recommendations...")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<4) { _ in
                        RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                            .fill(CinemaTokens.Colors.elevated)
                            .frame(width: 124, height: 186)
                            .overlay(
                                RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                                    .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func castSection(for cast: [CastMember]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cast")
                .font(.headline.weight(.bold))
                .foregroundStyle(CinemaTokens.Colors.textPrimary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(cast, id: \.uniqueID) { member in
                        NavigationLink(
                            destination: PersonView(
                                personId: member.id,
                                name: member.name,
                                profilePath: member.profilePath
                            )
                        ) {
                            VStack(spacing: 6) {
                                castAvatar(for: member)

                                Text(member.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
                                    .lineLimit(1)

                                if !member.character.isEmpty {
                                    Text(member.character)
                                        .font(.caption2)
                                        .foregroundStyle(CinemaTokens.Colors.textMuted)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 84)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(CastCellButtonStyle())
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            member.character.isEmpty
                                ? "Films with \(member.name)"
                                : "Films with \(member.name), \(member.character)"
                        )
                        .accessibilityHint("Opens this person's filmography")
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func castAvatar(for member: CastMember) -> some View {
        ZStack {
            CinemaTokens.Colors.elevated

            if let path = member.profilePath, let url = TMDBConfig.imageURL(path: path, size: "w185") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(CinemaTokens.Colors.textMuted)
                    }
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
        )
    }

    private func relatedMovieCard(for movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                TMDBImageView(path: movie.posterPath, size: "w500")
                    .frame(width: 124, height: 186)
                    .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                            .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                    )

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.6),
                        .init(color: .black.opacity(0.75), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
            }
            .frame(width: 124, height: 186)

            Text(movie.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CinemaTokens.Colors.textPrimary)
                .lineLimit(1)

            HStack(spacing: 6) {
                RatingBadgeView(rating: movie.voteAverage)

                if let year = movie.releaseDate?.prefix(4), !year.isEmpty {
                    Text(String(year))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(CinemaTokens.Colors.textMuted)
                }
            }
        }
        .frame(width: 124, alignment: .leading)
    }

    private func threePillarStatsCard(detail: MovieDetail) -> some View {
        HStack(spacing: 0) {
            // Pillar 1: TMDB Rating
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(CinemaTokens.Colors.gold)
                    Text(String(format: "%.1f", detail.voteAverage))
                        .font(.subheadline.weight(.heavy))
                        .monospacedDigit()
                        .foregroundStyle(CinemaTokens.Colors.textPrimary)
                }
                Text("\(detail.voteCount) votes")
                    .font(.caption2)
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 32)
                .overlay(CinemaTokens.Colors.glassStroke)

            // Pillar 2: Duration
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    Text(detail.formattedRuntime)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(CinemaTokens.Colors.textPrimary)
                }
                Text("Duration")
                    .font(.caption2)
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 32)
                .overlay(CinemaTokens.Colors.glassStroke)

            // Pillar 3: Release Year
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    Text(detail.formattedReleaseYear)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(CinemaTokens.Colors.textPrimary)
                }
                Text("Release")
                    .font(.caption2)
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 14)
        .background(CinemaTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
    }
}

private struct CastCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TrailerPresentation: Identifiable {
    let video: MovieVideo
    let title: String

    var id: String { video.id }
}

#Preview {
    NavigationStack {
        MovieDetailView(movieId: 550)
    }
}
