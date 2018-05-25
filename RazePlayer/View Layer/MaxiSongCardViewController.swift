/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

protocol MaxiPlayerSource: class {

  var originatingFrameInWindow: CGRect { get }
  var originatingCoverImageView: UIImageView { get }

}

class MaxiSongCardViewController: UIViewController, SongSubscriber {

  weak var sourceView: MaxiPlayerSource?
  // MARK: - Properties
  let cardCornerRadius: CGFloat = 10
  var currentSong: Song?
  
  let primaryDuration = 0.5 //set to 0.5 when ready (was 4.0 when start coding)
  let backingImageEdgeInset: CGFloat = 15.0
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  //scroller
  @IBOutlet weak var scrollView: UIScrollView!
  //this gets colored white to hide the background.
  //It has no height so doesnt contribute to the scrollview content
  @IBOutlet weak var stretchySkirt: UIView!
  
  //cover image
  @IBOutlet weak var coverImageContainer: UIView!
  @IBOutlet weak var coverArtImage: UIImageView!
  @IBOutlet weak var dismissChevron: UIButton!
  //add cover image constraints here
  
  //backing image
  var backingImage: UIImage?
  
  @IBOutlet weak var backingImageView: UIImageView!
  @IBOutlet weak var dimmerLayer: UIView!
  //add backing image constraints here
 
  @IBOutlet private weak var backingImageTopInset: NSLayoutConstraint!
  @IBOutlet private weak var backingImageLeadingInset: NSLayoutConstraint!
  @IBOutlet private weak var backingImageTrailingInset: NSLayoutConstraint!
  @IBOutlet private weak var backingImageBottomInset: NSLayoutConstraint!
  
  @IBOutlet private weak var coverImageBottom: NSLayoutConstraint!
  @IBOutlet private weak var coverImageTop: NSLayoutConstraint!
  @IBOutlet private weak var coverImageLeading: NSLayoutConstraint!
  @IBOutlet private weak var coverImageHeight: NSLayoutConstraint!
  
  @IBOutlet private weak var coverImageContainerTopInset: NSLayoutConstraint!

  @IBOutlet private weak var lowerModuleTopConstraint: NSLayoutConstraint!

  //fake tabbar contraints
  var tabBarImage: UIImage?
  
  @IBOutlet weak var bottomSectionHeight: NSLayoutConstraint!
  @IBOutlet weak var bottomSectionLowerConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomSectionImageView: UIImageView!

  // MARK: - View Life Cycle
  override func awakeFromNib() {
    super.awakeFromNib()

    modalPresentationCapturesStatusBarAppearance = true //allow this VC to control the status bar appearance
    modalPresentationStyle = .overFullScreen //dont dismiss the presenting view controller when presented
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    backingImageView.image = backingImage
   
    scrollView.contentInsetAdjustmentBehavior = .never //dont let Safe Area insets affect the scroll view
    
    coverImageContainer.layer.cornerRadius = cardCornerRadius
    coverImageContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    configureImageLayerInStartPosition()
    assert(sourceView != nil, "sourceView shouldn't be nil!")
    coverArtImage.image = sourceView?.originatingCoverImageView.image
    stretchySkirt.backgroundColor = .white //from starter project, this hides the gap
    configureLowerModuleInStartPosition()
    configureBottomSection()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    animateBackingImageIn()
    animateImageLayerIn()
    animateCoverImageIn()
    animateLowerModuleIn()
    animateBottomSectionOut()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? SongSubscriber {
      assert(currentSong != nil, "Current song shouldn't be nil.")
      destination.currentSong = currentSong
    }
  }
}

// MARK: - IBActions
extension MaxiSongCardViewController {

  @IBAction func dismissAction(_ sender: Any) {
    animateBackingImageOut()
    animateCoverImageOut()
    animateLowerModuleOut()
    animateBottomSectionIn()
    animateImageLayerOut { [weak self] in self?.dismiss(animated: $0) }
  }

}

// Background image animation
extension MaxiSongCardViewController {
  
  private func configureBackingImageInPosition(presenting: Bool) {
    let edgeInset: CGFloat = presenting ? backingImageEdgeInset : 0
    let dimmerAlpha: CGFloat = presenting ? 0.3 : 0
    let cornerRadius: CGFloat = presenting ? cardCornerRadius : 0
    
    [backingImageLeadingInset, backingImageTrailingInset].forEach { $0?.constant = edgeInset }
    
    let frame = backingImageView.frame
    let aspectRatio = frame.height / frame.width
    [backingImageTopInset, backingImageBottomInset].forEach { $0?.constant = edgeInset * aspectRatio }
    
    dimmerLayer.alpha = dimmerAlpha
    
    backingImageView.layer.cornerRadius = cornerRadius
  }
  
  private func animateBackingImage(presenting: Bool) {
    UIView.animate(withDuration: primaryDuration) { [weak self] in
      guard let `self` = self else { return }
      self.configureBackingImageInPosition(presenting: presenting)
      self.view.layoutIfNeeded()
    }
  }
  
  func animateBackingImageIn() {
    animateBackingImage(presenting: true)
  }
  
  func animateBackingImageOut() {
    animateBackingImage(presenting: false)
  }
  
}

// MARK: Image Container animation.
extension MaxiSongCardViewController {
  
