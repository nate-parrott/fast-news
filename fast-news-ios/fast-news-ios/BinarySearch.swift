//
//  BinarySearch.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 2/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

// via http://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array

func binarySearch<T:Comparable>(inputArr:Array<T>, searchItem: T)->Int{
    var lowerIndex = 0;
    var upperIndex = inputArr.count - 1
    
    while (true) {
        let currentIndex = (lowerIndex + upperIndex)/2
        if(inputArr[currentIndex] == searchItem) {
            return currentIndex
        } else if (lowerIndex > upperIndex) {
            return -1
        } else {
            if (inputArr[currentIndex] > searchItem) {
                upperIndex = currentIndex - 1
            } else {
                lowerIndex = currentIndex + 1
            }
        }
    }
}
