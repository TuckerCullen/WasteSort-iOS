//
//  EZTransition.swift
//  WasteSort
//
//  Created by Bryan Rombach on 1/17/20.
//  Copyright © 2020 Tucker  Cullen . All rights reserved.
//

import UIKit

class EZTransition: UIStoryboardSegue {
    override func perform() {
        // Add your own animation code here.
     
        [[self sourceViewController] presentViewController:[self destinationViewController] animated:NO completion:nil];
    }}
