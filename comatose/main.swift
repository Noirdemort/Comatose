//
//  main.swift
//  comatose
//
//  Created by Noirdemort on 31/03/20.
//  Copyright © 2020 Noirdemort. All rights reserved.
//

import Foundation
import MetalKit


func simplePipeline(){
 
    let device: MTLDevice! = MTLCreateSystemDefaultDevice()
/// Check for GPU devices other than Inbuilt Graphics card
//    let devices: [MTLDevice] = MTLCopyAllDevices()
//    for metalDevice: MTLDevice in devices {
//        if metalDevice.isHeadless {
//            device = metalDevice
//        }
//    }
//    // exit with an error message if all devices are used by monitor
//    if !device.isHeadless {
//        print("no dedicated device found")
//        exit(1)
//    }
    
    let commandQueue: MTLCommandQueue! = device.makeCommandQueue()

    _ = commandQueue.makeCommandBuffer()
    
    
    let args = CommandLine.arguments
    
    if args.count < 3 {
        print("Usage: comatose base<int> operand<int> // comatose 3 5 -> 3^5 Operations")
        exit(EXIT_FAILURE)
    }
    
    let start = Date()

    
    let K = Int(args[1])!
    let L = Int(args[2])!
    
    let numberOfStates = Int(pow(Double(K), Double(L)))
    let unitSize = MemoryLayout<Float>.size
    let resultBufferSize = numberOfStates*unitSize
    
    let resourceOption = MTLResourceOptions()
    
    let buffer: [MTLBuffer] = [
        device.makeBuffer(length: resultBufferSize, options: resourceOption)!,
        device.makeBuffer(length: resultBufferSize, options: resourceOption)!,
        device.makeBuffer(length: resultBufferSize, options: resourceOption)!,
        device.makeBuffer(length: resultBufferSize, options: resourceOption)!,
    ]
    
    let threadExecutionWidth = 512
    
    
    let numThreadsPerGroup = MTLSize(width:threadExecutionWidth, height:1, depth:1)

    let dist: [Float] = [1.0, 3.4, 4.5, 2.3, 6.9, 4.5, 2.2, 5.3, 5.2, 4.3, 3.4, 5.4, 2.3, 22, 1.1, 4.3]
    
    let paramemterVector: [Float] = [
        1.0,
        8,
        3.0,
        45,
        2.1,
        5,
        3.4,
        64,
        2.3,
        5,
        11,
        7
    ]
    
    let p2: [Float] = [1.3, 10.0, 2, 54.0, 65.0, 2.1, 54.0, 3.4, 5.2, 5.6, 5.3, 7.2]
    
    let pb: MTLBuffer = device.makeBuffer(bytes: p2, length: MemoryLayout<Double>.size*p2.count, options: resourceOption)!
    let parameterBuffer: MTLBuffer = device.makeBuffer(bytes: paramemterVector, length: unitSize*paramemterVector.count, options: resourceOption)!
       
    let distributionBuffer: MTLBuffer = device.makeBuffer(bytes: dist, length: unitSize*dist.count, options: resourceOption)!
    
//    device.makeLibrary(filepath: <#T##String#>)
    let DPLibrary: MTLLibrary! = device.makeDefaultLibrary()
    let initDP = DPLibrary.makeFunction(name: "initialize")
    let pipelineFilterInit = try! device.makeComputePipelineState(function: initDP!)
    let iterateDP = DPLibrary.makeFunction(name: "iterate")
    _ = try! device.makeComputePipelineState(function: iterateDP!)
    
    let iterateXDP = DPLibrary.makeFunction(name: "iterateX")
    let pipelineFilterIterateX = try! device.makeComputePipelineState(function: iterateXDP!)
    
    
    
    for l in 1...L {

        let batchSize:uint = uint(pow(Float(K),Float(l-1)))
        let numGroupsBatch = MTLSize(width:(Int(batchSize)+threadExecutionWidth-1)/threadExecutionWidth, height:1, depth:1)
        
         print("Batch Size = ", batchSize)
        
        for batchIndex in 1..<uint(K) {
            
            let dispatchIterator: [uint] = [batchSize, batchIndex]
            let dispatchBuffer: MTLBuffer = device.makeBuffer(bytes: dispatchIterator, length: MemoryLayout<uint>.size*dispatchIterator.count, options: resourceOption)!
            
            let commandBufferInitDP: MTLCommandBuffer! = commandQueue.makeCommandBuffer()
            let encoderInitDP = commandBufferInitDP.makeComputeCommandEncoder()

            encoderInitDP!.setComputePipelineState(pipelineFilterInit)

            encoderInitDP!.setBuffer(buffer[0], offset: 0, index: 0)
            encoderInitDP!.setBuffer(dispatchBuffer, offset: 0, index: 1)
            encoderInitDP!.setBuffer(parameterBuffer, offset: 0, index: 2)

            encoderInitDP!.dispatchThreadgroups(numGroupsBatch, threadsPerThreadgroup: numThreadsPerGroup)
            encoderInitDP!.endEncoding()
            commandBufferInitDP.commit()
            commandBufferInitDP.waitUntilCompleted()
        }
    }
    
    
    for i in 1...3 {
        for l in 0...L {
            var batchSize: uint = 1
            var batchNum: uint = 1
            var batchStart: uint = 0
            if l>0 {
                batchSize = uint(pow(Float(K),Float(l-1)))
                batchStart = 1
                batchNum = uint(K)
            }

            let numGroupsBatch = MTLSize(width:(Int(batchSize)+threadExecutionWidth-1)/threadExecutionWidth, height:1, depth:1)

            for batchIndex in batchStart..<batchNum {

                //print("Iterate Batch Size = ", batchSize, "batchIndex = ", batchIndex)
                
                let dispatchIterator: [uint] = [batchSize, batchIndex, uint(i)]
                let dispatchBuffer:MTLBuffer = device.makeBuffer(bytes: dispatchIterator, length: MemoryLayout<uint>.size*dispatchIterator.count, options: resourceOption)!
                
                let commandBufferIterateDP: MTLCommandBuffer! = commandQueue.makeCommandBuffer()
                let encoderIterateDP = commandBufferIterateDP.makeComputeCommandEncoder()
                
//                encoderIterateDP!.setComputePipelineState(pipelineFilterIterate)
//
//                encoderIterateDP!.setBuffer(buffer[i%2], offset: 0, index: 0)
//                encoderIterateDP!.setBuffer(buffer[(i+1)%2], offset: 0, index: 1)
//                encoderIterateDP!.setBuffer(buffer[2], offset: 0, index: 2)
//                encoderIterateDP!.setBuffer(buffer[3], offset: 0, index: 3)
//                encoderIterateDP!.setBuffer(dispatchBuffer, offset: 0, index: 4)
//                encoderIterateDP!.setBuffer(parameterBuffer, offset: 0, index: 5)
//                encoderIterateDP!.setBuffer(distributionBuffer, offset: 0, index: 6)
                
                encoderIterateDP!.setComputePipelineState(pipelineFilterIterateX)
               
                encoderIterateDP!.setBuffer(buffer[0], offset: 0, index: 0)
                encoderIterateDP!.setBuffer(buffer[1], offset: 0, index: 1)
                encoderIterateDP!.setBuffer(pb, offset: 0, index: 2)
                encoderIterateDP!.setBuffer(distributionBuffer, offset: 0, index: 3)
                encoderIterateDP!.setBuffer(dispatchBuffer, offset: 0, index: 4)
                
                encoderIterateDP!.dispatchThreadgroups(numGroupsBatch, threadsPerThreadgroup: numThreadsPerGroup)
                encoderIterateDP!.endEncoding()
                commandBufferIterateDP.commit()
                commandBufferIterateDP.waitUntilCompleted()

            }
        }
        
    }
    
    
    // Get data from device
    let data = Data(bytesNoCopy: buffer[1].contents(), count: resultBufferSize, deallocator: .unmap)
    
    
    let finalResultArray: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer.allocate(capacity: numberOfStates)
    
    defer {
        finalResultArray.deallocate()
    }
    
    _ = data.copyBytes(to: finalResultArray)

    print(finalResultArray)
//    finalResultArray.forEach({val in
//        print(val)
//    })
    
    // Output data
//    for i in 0...numberOfStates-1{
//
//        print(finalResultArray[i])
//
//    }
  
    let end = Date()
    print("The time elapsed is ", Double(end.timeIntervalSince(start)))

    
}


simplePipeline()
