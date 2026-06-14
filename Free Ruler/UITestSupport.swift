import Darwin
import Foundation

final class UITestSupport {
    private static let uiTestsEnvironmentKey = "FREE_RULER_UI_TESTS"
    private static let cursorStateNameEnvironmentKey = "FREE_RULER_UI_TEST_CURSOR_STATE_NAME"
    private static let preferencesStateNameEnvironmentKey = "FREE_RULER_UI_TEST_PREFERENCES_STATE_NAME"

    private static var installedSupport: UITestSupport?

    static var current: UITestSupport? {
        return installedSupport
    }

    static var isEnabled: Bool {
        return isEnabled(in: ProcessInfo.processInfo.environment)
    }

    let stateNamePrefix: String
    let stateDirectoryURL: URL
    let cursorStateName: String
    let preferencesStateName: String

    var cursorStateURL: URL {
        return stateDirectoryURL.appendingPathComponent(cursorStateName)
    }

    var preferencesStateURL: URL {
        return stateDirectoryURL.appendingPathComponent(preferencesStateName)
    }

    var launchEnvironment: [String: String] {
        return [
            Self.uiTestsEnvironmentKey: "1",
            Self.cursorStateNameEnvironmentKey: cursorStateName,
            Self.preferencesStateNameEnvironmentKey: preferencesStateName,
        ]
    }

    private init(
        stateNamePrefix: String,
        cursorStateName: String? = nil,
        preferencesStateName: String? = nil,
        stateDirectoryURL: URL
    ) {
        self.stateNamePrefix = stateNamePrefix
        self.stateDirectoryURL = stateDirectoryURL
        self.cursorStateName = cursorStateName ?? "\(stateNamePrefix).cursor"
        self.preferencesStateName = preferencesStateName ?? "\(stateNamePrefix).preferences"
    }

    @discardableResult
    static func prepareForLaunch() -> UITestSupport {
        let support = UITestSupport(
            stateNamePrefix: makeStateNamePrefix(),
            stateDirectoryURL: appContainerTemporaryDirectoryURL()
        )
        installedSupport = support
        return support
    }

    @discardableResult
    static func installIfNeeded(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> UITestSupport? {
        guard isEnabled(in: environment) else {
            installedSupport = nil
            return nil
        }

        let stateNamePrefix = makeStateNamePrefix()
        let support = UITestSupport(
            stateNamePrefix: stateNamePrefix,
            cursorStateName: stateName(
                from: cursorStateNameEnvironmentKey,
                in: environment
            ),
            preferencesStateName: stateName(
                from: preferencesStateNameEnvironmentKey,
                in: environment
            ),
            stateDirectoryURL: processTemporaryDirectoryURL()
        )
        installedSupport = support
        return support
    }

    private static func isEnabled(in environment: [String: String]) -> Bool {
        return environment[uiTestsEnvironmentKey] != nil
    }

    func resetStateFiles() {
        try? FileManager.default.createDirectory(
            at: stateDirectoryURL,
            withIntermediateDirectories: true
        )
        removeStateFiles()
    }

    func removeStateFiles() {
        try? FileManager.default.removeItem(at: cursorStateURL)
        try? FileManager.default.removeItem(at: preferencesStateURL)
    }

    func writeCursorState(_ value: String) {
        writeState(value, to: cursorStateURL)
    }

    func writeState(_ value: String, to url: URL) {
        try? value.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func stateName(from environmentKey: String, in environment: [String: String]) -> String? {
        guard let name = environment[environmentKey] else { return nil }

        let lastPathComponent = URL(fileURLWithPath: name).lastPathComponent
        guard !lastPathComponent.isEmpty, lastPathComponent == name else { return nil }
        return name
    }

    private static func makeStateNamePrefix() -> String {
        return "FreeRulerUITests-\(UUID().uuidString)"
    }

    private static func processTemporaryDirectoryURL() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    private static func appContainerTemporaryDirectoryURL() -> URL {
        return URL(fileURLWithPath: currentUserHomeDirectory())
            .appendingPathComponent("Library/Containers/com.pascal.freeruler/Data/tmp", isDirectory: true)
    }

    private static func currentUserHomeDirectory() -> String {
        guard let passwd = getpwuid(getuid()) else {
            return NSHomeDirectory()
        }

        return String(cString: passwd.pointee.pw_dir)
    }
}
