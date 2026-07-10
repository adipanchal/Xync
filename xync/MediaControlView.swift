//
//  MediaControlView.swift
//  xync
//
//  Created by Aditya on 25/06/26.
//

import SwiftUI

struct MediaControlView: View {
    @ObservedObject var mediaManager = MediaManager.shared
    var device: Device
    
    // Optional: a slightly different layout for MenuBar vs Tab
    var isCompact: Bool = false
    
    var body: some View {
        if isCompact {
            VStack(spacing: 8) {
                // Track Info
                VStack(spacing: 2) {
                    if mediaManager.currentMediaState.title.isEmpty {
                        Image("MenuBarIcon")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 18)
                            .foregroundColor(.secondary.opacity(0.8))
                    } else {
                        Text(mediaManager.currentMediaState.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(mediaManager.currentMediaState.artist.isEmpty ? "Unknown Artist" : mediaManager.currentMediaState.artist)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Playback Controls
                HStack(spacing: 24) {
                    Button(action: { mediaManager.volumeDown() }) {
                        Image(systemName: "speaker.minus.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaManager.prevTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaManager.playPause() }) {
                        Image(systemName: mediaManager.currentMediaState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaManager.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaManager.volumeUp() }) {
                        Image(systemName: "speaker.plus.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .onAppear { mediaManager.startPolling(serial: device.serial, subscriber: "MediaControlView_compact") }
            .onDisappear { mediaManager.stopPolling(subscriber: "MediaControlView_compact") }
        } else {
            VStack(spacing: 20) {
                // Album Art Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(.top, 20)
                
                // Track Info
                VStack(spacing: 4) {
                    if mediaManager.currentMediaState.title.isEmpty {
                        Image("MenuBarIcon")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                            .foregroundColor(.secondary.opacity(0.8))
                    } else {
                        Text(mediaManager.currentMediaState.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text(mediaManager.currentMediaState.artist.isEmpty ? "Unknown Artist" : mediaManager.currentMediaState.artist)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal)
                
                // Playback Controls
                HStack(spacing: 30) {
                    Button(action: {
                        mediaManager.volumeDown()
                    }) {
                        Image(systemName: "speaker.minus.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        mediaManager.prevTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        mediaManager.playPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.primary.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: mediaManager.currentMediaState.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        mediaManager.nextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        mediaManager.volumeUp()
                    }) {
                        Image(systemName: "speaker.plus.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 20)
            }
            .padding(20)
            .onAppear {
                mediaManager.startPolling(serial: device.serial, subscriber: "MediaControlView_full")
            }
            .onDisappear {
                mediaManager.stopPolling(subscriber: "MediaControlView_full")
            }
        }
    }
}
