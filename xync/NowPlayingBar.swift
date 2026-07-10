import SwiftUI

struct NowPlayingBar: View {
    @ObservedObject var mediaManager = MediaManager.shared
    var device: Device
    
    var body: some View {
        HStack {
            // Left: Playback controls
            HStack(spacing: 16) {
                Button(action: { mediaManager.prevTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { mediaManager.playPause() }) {
                    Image(systemName: mediaManager.currentMediaState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { mediaManager.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            // Center: Track info
            VStack(alignment: .center, spacing: 2) {
                if mediaManager.currentMediaState.title.isEmpty {
                    Image("MenuBarIcon")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 18)
                        .foregroundColor(.secondary.opacity(0.8))
                } else {
                    Text(mediaManager.currentMediaState.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(mediaManager.currentMediaState.artist.isEmpty ? "Unknown Artist" : mediaManager.currentMediaState.artist)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Right: Volume controls
            HStack(spacing: 16) {
                Button(action: { mediaManager.volumeDown() }) {
                    Image(systemName: "speaker.minus.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: { mediaManager.volumeUp() }) {
                    Image(systemName: "speaker.plus.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(BlurView(material: .hudWindow, blendingMode: .withinWindow).clipShape(Capsule()))
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .onAppear {
            mediaManager.startPolling(serial: device.serial, subscriber: "NowPlayingBar")
        }
        .onDisappear {
            mediaManager.stopPolling(subscriber: "NowPlayingBar")
        }
    }
}

// A simple NSVisualEffectView wrapper for nice blurring
struct BlurView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
