//
//  AdsViewController.swift
//  HomeWork
//
//  Created by Robert on 7/2/17.
//  Copyright © 2017 Robert. All rights reserved.
//

import UIKit

protocol AdsProtocol : class {
    func finishTime()
}

class AdsViewController: UIViewController {

    @IBOutlet weak var lblTime: UILabel!
    var currentSecond = 30;
    weak var delegate:AdsProtocol?
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func updateTime() {
        currentSecond -= 1;
        if currentSecond > 0 {
            let second = currentSecond <= 9 ? "0\(currentSecond)" : "\(currentSecond)"
            self.lblTime.text = "00:\(second)"
        } else {
            timer?.invalidate()
            self.delegate?.finishTime()
        }
    }

}
