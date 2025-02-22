//
//  CompressXApp.swift
//  CompressX
//
//  Created by Dinh Quang Hieu on 18/11/2023.
//

import SwiftUI
import TelemetryClient
import Sparkle
import SettingsAccess
import UserNotifications
import Cocoa
import ImageIO
import UniformTypeIdentifiers
import KeyboardShortcuts

let telemetryConfiguration = TelemetryManagerConfiguration(appID: "")

@main
struct CompressXApp: App {

  @Environment(\.openWindow) var openWindow
  @Environment(\.colorScheme) var colorScheme

  @FocusState private var isFocused: Bool

  @AppStorage("shouldShowOnboardingV2") var shouldShowOnboardingV2 = true
  @AppStorage("shareAnonymousAnalytics") var shareAnonymousAnalytics = true
  @AppStorage("showMenuBarIcon") var showMenuBarIcon = true
  @AppStorage("selectedAppIconName") var selectedAppIconName = "AppIcon"
  @AppStorage("pinMainWindowOnTop") var pinMainWindowOnTop = false
  @AppStorage("automaticallyChecksForUpdates") var automaticallyChecksForUpdates = true
  @AppStorage("menuBarIconStyle") var menuBarIconStyle: MenuBarIconStyle = .sameAsDock

  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  private let updaterController: SPUStandardUpdaterController
  private let updater = Updater.shared

  @StateObject var installationManager = InstallationManager()

  @StateObject var keyboardShortcutsManager = KeyboardShortcutsManager()

