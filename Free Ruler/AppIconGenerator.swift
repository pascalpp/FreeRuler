import Foundation

#if APP_ICON_GENERATOR_CLI
@main
enum AppIconGeneratorCLI {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw AppIconGeneratorError.missingOutputPath
        }

        let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
        try AppIconRenderer.exportAppIconSet(to: outputDirectory)
    }
}

enum AppIconGeneratorError: Error {
    case missingOutputPath
}
#endif
