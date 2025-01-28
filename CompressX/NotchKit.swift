//
//  NotchKit.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 01/03/2024.
//

import SwiftUI

class NotchKit {

  static let WIDTH: CGFloat = 354

  var workItem: DispatchWorkItem?

  static var shared = NotchKit()

  var notchWindow: NSWindow?
  var notchView: NotchView?

  func show(folderPath: String, notchStyle: NotchStyle, dismissDelay: TimeInterval? = nil) {
    let frame = NSRect(
      x: ((NSScreen.main?.frame.width ?? 0) - NotchKit.WIDTH) / 2 + (NSScreen.main?.frame.origin.x ?? 0),
      y: (NSScreen.main?.frame.height ?? 0) + (NSScreen.main?.frame.origin.y ?? 0) - 100,
      width: NotchKit.WIDTH,
      height: 100
    )
    if self.notchWindow != nil {
      notchWindow?.setFrameOrigin(frame.origin)
      return
    }
    let window = NSWindow()
    let onClose: () -> Void = { [weak self] in
      self?.close()
    }
    let notchView = NotchView(
      hasNotch: hasNotch,
      folderPath: folderPath,
      onClose: onClose,
      notchStyle: notchStyle,
      dismissDelay: dismissDelay
    )
    let view = NSHostingView(rootView: notchView)
    window.contentView = view
    window.level = .screenSaver
    window.backgroundColor = NSColor.clear
    window.styleMask = [.borderless]
    window.backingType = .buffered
    window.setFrame(frame, display: true)
    window.orderFront(nil)
    window.isReleasedWhenClosed = false
    self.notchWindow = window
    self.notchView = notchView
  }

  func dismiss() {
    notchView?.dismiss()
  }

  func close() {
    notchWindow?.contentView = nil
    notchWindow?.close()
    notchWindow = nil
    notchView = nil
  }
}

struct CornerShape: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: .zero)
      path.addCurve(
        to: CGPoint(x: 12, y: 12),
        control1: CGPoint(x: 12, y: 0),
        control2: CGPoint(x: 12, y: 12))
      path.addLine(to: CGPoint(x: 12, y: 0))

      path.addLine(to: .zero)
      path.closeSubpath()
    }
  }
}

struct NotchView: View {

  @ObservedObject var jobManager = HUDJobManager.shared

  @State private var scale = 0.5
  @State private var offset = 47.5
  @State private var alpha = 1.0
  @State private var isMinimized = false
  @State private var workItem: DispatchWorkItem?
  @State private var autoDismissWorkItem: DispatchWorkItem?

  var hasNotch: Bool
  var folderPath: String
  var onClose: () -> Void
  var notchStyle: NotchStyle
  var dismissDelay: TimeInterval?

  var progressCount: String {
    let current = jobManager.currentIndex ?? jobManager.jobs.count
    let total = jobManager.jobs.count
    return "\(current)/\(total)"
  }

  var bottomText: String {
    if jobManager.isRunning {
      return jobManager.currentJob?.inputFileURL.lastPathComponent ?? ""
    } else {
      if jobManager.jobs.count > 1 {
        return "Saved to \(folderPath)"
      }
      return "Saved as " + (jobManager.jobs.last?.outputFileURL.lastPathComponent ?? "")
    }
  }

  var bottomRightText: String? {
    if jobManager.isRunning {
      return fileSizeString(from: jobManager.currentJob?.inputFileSize)
    } else {
      if jobManager.jobs.count > 1 {
        return nil
      }
      return fileSizeString(from: jobManager.jobs.last?.outputFileSize)
    }
  }

