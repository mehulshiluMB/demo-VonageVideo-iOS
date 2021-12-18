//
//  VideoCallVC.swift
//  Demo-Opentok
//
//  Created by Parth Dumaswala on 10/12/21.
//

import UIKit
import Photos
import OpenTok
import CoreImage

class VideoCallVC: UIViewController {
    
    //MARK: IBOutlets
    @IBOutlet var btnMute: UIButton!
    @IBOutlet var btnVideo: UIButton!
    @IBOutlet var btnEndCall: UIButton!
    @IBOutlet var btnSpeaker: UIButton!
    @IBOutlet var vwCallerSession: UIView!
    @IBOutlet var vwBottomOptions: UIView!
    @IBOutlet var collectionView: UICollectionView!
    
    //MARK:- Variables
    private let kAPIKey = "47399931"
    
    //SERVER GENERATED TOKEN AND SESSION ID
    private let kSessionId = "2_MX40NzM5OTkzMX5-MTYzOTgwNDUyMDYyOH5wTzlubXh2MUo2RkpEL08xREM5cFhKa0J-UH4"
    
    private let kToken = "T1==cGFydG5lcl9pZD00NzM5OTkzMSZzaWc9YmEzMmU5YzdjOTA2OTE2NWJkNDYwODEwMWNjMjg4NjBkNTUzM2Y0NzpzZXNzaW9uX2lkPTJfTVg0ME56TTVPVGt6TVg1LU1UWXpPVGd3TkRVeU1EWXlPSDV3VHpsdWJYaDJNVW8yUmtwRUwwOHhSRU01Y0ZoS2EwSi1VSDQmY3JlYXRlX3RpbWU9MTYzOTgwNDUyMiZub25jZT0wLjM4NjI2OTkzNDI5ODM4ODImcm9sZT1wdWJsaXNoZXImZXhwaXJlX3RpbWU9MTYzOTg5MDkyMiZpbml0aWFsX2xheW91dF9jbGFzc19saXN0PQ=="
    
    lazy var session: OTSession = { //1.
        return OTSession(apiKey: kAPIKey, sessionId: kSessionId, delegate: self)!
    }()
    
    private var publisher: OTPublisher?
    
    private var error: OTError?
    
    private var subscribers: [IndexPath: OTSubscriber] = [:]
    
    private var subscriberArray : [OTSubscriber] = []
    
    //MARK:- Page Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialConfig()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidLayoutSubviews() {
        self.decorateView()
    }
    
    //MARK:- Private Methods
    private func initialConfig() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: true)
        
        self.onConfigureVideoSession()
    }
    
    private func decorateView() {
        
        self.vwCallerSession.layer.borderWidth = 2
        self.vwCallerSession.layer.borderColor = UIColor.white.cgColor
        self.vwCallerSession.layer.cornerRadius = vwCallerSession.frame.height / 2
        
        vwBottomOptions.clipsToBounds = true
        vwBottomOptions.layer.cornerRadius = vwBottomOptions.frame.height / 2
        
        if #available(iOS 11.0, *) {
            vwBottomOptions.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] // Top right corner
        } else {
            // Fallback on earlier versions
        }
    }
    
    private func onConfigureVideoSession() {
        session.connect(withToken: kToken, error: &error) //2.
    }
    
    private func toggleVideoControls(_ isShow:Bool) {
        self.vwBottomOptions.isHidden = !isShow
    }
    
    private func reloadCollectionView() {
        
        DispatchQueue.main.async {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.isHidden = self.subscribers.count == 0
            self.collectionView.reloadData()
        }
        self.view.layoutSubviews()
    }
    
    private func doPublish() {
        
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.identifierForVendor?.uuidString
        
        guard let publisherIs = OTPublisher(delegate: self, settings: settings) else {
            return
        }
        self.publisher = publisherIs
        
        var error: OTError?
        session.publish(publisherIs, error: &error)
        guard error == nil else {
            print(error?.localizedDescription ?? "")
            return
        }
        
        guard let publisherView = publisherIs.view else {
            return
        }
        publisherView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        publisherView.clipsToBounds = true
        publisherView.layer.cornerRadius = 50
        self.vwCallerSession.addSubview(publisherView)
    }
    
    private func doSubscribe(to stream: OTStream) {
        
        if let subscriber = OTSubscriber(stream: stream, delegate: self) {
            let indexPath = IndexPath(item: subscribers.count, section: 0)
            subscribers[indexPath] = subscriber
            session.subscribe(subscriber, error: &error)
            subscriberArray.append(subscriber)
            reloadCollectionView()
        }
    }
    
    private func findSubscriber(byStreamId id: String) -> (IndexPath, OTSubscriber)? {
        
        for (_, entry) in subscribers.enumerated() {
            if let stream = entry.value.stream, stream.streamId == id {
                return (entry.key, entry.value)
            }
        }
        return nil
    }
}

//MARK: OTSessionDelegate
extension VideoCallVC: OTSessionDelegate {
    
