import Foundation
import Metal

struct UUIDGenerator {
    static func run() {
        let arguments = CommandLine.arguments

        guard arguments.count >= 5,
              arguments[1] == "--quantity",
              let quantity = Int(arguments[2]),
              arguments[3] == "--prefix" else {
            printUsage()
            exit(1)
        }

        let prefix = arguments[4]

        guard isValidHexPrefix(prefix) else {
            print("Error: Invalid hex prefix")
            exit(1)
        }

        let generator = UUIDMetalGenerator()
        generator.generateUUIDs(quantity: quantity, prefix: prefix)
    }

    static func printUsage() {
        print("Usage: uuidx --quantity <number> --prefix <hex_prefix>")
        print("Example: uuidx --quantity 100 --prefix fff")
        print("Note: prefix can be up to 8 hex characters (0-9, a-f, A-F)")
    }

    static func isValidHexPrefix(_ prefix: String) -> Bool {
        let cleanPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexCharacters = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return cleanPrefix.count <= 8 && cleanPrefix.unicodeScalars.allSatisfy { hexCharacters.contains($0) }
    }
}

class UUIDMetalGenerator {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    private let function: MTLFunction
    private let pipelineState: MTLComputePipelineState

    init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to initialize Metal device or command queue")
        }

        let libraryPath = "default.metallib"
        guard let libraryURL = URL(string: libraryPath),
              let library = try? device.makeLibrary(URL: libraryURL),
              let function = library.makeFunction(name: "generateUUID"),
              let pipelineState = try? device.makeComputePipelineState(function: function) else {
            fatalError("Failed to initialize Metal library or pipeline state")
        }

        self.device = device
        self.commandQueue = commandQueue
        self.library = library
        self.function = function
        self.pipelineState = pipelineState
    }

    func generateUUIDs(quantity: Int, prefix: String) {
        let bufferSize = quantity * MemoryLayout<UInt32>.size * 4
        guard let buffer = device.makeBuffer(length: bufferSize, options: .storageModeShared) else {
            fatalError("Failed to create buffer")
        }

        // Convert prefix to proper format (up to 8 hex digits)
        let cleanPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var prefixValue = UInt32(cleanPrefix, radix: 16) ?? 0
        var prefixLength = UInt32(cleanPrefix.count)
        var timestamp = UInt32(truncatingIfNeeded: Int(Date().timeIntervalSince1970))

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create command buffer or encoder")
        }

        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(buffer, offset: 0, index: 0)
        computeEncoder.setBytes(&prefixValue, length: MemoryLayout<UInt32>.size, index: 1)
        computeEncoder.setBytes(&timestamp, length: MemoryLayout<UInt32>.size, index: 2)
        computeEncoder.setBytes(&prefixLength, length: MemoryLayout<UInt32>.size, index: 3)

        let threadsPerGroup = MTLSize(width: 256, height: 1, depth: 1)
        let numThreadgroups = MTLSize(
            width: (quantity + 255) / 256,
            height: 1,
            depth: 1
        )

        computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let data = Data(bytesNoCopy: buffer.contents(),
                       count: bufferSize,
                       deallocator: .none)

        printUUIDs(data: data, count: quantity)
    }

    private func printUUIDs(data: Data, count: Int) {
        data.withUnsafeBytes { rawBuffer in
            let uuidBuffer = rawBuffer.bindMemory(to: UInt32.self)

            for i in 0..<count {
                let index = i * 4
                let uuid = String(format: "%08x-%04x-%04x-%04x-%012x",
                                uuidBuffer[index],
                                uuidBuffer[index + 1] >> 16,
                                uuidBuffer[index + 1] & 0xFFFF,
                                uuidBuffer[index + 2] >> 16,
                                ((UInt64(uuidBuffer[index + 2] & 0xFFFF) << 32) | UInt64(uuidBuffer[index + 3])))
                print(uuid)
            }
        }
    }
}

// Start the program
UUIDGenerator.run()