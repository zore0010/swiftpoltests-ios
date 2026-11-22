import XCTest
@testable import SwiftPolTest

final class LegalDocumentTests: XCTestCase {
    func testEveryDocumentIsBundled() {
        for document in LegalDocument.allCases {
            let text = document.text() ?? ""
            XCTAssertFalse(text.isEmpty, document.fileName)
        }
    }

    func testPrivacyPolicyHasItsContact() throws {
        let text = try XCTUnwrap(LegalDocument.privacy.text())
        XCTAssertTrue(text.contains("zore4913@proton.me"))
    }

    func testLegalNoticeHasBothLanguages() throws {
        let blocks = MarkdownBlock.parse(try XCTUnwrap(LegalDocument.notice.text()))
        XCTAssertTrue(blocks.contains(.heading(level: 2, text: "English")))
        XCTAssertTrue(blocks.contains(.heading(level: 2, text: "Tiếng Việt")))
    }

    func testMarkdownParsing() {
        let blocks = MarkdownBlock.parse("# Title\n\n[English](#english) | [Other](#other)\n\n## Part\nText here.\n- item\n---\n")
        XCTAssertEqual(blocks, [
            .heading(level: 1, text: "Title"),
            .heading(level: 2, text: "Part"),
            .paragraph("Text here."),
            .bullet("item"),
            .divider
        ])
    }
}
