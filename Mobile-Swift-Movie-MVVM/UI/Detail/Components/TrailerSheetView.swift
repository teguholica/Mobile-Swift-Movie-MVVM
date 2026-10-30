//
//  TrailerSheetView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI
import WebKit

public struct TrailerSheetView: View {
    private let video: MovieVideo
    private let movieTitle: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    public init(video: MovieVideo, movieTitle: String) {
        self.video = video
        self.movieTitle = movieTitle
    }

    private var watchURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(video.key)")
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Group {
                    if !video.key.isEmpty {
                        YouTubeWebView(videoKey: video.key)
                    } else {
                        ContentUnavailableView(
                            "Trailer Unavailable",
                            systemImage: "play.slash",
                            description: Text("This trailer cannot be played right now.")
                        )
                    }
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
                .padding(.horizontal, 16)

                if let watchURL = watchURL {
                    Button {
                        openURL(watchURL)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open in YouTube")
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(CinemaTokens.Colors.crimson)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .accessibilityLabel("Open trailer in YouTube")
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
            .navigationTitle(movieTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(CinemaTokens.Colors.accent)
                }
            }
        }
    }
}

private struct YouTubeWebView: UIViewRepresentable {
    let videoKey: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.accessibilityLabel = "Trailer player"
        webView.loadHTMLString(Self.html(for: videoKey), baseURL: URL(string: "https://www.youtube.com"))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func html(for videoKey: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>html,body{margin:0;padding:0;height:100%;background:#000;}iframe{display:block;width:100%;height:100%;border:0;}</style>
        </head>
        <body>
        <iframe src="https://www.youtube.com/embed/\(videoKey)?playsinline=1&rel=0&origin=https://www.youtube.com"
                allow="autoplay; encrypted-media; fullscreen"
                allowfullscreen></iframe>
        </body>
        </html>
        """
    }
}
