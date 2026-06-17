#if APP_ICON_GENERATOR_CLI
import Darwin
import Foundation

@main
enum AppIconGeneratorCLI {
    static func main() {
        guard CommandLine.arguments.count == 3 else {
            printError("Usage: \(executableName()) <app-icon-output-directory> <dark-icon-output-directory>")
            exit(64)
        }

        let appIconOutputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
        let darkIconOutputDirectory = URL(fileURLWithPath: CommandLine.arguments[2])
        do {
            try AppIconRenderer.exportAppIconSet(to: appIconOutputDirectory)
            try AppIconRenderer.exportDarkAppIconImageSet(to: darkIconOutputDirectory)
        } catch {
            printError("Could not generate app icons: \(error.localizedDescription)")
            exit(1)
        }
    }

    private static func executableName() -> String {
        URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
    }

    private static func printError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
#endif
