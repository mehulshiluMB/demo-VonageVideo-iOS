//
//  SubscriberCell.swift
//  Demo-Opentok
//
//  Created by Parth Dumaswala on 10/12/21.
//

import UIKit
import OpenTok

class SubscriberCell: UICollectionViewCell {
    
    @IBOutlet var vwContent: UIView!
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var imgMuteStatus: UIImageView!
    @IBOutlet var lblUsername: UILabel!
    
    var subscriber: OTSubscriber?
    
    override func layoutSubviews() {
        super.layoutSubviews()

        vwContent.layoutSubviews()
        if let sub = subscriber, let subView = sub.view {
            subView.frame = self.vwContent.bounds
            subView.clipsToBounds = true
            vwContent.addSubview(subView)
        }
    }
}
