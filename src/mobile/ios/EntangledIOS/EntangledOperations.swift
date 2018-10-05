//
//  EntangledOperations.swift
//  iotaWallet
//
//  Created by Rajiv Shah on 10/5/18.
//  Copyright © 2018 IOTA Foundation. All rights reserved.
//

import Foundation

enum BatchState {
  case pending, completed, failed
}

// MARK: Address generation
@objc public class AddressBatch: NSObject {
  let seed: UnsafeMutableRawPointer
  let index: Int
  let security: Int
  let total: Int
  var addresses: [String] = []
  var state = BatchState.pending
  @objc init(seed: UnsafePointer<CChar>, index: Int, security: Int, total: Int) {
    memcpy(self.seed, seed, strlen(seed))
    self.index = index
    self.security = security
    self.total = total
  }
}

class AddressGenerator: Operation {
  let addressBatch: AddressBatch
  
  init(addressBatch: AddressBatch) {
    self.addressBatch = addressBatch
  }
  
  override func main() {
    
    if isCancelled {
      return
    }
    
    var i = 0
    let addressSeed = addressBatch.seed.load(as: UnsafePointer<CChar>.self)
    var addressIndex = CInt(addressBatch.index)
    let addressSecurity = CInt(addressBatch.security)
    var addresses = addressBatch.addresses
    
    repeat {
      if isCancelled {
        return
      }
      let address = generateAddress(addressSeed, addressIndex, addressSecurity)
      let addressString = String.init(cString: address!)
      addresses.append(addressString)
      i += 1
      addressIndex += 1
    } while i < addressBatch.total
    
    if addresses.isEmpty {
      addressBatch.state = .failed
    } else {
      addressBatch.addresses = addresses
      addressBatch.state = .completed
    }
  }
}

var addressGenerationQueue: OperationQueue = {
  var queue = OperationQueue()
  queue.name = "Entangled - Address Generation"
  queue.maxConcurrentOperationCount = 1
  return queue
}()

@objc public class GenerateAddresses: NSObject {
  @objc func generateAddresses(addressBatch: AddressBatch) {
    let addressGenerator = AddressGenerator(addressBatch: addressBatch)
    
    addressGenerator.completionBlock = {
      if addressGenerator.isCancelled {
        return
      }
      let entangledIOS = EntangledIOS()
      entangledIOS.addressesGenerated(addressBatch.addresses)
    }
    
    addressGenerationQueue.addOperation(addressGenerator)
  }
}
