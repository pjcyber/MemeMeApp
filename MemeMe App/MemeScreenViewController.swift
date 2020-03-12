//
//  ViewController.swift
//  MemeMe App
//
//  Created by Pjcyber on 3/7/20.
//  Copyright © 2020 Pjcyber. All rights reserved.
//

import UIKit

class MemeScreenViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var topNavBar: UIToolbar!
    @IBOutlet weak var bottomToolBar: UIToolbar!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Global Variables
    var position: CGFloat = 0
    var pictureLandscape: Bool = false
    var screenOrientationPortrait: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // MARK: - to detect change in device orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // adjust the contentMode to .scaleAspectFill/.scaleAspectFit depending of picture orientation and device orientation
        screenOrientationPortrait = UIDevice.current.orientation.isPortrait
        adjustPictureScaleAspect(pictureLandscape: pictureLandscape)
    }
    
    // MARK: - To Open UIImagePickerController to get image from the device gallery
    @IBAction func onClickPickAnImageFromAlbum(_ sender: Any) {
        pickImage(from: .photoLibrary)
    }
    
    // MARK: - To open Camera
    @IBAction func onClickPickAnImageFromCamera(_ sender: Any) {
        pickImage(from: .camera)
    }
    
    // MARK: - To open UIActivityViewController to share Meme Image
    @IBAction func onClickShareButton() {
        let meme = saveMeme()
        let items = [meme.memedImage]
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityController, animated: true)
        
        // Completion handler
        activityController.completionWithItemsHandler = {
            _, completed, _, error in
            if completed {
                print("share completed")
                return
            } else {
                print("cancel")
            }
            if let shareError = error {
                print("error while sharing: \(shareError.localizedDescription)")
            }
        }
    }
    
    // MARK: - Click cancel to reset the app to the initial state
    @IBAction func onClikCancel() {
        imageView.image = nil
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
        enableTextFields(false)
    }
    
    // MARK: - open UIImagePickerController
    func pickImage(from: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = from
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            // adding image to imageView
            imageView.image = image
            // enabling topTextField and bottomTextField
            enableTextFields(true)
            // adjust the contentMode to .scaleAspectFill/.scaleAspectFit depending of picture orientation and device orientation
            pictureLandscape = image.size.width > image.size.height
            adjustPictureScaleAspect(pictureLandscape: pictureLandscape)
        }
        
        // to return to this UIViewController
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // to return to this UIViewController
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - func to adjust contentMode in imageView
    func adjustPictureScaleAspect(pictureLandscape: Bool) {
        if screenOrientationPortrait {
            if pictureLandscape {
                imageView.contentMode = .scaleAspectFit
            } else {
                imageView.contentMode = .scaleAspectFill
            }
        } else {
            imageView.contentMode = .scaleAspectFit
        }
    }
    
    // MARK: - subscription to keyboard notification to detect if the keyboard is shown
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }
    
    // MARK: - removing subscription to keyboard notification
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    // MARK: - func to move the view according to the keyboard visibility
    @objc func keyboardWillShow(_ notification: Notification) {
        if bottomTextField.isEditing {
            view.frame.origin.y -= getKeyboardHeight(notification)
            
            // disable toolbar buttons to avoid move the view twice
            enablePickImageButtons(false)
        }
    }
    
    // MARK: - func to get keyboard height
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    // MARK: - func to hide keboard and reset view to the original position when the user tap enter
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        view.frame.origin.y = position
        // enable toolbar buttons after edit TextField
        enablePickImageButtons(true)
        return false
    }
    
    // MARK: - func to clean initial text when the user tap TextField
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    // MARK: - func to save Meme date in struct
    func saveMeme() -> Meme {
        // Create the meme
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!,
                        originalImage: imageView.image!, memedImage: generateMemedImage())
        return meme
    }
    
    // MARK: - func to generate Meme Image
    func generateMemedImage() -> UIImage {
        // Hide toolbar and navbar
        hideToolBar(true)
        
        // Render view to an image
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Show toolbar and navbar
        hideToolBar(false)
        
        return memedImage
    }
    
    func initializeUI() {
        let size = UIScreen.main.bounds.size
        screenOrientationPortrait = size.width < size.height
        position = view.frame.origin.y
        
        setTextFieldAttributes()
        enableTextFields(false)
        topTextField.delegate = self
        bottomTextField.delegate = self
    }
    
    func enableTextFields(_ enable: Bool) {
        topTextField.isEnabled = enable
        bottomTextField.isEnabled = enable
        shareButton.isEnabled = enable
    }
    
    func hideToolBar(_ show: Bool) {
        topNavBar.isHidden = show
        bottomToolBar.isHidden = show
    }
    
    func setTextFieldAttributes() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let memeTextAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: paragraph,
            NSAttributedString.Key.strokeColor: UIColor.black,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedString.Key.strokeWidth: -3.0
        ]
        
        topTextField.defaultTextAttributes = memeTextAttributes
        bottomTextField.defaultTextAttributes = memeTextAttributes
    }
    
    func enablePickImageButtons(_ enable: Bool) {
        cameraButton.isEnabled = enable
        albumButton.isEnabled = enable
    }
}
