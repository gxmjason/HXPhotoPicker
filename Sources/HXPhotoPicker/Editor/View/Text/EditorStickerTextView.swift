//
//  EditorStickerTextView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

class EditorStickerTextView: UIView {
    var config: EditorConfiguration.Text
    var textView: UITextView!
    private var textButton: UIButton!
    private var flowLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    /// 字体选择（在 fontSlider 上方）
    private var fontFlowLayout: UICollectionViewFlowLayout!
    var fontCollectionView: UICollectionView!
    /// 内置 16 种字体：(PostScript 名称, 展示名)，nil 表示系统粗体
    private static let builtInFonts: [(name: String?, displayName: String)] = [
        (nil, "系统粗体"),
        ("PingFangSC-Regular", "苹方"),
        ("PingFangSC-Medium", "苹方中黑"),
        ("PingFangSC-Semibold", "苹方中粗"),
        ("ziticqtezhanti", "特战体"),
        ("-Regular", "哑铃黑方体"),
        ("WD-XLLubrifontTC-Regular", "滑油体"),
        ("zcoolwenyiti", "文艺体"),
        ("WenCang-Regular", "书房体"),
        ("ZiZhiQuXiMaiTi", "喜脉体"),
        ("YOUSHEhaoshenti", "优设体"),
        ("WeChat-Sans-SS-Bold", "薇中体"),
        ("WeChat-Sans-Std-Regular", "小称体"),
        ("Helvetica", "Helvetica"),
        ("Helvetica-Bold", "Helvetica-Bold"),
        ("ArialMT", "Arial"),
        ("Arial-BoldMT", "Arial-Bold"),
        ("Georgia", "Georgia"),
        ("TimesNewRomanPSMT", "Times"),
        ("Courier", "Courier"),
        ("Menlo-Regular", "Menlo"),
        ("Avenir-Book", "Avenir"),
        ("Avenir-Heavy", "Avenir-Heavy"),
        ("ChalkboardSE-Regular", "Chalkboard"),
        ("AmericanTypewriter", "American")
    ]
    var selectedFontIndex: Int = 0

    var fontSlider: UISlider!
    var fontLabel: UILabel!
    var setFont: UIFont?
    
    var text: String {
        textView.text
    }
    var currentSelectedIndex: Int = 0 {
        didSet {
            if currentSelectedIndex < 0 {
                return
            }
            collectionView.scrollToItem(
                at: IndexPath(item: currentSelectedIndex, section: 0),
                at: .centeredHorizontally,
                animated: true
            )
        }
    }
    
