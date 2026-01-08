//
//  TraktorOBSRelayClient.swift
//  chuneesium
//
//  A Swift client for Traktor-OBS-Relay, modelled after the original JS API:
//  - HTTP polling: https://github.com/vladkorotnev/traktor-obs-relay/blob/master/assets/api/api.js
//  - WebSocket push: https://github.com/vladkorotnev/traktor-obs-relay/blob/master/assets/api/api-ws.js
//
//  Created by DJ AKASAKA with help from Cursor.
//

import Foundation
import Combine
import Starscream

/// Representation of a track/deck entry from Traktor-OBS-Relay `nowPlaying` payload.
///
/// The JS client uses fields like `deck`, `filePath` and `isPlaying`:
/// see `assets/api/api.js` in the upstream repo.
struct TraktorSongOnAir: Codable, Hashable, Identifiable {
    /// Deck identifier (e.g. "A", "B", "C", "D").
    let deck: String?
    /// Full path of the track file on disk.
    let filePath: String?
    /// Whether this deck is currently playing.
    let isPlaying: Bool?

    // Common metadata fields used by typical Traktor-OBS-Relay setups.
    let title: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let bpm: Double?

    /// Stable identifier – uses `filePath` when available.
    var id: String {
        filePath ?? UUID().uuidString
    }

    enum CodingKeys: String, CodingKey {
        case deck
        case filePath
        case isPlaying
        case title
        case artist
        case album
        case duration
        case bpm
    }
}

/// Top‑level payload pushed by Traktor-OBS-Relay.
///
/// Mirrors the structure consumed by `processUpdates(info)` in
/// `assets/api/api.js` from the original project.
struct TraktorNowPlayingInfo: Codable {
    let songsOnAir: [TraktorSongOnAir]?
    let tickedDeck: String?
    let bpm: Double?
}

/// Swift/Combine client for Traktor-OBS-Relay, modelled after the JS WebSocket API client
/// (`api-ws.js`) and its `processUpdates(info)` function in `api.js`.
///
/// It exposes high‑level Combine publishers that correspond to the
/// callback‑style hooks in the JS client (`pushTrack`, `popTrack`, `onBpmChanged`, etc.).
final class TraktorOBSRelayClient: NSObject, ObservableObject {

    // MARK: - Nested types

    struct Configuration: Equatable {
        /// Hostname of the Traktor-OBS-Relay server.
        var host: String = "localhost"
        /// HTTP port for the REST API (defaults to 8080 as in `api.js`).
        var httpPort: Int = 8080
        /// WebSocket port for push updates (defaults to 9090 as in `api-ws.js`).
        var webSocketPort: Int = 9090
        /// Whether to use HTTPS/WSS instead of HTTP/WS.
        var useTLS: Bool = false
        /// Polling interval (milliseconds in JS, seconds here).
        var pollingInterval: TimeInterval = 2.0

        fileprivate var httpScheme: String { useTLS ? "https" : "http" }
        fileprivate var wsScheme: String { useTLS ? "wss" : "ws" }
    }

    // MARK: - Public publishers (API surface)

    /// Raw `nowPlaying` payloads, mirroring `processUpdates(info)` input.
    var nowPlaying: AnyPublisher<TraktorNowPlayingInfo, Never> {
        nowPlayingSubject.eraseToAnyPublisher()
    }

    /// Tracks that started playing (JS: `pushTrack`).
    var trackStarted: AnyPublisher<TraktorSongOnAir, Never> {
        trackStartedSubject.eraseToAnyPublisher()
    }

    /// Tracks that stopped playing (JS: `popTrack`).
    var trackStopped: AnyPublisher<TraktorSongOnAir, Never> {
        trackStoppedSubject.eraseToAnyPublisher()
    }

    /// Decks that appeared (JS: `pushDeck`).
    var deckAppeared: AnyPublisher<TraktorSongOnAir, Never> {
        deckAppearedSubject.eraseToAnyPublisher()
    }

    /// Decks that disappeared (JS: `popDeck`).
    var deckDisappeared: AnyPublisher<TraktorSongOnAir, Never> {
        deckDisappearedSubject.eraseToAnyPublisher()
    }

    /// Per‑tick updates for the deck indicated by `tickedDeck` (JS: `trackTick`).
    var trackTicked: AnyPublisher<TraktorSongOnAir, Never> {
        trackTickedSubject.eraseToAnyPublisher()
    }

    /// Tracks that are present but currently paused (JS: `trackPaused`).
    var trackPaused: AnyPublisher<TraktorSongOnAir, Never> {
        trackPausedSubject.eraseToAnyPublisher()
    }

    /// BPM changes (JS: `onBpmChanged`).
    var bpmChanged: AnyPublisher<Double, Never> {
        bpmChangedSubject.eraseToAnyPublisher()
    }

