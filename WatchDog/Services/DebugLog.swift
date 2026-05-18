import Foundation

/// Logging that compiles to a no-op in Release. Use this instead of `print`
/// anywhere — placeholder action stubs, error breadcrumbs that don't need
/// to ship to Sentry, etc.
@inlinable
func DebugLog(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n"
) {
    #if DEBUG
    let message = items.map { "\($0)" }.joined(separator: separator)
    print(message, terminator: terminator)
    #endif
}