    var customColor: PhotoEditorBrushCustomColor
    var isShowCustomColor: Bool {
        if #available(iOS 14.0, *), config.colors.count > 1 {
            return true
        }
        return false
    }
    var currentSelectedColor: UIColor = .clear
    var typingAttributes: [NSAttributedString.Key: Any] = [:]
    var stickerText: EditorStickerText?
    
    var showBackgroudColor: Bool = false
    var useBgColor: UIColor = .clear
    var textIsDelete: Bool = false
    var textLayer: EditorStickerTextLayer?
    var rectArray: [CGRect] = []
    var blankWidth: CGFloat = 22
    var layerRadius: CGFloat = 8
    var keyboardFrame: CGRect = .zero
    var maxIndex: Int = 0
    
    init(
        config: EditorConfiguration.Text,
        stickerText: EditorStickerText?
    ) {
        self.config = config
        let fontSize = UserDefaults.standard.value(forKey: "KEY_Edit_Add_words_Font_Size")
        if fontSize != nil {
            self.config.font = .boldSystemFont(ofSize: fontSize as! CGFloat)
        }
        if #available(iOS 14.0, *), config.colors.count > 1, let color = config.colors.last?.color {
            self.customColor = .init(color: color)
        }else {
            self.customColor = .init(color: .clear)
        }
        self.stickerText = stickerText
        super.init(frame: .zero)
        initViews()
        setupTextConfig()
        setupStickerText()
        setupTextColors()
        addKeyboardNotificaition()
        
        textView.becomeFirstResponder()
    }
    
    private func initViews() {
        textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.layoutManager.delegate = self
        textView.textContainerInset = UIEdgeInsets(
            top: 15,
            left: 15 + UIDevice.leftMargin,
            bottom: 15,
            right: 15 + UIDevice.rightMargin
        )
        textView.contentInset = .zero
        addSubview(textView)
        
        textButton = UIButton(type: .custom)
        textButton.setImage(.imageResource.editor.text.backgroundNormal.image, for: .normal)
        textButton.setImage(.imageResource.editor.text.backgroundSelected.image, for: .selected)
        textButton.addTarget(self, action: #selector(didTextButtonClick(button:)), for: .touchUpInside)
        addSubview(textButton)
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.itemSize = CGSize(width: 37, height: 37)
        collectionView = HXCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            EditorStickerTextViewCell.self,
            forCellWithReuseIdentifier: "EditorStickerTextViewCellID"
        )
        addSubview(collectionView)
        
        fontFlowLayout = UICollectionViewFlowLayout()
        fontFlowLayout.scrollDirection = .horizontal
        fontFlowLayout.minimumInteritemSpacing = 8
        fontFlowLayout.itemSize = CGSize(width: 110, height: 52)
        fontCollectionView = HXCollectionView(frame: .zero, collectionViewLayout: fontFlowLayout)
        fontCollectionView.backgroundColor = .clear
        fontCollectionView.dataSource = self
        fontCollectionView.delegate = self
        fontCollectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            fontCollectionView.contentInsetAdjustmentBehavior = .never
        }
        fontCollectionView.register(
            EditorStickerTextFontCell.self,
            forCellWithReuseIdentifier: "EditorStickerTextFontCellID"
        )
        addSubview(fontCollectionView)
        
        fontSlider = UISlider()
        fontSlider.minimumValue = 10
        fontSlider.maximumValue = 30
        fontSlider.value = Float(config.font.pointSize)
        fontSlider.addTarget(self, action: #selector(fontSliderDidChange), for: .valueChanged)
        addSubview(fontSlider)
        
        fontLabel = UILabel()
        fontLabel.font = .boldSystemFont(ofSize: 14)
        fontLabel.textColor = .white
        fontLabel.text = "\(String(format: "%.1f", fontSlider.value))"
        addSubview(fontLabel)
        applyCurrentFont()
    }
    
    @objc private func fontSliderDidChange() {
        fontLabel.text = "\(String(format: "%.1f", fontSlider.value))"
        applyCurrentFont()
    }
    
    /// 根据当前选中的字体索引和滑块字号应用字体
    func applyCurrentFont() {
        let size = CGFloat(fontSlider.value)
        let font = Self.font(forIndex: selectedFontIndex, size: size)
        textView.font = font
        config.font = font
        setFont = config.font
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        let attributes: [NSAttributedString.Key: Any] = [
            .font: config.font,
            .paragraphStyle: paragraphStyle
        ]
        typingAttributes = attributes
        changeTextColor(color: textView.textColor ?? currentSelectedColor)
    }
    
    private static func font(forIndex index: Int, size: CGFloat) -> UIFont {
        let safeIndex = min(max(index, 0), builtInFonts.count - 1)
        let pair = builtInFonts[safeIndex]
        if let name = pair.name, let f = UIFont(name: name, size: size) {
            return f
        }
        return .boldSystemFont(ofSize: size)
    }
    
    /// 供扩展使用：内置字体数量
    static var builtInFontsCount: Int { builtInFonts.count }
    /// 供扩展使用：按索引取内置字体（展示用字号）
    static func fontForBuiltInIndex(_ index: Int, size: CGFloat = 16) -> UIFont {
        font(forIndex: index, size: size)
    }
    /// 供扩展使用：按索引获取字体展示名称
    static func displayNameForBuiltInIndex(_ index: Int) -> String {
        let safeIndex = min(max(index, 0), builtInFonts.count - 1)
        return builtInFonts[safeIndex].displayName
    }
    
    private func setupStickerText() {
        if let text = stickerText {
            showBackgroudColor = text.showBackgroud
            textView.text = text.text
            textButton.isSelected = text.showBackgroud
        }
        setupTextAttributes()
    }
    
    private func setupTextConfig() {
        textView.tintColor = config.tintColor
        textView.font = config.font
    }
    
    private func setupTextAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        let attributes = [NSAttributedString.Key.font: config.font,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        typingAttributes = attributes
        textView.attributedText = NSAttributedString(string: stickerText?.text ?? "", attributes: attributes)
    }
    
    private func setupTextColors() {
        var hasColor: Bool = false
        for (index, colorHex) in config.colors.enumerated() {
            let color = colorHex.color
            if let text = stickerText {
                if color == text.textColor {
                    if text.showBackgroud {
                        if color.isWhite {
                            changeTextColor(color: .black)
                        }else {
                            changeTextColor(color: .white)
                        }
                        useBgColor = color
                    }else {
                        changeTextColor(color: color)
                    }
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                    hasColor = true
                }
            }else {
                if index == 0 {
                    changeTextColor(color: color)
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                    hasColor = true
                }
            }
        }
        if !hasColor {
            if let text = stickerText {
                changeTextColor(color: text.textColor)
                currentSelectedColor = text.textColor
                currentSelectedIndex = -1
            }
        }
        if textButton.isSelected {
            drawTextBackgroudColor()
        }
    }
    
    @objc
    private func didTextButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected
        showBackgroudColor = button.isSelected
        useBgColor = currentSelectedColor
        if button.isSelected {
            if currentSelectedColor.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: currentSelectedColor)
        }
    }
    
    private func addKeyboardNotificaition() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillAppearance),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDismiss),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc
    private func keyboardWillAppearance(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.keyboardFrame = keyboardFrame
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    @objc
    private func keyboardWillDismiss(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        keyboardFrame = .zero
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12 + UIDevice.rightMargin)
        textButton.frame = CGRect(
            x: UIDevice.leftMargin,
            y: height,
            width: 50,
            height: 50
        )
        if keyboardFrame.isEmpty {
            if UIDevice.isPad {
                if config.modalPresentationStyle == .fullScreen {
                    textButton.y = height - (UIDevice.bottomMargin + 50)
                }else {
                    textButton.y = height - 50
                }
            }else {
                textButton.y = height - (UIDevice.bottomMargin + 50)
            }
        }else {
            if UIDevice.isPad {
                let firstTextButtonY: CGFloat
                if config.modalPresentationStyle == .fullScreen {
                    firstTextButtonY = height - UIDevice.bottomMargin - 50
                }else {
                    firstTextButtonY = height - 50
                }
                let buttonRect = convert(
                    .init(x: 0, y: firstTextButtonY, width: 50, height: 50),
                    to: UIApplication.hx_keyWindow
                )
                if buttonRect.maxY > keyboardFrame.minY {
                    textButton.y = height - (buttonRect.maxY - keyboardFrame.minY + 50)
                }else {
                    if config.modalPresentationStyle == .fullScreen {
                        textButton.y = height - (UIDevice.bottomMargin + 50)
                    }else {
                        textButton.y = height - 50
                    }
                }
            }else {
                textButton.y = height - (50 + keyboardFrame.height)
            }
        }
        collectionView.frame = CGRect(
            x: textButton.frame.maxX,
            y: textButton.y,
            width: width - textButton.width,
            height: 50
        )
        textView.frame = CGRect(x: 10, y: 0, width: width - 20, height: textButton.y)
        textView.textContainerInset = UIEdgeInsets(
            top: 15,
            left: 15 + UIDevice.leftMargin,
            bottom: 15,
            right: 15 + UIDevice.rightMargin
        )
        let fontRowY = textButton.y - 84
        fontFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12 + UIDevice.rightMargin)
        fontCollectionView.frame = CGRect(
            x: textButton.frame.maxX,
            y: fontRowY,
            width: width - textButton.width,
            height: 44
        )
        fontLabel.frame = CGRect(
            x: textButton.frame.minX + 10,
            y: textButton.y - 30,
            width: 40,
            height: 30
        )
        fontSlider.frame = CGRect(
            x: textButton.frame.maxX + 5,
            y: textButton.y - 40,
            width: width - textButton.width - 15,
            height: 50
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class EditorStickerTextViewCell: UICollectionViewCell {
    private var colorBgView: UIView!
    private var imageView: UIImageView!
    private var colorView: UIView!
    
    var colorHex: String! {
        didSet {
            imageView.isHidden = true
            guard let colorHex = colorHex else { return }
            let color = colorHex.color
            if color.isWhite {
                colorBgView.backgroundColor = "#dadada".color
            }else {
                colorBgView.backgroundColor = .white
            }
            colorView.backgroundColor = color
        }
    }
    
    var customColor: PhotoEditorBrushCustomColor? {
        didSet {
            guard let customColor = customColor else {
                return
            }
            imageView.isHidden = false
            colorView.backgroundColor = customColor.color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.colorBgView.transform = self.isSelected ? .init(scaleX: 1.25, y: 1.25) : .identity
                self.colorView.transform = self.isSelected ? .init(scaleX: 1.3, y: 1.3) : .identity
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(image: .imageResource.editor.text.customColor.image)
        imageView.isHidden = true
        
        let bgLayer = CAShapeLayer()
        bgLayer.contentsScale = UIScreen._scale
        bgLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bgLayer.fillColor = UIColor.white.cgColor
        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: 1.5, y: 1.5, width: 19, height: 19),
            cornerRadius: 19 * 0.5
        )
        bgLayer.path = bgPath.cgPath
        imageView.layer.addSublayer(bgLayer)

        let maskLayer = CAShapeLayer()
        maskLayer.contentsScale = UIScreen._scale
        maskLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let maskPath = UIBezierPath(rect: bgLayer.bounds)
        maskPath.append(
            UIBezierPath(
                roundedRect: CGRect(x: 3, y: 3, width: 16, height: 16),
                cornerRadius: 8
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        imageView.layer.mask = maskLayer
        
        colorBgView = UIView()
        colorBgView.size = CGSize(width: 22, height: 22)
        colorBgView.layer.cornerRadius = 11
        colorBgView.layer.masksToBounds = true
        colorBgView.addSubview(imageView)
        contentView.addSubview(colorBgView)
        
        colorView = UIView()
        colorView.size = CGSize(width: 16, height: 16)
        colorView.layer.cornerRadius = 8
        colorView.layer.masksToBounds = true
        contentView.addSubview(colorView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        colorBgView.center = CGPoint(x: width / 2, y: height / 2)
        imageView.frame = colorBgView.bounds
        colorView.center = CGPoint(x: width / 2, y: height / 2)
    }
}

/// 字体选项 cell：预览 + 字体名称
class EditorStickerTextFontCell: UICollectionViewCell {
    private let sampleLabel: UILabel = {
        let l = UILabel()
        l.text = "ABCabc123"
        l.textAlignment = .center
        l.textColor = .white
        l.font = .boldSystemFont(ofSize: 16)
        return l
    }()
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .white
        l.font = .systemFont(ofSize: 11)
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 2 : 0
            layer.borderColor = isSelected ? UIColor.white.cgColor : nil
            layer.cornerRadius = 6
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(sampleLabel)
        contentView.addSubview(nameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = contentView.bounds
        let sampleHeight = bounds.height * 0.6
        sampleLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: sampleHeight)
        nameLabel.frame = CGRect(x: 2, y: sampleHeight, width: bounds.width - 4, height: bounds.height - sampleHeight)
    }
    
    func configure(font: UIFont, name: String, selected: Bool) {
        sampleLabel.font = font
        nameLabel.text = name
        isSelected = selected
    }
}

struct PhotoEditorBrushCustomColor {
    var isFirst: Bool = true
    var isSelected: Bool = false
    var color: UIColor
}
