import SwiftUI
import UIKit

// MARK: - 系统分享面板
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - 接收主界面
struct ReceiverView: View {
    @StateObject private var viewModel = ReceiverViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var fullFileName: String = ""
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var showCompletedAnimation = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.cameraManager.session)
                .edgesIgnoringSafeArea(.all)

            if viewModel.state == .completed {
                LinearGradient(
                    colors: [.black.opacity(0.7), .black.opacity(0.4), .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            }

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                Spacer()

                if viewModel.state == .scanning {
                    scanningOverlay
                } else {
                    completedOverlay
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                Spacer()

                if viewModel.state == .scanning {
                    progressBar
                        .padding(.bottom, 8)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.state == .completed)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            if viewModel.state == .completed {
                resetTransfer()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active && viewModel.state == .scanning {
                viewModel.cameraManager.start()
            }
        }
        .onChange(of: viewModel.state) { newState in
            if newState == .completed {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showCompletedAnimation = true
                }
            } else {
                showCompletedAnimation = false
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "wave.3.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.green)

            Text("ChromaStream")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var scanningOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.up")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 8)

            Text("Keep arrow pointing up\nto align with QR code on screen")
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            ZStack {
                ScanCorners()
                    .stroke(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)

                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 280, height: 280)
                    .scaleEffect(pulseScale)
                    .opacity(2 - Double(pulseScale))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                            pulseScale = 1.15
                        }
                    }
            }

            if viewModel.progress > 0 {
                Text(String(format: "%.1f%%", viewModel.progress * 100))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.progress)
            }

            Text("Point camera at the dynamic QR code\non the sender's screen")
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.4), in: Capsule())
        }
    }

    private var completedOverlay: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showCompletedAnimation ? 1.0 : 0.3)
                        .opacity(showCompletedAnimation ? 1.0 : 0)
                }

                Text("Transfer Complete")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("File successfully decoded and decompressed")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 24)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FILE NAME")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))

                        TextField("Enter file name (including extension)", text: $fullFileName)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .onAppear {
                    // 如果解码得到了原文件名，默认填充
                    if let originalName = viewModel.originalFileName {
                        fullFileName = originalName
                    }
                }

                HStack(spacing: 12) {
                    Button(action: saveAndShare) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Save / Share")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: fullFileName.isEmpty
                                    ? [.gray.opacity(0.3), .gray.opacity(0.2)]
                                    : [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: fullFileName.isEmpty ? .clear : .blue.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(fullFileName.isEmpty)

                    Button(action: resetTransfer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal, 24)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * viewModel.progress), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                    if viewModel.progress > 0.01 {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                            .shadow(color: .green.opacity(0.6), radius: 6)
                            .offset(x: max(0, geo.size.width * viewModel.progress - 5))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                    }
                }
            }
            .frame(height: 10)

            HStack {
                Text(String(format: "%.0f%%", viewModel.progress * 100))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Receiving...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private func saveAndShare() {
        guard let url = viewModel.saveFile(fullName: fullFileName) else { return }
        shareURL = url
        showShareSheet = true
    }

    private func resetTransfer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.reset()
            fullFileName = ""
            shareURL = nil
            showCompletedAnimation = false
        }
    }
}

// MARK: - 扫描框四角标记线
struct ScanCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerLength: CGFloat = 30
        let cornerRadius: CGFloat = 16

        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}
