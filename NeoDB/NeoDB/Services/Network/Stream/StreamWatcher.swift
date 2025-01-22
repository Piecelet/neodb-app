//
//  StreamWatcher.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import Foundation
import OSLog

@MainActor
class StreamWatcher: ObservableObject {
    private let logger = Logger.networkStream
    private var accountsManager: AppAccountsManager?
    private var task: URLSessionWebSocketTask?
    private var watchedStreams: [Stream] = []
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    public enum Stream: String {
        case local = "public:local"
        case home = "user"
        case federated = "public"
    }
    
    @Published public var events: [any StreamEvent] = []
    @Published public var latestEvent: (any StreamEvent)?
    
    init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    public func setAccountsManager(_ accountsManager: AppAccountsManager) {
        if self.accountsManager != nil {
            stopWatching()
        }
        self.accountsManager = accountsManager
        connect()
    }
    
    private func connect() {
        guard let accountsManager = accountsManager else { return }
        
        do {
            task = try accountsManager.currentClient.makeWebSocketTask(endpoint: StreamingEndpoint.streaming)
            task?.resume()
            receiveMessage()
        } catch {
            logger.error("Failed to create WebSocket connection: \(error.localizedDescription)")
        }
    }
    
    public func watch(streams: [Stream]) {
        if accountsManager?.isAuthenticated == false {
            return
        }
        if task == nil {
            connect()
        }
        watchedStreams = streams
        streams.forEach { stream in
            sendMessage(message: StreamMessage(type: "subscribe", stream: stream.rawValue))
        }
    }
    
    public func stopWatching() {
        task?.cancel()
        task = nil
    }
    
    private func sendMessage(message: StreamMessage) {
        task?.send(.data(try! encoder.encode(message))) { _ in }
    }
    
    private func receiveMessage() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let string):
                    Task { @MainActor in
                        do {
                            guard let data = string.data(using: .utf8) else {
                                self.logger.error("Error decoding streaming event string")
                                return
                            }
                            let rawEvent = try self.decoder.decode(RawStreamEvent.self, from: data)
                            if let event = self.rawEventToEvent(rawEvent: rawEvent) {
                                self.events.append(event)
                                self.latestEvent = event
                            }
                        } catch {
                            self.logger.error("Error decoding streaming event: \(error.localizedDescription)")
                        }
                    }
                default:
                    break
                }
                
                self.receiveMessage()
                
            case .failure:
                // Reconnect after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
                    guard let self = self else { return }
                    self.stopWatching()
                    self.connect()
                    self.watch(streams: self.watchedStreams)
                }
            }
        }
    }
    
    private func rawEventToEvent(rawEvent: RawStreamEvent) -> (any StreamEvent)? {
        guard let payloadData = rawEvent.payload.data(using: .utf8) else {
            return nil
        }
        
        do {
            switch rawEvent.event {
            case "update":
                let status = try decoder.decode(MastodonStatus.self, from: payloadData)
                return StreamEventUpdate(status: status)
            case "status.update":
                let status = try decoder.decode(MastodonStatus.self, from: payloadData)
                return StreamEventStatusUpdate(status: status)
            case "delete":
                return StreamEventDelete(status: rawEvent.payload)
            default:
                return nil
            }
        } catch {
            logger.error("Error decoding streaming event to final event: \(error.localizedDescription)")
            return nil
        }
    }
} 
