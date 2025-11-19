//
//  OnboardingSteps.swift
//  HelloGT
//
//  Created by Assistant on 11/18/25.
//

import SwiftUI

// MARK: - Welcome Step
struct WelcomeStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 12) {
                    Text("Welcome to HelloGT!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's create your profile to connect with fellow Yellow Jackets")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button("Get Started") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                
                Text("This will take about 2 minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Basic Info Step
struct BasicInfoStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var nameValid = false
    @State private var usernameValid = false
    @State private var majorValid = false
    @State private var yearValid = false
    
    private var isStepValid: Bool {
        nameValid && usernameValid && majorValid && yearValid
    }
    
    private let years = ["2025", "2026", "2027", "2028", "2029", "2030"]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("Basic Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Help other Yellow Jackets find you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Form
            VStack(spacing: 20) {
                ValidatedTextField(
                    title: "Full Name",
                    text: $profile.name,
                    isValid: $nameValid,
                    validation: { !$0.isEmpty },
                    placeholder: "John Doe"
                )
                
                ValidatedTextField(
                    title: "Username",
                    text: $profile.username,
                    isValid: $usernameValid,
                    validation: { !$0.isEmpty && $0.count >= 3 },
                    placeholder: "johndoe"
                )
                
                ValidatedTextField(
                    title: "Major",
                    text: $profile.major,
                    isValid: $majorValid,
                    validation: { !$0.isEmpty },
                    placeholder: "Computer Science"
                )
                
                YearPickerField(
                    selectedYear: $profile.year,
                    isValid: $yearValid,
                    years: years
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 20) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Continue") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!isStepValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Bio Step
struct BioStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var bioValid = false
    
    private var characterCount: Int {
        profile.bio.count
    }
    
    private var isStepValid: Bool {
        bioValid && characterCount >= 20
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("Tell Us About Yourself")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Write a brief bio to help others get to know you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            // Form
            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 120)
                    
                    TextEditor(text: $profile.bio)
                        .padding(12)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                        .onChange(of: profile.bio) { _ in
                            bioValid = !profile.bio.isEmpty
                        }
                    
                    if profile.bio.isEmpty {
                        Text("Share your interests, what you're studying, or what you love about GT...")
                            .foregroundColor(.secondary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
                
                HStack {
                    Text("\(characterCount)/20 minimum")
                        .font(.caption)
                        .foregroundColor(characterCount >= 20 ? .green : .secondary)
                    
                    Spacer()
                    
                    if characterCount >= 20 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 20) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Continue") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!isStepValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Helper Components
struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    @Binding var isValid: Bool
    let validation: (String) -> Bool
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) { newValue in
                    isValid = validation(newValue)
                }
                .onAppear {
                    isValid = validation(text)
                }
        }
    }
}

struct YearPickerField: View {
    @Binding var selectedYear: String
    @Binding var isValid: Bool
    let years: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Graduation Year")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }
            
            Menu {
                ForEach(years, id: \.self) { year in
                    Button(year) {
                        selectedYear = year
                        isValid = true
                    }
                }
            } label: {
                HStack {
                    Text(selectedYear.isEmpty ? "Select graduation year" : selectedYear)
                        .foregroundColor(selectedYear.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .onAppear {
            isValid = !selectedYear.isEmpty
        }
    }
}

// MARK: - Interests Step
struct InterestsStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var newInterest = ""
    
    private var isStepValid: Bool {
        profile.interests.count >= 2
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("Your Interests")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add at least 2 interests to help others connect with you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            // Form
            VStack(spacing: 20) {
                // Add new interest
                HStack {
                    TextField("Add an interest", text: $newInterest)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        guard !newInterest.isEmpty,
                              !profile.interests.contains(newInterest) else { return }
                        profile.interests.append(newInterest)
                        newInterest = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newInterest.isEmpty)
                }
                
                // Current interests
                if !profile.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Interests (\(profile.interests.count)/2+ required)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if isStepValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.subheadline)
                            }
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(profile.interests, id: \.self) { interest in
                                InterestChip(
                                    text: interest,
                                    onRemove: {
                                        profile.interests.removeAll { $0 == interest }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 20) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Continue") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!isStepValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Clubs Step
struct ClubsStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var newClub = ""
    
    private var isStepValid: Bool {
        profile.clubs.count >= 1
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("Your Clubs")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add at least 1 club or organization you're part of")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            // Form
            VStack(spacing: 20) {
                // Add new club
                HStack {
                    TextField("Add a club or organization", text: $newClub)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Add") {
                        guard !newClub.isEmpty,
                              !profile.clubs.contains(newClub) else { return }
                        profile.clubs.append(newClub)
                        newClub = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newClub.isEmpty)
                }
                
                // Current clubs
                if !profile.clubs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Clubs (\(profile.clubs.count)/1+ required)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if isStepValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.subheadline)
                            }
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(profile.clubs, id: \.self) { club in
                                InterestChip(
                                    text: club,
                                    onRemove: {
                                        profile.clubs.removeAll { $0 == club }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 20) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Continue") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!isStepValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Personality Step
struct PersonalityStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    let isCompleting: Bool
    
    private var isStepValid: Bool {
        profile.personalityAnswers.allSatisfy { !$0.isEmpty }
    }
    
    private let questions = [
        "What do you do in your free time?",
        "What are 3 words to describe yourself?",
        "What are you passionate about?",
        "What is your favorite study spot?"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Personality Questions")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Help others get to know the real you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
                
                // Questions
                VStack(spacing: 24) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        OnboardingPersonalityQuestion(
                            number: index + 1,
                            question: questions[index],
                            answer: Binding(
                                get: {
                                    profile.personalityAnswers.count > index ? profile.personalityAnswers[index] : ""
                                },
                                set: { newValue in
                                    ensurePersonalityAnswersSize()
                                    profile.personalityAnswers[index] = newValue
                                }
                            )
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 100)
                
                // Navigation
                HStack(spacing: 20) {
                    Button("Back") {
                        onBack()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(isCompleting)
                    
                    Button(isCompleting ? "Creating Profile..." : "Complete Profile") {
                        onNext()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(!isStepValid || isCompleting)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func ensurePersonalityAnswersSize() {
        while profile.personalityAnswers.count < 4 {
            profile.personalityAnswers.append("")
        }
    }
}

// MARK: - Helper Components
struct InterestChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.subheadline)
                .lineLimit(1)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

struct OnboardingPersonalityQuestion: View {
    let number: Int
    let question: String
    @Binding var answer: String
    
    private var isValid: Bool {
        !answer.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(number). \(question)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }
            
            TextField("Your answer...", text: $answer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }
}