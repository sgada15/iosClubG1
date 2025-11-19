//
//  AuthenticationView.swift
//  BuzzBuddy
//
//  Created by Sanaa Gada on 11/16/25.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var isShowingSignUp = false
    
    var body: some View {
        ZStack {
            if authManager.isSignedIn {
                MainTabView()
                    .environmentObject(authManager)
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                ZStack {
                    if isShowingSignUp {
                        SignUpView(authManager: authManager) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isShowingSignUp = false
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    } else {
                        SignInView(authManager: authManager) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isShowingSignUp = true
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: authManager.isSignedIn)
    }
}

struct SignInView: View {
    let authManager: AuthenticationManager
    let onShowSignUp: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPassword = false
    @State private var resetEmail = ""
    @FocusState private var isPasswordFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.yellow.opacity(0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 60)
                        
                        // Logo and Title
                        VStack(spacing: 16) {
                            Image("beeIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            
                            Text("BuzzBuddy")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.primary)
                            
                            Text("Where the buzz at?")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Sign In Form
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                TextField("Gmail Address", text: $email)
                                    .textFieldStyle(GTTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .onSubmit { isPasswordFocused = true }
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(GTTextFieldStyle())
                                    .textContentType(.password)
                                    .focused($isPasswordFocused)
                                    .onSubmit { signIn() }
                            }
                            
                            if let errorMessage = authManager.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: signIn) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GTButtonStyle())
                            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                            
                            Button("Forgot Password?") {
                                resetEmail = email
                                showingForgotPassword = true
                            }
                            .foregroundColor(.accentColor)
                            .font(.subheadline)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        // Sign Up Link
                        VStack(spacing: 8) {
                            Text("New user?")
                                .foregroundColor(.secondary)
                            
                            Button("Create Account") {
                                onShowSignUp()
                            }
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                }
            }
        }
        .alert("Reset Password", isPresented: $showingForgotPassword) {
            TextField("Enter your Gmail address", text: $resetEmail)
            Button("Send Reset Link") {
                Task {
                    await authManager.resetPassword(email: resetEmail)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your Gmail address to receive a password reset link.")
        }
    }
    
    private func signIn() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

struct SignUpView: View {
    let authManager: AuthenticationManager
    let onShowSignIn: () -> Void
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @FocusState private var focusedField: SignUpField?
    
    enum SignUpField: Hashable {
        case firstName, lastName, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.yellow.opacity(0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)
                        
                        // Logo and Title
                        VStack(spacing: 16) {
                            Image("beeIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            
                            Text("Join BuzzBuddy")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.primary)
                            
                            Text("Where the buzz at?")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                TextField("First Name", text: $firstName)
                                    .textFieldStyle(GTTextFieldStyle())
                                    .textContentType(.givenName)
                                    .focused($focusedField, equals: .firstName)
                                    .onSubmit { focusedField = .lastName }
                                
                                TextField("Last Name", text: $lastName)
                                    .textFieldStyle(GTTextFieldStyle())
                                    .textContentType(.familyName)
                                    .focused($focusedField, equals: .lastName)
                                    .onSubmit { focusedField = .email }
                                
                                TextField("Gmail Address (@gmail.com)", text: $email)
                                    .textFieldStyle(GTTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                                    .onSubmit { focusedField = .password }
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(GTTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .password)
                                    .onSubmit { focusedField = .confirmPassword }
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(GTTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .onSubmit { signUp() }
                            }
                            
                            // Password requirements
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password Requirements:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(password.count >= 6 ? .green : .secondary)
                                        .font(.caption)
                                    Text("At least 6 characters")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(passwordsMatch ? .green : .secondary)
                                        .font(.caption)
                                    Text("Passwords match")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let errorMessage = authManager.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: signUp) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create Account")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GTButtonStyle())
                            .disabled(!canSignUp || authManager.isLoading)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        // Sign In Link
                        VStack(spacing: 8) {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Sign In") {
                                onShowSignIn()
                            }
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var passwordsMatch: Bool {
        return !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    private var canSignUp: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !email.isEmpty &&
               password.count >= 6 &&
               passwordsMatch
    }
    
    private func signUp() {
        Task {
            await authManager.signUp(email: email, password: password, firstName: firstName, lastName: lastName)
        }
    }
}

// MARK: - Custom Button and TextField Styles

struct GTButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gtGold)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GTTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gtCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gtPastelYellow.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.gtGold.opacity(0.1), radius: 2, x: 0, y: 1)
            )
    }
}

#Preview {
    AuthenticationView()
}