  var body: some View {
    VStack {
      HStack(spacing: 0) {
        Spacer(minLength: 0)
          .background(.clear)
        CornerShape()
          .fill(Color.black)
          .frame(width: 12, height: notchStyle == .compact || isMinimized ? 32 : 87)
        VStack {
          HStack(spacing: 0) {
            Text(progressCount)
            if !(isMinimized || notchStyle == .compact) {
              Text(jobManager.jobs.count > 1 ? " files" : " file")
                .transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
            }
            Spacer()
            if jobManager.isRunning {
              Text("\(Int(jobManager.currentProgress * 100))%")
            } else {
              Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14, alignment: .center)
            }
          }
          .foregroundStyle(.white)
          .opacity(alpha)
          .onTapGesture {
            withAnimation(.spring()) {
              isMinimized = false
            }
          }
          if !(isMinimized || notchStyle == .compact) {
            VStack {
              HStack {
                if (jobManager.currentJob?.isMKV ?? false) || (jobManager.currentJob?.isPdf ?? false) {
                  ProgressView()
                    .progressViewStyle(.linear)
                    .preferredColorScheme(.dark)
                } else {
                  ProgressView(value: jobManager.currentProgress, total: 1)
                    .progressViewStyle(.linear)
                    .preferredColorScheme(.dark)
                }

                if jobManager.isRunning {
                  Button(action: {
                    dismiss()
                    jobManager.terminate()
                  }, label: {
                    Image(systemName: "xmark.circle.fill")
                  })
                  .buttonStyle(.plain)
                  .foregroundStyle(.white)
                }
              }
              .opacity(alpha)
              .animation(.spring(), value: jobManager.isRunning)
              .transition(.asymmetric(insertion: .push(from: .top).combined(with: .opacity), removal: .push(from: .bottom).combined(with: .opacity)))
              HStack {
                if jobManager.isRunning {
                  Button(action: {
                    withAnimation(.spring()) {
                      isMinimized = true
                    }
                  }, label: {
                    Image(systemName: "chevron.up")
                  })
                  .buttonStyle(.plain)
                  .foregroundStyle(.white)
                  .transition(.asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
                }
                Text(bottomText)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .foregroundStyle(.gray)
                  .lineLimit(1)
                  .truncationMode(.middle)
                  .opacity(alpha)
                  .onTapGesture {
                    if !jobManager.isRunning {
                      NSWorkspace.shared.activateFileViewerSelecting(jobManager.jobs.map { $0.outputFileURL} )
                      dismiss()
                    }
                  }
                if let text = bottomRightText {
                  Text(text)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                    .opacity(alpha)
                }
              }
            }
            .transition(.asymmetric(insertion: .push(from: .top).combined(with: .opacity), removal: .push(from: .bottom).combined(with: .opacity)))
          }
        }
        .padding(.top, 8)
        .padding(.horizontal, notchStyle == .compact || isMinimized ? 8 : 16)
        .padding(.bottom, notchStyle == .compact || isMinimized ? 8 : 16)
        .background(
          UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: notchStyle == .compact || isMinimized ? 8 : 16,
            bottomTrailingRadius: notchStyle == .compact || isMinimized ? 8 : 16,
            topTrailingRadius: 0,
            style: .continuous
          )
          .fill(Color.black)
        )
        .frame(width: NotchKit.WIDTH - 12*2 - (notchStyle == .compact || isMinimized ? 64 : 0))
        CornerShape()
          .fill(Color.black)
          .frame(width: 12, height: notchStyle == .compact || isMinimized ? 32 : 87)
          .rotation3DEffect(
            .degrees(180),
            axis: (x: 0.0, y: 1.0, z: 0.0)
          )
        Spacer(minLength: 0)
          .background(.clear)
      }
      Spacer(minLength: 0)
        .background(.clear)
    }
    .scaleEffect(scale)
    .offset(x: 0, y: -offset)
    .task {
      appear()
      if let delay = dismissDelay {
        autoDismissWorkItem = DispatchWorkItem {
          dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: autoDismissWorkItem!)
      }
    }
    .onChange(of: jobManager.isRunning) { newValue in
      if newValue == false {
        workItem = DispatchWorkItem {
          dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem!)
      } else {
        workItem?.cancel()
        workItem = nil
      }
    }
  }

  func appear() {
    withAnimation(.spring()) {
      scale = 1.0
      offset = 0
      alpha = 1.0
    }
  }

  func dismiss() {
    autoDismissWorkItem?.cancel()
    withAnimation(.spring()) {
      if hasNotch {
        scale = 0.5
        offset = 47.5
      } else {
        scale = 0.1
        offset = 47.5 * 2
      }
      alpha = 0.0
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      onClose()
    }
  }
}