    /// Connection state of the WebSocket.
    @Published private(set) var isConnected: Bool = false

    // MARK: - Private state

    private let configuration: Configuration

    // Mirrors JS globals `tracks`/`decks`/`oldBpm`.
    private var tracksByPath: [String: TraktorSongOnAir] = [:]
    private var decksById: [String: TraktorSongOnAir] = [:]
    private var lastBPM: Double?

    // Current-track bookkeeping
    private var activeTrackOrder: [String] = []   // filePath keys, first = oldest
    private var currentTrackKey: String?

    // Combine subjects backing the public publishers
    private let nowPlayingSubject = PassthroughSubject<TraktorNowPlayingInfo, Never>()
    private let trackStartedSubject = PassthroughSubject<TraktorSongOnAir, Never>()
    private let trackStoppedSubject = PassthroughSubject<TraktorSongOnAir, Never>()
    private let deckAppearedSubject = PassthroughSubject<TraktorSongOnAir, Never>()
    private let deckDisappearedSubject = PassthroughSubject<TraktorSongOnAir, Never>()
    private let trackTickedSubject = PassthroughSubject<TraktorSongOnAir, Never>()
    private let trackPausedSubject = PassthroughSubject<TraktorSongOnAir, Never>()
    private let bpmChangedSubject = PassthroughSubject<Double, Never>()

    private let currentTrackSubject = CurrentValueSubject<TraktorSongOnAir?, Never>(nil)

    /// The "current" track, following these rules:
    /// - No current track initially
    /// - First started track becomes current
    /// - Additional started tracks do not change the current track
    /// - When the current track stops, the next started (still playing) track becomes current
    var currentTrack: AnyPublisher<TraktorSongOnAir?, Never> {
        currentTrackSubject.removeDuplicates().eraseToAnyPublisher()
    }

    // WebSocket handling
    private var socket: WebSocket?
    private let decoder = JSONDecoder()
    private var reconnectWorkItem: DispatchWorkItem?

