#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Localize_Swift

@available(iOS 13.0, *)
struct DefaultsList: View {

    @EnvironmentObject var env: DefaultsEnvironmentObject

    var body: some View {
        List {
            ForEach(env.viewModels) { _ in
                Section(header: Text("Hello")) {
                    Text("World")
                }
            }

        }.listStyle(GroupedListStyle())
    }
}

@available(iOS 13.0, *)
struct DefaultsList_Previews: PreviewProvider {
    static var previews: some View {
        return DefaultsList().environmentObject(DefaultsEnvironmentObject())
    }
}
#endif
