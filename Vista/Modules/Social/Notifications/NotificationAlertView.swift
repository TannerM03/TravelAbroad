//
//  NotificationAlertView.swift
//  Vista
//
//  Created by Tanner Macpherson on 12/13/25.
//

import Kingfisher
import SwiftUI

struct NotificationAlertView: View {
    @State var vm: NotificationAlertViewModel

    var body: some View {
        VStack {
            if vm.isLoading {
                ProgressView("Loading notifications...")
            } else if vm.notifications.isEmpty {
                emptyStateView
            } else {
                notificationList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !vm.notifications.isEmpty && vm.unreadCount > 0 {
                    Button("Mark All Read") {
                        Task {
                            await vm.markAllAsRead()
                        }
                    }
                }
            }
        }
        .background {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .task {
            await vm.fetchNotifications()
        }
        .refreshable {
            await vm.refresh()
        }
    }

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.notifications) { notification in
                    NotificationCard(notification: notification, vm: vm)
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No notifications yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("You'll see notifications here when someone follows you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotificationCard: View {
    let notification: AppNotification
    let vm: NotificationAlertViewModel

    var body: some View {
        NavigationLink(destination: OtherProfileView(selectedUserId: notification.actorUserId.uuidString)) {
            HStack(spacing: 12) {
                // Profile image
                ZStack {
                    if let imageUrl = notification.actorImageUrl, let url = URL(string: imageUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(notification.actorUsername?.prefix(1) ?? "?").uppercased())
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)
                            )
                    }

                    if notification.actorIsPopular {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white, .blue)
                            .background(Circle().fill(.white))
                            .offset(x: 18, y: -18)
                    }
                }
                .frame(width: 50, height: 50)

                // Notification content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.actorUsername ?? "Someone")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("started following you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(notification.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
            .padding()
            .background(notification.isRead ? Color(.tertiarySystemGroupedBackground) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                Task {
                    await vm.markAsRead(notification: notification)
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        NotificationAlertView(vm: NotificationAlertViewModel())
    }
}
