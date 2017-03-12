//
//  ResultViewController.swift
//  HomeWork
//
//  Created by Robert on 11/3/17.
//  Copyright © 2017 Robert. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {

    @IBOutlet weak var tvResult: UITextView!
    var results:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for result in results {
            tvResult.text.append(result + "\n")
        }
        
    }
    
}
