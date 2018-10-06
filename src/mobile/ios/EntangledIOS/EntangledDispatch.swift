//
//  EntangledDispatch.swift
//  iotaWallet
//
//  Created by Rajiv Shah on 10/5/18.
//  Copyright © 2018 IOTA Foundation. All rights reserved.
//

import Foundation

@objc class EntangledPowQueue: NSObject {
  let trytes: [String]
  let minWeightMagnitude: CInt
  let resolve: RCTPromiseResolveBlock
  let reject: RCTPromiseRejectBlock
  @objc init(trytes: [String], minWeightMagnitude: CInt, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.trytes = trytes
    self.minWeightMagnitude = minWeightMagnitude
    self.resolve = resolve
    self.reject = reject
  }
  
  @objc func start() {
    let powGroup = DispatchGroup.init()
    var workItems: Array<DispatchWorkItem> = []
    let groupedItems = splitItems(array: self.trytes, groups: 3)
    var nonces: Array<String> = []
    for group in groupedItems {
      let item = DispatchWorkItem.init(block: {
        powGroup.enter()
        for item in group {
          let trytesC = item.cString(using: String.Encoding.utf8)
          let nonceC = doPOW(trytesC!, self.minWeightMagnitude)
          let nonce = String.init(cString: nonceC!)
          nonces.append(nonce)
        }
        powGroup.leave()
      })
      workItems.append(item)
    }
    powGroup.wait()
    self.resolve(nonces)
  }
}

func splitItems(array: [String], groups: Int) -> [[String]] {
  let items = array.count
  let remainder = items % groups
  let groupLimit = items / groups
  var groupedItems: Array<Array<String>> = []
  var i = 0, j = 0, k = 0
  repeat {
    i = 0
    var group: Array<String> = []
    repeat {
      group.append(array[i])
      i += 1
    } while i < groupLimit
    groupedItems.append(group)
    j += 1
  } while j < (items - remainder)
  
  if remainder != 0 {
    repeat {
      groupedItems[groupedItems.count - 1].append(array[items - remainder + k])
      k += 1
    } while k < remainder
  }
  
  return groupedItems
}
