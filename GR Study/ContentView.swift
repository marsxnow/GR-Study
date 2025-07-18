//
//  ContentView.swift
//  GR Study
//
//  Created by rax  on 7/17/25.
//

import SwiftUI
import Foundation

@main
struct GoldenRatioStudyApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                SignInView(authManager: authManager)
            }
        }
    }
}

// Mark: Data Models
struct StudyMethod {
    let name: String
    let studyMinutes: Int
    let breakMinutes: Int
    let description: String
    let icon: String
}

class StudySession: ObservableObject {
    @Published var isStudyPhase = true
    @Published var isRunning = false
    @Published var remainingSeconds = 0
    @Published var sessionNumber = 1
    @Published var totalStudyMinutes = 0
    @Published var totalBreakMinutes = 0
    
    let method: StudyMethod
    private var timer: Timer?
    
    init(method: StudyMethod) {
        self.method = method
        self.remainingSeconds = method.studyMinutes * 60
    }
    
    func start() {
        isRunning = true
        startTimer()
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
    }
    
    func resume() {
        isRunning = true
        startTimer()
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
    }
    
    func skipPhase() {
        timer?.invalidate()
        switchPhase()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.switchPhase()
            }
        }
    }
    
    private func switchPhase() {
        timer?.invalidate()
        
        if isStudyPhase {
            totalStudyMinutes += method.studyMinutes
            isStudyPhase = false
            remainingSeconds = method.breakMinutes * 60
        } else {
            totalBreakMinutes += method.breakMinutes
            isStudyPhase = true
            remainingSeconds = method.studyMinutes * 60
            sessionNumber += 1
        }
        
        if isRunning {
            startTimer()
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var studySession: StudySession?
    @State private var selectedMethod: StudyMethod?
    @State private var showingSession = false
    @State private var showingProfile = false
    
    private lazy var profileManager = ProfileManager(authManager: authManager)
    
    let studyMethods = [
        StudyMethod(
            name: "Classic Golden Timer",
            studyMinutes: 62,
            breakMinutes: 38,
            description: "62min study : 38min break",
            icon: "timer"
        ),
        StudyMethod(
            name: "Quick Golden Sessions",
            studyMinutes: 25,
            breakMinutes: 15,
            description: "25min study : 15min break",
            icon: "bolt.fill"
        ),
        StudyMethod(
            name: "Deep Focus Golden",
            studyMinutes: 90,
            breakMinutes: 56,
            description: "90min study : 56min break",
            icon: "brain.head.profile"
        )
    ]
    
    var body: some View {
        NavigationView {
            if showingSession, let session = studySession {
                StudySessionView(session: session) {
                    endSession()
                }
            } else {
                methodSelectionView
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var methodSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                VStack(spacing: 16) {
                    Text("Choose Your Study Method")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        
                    
                    ForEach(studyMethods, id: \.name) { method in
                        MethodCard(method: method) {
                            startStudySession(method: method)
                        }
                    }
                }
                
                goldenRatioInfoView
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Golden Ratio Study")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingProfile = true
                }) {
                    ProfilePictureView(
                        imageURL: authManager.currentUser?.profilePictureURL,
                        size: 32,
                        borderWidth: 2
                    )
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(authManager: authManager, profileManager: profileManager)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Golden Ratio Study Method")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text("Based on the golden ratio (φ ≈ 1.618:1)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private var goldenRatioInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("Golden Ratio Benefits")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                BenefitRow(text: "Optimizes focus and rest periods")
                BenefitRow(text: "Prevents mental fatigue")
                BenefitRow(text: "Maintains long-term motivation")
                BenefitRow(text: "Based on natural proportions")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func startStudySession(method: StudyMethod) {
        let session = StudySession(method: method)
        studySession = session
        showingSession = true
        session.start()
    }
    
    private func endSession() {
        studySession?.stop()
        studySession = nil
        showingSession = false
    }
}

// MARK: - Method Card Component
struct MethodCard: View {
    let method: StudyMethod
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(.orange)
                    .frame(width: 40)
                    
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(method.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Study Session View
struct StudySessionView: View {
    @ObservedObject var session: StudySession
    let onEndSession: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            phaseIndicator
            
            timerDisplay
            
            sessionControls
            
            sessionStats
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    private var phaseIndicator: some View {
        VStack(spacing: 16) {
            Text(session.isStudyPhase ? "STUDY TIME" : "BREAK TIME")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(session.isStudyPhase ? .green : .blue)
            
            Text("Session \(session.sessionNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private var timerDisplay: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(1 - Double(session.remainingSeconds) / Double(session.isStudyPhase ? session.method.studyMinutes * 60 : session.method.breakMinutes * 60)))
                    .stroke(
                        session.isStudyPhase ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: session.remainingSeconds)
                
                Text(formatTime(session.remainingSeconds))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(session.isStudyPhase ? .green : .blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private var sessionControls: some View {
        HStack(spacing: 20) {
            Button(action: {
                session.isRunning ? session.pause() : session.resume()
            }) {
                Label(session.isRunning ? "Pause" : "Resume",
                      systemImage: session.isRunning ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            
            Button(action: session.skipPhase) {
                Label("Skip", systemImage: "forward.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
//                    .buttonStyle(.glass)
            }
            
            Button(action: onEndSession) {
                Label("End", systemImage: "stop.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
    }
    
    private var sessionStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                StatItem(title: "Study Time", value: "\(session.totalStudyMinutes) min")
                Spacer()
                StatItem(title: "Break Time", value: "\(session.totalBreakMinutes) min")
                Spacer()
                StatItem(title: "Sessions", value: "\(session.sessionNumber)")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Helper Components
struct BenefitRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
