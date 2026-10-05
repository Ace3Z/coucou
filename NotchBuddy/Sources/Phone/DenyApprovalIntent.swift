import AppIntents
import Foundation

/// Deny on the Live Activity: answers the command waiting for your OK without
/// opening Coucou. Compiled into the app and the widgets extension; iOS runs
/// it in the app. (Allow opens Coucou instead, for Face ID: AllowApprovalIntent.)
struct DenyApprovalIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Deny the command"
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Request") var fingerprint: String
    @Parameter(title: "Agent") var pillId: String

    init() {}

    init(fingerprint: String, pillId: String) {
        self.fingerprint = fingerprint
        self.pillId = pillId
    }

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        let link = await PhoneLink.shared
        _ = await link.decide(.deny, fingerprint: fingerprint, pillId: pillId, summary: "Denied from the Lock Screen")
        #endif
        return .result()
    }
}

/// Allow on the Live Activity: opens Coucou on the command and asks for
/// Face ID right away. Nothing is sent without it.
struct AllowApprovalIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Review and allow the command"
    static var isDiscoverable: Bool { false }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Request") var fingerprint: String
    @Parameter(title: "Agent") var pillId: String

    init() {}

    init(fingerprint: String, pillId: String) {
        self.fingerprint = fingerprint
        self.pillId = pillId
    }

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        let fingerprint = fingerprint
        await MainActor.run {
            let link = PhoneLink.shared
            link.autoAllowFingerprint = fingerprint
            link.reviewFingerprint = fingerprint
            Task { await link.refresh() }
        }
        #endif
        return .result()
    }
}
