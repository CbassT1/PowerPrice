import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let session = AVCaptureSession()
        
        // Configurar la cámara trasera
        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device) {
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.frame
            view.layer.addSublayer(previewLayer)
            
            // Iniciar la sesión de video en segundo plano
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
