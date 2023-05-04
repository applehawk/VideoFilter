
import UIKit

import SwiftyCam
import RecordButton
import GPUImage
import YPImagePicker


class ViewController: UIViewController {
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet var filterView: GPUImageView?
    
    var progressTimer : Timer!
    var progress : Double! = 0
    let maximumVideoDuration = 1.0
    
    let videoCamera: GPUImageVideoCamera
    var blendImage: GPUImagePicture?
    
    var iterratorFilters = filterOperations.enumerated().makeIterator()
    
    var filterOperation: FilterOperationInterface? {
        didSet {
            self.configureView()
        }
    }
    
    required init(coder aDecoder: NSCoder)
    {
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.vga640x480.rawValue, cameraPosition: AVCaptureDevice.Position.back)
        videoCamera.outputImageOrientation = .portrait;
        
        super.init(coder: aDecoder)!
    }
    
    func configureView() {
        if let currentFilterConfiguration = self.filterOperation {
            self.title = currentFilterConfiguration.titleName
            
            videoCamera.removeAllTargets()
            // Configure the filter chain, ending with the view
            if let view = self.filterView {
                switch currentFilterConfiguration.filterOperationType {
                case .SingleInput:
                    videoCamera.addTarget((currentFilterConfiguration.filter as! GPUImageInput))
                    currentFilterConfiguration.filter.addTarget(view)
                case .Blend:
                    videoCamera.addTarget((currentFilterConfiguration.filter as! GPUImageInput))
                    let inputImage = UIImage(named:"WID-small.jpg")
                    self.blendImage = GPUImagePicture(image: inputImage)
                    self.blendImage?.addTarget((currentFilterConfiguration.filter as! GPUImageInput))
                    self.blendImage?.processImage()
                    currentFilterConfiguration.filter.addTarget(view)
                case let .Custom(filterSetupFunction:setupFunction):
                    let inputToFunction:(GPUImageOutput, GPUImageOutput?) = try! setupFunction(videoCamera, view) // Type inference falls down, for now needs this hard cast
                    currentFilterConfiguration.configureCustomFilter(input: inputToFunction)
                }
                
                videoCamera.startCapture()
            }
            
            // Hide or display the slider, based on whether the filter needs it
            /*if let slider = self.filterSlider {
                switch currentFilterConfiguration.sliderConfiguration {
                case .Disabled:
                    slider.isHidden = true
                //                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
                case let .Enabled(minimumValue, maximumValue, initialValue):
                    slider.minimumValue = minimumValue
                    slider.maximumValue = maximumValue
                    slider.value = initialValue
                    slider.isHidden = false
                    self.updateSliderValue()
                }
            }
            */
            
        }
    }
    
    @IBAction func swipeAction(_ swipe: UISwipeGestureRecognizer) {
        if swipe.direction == .left {
            print("left swipe")
            //let currentOperation = iterratorFilters.next()
           // filterOperation = currentOperation
        }
        if swipe.direction == .right {
            if let currentOperation = self.iterratorFilters.next() {
                self.filterOperation = currentOperation.element
            }
            print("right swipe")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordButton.addTarget(self, action: #selector(record), for: .touchDown)
        recordButton.addTarget(self, action: #selector(updateProgress), for: .touchUpInside)
        
        let gesture =  UISwipeGestureRecognizer(target: self, action: #selector(swipeAction))
        gesture.direction = .left
        self.view.addGestureRecognizer(gesture)
        let gesture2 =  UISwipeGestureRecognizer(target: self, action: #selector(swipeAction))
        gesture2.direction = .right
        self.view.addGestureRecognizer(gesture2)
        
        self.view.isUserInteractionEnabled = true
        
        videoCamera.startCapture()
    }
    
    @objc func updateProgress() {
        let maxDuration = self.maximumVideoDuration // Max duration of the recordButton
        print(maxDuration)
        progress = progress + (0.05 / self.maximumVideoDuration)
        recordButton.setProgress(CGFloat(progress))
        
        if progress >= 1 {
            progressTimer.invalidate()
        }
        
    }
    
    @objc func record() {
        //self.startVideoRecording()
        self.progressTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.updateProgress), userInfo: nil, repeats: true)
    }
    
    @objc func stop() {
        //self.stopVideoRecording()
        self.recordButton.setProgress(0.0)
        self.progress = 0
        self.progressTimer.invalidate()
    }

}

