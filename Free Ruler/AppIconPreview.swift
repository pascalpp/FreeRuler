import Cocoa
import SwiftUI

#if DEBUG
struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(nsImage: AppIconRenderer.image(size: 1024))
                .resizable()
                .frame(width: 256, height: 256)

            HStack(spacing: 20) {
                previewIcon(size: 128)
                previewIcon(size: 64)
                previewIcon(size: 32)
            }
        }
        .padding(32)
        .background(.regularMaterial)
    }

    private func previewIcon(size: CGFloat) -> some View {
        Image(nsImage: AppIconRenderer.image(size: 1024))
            .resizable()
            .frame(width: size, height: size)
    }
}

struct AppIconPreview_Previews: PreviewProvider {
    static var previews: some View {
        AppIconPreview()
            .previewLayout(.sizeThatFits)
    }
}
#endif
