//
//  MainTabView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            SavedProfilesView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }

            MyProfileView()
                .tabItem {
                    Label("My Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.accentColor)
    }
}
