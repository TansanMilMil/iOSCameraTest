import UIKit

class ViewController: UIViewController {

    var faceTracker: FaceTracker? = nil
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imageState: UILabel!
    
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
    }


}