    func sessionDidConnect(_ session: OTSession) {
        print(#function)
        
        self.session = session
        doPublish() //3.
    }
    
    func session(_ session: OTSession, connectionCreated connection: OTConnection) {
        print(connection)
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print(#function)

        subscribers.removeAll()
        reloadCollectionView()
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("A stream was created in the session.")
        
        if subscribers.count == 4 {
            print("Sorry, only supports up to 4 subscribers :)")
            return
        }
        doSubscribe(to: stream) //4.
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("A stream was destroyed in the session.")
    
        guard let (index, subscriber) = findSubscriber(byStreamId: stream.streamId) else {
            return
        }
        subscriber.view?.removeFromSuperview()
        subscribers.removeValue(forKey: index)
        reloadCollectionView()
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("\(#function): \(error.localizedDescription)")
    }
}

//MARK: OTPublisherDelegate callbacks
extension VideoCallVC: OTPublisherDelegate {
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        //MBAlertController.sharedAlert.showAlert(withTittle: "Publisher failed", message: error.localizedDescription, controller: self)
    }
}

//MARK: OTSubscriberDelegate callbacks
extension VideoCallVC: OTSubscriberDelegate {
    
    public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        print(#function)
        
        reloadCollectionView()
    }
    
    public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("\(#function): \(error.localizedDescription)")
        // MBAlertController.sharedAlert.showAlert(withTittle: "The subscriber failed to connect to the stream.", message: error.localizedDescription, controller: self)
    }
}

//MARK: IBActions
extension VideoCallVC {
    
    @IBAction func tapOnView(_ sender: Any) {
        self.toggleVideoControls(!self.vwBottomOptions.isHidden)
    }
    
    @IBAction func videoOptions_click(_ sender: UIButton) {
        
        switch sender.tag {
        case 2: ///Option button
            
            break
        case 3: ///Speaker
            let isSelected = !btnSpeaker.isSelected
            self.btnSpeaker.isSelected = isSelected
            let speakerImg = isSelected ? UIImage(named: "videoSpeakerOff") : UIImage(named: "videoSpeakerOn")
            self.btnSpeaker.setImage(speakerImg, for: .normal)
            
            for (index, _) in self.subscribers.enumerated() {
                let indexPath = IndexPath(row: index, section: 0)
                self.subscribers[indexPath]?.subscribeToAudio = !isSelected
            }
            
            break
        case 4: ///Screenshot
            
            break
        case 5: ///Chat
            break
        case 6: ///Mute - Mike
            let isSelected = !btnMute.isSelected
            self.btnMute.isSelected = isSelected
            let muteImg = isSelected ? UIImage(named: "videoMute")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "videoUnmute")
            self.btnMute.setImage(muteImg, for: .normal)
            self.btnMute.tintColor = .white
            
            self.publisher?.publishAudio = !isSelected
            
            break
        case 7: /// Video toggle
            let isSelected = !btnVideo.isSelected
            self.btnVideo.isSelected = isSelected
            let videoImg = isSelected ? UIImage(named: "videoOff")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "videoOn")
            self.btnVideo.setImage(videoImg, for: .normal)
            self.btnVideo.tintColor = .white
            
            self.publisher?.publishVideo = !isSelected
            
            break
        case 8: /// End Call
            ///Destro session here..
            session.disconnect(&error)
            self.dismiss(animated: true, completion: nil)
            break
        default:
            break
        }
    }
}

//MARK:- UICollectionViewCell Delegate & DataSource
extension VideoCallVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subscribers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubscriberCell", for: indexPath) as! SubscriberCell
        cell.tag = indexPath.row
        
        if subscribers.count > indexPath.row {
            
            let objSubscriber = self.subscribers[indexPath]
            cell.subscriber = objSubscriber
            
            cell.lblUsername.text = ""
            cell.imgProfile.isHidden = true
            
            if let isSubscribeToAudio = objSubscriber?.stream?.hasAudio, isSubscribeToAudio {
                cell.imgMuteStatus.image = UIImage(named: "videoUnmute")?.withRenderingMode(.alwaysTemplate)
            } else {
                cell.imgMuteStatus.image = UIImage(named: "videoMute")?.withRenderingMode(.alwaysTemplate)
            }
            cell.imgMuteStatus.tintColor = UIColor.red
            
            cell.vwContent.frame = cell.bounds
            cell.subscriber?.view?.frame = cell.bounds
            cell.imgMuteStatus.isHidden = subscribers.count == 1
            cell.layoutSubviews()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let totalSubscribers = self.subscribers.count
        var widthIs = self.collectionView.frame.size.width
        var heightIs = self.collectionView.frame.size.height
        
        if totalSubscribers ==  2 {
            widthIs = self.collectionView.frame.size.width
            heightIs = self.collectionView.frame.size.height / 2
        } else if totalSubscribers ==  3 {
            if indexPath.row == 0 || indexPath.row == 1 {
                widthIs = self.collectionView.frame.size.width / 2
                heightIs = self.collectionView.frame.size.height / 2
            } else {
                widthIs = self.collectionView.frame.size.width
                heightIs = self.collectionView.frame.size.height / 2
            }
        } else {
            widthIs = self.collectionView.frame.size.width
            heightIs = self.collectionView.frame.size.height
        }
        return CGSize(width: widthIs, height: heightIs)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.toggleVideoControls(self.vwBottomOptions.isHidden)
    }
}