    // MARK: - Init / deinit

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        super.init()
        configureWebSocket()
        // Always try to connect; Traktor-OBS-Relay uses WebSocket as the primary API.
        scheduleReconnect()
    }

    deinit {
        disconnect()
    }

    // MARK: - Public control

    /// Disconnects from WebSocket and cancels any scheduled reconnect attempts.
    func disconnect() {
        reconnectWorkItem?.cancel()
        socket?.disconnect()
    }

    // MARK: - URL helpers (artwork / subtitles / etc.)

    /// Base `http(s)://host:port/` URL, matching `API_ROOT` in `api.js`.
    private func apiRootURL() -> URL? {
        var components = URLComponents()
        components.scheme = configuration.httpScheme
        components.host = configuration.host
        components.port = configuration.httpPort
        return components.url
    }

    /// `artwork/<deck>` URL, equivalent to `getArtUrl(meta)` in JS.
    func artworkURL(for song: TraktorSongOnAir) -> URL? {
        guard let deck = song.deck, let root = apiRootURL() else { return nil }
        return root.appendingPathComponent("artwork").appendingPathComponent(deck)
    }

    /// `subtitles/<deck>` URL.
    func subtitlesURL(for song: TraktorSongOnAir) -> URL? {
        guard let deck = song.deck, let root = apiRootURL() else { return nil }
        return root.appendingPathComponent("subtitles").appendingPathComponent(deck)
    }

    /// `video/<deck>` URL.
    func videoURL(for song: TraktorSongOnAir) -> URL? {
        guard let deck = song.deck, let root = apiRootURL() else { return nil }
        return root.appendingPathComponent("video").appendingPathComponent(deck)
    }

    /// `filename/<deck>` URL.
    func filenameURL(for song: TraktorSongOnAir) -> URL? {
        guard let deck = song.deck, let root = apiRootURL() else { return nil }
        return root.appendingPathComponent("filename").appendingPathComponent(deck)
    }

    // MARK: - Internal networking

    private func configureWebSocket() {
        guard let url = makeWebSocketURL() else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let socket = WebSocket(request: request)
        socket.callbackQueue = .main
        socket.delegate = self
        self.socket = socket
    }

    private func makeWebSocketURL() -> URL? {
        var components = URLComponents()
        components.scheme = configuration.wsScheme
        components.host = configuration.host
        components.port = configuration.webSocketPort
        return components.url
    }

    private func scheduleReconnect() {
        reconnectWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.socket?.connect()
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    // MARK: - JS `processUpdates(info)` port

    /// Port of `processUpdates(info)` from the original JS `api.js`,
    /// but expressed in Combine publishers instead of global callbacks.
    private func processUpdates(_ info: TraktorNowPlayingInfo) {
        guard let songs = info.songsOnAir else { return }
        nowPlayingSubject.send(info)
        guard !songs.isEmpty else { return }

        // Build new maps
        let newTracksByPath: [String: TraktorSongOnAir] = Dictionary(
            uniqueKeysWithValues: songs
                .filter { $0.isPlaying == true }
                .compactMap { song in
                    guard let path = song.filePath else { return nil }
                    return (path, song)
                }
        )

        let newDecksById: [String: TraktorSongOnAir] = Dictionary(
            uniqueKeysWithValues: songs
                .compactMap { song in
                    guard let deck = song.deck else { return nil }
                    return (deck, song)
                }
        )

        let oldTrackPaths = Set(tracksByPath.keys)
        let newTrackPaths = Set(newTracksByPath.keys)

        let oldDeckIds = Set(decksById.keys)
        let newDeckIds = Set(newDecksById.keys)

        let removedTrackPaths = oldTrackPaths.subtracting(newTrackPaths)
        let addedTrackPaths = newTrackPaths.subtracting(oldTrackPaths)

        // JS: `popTrack` – tracks that disappeared
        for removedPath in removedTrackPaths {
            if let track = tracksByPath[removedPath] {
                trackStoppedSubject.send(track)
            }
        }

        // JS: `popDeck` – decks that disappeared
        for removedDeck in oldDeckIds.subtracting(newDeckIds) {
            if let deck = decksById[removedDeck] {
                deckDisappearedSubject.send(deck)
            }
        }

        // JS: `pushTrack` – newly playing tracks
        for addedPath in addedTrackPaths {
            if let track = newTracksByPath[addedPath] {
                trackStartedSubject.send(track)
            }
        }

        // JS: `pushDeck` – new decks
        for addedDeck in newDeckIds.subtracting(oldDeckIds) {
            if let deck = newDecksById[addedDeck] {
                deckAppearedSubject.send(deck)
            }
        }

        // JS: `trackTick` – deck indicated by `tickedDeck`
        if let tickedDeckId = info.tickedDeck,
           let tickedTrack = songs.first(where: { $0.deck == tickedDeckId }) {
            trackTickedSubject.send(tickedTrack)
        }

        // JS: `trackPaused` – tracks that are present but `isPlaying == false`
        let pausedTracks = songs.filter { $0.isPlaying == false }
        pausedTracks.forEach { trackPausedSubject.send($0) }

        // JS: BPM change handling (`onBpmChanged`)
        if let bpm = info.bpm {
            if lastBPM == nil || lastBPM != bpm {
                bpmChangedSubject.send(bpm)
                lastBPM = bpm
            }
        }

        // Current-track management
        updateCurrentTrackState(
            removedTrackPaths: removedTrackPaths,
            addedTrackPaths: addedTrackPaths,
            newTracksByPath: newTracksByPath
        )

        // Update state mirrors
        tracksByPath = newTracksByPath
        decksById = newDecksById
    }

    private func updateCurrentTrackState(
        removedTrackPaths: Set<String>,
        addedTrackPaths: Set<String>,
        newTracksByPath: [String: TraktorSongOnAir]
    ) {
        // Remove stopped tracks from the active order.
        if !removedTrackPaths.isEmpty {
            activeTrackOrder.removeAll { removedTrackPaths.contains($0) }
        }

        // Append newly started tracks to the end of the active order.
        if !addedTrackPaths.isEmpty {
            let newlyAddedOrdered = addedTrackPaths.sorted()
            activeTrackOrder.append(contentsOf: newlyAddedOrdered)
        }

        // Determine the current track key.
        if let currentKey = currentTrackKey, removedTrackPaths.contains(currentKey) {
            // Current track stopped – promote the next oldest track if any.
            currentTrackKey = activeTrackOrder.first
        } else if currentTrackKey == nil {
            // No current track yet – pick the first active track if available.
            currentTrackKey = activeTrackOrder.first
        }

        // Publish the current track model or nil.
        if let key = currentTrackKey, let model = newTracksByPath[key] {
            currentTrackSubject.send(model)
        } else {
            currentTrackKey = nil
            currentTrackSubject.send(nil)
        }
    }
}

// MARK: - Starscream WebSocketDelegate

extension TraktorOBSRelayClient: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true

        case .disconnected:
            isConnected = false
            scheduleReconnect()

        case .text(let text):
            guard let data = text.data(using: .utf8) else { return }
            do {
                let info = try decoder.decode(TraktorNowPlayingInfo.self, from: data)
                processUpdates(info)
            } catch {
                #if DEBUG
                print("Failed to decode WebSocket nowPlaying JSON: \(error)")
                #endif
            }

        case .binary:
            // Traktor-OBS-Relay only sends text frames; ignore binary.
            break

        case .error:
            isConnected = false
            scheduleReconnect()

        case .cancelled:
            isConnected = false
            scheduleReconnect()

        default:
            break
        }
    }
}