  init() {
    updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: updater, userDriverDelegate: nil)
    updater.updater = updaterController.updater
    updaterController.updater.automaticallyChecksForUpdates = false
    updaterController.updater.automaticallyDownloadsUpdates = false
    telemetryConfiguration.analyticsDisabled = !shareAnonymousAnalytics
    TelemetryDeck.initialize(config: telemetryConfiguration)
    if automaticallyChecksForUpdates {
      updater.checkForUpdates()
    }
    updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
  }

  var body: some Scene {
    Window("Compresto", id: "mainWindow") {
      if shouldShowOnboardingV2 {
        OnboardingView()
          .environmentObject(installationManager)
      } else if installationManager.isMissingDependencies {
        UpdateDependenciesView()
          .environmentObject(installationManager)
      } else {
        if #available(macOS 14.0, *) {
          CompressView()
            .focusable()
            .focused($isFocused)
            .focusEffectDisabled()
            .onKeyPress(action: { keyPress in
              if keyPress.modifiers == .command && keyPress.characters == "v" {
                handlePressPaste()
                return .handled
              }
              return .ignored
            })
            .fontDesign(.rounded)
            .task {
              isFocused = true
              await LicenseManager.shared.validate()
            }

            .onChange(of: pinMainWindowOnTop, perform: { newValue in
              updateWindowLevel()
            })
        } else {
          CompressView()
            .fontDesign(.rounded)
            .task {
              await LicenseManager.shared.validate()
            }
            .onChange(of: pinMainWindowOnTop, perform: { newValue in
              updateWindowLevel()
            })
        }
      }
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(shouldShowOnboardingV2 || installationManager.isMissingDependencies ? .contentSize : .automatic)
    .commands {
      CommandGroup(replacing: .newItem, addition: { })
      CommandGroup(replacing: .appInfo) {
        Button("About Compresto") {
          NSApplication.shared.orderFrontStandardAboutPanel(
            options: [
              NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2024 Dinh Quang Hieu"
            ]
          )
        }
      }
      CommandGroup(after: .appSettings) {
        Button("Compression history") {
          openWindow(id: "compressionHistory")
        }
        .keyboardShortcut("Y")
      }
      if #available(macOS 14.0, *) {
      } else {
        CommandGroup(replacing: CommandGroupPlacement.pasteboard) {
          PasteButton(supportedTypes: [UTType.fileURL.identifier, UTType.image.identifier]) { providers in
            handlePasteButton(providers: providers)
          }
          .keyboardShortcut("V", modifiers: [.command])
        }
      }
      CommandGroup(replacing: .help) {
        Link(destination: URL(string: "https://docs.compresto.app")!) {
          Text("📘 Documentation")
        }
        Link(destination: URL(string: "https://compresto.app/changelog")!) {
          Text("📝 Changelog")
        }
        Link(destination: URL(string: "https://t.me/+ldb3DRPCi6Y1NWNl")!) {
          Text("💬 Join Telegram community")
        }
        Link(destination: URL(string: "mailto:hieu@compresto.app")!) {
          Text("💌 Email hieu@compresto.app")
        }
      }
    }
    .handlesExternalEvents(matching: [])
    Window("Compression history", id: "compressionHistory") {
      CompressHistoryView()
        .task {
          updateWindowLevel()
        }
    }
    .windowResizability(.automatic)
    .handlesExternalEvents(matching: [])
    Settings {
      SettingsV2View(updater: updaterController.updater)
        .modifier(SettingsViewModifier())
        .task {
          updateWindowLevel()
        }
        .environmentObject(installationManager)
        .onChange(of: pinMainWindowOnTop, perform: { newValue in
          updateWindowLevel()
        })
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    MenuBarExtra(isInserted: $showMenuBarIcon) {
      MenuBarView()
    } label: {
      let imageName: String = {
        switch menuBarIconStyle {
        case .sameAsDock:
          return selectedAppIconName + "_menubar"
        case .simple:
          return "SimpleMenuBarIcon"
        }
      }()
      let image: NSImage = {
        let ratio = $0.size.height / $0.size.width
        $0.size.height = 18
        $0.size.width = 18 / ratio
        return $0
      }(NSImage(named: imageName)!)
      return Image(nsImage: image)
    }
    .menuBarExtraStyle(.menu)
    .onChange(of: keyboardShortcutsManager.mainWindowTrigger, perform: { _ in
      openWindow(id: "mainWindow")
    })
    .onChange(of: keyboardShortcutsManager.togglePinMainWindowOnTopTrigger, perform: { _ in
      pinMainWindowOnTop.toggle()
    })
  }

  private func updateWindowLevel() {
    for window in NSApplication.shared.windows {
//      print(window.title)
      if window.title != "Item-0" {
        window.level = pinMainWindowOnTop ? .floating : .normal
      }
    }
  }

  private func handlePasteButton(providers: [NSItemProvider]) {
    let group = DispatchGroup()
    var urls: [URL] = []
    for provider in providers {
      if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        group.enter()
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
          if let data = item as? Data,
             let url = URL(dataRepresentation: data, relativeTo: nil) {
            urls.append(url)
          }
          group.leave()
        }
      }
      if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
        group.enter()
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item, error) in
          if let data = item as? Data,
             let nsImage = NSImage(data: data) {
            let path = FileManager.default.temporaryDirectory.path + "/clipboard_\(Int(Date().timeIntervalSince1970)).png"
            _ = saveImageAsPNG(image: nsImage, toPath: path)
            urls.append(URL(fileURLWithPath: path))
          }
          group.leave()
        }
      }
    }
    group.notify(queue: .main, work: DispatchWorkItem(block: {
      OpenWithHandler.shared.pasteHandler?(urls)
    }))
  }

  private func handlePressPaste() {
    let pasteboardItems = NSPasteboard.general.pasteboardItems ?? []
    guard pasteboardItems.count > 0 else { return }
    var urls: [URL] = []
    for item in pasteboardItems {
      if let data = item.data(forType: .fileURL), let url = URL(dataRepresentation: data, relativeTo: nil) {
        urls.append(url)
      } else if let data = item.data(forType: .png), let nsImage = NSImage(data: data) {
        let path = FileManager.default.temporaryDirectory.path + "/clipboard_\(Int(Date().timeIntervalSince1970)).png"
        _ = saveImageAsPNG(image: nsImage, toPath: path)
        urls.append(URL(fileURLWithPath: path))
      }
    }
    DispatchQueue.main.async {
      OpenWithHandler.shared.pasteHandler?(urls)
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, UNUserNotificationCenterDelegate {

  var showDockIcon: Bool {
    return UserDefaults.standard.bool(forKey: "showDockIcon")
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    TelemetryDeck.signal("applicationDidFinishLaunching")
    for window in NSApp.windows {
      window.delegate = self
    }
    UNUserNotificationCenter.current().delegate = self
    Watcher.shared.setup()
    // init drop zone
    let _ = DropZoneManager.shared
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      if let showMainWindowAtLaunch = UserDefaults.standard.object(forKey: "showMainWindowAtLaunch") as? Bool, showMainWindowAtLaunch == false {

        NSApp.hide(nil)
        if let showDockIcon = UserDefaults.standard.object(forKey: "showDockIcon") as? Bool {
          if showDockIcon {
            NSApp.setActivationPolicy(.regular)
          } else {
            NSApp.setActivationPolicy(.accessory)
          }
        }
      }
    }
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .sound])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    if response.notification.request.identifier.hasPrefix("compress.finish"),
       response.actionIdentifier == UNNotificationDefaultActionIdentifier,
       let fileURLsString = response.notification.request.content.userInfo["fileURLs"] as? [String] {
      let urls = fileURLsString.compactMap { URL(string: $0) }
      NSWorkspace.shared.activateFileViewerSelecting(urls)
    }
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag, let window = sender.windows.first(where: { $0.title == "Compresto" }) {
      window.makeKeyAndOrderFront(self)
    }
    if showDockIcon {
      NSApp.setActivationPolicy(.regular)
    }
    return true
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    NSApp.setActivationPolicy(.accessory)
    return false
  }
  
  func applicationWillFinishLaunching(_ notification: Notification) {
    if let iconName = UserDefaults.standard.string(forKey: "selectedAppIconName"), let iconImage = NSImage(named: iconName) {
      #if !DEBUG
      changeAppIcon(image: iconImage)
      #endif
    }
    NSWindow.allowsAutomaticWindowTabbing = false
  }
  
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if sender.title == "Compresto", JobManager.shared.isRunning {
      let alert = NSAlert.init()
      alert.addButton(withTitle: "Don't close")
      alert.addButton(withTitle: "Close anyway")
      alert.messageText = "Keep this window open"
      alert.informativeText = "Close this window will terminate the compression"
      let response = alert.runModal()
      if response == NSApplication.ModalResponse.alertFirstButtonReturn {
        return false
      } else {
        DispatchQueue.global(qos: .background).async {
          JobManager.shared.terminate()
        }
        return true
      }
    }
    return true
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    if showDockIcon {
      NSApp.hide(nil)
    } else {
      NSApp.setActivationPolicy(.accessory)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      NSApp.windows.forEach {
        if $0.title == "Compresto" {
          $0.orderOut(nil)
        }
      }
      let jobs = urls.flatMap { DeeplinkParser.shared.parse(url: $0) }
      if !jobs.isEmpty {
        Watcher.shared.addJobs(jobs)
      }
    }
  }
}
