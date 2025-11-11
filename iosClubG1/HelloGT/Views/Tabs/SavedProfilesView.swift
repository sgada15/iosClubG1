//
//  SavedProfilesView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct SavedProfile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bio: String
    let dateSaved: Date
    let imageName: String
}

struct SavedProfilesView: View {
    @State private var savedProfiles: [SavedProfile] = [
        SavedProfile(name: "Ava Patel",
                     bio: "Biomedical Engineering major passionate about research and volunteering.",
                     dateSaved: Date(),
                     imageName: "person1"),
        SavedProfile(name: "Liam Chen",
                     bio: "CS major who loves hackathons, startups, and bubble tea.",
                     dateSaved: Date().addingTimeInterval(-86400),
                     imageName: "person2"),
        SavedProfile(name: "Nia Roberts",
                     bio: "Psych major exploring mental health advocacy and art therapy.",
                     dateSaved: Date().addingTimeInterval(-172800),
                     imageName: "person3")
    ]
    
    @State private var profileToDelete: SavedProfile? = nil
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(savedProfiles) { profile in
                        SavedProfileCard(profile: profile) {
                            profileToDelete = profile
                            showDeleteAlert = true
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .leading)) // 👈 slides LEFT when deleted
                        ))
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Saved Profiles")
            .animation(.easeInOut(duration: 0.3), value: savedProfiles)
            .alert("Delete Profile?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let profile = profileToDelete {
                        delete(profile)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let profile = profileToDelete {
                    Text("Are you sure you want to delete \(profile.name)’s profile?")
                } else {
                    Text("Are you sure you want to delete this profile?")
                }
            }
        }
    }
    
    private func delete(_ profile: SavedProfile) {
        withAnimation {
            savedProfiles.removeAll { $0.id == profile.id }
        }
    }
}

struct SavedProfileCard: View {
    let profile: SavedProfile
    let onDeleteTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile picture
            Image(profile.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 55, height: 55)
                .clipShape(Circle())
                .shadow(radius: 2)
            
            // Info section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(profile.name)
                        .font(.headline)
                    Spacer()
                    Text(profile.dateSaved, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(profile.bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Trash button
            Button(action: onDeleteTapped) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}
