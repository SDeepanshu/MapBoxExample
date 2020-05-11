//
//  Feature.swift
//  MapBoxDemoApp
//
//  Created by Rahul Sharma on 23/08/19.
//  Copyright © 2019 Rahul Sharma. All rights reserved.
//

import Foundation

struct Feature: Codable {
    var id: String!
    var type: String?
    var matching_place_name: String?
    var place_name: String?
    var geometry: Geometry
    var center: [Double]
    var properties: Properties
}

struct Geometry: Codable {
    var type: String?
    var coordinates: [Double]
}

struct Properties: Codable {
    var address: String?
}

struct PlaceName : Codable{
    var place_name: String?

}
