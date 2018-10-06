//
//  EntangledDispatch.swift
//  iotaWallet
//
//  Created by Rajiv Shah on 10/5/18.
//  Copyright © 2018 IOTA Foundation. All rights reserved.
//

import Foundation

/// Manages the GCD queue for Entangled PoW
@objc class EntangledPowQueue: NSObject {
  let trytes: [String]
  let minWeightMagnitude: CInt
  let resolve: RCTPromiseResolveBlock
  let reject: RCTPromiseRejectBlock
  let queue = DispatchQueue.init(label: "EntangledIOS Address Generation")
  @objc init(trytes: [String], minWeightMagnitude: CInt, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.trytes = trytes
    self.minWeightMagnitude = minWeightMagnitude
    self.resolve = resolve
    self.reject = reject
  }

  /// Starts the PoW queue
  @objc func start() {
    let powGroup = DispatchGroup.init()
    var nonces: Array<String> = []
    for tryteElement in self.trytes {
        powGroup.enter()
        let trytesC = tryteElement.cString(using: String.Encoding.utf8)
        let nonceC = doPOW(trytesC!, self.minWeightMagnitude)
        let nonce = String.init(cString: nonceC!)
        nonces.append(nonce)
        powGroup.leave()
    }
    // Block the thread until all PoW jobs finish
    powGroup.wait()
    self.resolve(nonces)
  }
}
