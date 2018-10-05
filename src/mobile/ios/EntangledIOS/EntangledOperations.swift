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
public class AddressBatch {
  let seed: UnsafePointer<CChar>
  let index: Int
  let security: Int
  let total: Int
  var addresses: [String] = []
  var state = BatchState.pending
  init(_ seed: UnsafePointer<CChar>, index: Int, security: Int, total: Int) {
    self.seed = seed
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
    var addressIndex = CInt(addressBatch.index)
    let addressSecurity = CInt(addressBatch.security)
    var addresses = addressBatch.addresses
    
    repeat {
      if isCancelled {
        return
      }
      let address = generateAddress(addressBatch.seed, addressIndex, addressSecurity)
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

func generateAddresses(for addressBatch: AddressBatch) {
  let addressGenerator = AddressGenerator(addressBatch: addressBatch)
  
  addressGenerator.completionBlock = {
    if addressGenerator.isCancelled {
      return
    }
  }
  
  addressGenerationQueue.addOperation(addressGenerator)
}
