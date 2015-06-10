//
//  Ruler.swift
//  Free Ruler
//
//  Created by Pascal on 6/9/15.
//  Copyright (c) 2015 Pascal. All rights reserved.
//

import Foundation

class Ruler: NSObject {
	var length: Int
	var opacity: Float
	
	override init() {
		self.length = 200
		self.opacity = 1
	}
	
	init(length: Int, opacity: Float) {
		self.length = length
		self.opacity = opacity
	}
	
}