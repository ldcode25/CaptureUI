//
//  MainView.swift
//  Camera
//
//  Created by Yoshimasa Niwa on 4/1/25.
//

import AVKit
import CaptureUI
import Logger
import SwiftUI

struct MainView: View {
    @State
    private var isEnabled: Bool = true
    @State
    private var isRunning: Bool = false

    @State
    private var captureDevice: CaptureDevice = .backCamera

    private enum CaptureState: Equatable {
        case inProgress
        case captured(uiImage: UIImage)
        case recorded(player: AVPlayer)
    }

    @State
    private var captureState: CaptureState?

    @State
    private var isPreviewPresented: Bool = false

    var body: some View {
        CaptureSession(isEnabled: isEnabled, isRunning: $isRunning) {
            ZStack {
                CapturePreviewView(device: captureDevice)
                    .blur(radius: isRunning ? 0.0 : 10.0, opaque: true)
                    .ignoresSafeArea()

                CaptureOutput(device: captureDevice) { output in
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()

                            CaptureButton {
                                Task {
                                    do {
                                        captureState = .inProgress
                                        let image = try await output.capture()
                                        let uiImage = try await Task.detached {
                                            try image.renderUIImage()
                                        }.value
                                        captureState = .captured(uiImage: uiImage)
                                    } catch {
                                        log(error: error)
                                        captureState = nil
                                    }
                                }
                            } longPressChanged: { isLongPressing in
                                if isLongPressing {
                                    Task {
                                        do {
                                            let url = try await output.startRecording()
                                            let player = AVPlayer(url: url)
                                            captureState = .recorded(player: player)
                                        } catch {
                                            log(error: error)
                                            captureState = nil
                                        }
                                    }
                                } else {
                                    captureState = .inProgress
                                    output.stopRecording()
                                }
                            }
                            .accessibilityLabel("Capture")
                            .frame(width: 60.0, height: 60.0)
                            .disabled(captureState != nil)

                            Spacer()
                                .overlay {
                                    Button {
                                        captureDevice.toggle()
                                    } label: {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30.0, height: 30.0)
                                            .padding(8.0)
                                            .background {
                                                Circle()
                                                    .fill(.regularMaterial)
                                            }
                                    }
                                    .foregroundColor(.primary)
                                    .accessibilityLabel("Toggle")
                                }
                        }
                    }
                }
                .onChange(of: captureState) { _, captureState in
                    switch captureState {
                    case .captured, .recorded:
                        isPreviewPresented = true
                    default:
                        break
                    }
                }
                .sheet(isPresented: $isPreviewPresented) {
                    switch captureState {
                    case .captured(uiImage: let uiImage):
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .containerRelativeFrame(.horizontal) { size, _ in
                                size
                            }
                            .ignoresSafeArea()
                    case .recorded(player: let player):
                        VideoPlayer(player: player)
                            .ignoresSafeArea()
                            .onAppear {
                                Task {
                                    // Wait for the sheet is presenting.
                                    // I know this is not good way to wait for that.
                                    try await Task.sleep(nanoseconds: 300_000_000)
                                    player.play()
                                }
                            }
                    default:
                        // Must not reach here.
                        EmptyView()
                    }
                }
                .onChange(of: isPreviewPresented) { _, isPreviewPresented in
                    if isPreviewPresented {
                        isEnabled = false
                    } else {
                        isEnabled = true
                        captureState = nil
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}
