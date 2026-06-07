#if APP_ICON_GENERATOR_CLI
import Darwin
import Foundation

@main
enum AppIconGeneratorCLI {
    static func main() {
        guard CommandLine.arguments.count == 2 else {
            printError("Usage: \(executableName()) <output-directory>")
            exit(64)
        }

        let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
        do {
            try AppIconRenderer.exportAppIconSet(to: outputDirectory)
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
