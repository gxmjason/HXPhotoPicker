//
//  EditorViewController+Text.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit

extension EditorViewController: EditorStickerTextViewControllerDelegate {
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerText: EditorStickerText
    ) {
        deselectedDrawTool()
        if let tool = selectedTool,
           tool.type == .graffiti || tool.type == .graffiti {
            selectedTool = nil
            updateBottomMaskLayer()
        }
        let stickerBaseView = editorView.addSticker(stickerText)
        checkSelectedTool()
        checkFinishButtonState()
        noticeStickerTextViewControllerDidFinish(sticker: stickerBaseView)
    }
    
    func stickerTextViewController(_ controller: EditorStickerTextViewController, didFinishUpdate stickerText: EditorStickerText, ID: String) {
        deselectedDrawTool()
        if let tool = selectedTool,
           tool.type == .graffiti || tool.type == .graffiti {
            selectedTool = nil
            updateBottomMaskLayer()
        }
        let stickerBaseView = editorView.updateSticker(stickerText, ID)
        checkSelectedTool()
        noticeStickerTextViewControllerDidUpdate(sticker: stickerBaseView)
    }
}
