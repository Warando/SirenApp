import SwiftUI
import AVFoundation
import Combine

// MARK: - Sound Model (вынесено наружу, чтобы не было проблем с вложенными типами)

enum SoundType {
    case normal
    case loop
    case siren
}

struct Sound: Identifiable {
    let id: UUID = UUID()
    let name: String
    let icon: String
    let color: Color
    let file: String
    let type: SoundType
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var selectedSound: Sound?

    let sounds: [Sound] = ContentView.makeSounds()

    static func makeSounds() -> [Sound] {
        var result: [Sound] = []
        result.append(Sound(name: "Сирена", icon: "🚨", color: Color.red, file: "siren.mp3", type: SoundType.siren))
        result.append(Sound(name: "Горн", icon: "📯", color: Color.purple, file: "horn.mp3", type: SoundType.normal))
        result.append(Sound(name: "Команда", icon: "🎤", color: Color.blue, file: "voice.mp3", type: SoundType.normal))
        return result
    }

    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
        }
    }

    // Фон
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(white: 0.05),
                Color(white: 0.15)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // Основной контент
    var mainContent: some View {
        VStack(spacing: 25) {
            headerView
            statusView
            Spacer()
            soundButtons
            Spacer()
            stopButton
            volumeControl
            Spacer().frame(height: 20)
        }
    }

    // Заголовок
    var headerView: some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "radio.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("СГУ")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                Text("РАЦИЯ")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.blue)
            }

            Text("Станция Громкоговорящего Управления")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.top, 30)
    }

    // Статус
    var statusView: some View {
        StatusView(
            status: audioManager.status,
            isPlaying: audioManager.isPlaying,
            currentSound: selectedSound
        )
    }

    // Кнопки звуков
    var soundButtons: some View {
        VStack(spacing: 20) {
            ForEach(sounds) { sound in
                SoundButton(
                    sound: sound,
                    isSelected: selectedSound?.id == sound.id,
                    isPlaying: audioManager.isPlaying && selectedSound?.id == sound.id,
                    action: { handleSoundTap(sound: sound) }
                )
            }
        }
        .padding(.horizontal, 30)
    }

    // Кнопка стоп
    var stopButton: some View {
        StopButton {
            audioManager.stop()
            selectedSound = nil
        }
    }

    // Громкость
    var volumeControl: some View {
        VolumeControl(volume: $audioManager.volume)
    }

    // Обработчик нажатия
    func handleSoundTap(sound: Sound) {
        if selectedSound?.id == sound.id && audioManager.isPlaying {
            audioManager.stop()
            selectedSound = nil
        } else {
            selectedSound = sound
            audioManager.playSound(sound: sound)
        }
    }
}

// MARK: - Status View

struct StatusView: View {
    let status: String
    let isPlaying: Bool
    let currentSound: Sound?

    var statusColor: Color {
        isPlaying ? Color.yellow : Color.green
    }

    var pulseAnimation: Animation {
        if isPlaying {
            return Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
        } else {
            return Animation.default
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 14, height: 14)
                .scaleEffect(isPlaying ? 1.3 : 1.0)
                .animation(pulseAnimation, value: isPlaying)

            Text(status)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(statusColor)

            if let sound = currentSound, isPlaying {
                Text("•")
                    .foregroundColor(.gray)
                Text("\(sound.icon) \(sound.name)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(sound.color)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Sound Button

struct SoundButton: View {
    let sound: Sound
    let isSelected: Bool
    let isPlaying: Bool
    let action: () -> Void

    @State private var isPressed: Bool = false

    var ringAnimation: Animation {
        Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            HStack(spacing: 20) {
                soundIcon
                soundInfo
                Spacer()
                playIcon
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(soundBackground)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    var soundIcon: some View {
        ZStack {
            Circle()
                .fill(sound.color.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: 60, height: 60)

            Text(sound.icon)
                .font(.system(size: 32))

            if isPlaying && isSelected {
                Circle()
                    .stroke(sound.color, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .scaleEffect(1.2)
                    .opacity(0.8)
                    .animation(ringAnimation, value: isPlaying)
            }
        }
    }

    var soundInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sound.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(isSelected ? sound.color : .white)

            if isPlaying && isSelected {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(sound.color)
                            .frame(width: 6, height: 6)
                    }
                    Text("ИГРАЕТ")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(sound.color)
                }
            } else {
                Text("Нажмите для воспроизведения")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
    }

    var playIcon: some View {
        Image(systemName: isPlaying && isSelected ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 30))
            .foregroundColor(isSelected ? sound.color : .gray)
    }

    var soundBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? sound.color.opacity(0.15) : Color(white: 0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? sound.color : Color(white: 0.2), lineWidth: isSelected ? 2.5 : 1)
            )
    }
}

// MARK: - Stop Button

struct StopButton: View {
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                action()
            }
        }) {
            HStack(spacing: 15) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 28))

                Text("ОСТАНОВИТЬ ВСЕ")
                    .font(.system(size: 20, weight: .bold))

                Spacer()

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 2)
                    )
            )
            .foregroundColor(.white)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: Color.red.opacity(0.3), radius: 15, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Volume Control

