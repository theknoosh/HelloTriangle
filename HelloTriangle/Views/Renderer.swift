//
//  Renderer.swift
//  HelloTriangle
//
//  Created by DARRELL A PAYNE on 9/19/22.
//

import MetalKit
import Foundation

class Renderer: NSObject, MTKViewDelegate {
    
    var parent: ContentView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue
    let pipelineState: MTLRenderPipelineState
    var scene: RenderScene
    let mesh: TriangleMesh
    
    init(_ parent: ContentView) {
        
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()!
        
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            try pipelineState = metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError()
        }
        
        
        mesh = TriangleMesh(metalDevice: metalDevice)
        
        scene = RenderScene()
        
        super.init()
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        scene.update()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        let commandBuffer = metalCommandQueue.makeCommandBuffer()
        
        let rendererPassDescriptor = view.currentRenderPassDescriptor
        rendererPassDescriptor?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.5, 0.5, 1.0)
        rendererPassDescriptor?.colorAttachments[0].loadAction = .clear
        rendererPassDescriptor?.colorAttachments[0].storeAction = .store
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rendererPassDescriptor!)
        
        var cameraData: CameraParameters = CameraParameters()
        cameraData.view = Matrix44.create_lookat(
            eye: scene.player.position,
            target: scene.player.position + scene.player.forwards,
            up: scene.player.up
        )
        cameraData.projection = Matrix44.create_perspective_projection(
            fovy: 45, aspect: 800/600, near: 0.1, far: 10
        )
        renderEncoder?.setVertexBytes(&cameraData, length: MemoryLayout<CameraParameters>.stride, index: 2)
        
        for triangle in scene.triangles {
            
            var modelMatrix: matrix_float4x4 = Matrix44.create_from_rotation(eulers: triangle.eulers)
            modelMatrix = Matrix44.create_from_translation(translation: triangle.position) * modelMatrix;
            renderEncoder?.setVertexBytes(&modelMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
            
            renderEncoder?.setRenderPipelineState(pipelineState)
            renderEncoder?.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }
        
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
    }
}
