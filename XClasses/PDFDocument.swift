//
//  PDFDocument.swift
//  
//
//  Created by Adrian on 3/12/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Hydra

protocol PDFPageDelegate {
    var pageNumber: Int { get }
    var pdfDocument: PDFDocument { get }
}

enum PDFError: LocalizedError {
    case pageNotReady

    public var errorDescription: String? {
        switch self {
        case .pageNotReady:
            return NSLocalizedString("Page is still downloading.", comment: "")
        }
    }
}

/// PDFDocument handles the opening and image caching of a PDF. When a page is drawn and cached, it will also draw and cache the pages before and after that page.
class PDFDocument {
    let cachedImages = NSCache<NSNumber, UIImage>()
    let cacheImageCount = 5
    var pdfDocument: CGPDFDocument?
    var firstRetry: Date?

    init(url: URL) {
        pdfDocument = CGPDFDocument(url as CFURL)
        cachedImages.countLimit = cacheImageCount
    }

    init() {
        cachedImages.countLimit = cacheImageCount
    }

    /// Get UIImage of specific page. Will call cachePages.
    func pdfPageImage(pageNumber: Int, size: CGSize = UIScreen.main.bounds.size) -> Promise<UIImage> {
        return Promise<UIImage>(in: .userInitiated) { resolve, reject, _ in
            self.cachePages(pageNumber: pageNumber, size: size)
            if let image = self.cachedImages.object(forKey: NSNumber(value: pageNumber)) {
                resolve(image)
            }
            else {
                reject(PDFError.pageNotReady)
            }
        }
    }

    /// Draw and cache the current page as well as the pages before and after the current page.
    func cachePages(pageNumber: Int, size: CGSize = UIScreen.main.bounds.size) {
        cachePage(pageNumber: pageNumber, size: size)
        
        let queue = DispatchQueue(label: "caching", qos: DispatchQoS.default)
        queue.async {
            self.cachePage(pageNumber: pageNumber + 1, size: size)
            self.cachePage(pageNumber: pageNumber - 1, size: size)
        }
    }

    /// Cache page in object.
    func cachePage(pageNumber: Int, size: CGSize = UIScreen.main.bounds.size) {
        let n = NSNumber(value: pageNumber)
        let cachedImage = cachedImages.object(forKey: n)
        // TODO: if Sizes are different then recache
        guard let pdfDocument = pdfDocument, pageNumber >= 1, pageNumber <= pdfDocument.numberOfPages, cachedImage == nil else {
//            if pageNumber < 1 {
//                print("Warning: Page numbers out of bounds in cachePage in PDFDocument")
//            }
            return
        }

        if let image = pdfDocument.imageFromPage(number: pageNumber, with: size) {
            cachedImages.setObject(image, forKey: n)
        }
    }

    func resetCache() {
        cachedImages.removeAllObjects()
    }
}
