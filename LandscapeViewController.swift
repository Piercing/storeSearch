//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Piercing on 28/6/18.
//  Copyright © 2018 com.devspain. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {

    // Para comprobar por consola que el objeto se
    // cancela correcta/ cuando la pantalla se cierra.
    deinit {
        print("deinit \(self)")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
