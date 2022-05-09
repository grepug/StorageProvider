//
//  iCloudSettingsView.swift
//  Vision 3
//
//  Created by Kai on 2021/12/29.
//

import SwiftUI
import Combine
import CloudKitSyncMonitor

public struct iCloudSettingsView: View {
    @ObservedObject var vcWrapper: ViewControllerWrapper
    var config: Config
    
    @AppStorage("iCloudEnabled") private var isUserEnabled = false
    @ObservedObject private var syncMonitor = SyncMonitor.shared
    
    @State private var showingAlertMessage: AlertMessage?
    
    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    var isAccountAvailable: Bool {
        syncMonitor.iCloudAccountStatus == .available
    }
    
    var isPro: Bool {
        (syncMonitor as? SyncMonitorWithCloudKit)?.isPro ?? false
    }
    
    var isCloudEnabled: Bool {
        (syncMonitor as? SyncMonitorWithCloudKit)?.isCloudEnabled ?? false
    }
    
    enum AlertMessage: String, Identifiable {
        case cannotDisable = "settings_icloud_footer_disable"
        case notAvailiable = "settings_icloud_footer_enable_in_system_settings"
        
        var id: String { rawValue }
    }

    public var body: some View {
        List {
            let isOn = Binding<Bool> {
                isCloudEnabled
            } set: { isOn in
                if isOn {
                    if isAccountAvailable {
                        enable()
                    } else {
                        showingAlertMessage = .notAvailiable
                    }
                } else {
                    showingAlertMessage = .cannotDisable
                }
            }
            
            Section {
                HStack {
                    Label(title: {
                        Text("action_enable")
                    }, icon: {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                    })
                    
                    Spacer()
                    
                    Button("") {}
                        .alert(item: $showingAlertMessage) { message in
                            Alert(title: Text("action_title_caution"),
                                  message: Text(message.rawValue.loc))
                        }
                        .opacity(0)
                        .buttonStyle(.plain)
                    
                    Toggle("", isOn: isOn)
                }
            }
            
            if isCloudEnabled {
                iCloudSyncStatus
            }
        }
        .listStyle(.insetGrouped)
        .onReceive(config.isProSubject, perform: { _ in
            vcWrapper.objectWillChange.send()
        })
    }
}

extension iCloudSettingsView {
    var iCloudSyncStatus: some View {
        Section {
            HStack {
                Text("settings_icloud_status")
                Spacer()
                HStack {
                    Text(syncMonitor.syncStateSummary.text)
                        .foregroundColor(.secondary)
                    Image(systemName: syncMonitor.syncStateSummary.symbolName)
                        .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
                }
            }
            
            stateTextView("settings_icloud_state_title_setup", for: syncMonitor.setupState)
            stateTextView("settings_icloud_state_title_import", for: syncMonitor.importState)
            stateTextView("settings_icloud_state_title_export", for: syncMonitor.exportState)
            
            if syncMonitor.syncStateSummary.isBroken {
                Image(systemName: syncMonitor.syncStateSummary.symbolName)
                    .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
            }
        } footer: {
            Text("settings_icloud_footer_failed")
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.secondary)
                .font(.footnote)
        }
        .onReceive(timer) { _ in
            syncMonitor.objectWillChange.send()
        }
    }
    
    func stateTextView(_ title: LocalizedStringKey, for state: SyncMonitor.SyncState) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(stateText(for: state))
                .foregroundColor(.secondary)
        }
    }
    
    func stateText(for state: SyncMonitor.SyncState) -> String {
        switch state {
        case .notStarted:
            return "settings_icloud_state_notStarted".loc
        case .inProgress(started: let date):
            return "\("settings_icloud_state_inProgress".loc) \(dateFormatted(from: date))"
        case let .succeeded(started: _, ended: endDate):
            return "\("settings_icloud_state_succeeded".loc) \(dateFormatted(from: endDate))"
        case let .failed(started: _, ended: endDate, error: _):
            return "\("settings_icloud_state_failed".loc) \(dateFormatted(from: endDate))"
        }
    }
    
    func dateFormatted(from date: Date) -> String {
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.unitsStyle = .full
        
        return dateFormatter.localizedString(for: date, relativeTo: Date())
    }
}

extension iCloudSettingsView {
    func enable() {
        guard isPro else {
            config.presentNonProErrorAlert(vcWrapper.vc!)
            return
        }

        isUserEnabled = true
        (syncMonitor as? SyncMonitorWithCloudKit)?.iCloudToggle(iCloudEnabled: true)
    }
}

public extension iCloudSettingsView {
    static func makeViewController(withConfig config: Config) -> UIViewController {
        let vcWrapper = ViewControllerWrapper()
        let rootView = iCloudSettingsView(vcWrapper: vcWrapper, config: config)
        let vc = UIHostingController(rootView: rootView)
        
        vc.title = "iCloud"
        vcWrapper.vc = vc
        
        return vc
    }
    
    struct Config {
        public init(isProSubject: PassthroughSubject<Bool, Never>, presentNonProErrorAlert: @escaping (UIViewController) -> Void) {
            self.isProSubject = isProSubject
            self.presentNonProErrorAlert = presentNonProErrorAlert
        }
        
        var isProSubject: PassthroughSubject<Bool, Never>
        var presentNonProErrorAlert: (UIViewController) -> Void
    }
}

extension SyncMonitor.SyncSummaryStatus {
    var text: String {
        switch self {
        case .inProgress: return "settings_icloud_SyncSummaryStatus_inProgress".loc
        case .error: return "settings_icloud_SyncSummaryStatus_error".loc
        case .accountNotAvailable: return "settings_icloud_SyncSummaryStatus_accountNotAvailable".loc
        case .notSyncing: return "settings_icloud_SyncSummaryStatus_notSyncing".loc
        case .noNetwork: return "settings_icloud_SyncSummaryStatus_noNetwork".loc
        case .succeeded: return "settings_icloud_SyncSummaryStatus_succeeded".loc
        case .notStarted: return "settings_icloud_SyncSummaryStatus_notStarted".loc
        case .unknown: return "settings_icloud_SyncSummaryStatus_unknown".loc
        }
    }
}
