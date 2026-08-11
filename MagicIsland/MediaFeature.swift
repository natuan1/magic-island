import Foundation

struct MediaActivity: Equatable {
    let appName: String
    let title: String
    let artist: String
    let artworkData: Data?
    let playbackState: MediaPlaybackState
    let supportedControls: MediaControls
    let duration: TimeInterval?
    let position: TimeInterval?

    init(snapshot: MediaSnapshot) {
        appName = snapshot.appName
        title = snapshot.title
        artist = snapshot.artist
        artworkData = snapshot.artworkData
        playbackState = snapshot.playbackState
        supportedControls = snapshot.supportedControls
        duration = snapshot.duration
        position = snapshot.position
    }
}

enum MediaPlaybackState: Equatable {
    case playing
    case paused
    case stopped
}

struct MediaControls: OptionSet, Equatable {
    let rawValue: Int

    static let playPause = MediaControls(rawValue: 1 << 0)
    static let previous = MediaControls(rawValue: 1 << 1)
    static let next = MediaControls(rawValue: 1 << 2)
    static let seek = MediaControls(rawValue: 1 << 3)
}

struct MediaSnapshot: Equatable {
    let appName: String
    let title: String
    let artist: String
    let artworkData: Data?
    let playbackState: MediaPlaybackState
    let supportedControls: MediaControls
    let duration: TimeInterval?
    let position: TimeInterval?
}

protocol MediaProviding {
    mutating func currentSnapshot() throws -> MediaSnapshot?
    mutating func perform(_ command: MediaCommand) throws
}

enum MediaCommand: Equatable {
    case playPause
    case previous
    case next
    case seek(TimeInterval)
}

extension MediaProviding {
    mutating func perform(_ command: MediaCommand) throws {}
}

struct MediaFeature<Provider: MediaProviding> {
    static var featureID: String { "media" }
    static var activityID: String { "media.current" }

    private var provider: Provider
    private(set) var isEnabled = true

    init(provider: Provider) {
        self.provider = provider
    }

    mutating func refresh(now: Date = Date(), engine: inout ActivityEngine) {
        guard isEnabled else {
            return
        }

        do {
            guard let snapshot = try provider.currentSnapshot(),
                  snapshot.playbackState != .stopped else {
                engine.removeActivity(id: Self.activityID)
                return
            }

            engine.publish(Activity(
                id: Self.activityID,
                featureID: Self.featureID,
                priority: 50,
                startedAt: now,
                expiresAt: nil,
                presentation: .media(MediaActivity(snapshot: snapshot))
            ))
        } catch {
            isEnabled = false
            engine.removeActivities(for: Self.featureID)
        }
    }

    mutating func perform(_ command: MediaCommand) {
        guard isEnabled else {
            return
        }

        do {
            try provider.perform(command)
        } catch {
            isEnabled = false
        }
    }
}

struct SpotifyMediaProvider: MediaProviding {
    enum ProviderError: Error {
        case scriptFailed
    }

    mutating func currentSnapshot() throws -> MediaSnapshot? {
        let source = """
        tell application "System Events"
            if not (exists process "Spotify") then return "stopped"
        end tell
        tell application "Spotify"
            if player state is stopped then return "stopped"
            set trackName to name of current track
            set artistName to artist of current track
            set stateName to player state as string
            set trackDuration to duration of current track / 1000
            set trackPosition to player position
            return trackName & linefeed & artistName & linefeed & stateName & linefeed & trackDuration & linefeed & trackPosition
        end tell
        """

        var error: NSDictionary?
        guard let output = NSAppleScript(source: source)?.executeAndReturnError(&error).stringValue else {
            throw ProviderError.scriptFailed
        }

        guard output != "stopped" else {
            return nil
        }

        let lines = output.components(separatedBy: "\n")
        guard lines.count >= 5 else {
            throw ProviderError.scriptFailed
        }

        let artworkData = try artworkData()

        return MediaSnapshot(
            appName: "Spotify",
            title: lines[0],
            artist: lines[1],
            artworkData: artworkData,
            playbackState: lines[2] == "playing" ? .playing : .paused,
            supportedControls: [.playPause, .previous, .next, .seek],
            duration: TimeInterval(lines[3]),
            position: TimeInterval(lines[4])
        )
    }

    mutating func perform(_ command: MediaCommand) throws {
        let source: String

        switch command {
        case .playPause:
            source = "tell application \"Spotify\" to playpause"
        case .previous:
            source = "tell application \"Spotify\" to previous track"
        case .next:
            source = "tell application \"Spotify\" to next track"
        case .seek(let position):
            source = "tell application \"Spotify\" to set player position to \(position)"
        }

        var error: NSDictionary?
        guard NSAppleScript(source: source)?.executeAndReturnError(&error) != nil else {
            throw ProviderError.scriptFailed
        }
    }

    private func artworkData() throws -> Data? {
        let source = """
        tell application "System Events"
            if not (exists process "Spotify") then return ""
        end tell
        tell application "Spotify"
            if player state is stopped then return ""
            return artwork url of current track
        end tell
        """

        var error: NSDictionary?
        guard let artworkURL = NSAppleScript(source: source)?.executeAndReturnError(&error).stringValue else {
            throw ProviderError.scriptFailed
        }

        guard let url = URL(string: artworkURL), !artworkURL.isEmpty else {
            return nil
        }

        return try? Data(contentsOf: url)
    }
}
