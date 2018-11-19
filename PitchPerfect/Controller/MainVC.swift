//
//  MainVC.swift
//  PitchPerfect
//
//  Created by SARA ALHUMUD on 2/25/1440 AH.
//  Copyright © 1440 SARA ALHUMUD. All rights reserved.
//

import UIKit
import AVFoundation

class MainVC: UIViewController {

    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopBtn: UIButton!
    
    var audioRecorder: AVAudioRecorder!

    @IBAction func startRecording(_ sender: UIButton) {
        print("Recording is in progress.")
        configureUI(isRecording: true, recordingLabelText: "Recording is in progress.")
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, with:AVAudioSessionCategoryOptions.defaultToSpeaker)

        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder?.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        print("Recording is stoped.")
        configureUI(isRecording: false, recordingLabelText: "Tap to record.")
        
        audioRecorder.stop()
        let session = AVAudioSession.sharedInstance()
        try! session.setActive(false)
    
    }
    
    func configureUI(isRecording: Bool, recordingLabelText: String) {

        recordingLabel.text = recordingLabelText
        recordBtn.isEnabled = !isRecording
        stopBtn.isEnabled = isRecording
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stopBtn.isEnabled = false
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToSecondVC" {
            let secondVC = segue.destination as? SecondVC
            let audioURL = sender as! URL
            secondVC?.audioURL = audioURL
        }
    }


}

extension MainVC: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool){
        if flag {
        performSegue(withIdentifier: "GoToSecondVC", sender: audioRecorder.url)
        } else {
            print("Recording is faild")
            let alert = UIAlertController(title: "Recording Failed", message: "Recording is faild", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
}



