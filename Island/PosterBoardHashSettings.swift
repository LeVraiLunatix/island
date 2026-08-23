import SwiftUI

/// PosterBoard's own app container hash (its UUID under
/// /var/mobile/Containers/Data/Application/). Third-party apps cannot look
/// this up on-device -- it has to be found once with Nugget on a computer,
/// exactly as Pocket Poster's own setup flow requires. Stored locally so the
/// user only has to do this once.
enum PosterBoardHashStore {
    private static let key = "posterBoardAppHash"

    static var hash: String {
        get { UserDefaults.standard.string(forKey: key) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

struct PosterBoardHashSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hash: String = PosterBoardHashStore.hash

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hash de conteneur PosterBoard")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Island a besoin de l'identifiant du conteneur privé de l'app système PosterBoard pour y installer un fond d'écran. Cet identifiant ne peut pas être découvert depuis l'app elle-même — il faut passer par Nugget sur un ordinateur, une seule fois.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Installe Nugget sur ton ordinateur et connecte ton iPhone en USB.")
                        Text("2. Dans Nugget, ouvre Réglages puis « Pocket Poster Helper ».")
                        Text("3. Copie le hash affiché et colle-le ci-dessous.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))

                    TextField("Hash (UUID)", text: $hash)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Cet identifiant change si PosterBoard est réinstallé ou mis à jour ; refais l'opération si l'installation échoue soudainement.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationTitle("Réglages PosterBoard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        PosterBoardHashStore.hash = hash.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
