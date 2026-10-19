import SwiftUI
import SwiftData

/// La cuenta elegida queda delante; las siguientes se asoman detrás y se pueden traer al frente.
struct AccountCardCarousel: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let accounts: [Account]
    let onEdit: (Account) -> Void

    @State private var selectedID: PersistentIdentifier?
    @GestureState private var drag: CGFloat = 0

    private var accountIDs: [PersistentIdentifier] { accounts.map(\.persistentModelID) }
    private var selectedIndex: Int {
        accounts.firstIndex { $0.persistentModelID == selectedID } ?? 0
    }
    private var deck: [DeckEntry] {
        (0..<min(accounts.count, 4)).reversed().map { depth in
            let index = (selectedIndex + depth) % accounts.count
            return DeckEntry(account: accounts[index], index: index, depth: depth)
        }
    }
    private var cardHeight: CGFloat { 236 * scale }
    private var animation: Animation? {
        reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.84)
    }

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                let width = max(geometry.size.width - 32, 1)
                let cardWidth = accounts.count > 1 ? width * 0.82 : width

                ZStack(alignment: .topLeading) {
                    ForEach(deck) { entry in
                        let depth = entry.depth
                        let account = entry.account

                        Button {
                            if depth == 0 {
                                onEdit(account)
                            } else {
                                select(entry.index)
                            }
                        } label: {
                            accountCard(account, index: entry.index, compact: cardWidth < 340)
                                .frame(width: cardWidth, height: cardHeight)
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(1 - CGFloat(depth) * 0.07, anchor: .topLeading)
                        .offset(x: CGFloat(depth) * width * 0.11 + drag * 0.16,
                                y: CGFloat(depth) * 12 * scale)
                        .zIndex(Double(4 - depth))
                        .transition(.identity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(account.name)
                        .accessibilityValue(t.money(account.balance))
                        .accessibilityHint(depth == 0 ? t.edit : t.accounts)
                        .accessibilityAddTraits(depth == 0 ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 24)
                        .updating($drag) { value, state, _ in
                            if abs(value.translation.width) > abs(value.translation.height) {
                                state = min(max(value.translation.width, -120), 120)
                            }
                        }
                        .onEnded { value in
                            guard accounts.count > 1,
                                  abs(value.translation.width) > 40,
                                  abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
                            step(value.translation.width < 0 ? 1 : -1)
                        }
                )
            }
            .frame(height: cardHeight + 24)

            if accounts.count > 1 {
                HStack(spacing: 12) {
                    arrow("chevron.left", label: t.previousSection) { step(-1) }
                    Spacer(minLength: 0)
                    ScrollView(.horizontal) {
                        HStack(spacing: 4) {
                            ForEach(Array(accounts.enumerated()), id: \.element.persistentModelID) { index, account in
                                Button {
                                    select(index)
                                } label: {
                                    Capsule()
                                        .fill(index == selectedIndex ? tint(index).solid(scheme) : Color.primary.opacity(0.18))
                                        .frame(width: index == selectedIndex ? 24 : 7, height: 7)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(account.name)
                                .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
                            }
                        }
                        .frame(minWidth: 80)
                    }
                    .scrollIndicators(.hidden)
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text("\(selectedIndex + 1) / \(accounts.count)")
                        .appFont(.subheadline, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(t.carouselPosition(selectedIndex + 1, total: accounts.count))
                    arrow("chevron.right", label: t.nextSection) { step(1) }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 8)
        .animation(animation, value: selectedID)
        .onChange(of: accountIDs, initial: true) {
            if selectedID == nil || !accountIDs.contains(where: { $0 == selectedID }) {
                selectedID = accountIDs.first
            }
        }
    }

    private func accountCard(_ account: Account, index: Int, compact: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        return VStack(alignment: .leading, spacing: 12 * scale) {
            HStack(alignment: .top, spacing: 12) {
                Text(account.name)
                    .font(.system(size: 14 * scale, weight: .bold, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                if let currency = t.locale.currency?.identifier {
                    Text(currency)
                        .appFont(.subheadline, weight: .bold)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 12)
            VStack(alignment: .leading, spacing: 4 * scale) {
                Text(t.balance)
                    .appFont(.body, weight: .medium)
                Text(t.money(account.balance))
                    .font(.system(size: 40 * scale, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
            }
        }
        .foregroundStyle(.white)
        .padding((compact ? 18 : 26) * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(colors: tint(index).gradient(scheme), startPoint: .bottomLeading, endPoint: .topTrailing)
                Bubbles()
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: tint(index).solid(scheme).opacity(0.16), radius: 12, y: 8)
        .contentShape(shape)
    }

    private func tint(_ index: Int) -> ThemeTint {
        [ThemeTint.mint, .teal, .peach, .sand][index % 4]
    }

    private func select(_ index: Int) {
        guard accounts.indices.contains(index) else { return }
        withAnimation(animation) { selectedID = accounts[index].persistentModelID }
    }

    private func step(_ direction: Int) {
        guard accounts.count > 1 else { return }
        select((selectedIndex + direction + accounts.count) % accounts.count)
    }

    private func arrow(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13 * scale, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.05), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .help(label)
    }

    private struct DeckEntry: Identifiable {
        let account: Account
        let index: Int
        let depth: Int
        var id: PersistentIdentifier { account.persistentModelID }
    }
}
