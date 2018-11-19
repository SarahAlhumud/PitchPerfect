//
//  SecondVC.swift
//  PitchPerfect
//
//  Created by SARA ALHUMUD on 2/30/1440 AH.
//  Copyright © 1440 SARA ALHUMUD. All rights reserved.
//

import UIKit
import AVFoundation


class SecondVC: UIViewController {
    
    var audioURL: URL!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayer: AVAudioPlayerNode!
    var pitchControl: AVAudioUnitTimePitch!
    var stopTimer: Timer!

    
    enum buttonType: Int {
        case echo = 0, reverb, slow, fast, lowPitch, highPitch
    }
    
    enum playingState {
        case playing, notPlaying
    }

    //MARK:- IBOutlet
    @IBOutlet weak var echoBtn: UIButton!
    @IBOutlet weak var reverbBtn: UIButton!
    @IBOutlet weak var slowBtn: UIButton!
    @IBOutlet weak var fastBtn: UIButton!
    @IBOutlet weak var lowPitchBtn: UIButton!
    @IBOutlet weak var hightPitchBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!

    // MARK: Alerts
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }


    @IBAction func playSoundForButton(_ sender: UIButton) {
        configureUI(.playing)
        
        switch (buttonType(rawValue: sender.tag)!){
        case .echo:
            playSound(isEcho: true)
        case .reverb:
            playSound(isReverb: true)
        case .slow:
            playSound(rate: 0.5)
        case .fast:
            playSound(rate: 1.5)
        case .lowPitch:
            playSound(pitch: -1000)
        case .highPitch:
            playSound(pitch: 1000)
        }
        
        
    }
    
    @IBAction func stopButtonPressed(_ sender: AnyObject) {
        print("Stop Audio Button Pressed")
        stopAudio()
    }

    
    
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, isEcho: Bool = false, isReverb: Bool = false) {

        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayer = AVAudioPlayerNode()
        
        pitchControl = AVAudioUnitTimePitch()
        
        // node for rate
        if let rate = rate {
            pitchControl.rate = rate
        }
        
        // node for pitch
        if let pitch = pitch {
            pitchControl.pitch = pitch
        }
        
        // attch the components to our playback engine
        audioEngine.attach(audioPlayer)
        audioEngine.attach(pitchControl)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // arrange the parts so that output from one is input to another
        if isEcho && isReverb {
            connectNode(audioPlayer, pitchControl, echoNode, reverbNode, audioEngine.outputNode);
        } else if isEcho {
            connectNode(audioPlayer, pitchControl, echoNode, audioEngine.outputNode);
        } else if isReverb {
            connectNode(audioPlayer, pitchControl, reverbNode, audioEngine.outputNode);
        } else {
            connectNode(audioPlayer, pitchControl, audioEngine.outputNode);
        }
        
        // prepare the player to play its audioFile from the beginning
        audioPlayer.stop()
        audioPlayer.scheduleFile(audioFile, at: nil){
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayer.lastRenderTime, let playerTime = self.audioPlayer.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(SecondVC.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
        
        // start the engine and player
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        // play the recording!
        audioPlayer.play()

    }
    
    @objc func stopAudio() {
        
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        configureUI(.notPlaying)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    func connectNode(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1],format: audioFile.processingFormat)
        }
    }
    
    func configureUI(_ playingState: playingState){
        switch playingState {
        case .playing:
            enablingPlayingBtn(false)
            stopBtn.isEnabled = true
        case .notPlaying:
            enablingPlayingBtn(true)
            stopBtn.isEnabled = false
        }
        
    }
    
    func enablingPlayingBtn(_ isEnabled: Bool){
        echoBtn.isEnabled = isEnabled
        reverbBtn.isEnabled = isEnabled
        slowBtn.isEnabled = isEnabled
        fastBtn.isEnabled = isEnabled
        lowPitchBtn.isEnabled = isEnabled
        hightPitchBtn.isEnabled = isEnabled
        
    }
    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI(.notPlaying)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // load the audioFile
        do {
            audioFile = try AVAudioFile(forReading: audioURL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
        
        stopBtn.isEnabled = false
        
        slowBtn.imageView?.contentMode = .scaleAspectFit
        fastBtn.imageView?.contentMode = .scaleAspectFit
        hightPitchBtn.imageView?.contentMode = .scaleAspectFit
        lowPitchBtn.imageView?.contentMode = .scaleAspectFit
        echoBtn.imageView?.contentMode = .scaleAspectFit
        reverbBtn.imageView?.contentMode = .scaleAspectFit
        stopBtn.imageView?.contentMode = .scaleAspectFit
    }

}
