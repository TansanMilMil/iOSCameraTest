import UIKit
import Foundation

class FaceDetectionController: UIViewController {

    var faceTracker: FaceTracker? = nil
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imageState: UILabel!
    var destroyViewAsync: DispatchWorkItem = DispatchWorkItem() {}
    
    var rectView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageState.text = ""
        self.rectView.layer.borderWidth = 1
        self.rectView.layer.borderColor = UIColor.green.cgColor
        self.view.addSubview(self.rectView)
        faceTracker = FaceTracker(
            viewForDisplay: self.cameraView,
            findface: {
                arr in let rect = arr[0]
                self.rectView.frame = rect
            },
            imageState: self.imageState
        )
        // 非同期で一定時間後にViewを閉じる
        destroyViewAsync = DispatchWorkItem() {
            self.destroyView()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 60, execute: destroyViewAsync)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        destroyViewAsync.cancel()
    }

    @IBAction func closeView(_ sender: Any) {
        destroyView()
    }
    
    private func destroyView() {
        self.dismiss(animated: true, completion: nil)
    }
}

