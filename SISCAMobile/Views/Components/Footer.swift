import SwiftUI

/// Pie de página común. Port de `Footer` (Android).
struct Footer: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("version 1.0")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.bodyText)
            Text("© 2025 SISCA Mobile")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.bodyText)
            Text("Powered by REINTE")
                .font(.system(size: 10, weight: .light))
                .foregroundColor(AppColor.bodyText)
        }
        .padding(.bottom, 20)
    }
}
