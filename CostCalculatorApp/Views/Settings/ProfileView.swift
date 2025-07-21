//
//  ProfileView.swift
//  CostCalculatorApp
//
//  Created by Claude on 2024-07-15.
//

import SwiftUI

struct ProfileView: View {
    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var showingCloudKitSettings = false
    @State private var showingLanguageSettings = false
    @State private var languageChanged = false
    @StateObject private var cloudKitSettings = CloudKitSettingsManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("settings".localized())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)
                
                // Settings List
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "gear",
                        title: "app_settings".localized(),
                        subtitle: "app_settings_subtitle".localized(),
                        action: { showingSettings = true }
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        icon: "globe",
                        title: "language_settings".localized(),
                        subtitle: "language_subtitle".localized(),
                        action: { showingLanguageSettings = true }
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "about_app".localized(),
                        subtitle: "about_app_subtitle".localized(),
                        action: { showingAbout = true }
                    )
                    
                    Divider()
                    
                    CloudKitSettingsRow(
                        cloudKitSettings: cloudKitSettings,
                        action: { showingCloudKitSettings = true }
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        icon: "envelope",
                        title: "feedback".localized(),
                        subtitle: "feedback_subtitle".localized(),
                        action: { }
                    )
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Version Info
                VStack(spacing: 5) {
                    Text("cost_calculator".localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("version".localized())
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .id(languageManager.currentLanguage.rawValue)
        .sheet(isPresented: $showingSettings) {
            AppSettingsView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingCloudKitSettings) {
            CloudKitSettingsView()
        }
        .sheet(isPresented: $showingLanguageSettings) {
            LanguageSettingsView()
        }
        .alert("restart_required".localized(), isPresented: $cloudKitSettings.showRestartAlert) {
            Button("ok".localized()) {
                cloudKitSettings.showRestartAlert = false
            }
        } message: {
            Text("icloud_note3".localized())
        }
        .alert("restart_required".localized(), isPresented: $languageManager.showRestartAlert) {
            Button("ok".localized()) {
                languageManager.showRestartAlert = false
            }
        } message: {
            Text("restart_message".localized())
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
        .onReceive(LanguageManager.shared.$refreshUI) { _ in
            languageChanged.toggle()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var languageChanged = false
    
    var body: some View {
NavigationView {
            VStack {
                Text("app_settings".localized())
                    .font(.title)
                    .padding()
                
                // Settings content will be implemented here
                Text("settings_under_development".localized())
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("settings".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized()) {
                        dismiss()
                    }
                }
            }
        }
        .id(LanguageManager.shared.currentLanguage.rawValue)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
        .onReceive(LanguageManager.shared.$refreshUI) { _ in
            languageChanged.toggle()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var languageChanged = false
    
    var body: some View {
NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "app.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("cost_calculator".localized())
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("version".localized())
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("features".localized())
                        .font(.headline)
                    
                    Text("feature_cost_calculation".localized())
                    Text("feature_multi_material".localized())
                    Text("feature_cloud_sync".localized())
                    Text("feature_history".localized())
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(10)
                
                Spacer()
                
                Text("copyright".localized())
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding()
            .navigationTitle("about".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized()) {
                        dismiss()
                    }
                }
            }
        }
        .id(LanguageManager.shared.currentLanguage.rawValue)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
        .onReceive(LanguageManager.shared.$refreshUI) { _ in
            languageChanged.toggle()
        }
    }
}

struct CloudKitSettingsRow: View {
    @ObservedObject var cloudKitSettings: CloudKitSettingsManager
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "icloud")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("data_sync".localized())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(cloudKitSettings.cloudKitStatusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(cloudKitSettings.cloudKitStatus)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct CloudKitSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cloudKitSettings = CloudKitSettingsManager.shared
    @State private var languageChanged = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Section
                VStack(spacing: 15) {
                    Image(systemName: "icloud")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("icloud_sync".localized())
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(cloudKitSettings.cloudKitStatusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(cloudKitSettings.cloudKitStatus)
                            .font(.headline)
                            .foregroundColor(cloudKitSettings.cloudKitStatusColor)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Settings Section
                VStack(spacing: 0) {
                    if cloudKitSettings.isCloudKitAvailable {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("enable_icloud".localized())
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("icloud_description".localized())
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $cloudKitSettings.isCloudKitEnabled)
                                    .labelsHidden()
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("explanation".localized())
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text("icloud_note1".localized())
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text("icloud_note2".localized())
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text("icloud_note3".localized())
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(20)
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("icloud_unavailable".localized())
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Text("icloud_login_required".localized())
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("open_settings".localized()) {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(20)
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("data_sync".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized()) {
                        dismiss()
                    }
                }
            }
        }
        .id(LanguageManager.shared.currentLanguage.rawValue)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
        .onReceive(LanguageManager.shared.$refreshUI) { _ in
            languageChanged.toggle()
        }
    }
}

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 15) {
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("language_settings".localized())
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("language_subtitle".localized())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Language Selection
                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        HStack {
                            Text(language.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            languageManager.setLanguage(language)
                        }
                        
                        if language != AppLanguage.allCases.last {
                            Divider()
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("language".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("back".localized()) {
                        dismiss()
                    }
                }
            }
        }
        .id(languageManager.currentLanguage.rawValue)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}