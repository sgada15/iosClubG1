//
//  SavedProfilesView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI

struct SavedProfilesView: View {
    @EnvironmentObject var savedProfilesManager: SavedProfilesManager
    
    var body: some View {
        NavigationView {
            Group {
                if savedProfilesManager.savedProfiles.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Saved Profiles")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Save profiles you're interested in from the Explore tab to see them here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Optional: Add a button to go to explore
                        Button("Explore Profiles") {
                            // This would need to be handled by a parent view to switch tabs
                            // For now, we'll just show the button
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // List of saved profiles
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(savedProfilesManager.savedProfiles, id: \.id) { profile in
                                NavigationLink {
                                    OtherProfileDetailView(profile: profile, isCurrentUser: false)
                                } label: {
                                    SavedProfileCard(
                                        profile: profile,
                                        onUnsave: {
                                            savedProfilesManager.unsaveProfile(profile)
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Saved Profiles")
            .refreshable {
                savedProfilesManager.reloadSavedProfiles()
            }
            .onAppear {
                // Ensure saved profiles are loaded when view appears
                savedProfilesManager.reloadSavedProfiles()
            }
        }
    }
}

struct SavedProfileCard: View {
    let profile: UserProfile
    let onUnsave: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile picture
            AsyncImage(url: URL(string: profile.profilePhotoURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            }
            .frame(width: 55, height: 55)
            .clipShape(Circle())
            .shadow(radius: 2)
            
            // Info section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                if !profile.major.isEmpty || !profile.year.isEmpty {
                    Text([profile.major, profile.year].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if !profile.interests.isEmpty {
                    Text(profile.interests.prefix(3).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Unsave button
            Button(action: onUnsave) {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.accentColor)
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
