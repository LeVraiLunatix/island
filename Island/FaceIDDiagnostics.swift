import LocalAuthentication
import SwiftUI

struct FaceIDStatus {
    enum Availability {
        case available
        case notEnrolled
        case lockedOut
        case passcodeNotSet
        case unavailable(String)
    }

    let biometryType: LABiometryType
    let availability: Availability
    let identitySpoofActive: Bool
    let spoofedProductType: String?
    let dynamicIslandOverrideActive: Bool
    let dynamicIslandSubtypeLabel: String?
}

enum FaceIDDiagnostics {
    private static let spoofFlagKey = "A62OafQ85EJAiiqKn4agtg"
    private static let spoofProductTypeKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    private static let dynamicIslandCompatibilityKey = "YlEtTtHlNesRBMal1CqRaA"
    private static let artworkDeviceKey = "oPeik/9e8lQWMszEjbPzng"

    /// Checks Face ID through the public LocalAuthentication API (the same
    /// check any app performs before offering biometric sign-in), then
    /// cross-references the live MobileGestalt plist for two overrides
    /// Island's own screens can leave active: the device-identity spoof
    /// from Apple Intelligence (explicitly flagged as a Face ID risk
    /// already), and the Dynamic Island subtype override -- which changes
    /// which physical TrueDepth housing/camera layout the system believes
    /// it has. The latter link is unconfirmed, but it's the app's core
    /// feature and worth surfacing since it touches the exact device
    /// attribute Face ID calibration is keyed on.
    static func currentStatus(plist: GestaltPlist?) -> FaceIDStatus {
        let context = LAContext()
        var evaluationError: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError)

        let availability: FaceIDStatus.Availability
        if canEvaluate {
            availability = .available
        } else if let evaluationError, let code = LAError.Code(rawValue: evaluationError.code) {
            switch code {
            case .biometryNotEnrolled:
                availability = .notEnrolled
            case .biometryLockout:
                availability = .lockedOut
            case .passcodeNotSet:
                availability = .passcodeNotSet
            default:
                availability = .unavailable(evaluationError.localizedDescription)
            }
        } else {
            availability = .unavailable("Raison inconnue.")
        }

        let cacheExtra = plist?.cacheExtra ?? [:]
        let spoofedProductType = cacheExtra[spoofProductTypeKey] as? String
        let spoofActive = (cacheExtra[spoofFlagKey] as? Int == 1) && spoofedProductType != nil

        let artwork = cacheExtra[artworkDeviceKey] as? [String: Any]
        let subtype = artwork?["ArtworkDeviceSubType"] as? Int
        let dynamicIslandActive = (cacheExtra[dynamicIslandCompatibilityKey] as? Int == 1) && subtype != nil
        let subtypeLabel = subtype.flatMap { value in
            DynamicIslandOption.all.first { $0.subtype == value }?.title
        }

        return FaceIDStatus(
            biometryType: context.biometryType,
            availability: availability,
            identitySpoofActive: spoofActive,
            spoofedProductType: spoofedProductType,
            dynamicIslandOverrideActive: dynamicIslandActive,
            dynamicIslandSubtypeLabel: subtypeLabel
        )
    }
}

extension LABiometryType {
    var label: String {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        case .none: "Aucune biométrie détectée"
        @unknown default: "Biométrie inconnue"
        }
    }
}

extension FaceIDStatus.Availability {
    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .available:
            "Répond normalement aux demandes d'authentification."
        case .notEnrolled:
            "Aucun visage enregistré, ou Face ID est désactivé dans Réglages > Face ID et code."
        case .lockedOut:
            "Verrouillé après trop d'échecs. Déverrouille l'appareil avec le code pour le réactiver."
        case .passcodeNotSet:
            "Aucun code n'est configuré sur l'appareil : Face ID ne peut pas fonctionner sans code."
        case .unavailable(let reason):
            reason
        }
    }
}

struct FaceIDDetailView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel
    @State private var status: FaceIDStatus?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let status {
                    statusCard(for: status)
                    if status.identitySpoofActive {
                        spoofWarningCard(for: status)
                    }
                    if status.dynamicIslandOverrideActive {
                        dynamicIslandWarningCard(for: status)
                    }
                    if status.availability.isAvailable && !status.identitySpoofActive && !status.dynamicIslandOverrideActive {
                        noOverrideCard
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 40)
                }
            }
            .padding(20)
        }
        .background(Color.black)
        .navigationTitle("Face ID")
        .navigationBarTitleDisplayMode(.inline)
        .task { refresh() }
        .refreshable { refresh() }
    }

    private func refresh() {
        status = FaceIDDiagnostics.currentStatus(plist: viewModel.plist)
    }

    @ViewBuilder
    private func statusCard(for status: FaceIDStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: status.availability.isAvailable ? "faceid" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(status.availability.isAvailable ? .green : .orange)
                Text(status.biometryType.label)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Text(status.availability.message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func spoofWarningCard(for status: FaceIDStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Identité de l'appareil usurpée", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Apple Intelligence est forcé avec une identité différente (\(status.spoofedProductType ?? "modèle inconnu")). C'est une cause connue de dysfonctionnement de Face ID : TrueDepth s'attend à retrouver le vrai modèle de puce.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Button {
                viewModel.resetIslandChanges()
            } label: {
                Text("Retirer l'usurpation (Réinitialiser Island)")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
            .disabled(viewModel.isBusy)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func dynamicIslandWarningCard(for status: FaceIDStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dynamic Island modifiée", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Le système croit avoir le boîtier caméra d'un \(status.dynamicIslandSubtypeLabel ?? "autre modèle"). Non confirmé, mais c'est exactement l'attribut d'appareil auquel le calibrage TrueDepth est habituellement lié — si Face ID a lâché après avoir changé ce réglage, c'est le suspect le plus probable.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Button {
                viewModel.resetIslandChanges()
            } label: {
                Text("Retirer la modification (Réinitialiser Island)")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.orange)
            .disabled(viewModel.isBusy)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var noOverrideCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Aucune trace d'une modification Island", systemImage: "checkmark.circle")
                .font(.subheadline)
                .foregroundStyle(.white)
            Text("Ni la Dynamic Island ni Apple Intelligence ne sont actuellement modifiées sur cet appareil, et le système dit pourtant que Face ID est prêt. Si le déverrouillage échoue quand même : redémarre l'appareil, vérifie qu'aucune coque/protection ne cache la caméra TrueDepth, puis essaie Réglages > Face ID et code > Réinitialiser Face ID et réinscris ton visage. C'est aussi une bêta iOS 27 très précoce — un vrai bug système n'est pas à exclure.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        FaceIDDetailView()
            .environmentObject(GestaltViewModel())
    }
}
