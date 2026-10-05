// Shows an iPhone's screen, over USB, in a window: the phone's own screen
// capture source (muxed), never a camera. Exits if there is none.
import AVFoundation
import AppKit
import CoreMediaIO

var prop = CMIOObjectPropertyAddress(
  mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
  mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
  mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
var allow: UInt32 = 1
CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil,
                          UInt32(MemoryLayout<UInt32>.size), &allow)

func phone() -> AVCaptureDevice? {
  AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .muxed,
                                   position: .unspecified).devices.first
}
var dev: AVCaptureDevice?
let deadline = Date().addingTimeInterval(15)
while dev == nil && Date() < deadline {
  RunLoop.main.run(until: Date().addingTimeInterval(0.5)); dev = phone()
}
guard let dev else { FileHandle.standardError.write("no iPhone screen source: is it plugged in, unlocked and trusted?\n".data(using: .utf8)!); exit(1) }

let session = AVCaptureSession()
session.addInput(try! AVCaptureDeviceInput(device: dev))
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let h: CGFloat = CGFloat(Double(CommandLine.arguments.dropFirst().first ?? "") ?? 820)
let win = NSWindow(contentRect: NSRect(x: 60, y: 60, width: h * 1290 / 2796, height: h),
                   styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
win.title = "iPhone"
let view = NSView(frame: win.contentView!.bounds)
view.wantsLayer = true
let layer = AVCaptureVideoPreviewLayer(session: session)
layer.videoGravity = .resizeAspect
layer.frame = view.bounds
layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
view.layer = layer
win.contentView = view
win.makeKeyAndOrderFront(nil)
session.startRunning()
print("showing \(dev.localizedName)")
app.activate(ignoringOtherApps: true)
app.run()