  private var startColor: UIColor {
    return UIColor.white.withAlphaComponent(0.3)
  }
  
  private var endColor: UIColor {
    return .white
  }
  
  private var imageLayerInsetForOutPosition: CGFloat {
    let imageFrame = view.convert(sourceView!.originatingFrameInWindow, to: view)
    let inset = imageFrame.minY - backingImageEdgeInset
    return inset
  }
  
  func configureImageLayerInStartPosition() {
    coverImageContainer.backgroundColor = startColor
    let startInset = imageLayerInsetForOutPosition
    dismissChevron.alpha = 0
    coverImageContainer.layer.cornerRadius = 0
    coverImageContainerTopInset.constant = startInset
    
    view.layoutIfNeeded()
  }
  
  func animateImageLayerIn() {
    UIView.animate(withDuration: primaryDuration / 4) { [weak coverImageContainer, weak endColor] in
      coverImageContainer?.backgroundColor = endColor
    }
    
    UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseIn], animations: {
      self.coverImageContainerTopInset.constant = 0
      self.dismissChevron.alpha = 1
      self.coverImageContainer.layer.cornerRadius = self.cardCornerRadius
      self.view.layoutIfNeeded()
    })
  }
  
  func animateImageLayerOut(completion: @escaping (Bool) -> Void) {
    let endInset = imageLayerInsetForOutPosition
    
    let animation: ()->() = { [weak self] in self?.coverImageContainer.backgroundColor = self?.startColor }
    UIView.animate(withDuration: primaryDuration / 4,
                   delay: 0,
                   options: [.curveEaseOut],
                   animations: animation,
                   completion: { completion($0) })
    
    UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseOut], animations: { [weak self] in
      guard let `self` = self else { return }
      self.coverImageContainerTopInset.constant = endInset
      self.dismissChevron.alpha = 0
      self.coverImageContainer.layer.cornerRadius = 0
      self.view.layoutIfNeeded()
    })
  }

}

// MARK: cover image animation
extension MaxiSongCardViewController {
  
  func configureCoverImageInStartPosition() {
    let originatingImageFrame = sourceView!.originatingCoverImageView.frame
    coverImageHeight.constant = originatingImageFrame.height
    coverImageLeading.constant = originatingImageFrame.minX
    coverImageTop.constant = originatingImageFrame.minY
    coverImageBottom.constant = originatingImageFrame.minY
  }
  
  func animateCoverImageIn() {
    let coverImageEdgeConstraint: CGFloat = 30
    let endHeight = coverImageContainer.bounds.width - coverImageEdgeConstraint * 2
    
    let animations: ()->() = { [weak self] in
      guard let `self` = self else { return }
      
      self.coverImageHeight.constant = endHeight
      self.coverImageLeading.constant = coverImageEdgeConstraint
      self.coverImageBottom.constant = coverImageEdgeConstraint
      self.coverImageTop.constant = coverImageEdgeConstraint
      
      self.view.layoutIfNeeded()
    }
    
    UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseOut], animations: animations)
  }
  
  func animateCoverImageOut() {
    let animations: ()->() = { [weak self] in
      guard let `self` = self else { return }
      
      self.configureCoverImageInStartPosition()
      
      self.view.layoutIfNeeded()
    }
    UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseOut], animations: animations)
  }

}

// MARK: lower module animation
extension MaxiSongCardViewController {

  private var lowerModuleInsetForOutPosition: CGFloat {
    let bounds = view.bounds
    let inset = bounds.height - bounds.width
    return inset
  }

  func configureLowerModuleInStartPosition() {
    lowerModuleTopConstraint.constant = lowerModuleInsetForOutPosition
  }
  
  func animateLowerModule(isPresenting: Bool) {
    let topInset = isPresenting ? 0 : lowerModuleInsetForOutPosition
    let animations = { [weak self] in
      guard let `self` = self else { return }
      
      self.lowerModuleTopConstraint.constant = topInset
      self.view.layoutIfNeeded()
    }
    UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseIn], animations: animations)
  }
  
  func animateLowerModuleIn() {
    animateLowerModule(isPresenting: true)
  }
  
  func animateLowerModuleOut() {
    animateLowerModule(isPresenting: false)
  }
  
}

// MARK: fake tab bar animation
extension MaxiSongCardViewController {
  
  func configureBottomSection() {
    if let tabBarImage = tabBarImage {
      bottomSectionImageView.image = tabBarImage
      bottomSectionHeight.constant = tabBarImage.size.height
    } else {
      bottomSectionHeight.constant = 0
    }
    view.layoutIfNeeded()
  }
  
  func animateBottomSectionOut() {
    guard tabBarImage != nil else { return }
    UIView.animate(withDuration: primaryDuration / 2) { [weak self] in
      guard let `self` = self else { return }
      self.bottomSectionLowerConstraint.constant = 0
      self.view.layoutIfNeeded()
    }
  }
  
  func animateBottomSectionIn () {
    guard let image = tabBarImage else { return }
    UIView.animate(withDuration: primaryDuration / 2) { [weak self] in
      guard let `self` = self else { return }
      self.bottomSectionLowerConstraint.constant = -image.size.height
      self.view.layoutIfNeeded()
    }
  }
  
}