struct VolumeControl: View {
    @Binding var volume: Float

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 16))

            Slider(value: $volume, in: 0...1)
                .tint(.white)

            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 16))

            Text("\(Int(volume * 100))%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(white: 0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Audio Manager

final class AudioManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var status: String = "ГОТОВ"
    @Published var volume: Float = 0.8 {
        didSet {
            audioPlayer?.volume = volume
            playerNode?.volume = volume
        }
    }

    private var audioPlayer: AVAudioPlayer?
    private var currentSound: Sound?
    private var timer: Timer?
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    func playSound(sound: Sound) {
        if currentSound?.id == sound.id && isPlaying {
            stop()
            return
        }

        stop()
        currentSound = sound

        if let url = Bundle.main.url(forResource: sound.file, withExtension: nil) {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.numberOfLoops = (sound.type == .loop || sound.type == .siren) ? -1 : 0
                player.prepareToPlay()
                player.play()
                audioPlayer = player

                isPlaying = true
                status = "ВОСПРОИЗВЕДЕНИЕ"

                if sound.type == .siren {
                    startSirenAnimation()
                }
            } catch {
                print("Ошибка загрузки файла \(sound.file): \(error)")
                generateSound(sound: sound)
            }
        } else {
            // Файл не найден в бандле — генерируем звук программно
            generateSound(sound: sound)
        }
    }

    private func generateSound(sound: Sound) {
        let frequency: Float
        let duration: Float

        switch sound.type {
        case .siren:
            frequency = 600
            duration = 2.0
        case .loop:
            frequency = 800
            duration = 1.0
        case .normal:
            frequency = 440
            duration = 0.5
        }

        let sampleRate: Float = 44100
        let totalFrames = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else {
            return
        }

        buffer.frameLength = AVAudioFrameCount(totalFrames)

        guard let channelData = buffer.floatChannelData?[0] else { return }

        for i in 0..<totalFrames {
            let time = Float(i) / sampleRate
            var sampleValue: Float
            if sound.type == .siren {
                let modFreq: Float = 2.0
                let freq = frequency + 300 * sin(2.0 * Float.pi * modFreq * time)
                sampleValue = 0.8 * sin(2.0 * Float.pi * freq * time)
            } else {
                sampleValue = 0.8 * sin(2.0 * Float.pi * frequency * time)
            }
            channelData[i] = sampleValue
        }

        let newEngine = AVAudioEngine()
        let newPlayerNode = AVAudioPlayerNode()
        newEngine.attach(newPlayerNode)
        newEngine.connect(newPlayerNode, to: newEngine.mainMixerNode, format: format)

        do {
            try newEngine.start()
        } catch {
            print("Ошибка запуска audio engine: \(error)")
            return
        }

        let shouldLoop = (sound.type == .loop || sound.type == .siren)
        let options: AVAudioPlayerNodeBufferOptions = shouldLoop ? .loops : []

        newPlayerNode.scheduleBuffer(buffer, at: nil, options: options, completionHandler: nil)
        newPlayerNode.volume = volume
        newPlayerNode.play()

        engine = newEngine
        playerNode = newPlayerNode

        isPlaying = true
        status = "ВОСПРОИЗВЕДЕНИЕ"

        if sound.type == .siren {
            startSirenAnimation()
        }
    }

    private func startSirenAnimation() {
        timer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.isPlaying {
                    self.status = self.status == "ВОСПРОИЗВЕДЕНИЕ" ? "🔴 СИРЕНА" : "ВОСПРОИЗВЕДЕНИЕ"
                }
            }
        }
        timer = newTimer
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil

        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil

        isPlaying = false
        status = "ГОТОВ"
        currentSound = nil
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}