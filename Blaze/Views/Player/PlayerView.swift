import SwiftUI
import WebKit

struct PlayerView: View {
    let video: WorkoutVideo
    @Binding var path: NavigationPath
    @Environment(SessionModel.self)  private var sessionModel
    @Environment(WorkoutModel.self)  private var workoutModel

    // Tracks whether the current video failed to play and a replacement is loading
    @State private var isFetchingReplacement = false
    @State private var replacementError: String? = nil

    var body: some View {
        ZStack {
            BlazeColour.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // YouTube player
                YouTubePlayerView(videoID: video.id, onPlaybackBlocked: handlePlaybackBlocked)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.md))
                    .padding(.horizontal, BlazeSpacing.md)
                    .padding(.top, BlazeSpacing.md)
                    .overlay(alignment: .center) {
                        if isFetchingReplacement {
                            ZStack {
                                Color.black.opacity(0.7)
                                    .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.md))
                                VStack(spacing: BlazeSpacing.sm) {
                                    ProgressView().tint(BlazeColour.accent)
                                    Text("Finding a different video…")
                                        .font(BlazeFont.body(13))
                                        .foregroundStyle(BlazeColour.textSecondary)
                                }
                            }
                            .padding(.horizontal, BlazeSpacing.md)
                            .padding(.top, BlazeSpacing.md)
                        }
                    }

                ScrollView {
                    VStack(alignment: .leading, spacing: BlazeSpacing.lg) {

                        // Error banner
                        if let err = replacementError {
                            HStack(spacing: BlazeSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(BlazeColour.warning)
                                Text(err)
                                    .font(BlazeFont.body(13))
                                    .foregroundStyle(BlazeColour.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(BlazeSpacing.md)
                            .background(BlazeColour.warning.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.md))
                        }

                        VStack(alignment: .leading, spacing: BlazeSpacing.sm) {
                            Text(video.title)
                                .font(BlazeFont.heading(18))
                                .foregroundStyle(BlazeColour.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(video.channelName)
                                .font(BlazeFont.body(14))
                                .foregroundStyle(BlazeColour.textMuted)

                            HStack(spacing: BlazeSpacing.md) {
                                StatChip(icon: "clock.fill",  value: video.formattedDuration, unit: "")
                                StatChip(icon: "flame.fill",  value: "\(video.estimatedCalories)", unit: "cal")
                                StatChip(icon: "figure.run",  value: video.activityType.rawValue, unit: "")
                            }
                        }

                        // Pro tip
                        HStack(alignment: .top, spacing: BlazeSpacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(BlazeColour.warning)
                            VStack(alignment: .leading, spacing: BlazeSpacing.xs) {
                                Text("Pro tip")
                                    .font(BlazeFont.body(13, weight: .semibold))
                                    .foregroundStyle(BlazeColour.warning)
                                Text(video.proTip)
                                    .font(BlazeFont.body(14))
                                    .foregroundStyle(BlazeColour.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(BlazeSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BlazeColour.warning.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.md))

                        // Mark as done
                        if !sessionModel.isCompleted(videoID: video.id) {
                            Button(action: {
                                sessionModel.markCompleted(videoID: video.id)
                                path.removeLast()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Done — back to playlist")
                                }
                                .font(BlazeFont.body(16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BlazeSpacing.md)
                                .background(BlazeColour.success)
                                .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BlazeColour.success)
                                Text("Completed")
                                    .foregroundStyle(BlazeColour.success)
                            }
                            .font(BlazeFont.body(15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BlazeSpacing.md)
                            .background(BlazeColour.success.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
                        }

                        Button(action: { path.removeLast() }) {
                            Label("Back to playlist", systemImage: "chevron.left")
                                .font(BlazeFont.body(14))
                                .foregroundStyle(BlazeColour.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(BlazeSpacing.lg)
                }
            }
        }
        .navigationTitle(video.activityType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
    }

    // Called by YouTubePlayerView when it detects a playback error in the page
    private func handlePlaybackBlocked() {
        guard !isFetchingReplacement else { return }
        isFetchingReplacement = true
        replacementError = nil

        Task {
            let currentIDs = Set((workoutModel.currentPlan?.videos ?? []).map { $0.id })
            let replacement = try? await YouTubeService.shared.fetchReplacement(
                for: video.activityType,
                durationSeconds: video.durationSeconds,
                excluding: currentIDs
            )
            await MainActor.run {
                isFetchingReplacement = false
                if let r = replacement {
                    workoutModel.replaceVideo(id: video.id, with: r)
                    // Navigate back to plan so the updated card is shown with the new video
                    path.removeLast()
                } else {
                    replacementError = "This video can't be played here. Tap 'Done' to skip it and continue your workout."
                }
            }
        }
    }
}

// MARK: - YouTube WKWebView wrapper

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    let onPlaybackBlocked: () -> Void

    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    func makeCoordinator() -> Coordinator { Coordinator(onPlaybackBlocked: onPlaybackBlocked) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Message handler lets JavaScript notify Swift when an error occurs
        config.userContentController.add(context.coordinator, name: "blazePlayer")

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.customUserAgent = userAgent
        wv.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        wv.isOpaque = false
        wv.scrollView.isScrollEnabled = false
        return wv
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onPlaybackBlocked = onPlaybackBlocked
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { width: 100%; height: 100%; background: #0D0D0D; overflow: hidden; }
            .wrap { position: relative; width: 100%; padding-bottom: 56.25%; height: 0; }
            iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
          </style>
        </head>
        <body>
          <div class="wrap">
            <iframe
              id="ytplayer"
              src="https://www.youtube-nocookie.com/embed/\(videoID)?playsinline=1&rel=0&modestbranding=1&enablejsapi=1&origin=https://www.youtube-nocookie.com&fs=1"
              allow="autoplay; fullscreen; accelerometer; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen>
            </iframe>
          </div>
          <script>
            // YouTube iFrame API — listens for player errors and notifies Swift
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            document.head.appendChild(tag);

            var player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('ytplayer', {
                events: { 'onError': onPlayerError }
              });
            }

            function onPlayerError(event) {
              // Error codes 2, 5, 100, 101, 150 all mean the video cannot be embedded/played
              var blocked = [2, 5, 100, 101, 150];
              if (blocked.indexOf(event.data) !== -1) {
                window.webkit.messageHandlers.blazePlayer.postMessage({ error: event.data });
              }
            }
          </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }

    // MARK: - Coordinator — receives JS messages

    class Coordinator: NSObject, WKScriptMessageHandler {
        var onPlaybackBlocked: () -> Void

        init(onPlaybackBlocked: @escaping () -> Void) {
            self.onPlaybackBlocked = onPlaybackBlocked
        }

        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "blazePlayer" else { return }
            DispatchQueue.main.async { self.onPlaybackBlocked() }
        }
    }
}
