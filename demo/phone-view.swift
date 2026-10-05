// Shows an iPhone's screen, over USB, in a window: the phone's own screen
// capture source (muxed), never a camera. Exits if there is none.
//
//   phone-view [height]                    # a window, height in points (820)
//   phone-view [height] --record out.mov   # the same, saved to out.mov
//
// Recording prints "recording" once the first frames are going to the file,
// and on SIGINT or SIGTERM finishes the file, prints "saved <path>" and
// exits — so a script can start it, wait for the line, and stop it.
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

func fail(_ s: String) -> Never {
  FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
  exit(1)
}

var args = Array(CommandLine.arguments.dropFirst())
var recordTo: URL?
if let i = args.firstIndex(of: "--record") {
  guard i + 1 < args.count else { fail("--record needs a path") }
  recordTo = URL(fileURLWithPath: args[i + 1])
  args.removeSubrange(i...(i + 1))
}
let h: CGFloat = CGFloat(Double(args.first ?? "") ?? 820)

func phone() -> AVCaptureDevice? {
  AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .muxed,
                                   position: .unspecified).devices.first
}
var dev: AVCaptureDevice?
let deadline = Date().addingTimeInterval(15)
while dev == nil && Date() < deadline {
  RunLoop.main.run(until: Date().addingTimeInterval(0.5)); dev = phone()
}
guard let dev else { fail("no iPhone screen source: is it plugged in, unlocked and trusted?") }

let session = AVCaptureSession()
session.addInput(try! AVCaptureDeviceInput(device: dev))

final class Recorder: NSObject, AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo url: URL, from connections: [AVCaptureConnection]) {
    print("recording \(url.path)"); fflush(stdout)
  }
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo url: URL, from connections: [AVCaptureConnection], error: Error?) {
    // An error with "finished successfully" set is the normal way a
    // stopped recording reports itself; anything else lost the file.
    let ok = (error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? (error == nil)
    if ok { print("saved \(url.path)") } else { fail("recording failed: \(error!.localizedDescription)") }
    fflush(stdout)
    exit(0)
  }
}
let recorder = Recorder()
let movie = AVCaptureMovieFileOutput()
if recordTo != nil {
  guard session.canAddOutput(movie) else { fail("this source cannot be recorded") }
  session.addOutput(movie)
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
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
print("showing \(dev.localizedName)"); fflush(stdout)

var stops: [DispatchSourceSignal] = []
if let url = recordTo {
  try? FileManager.default.removeItem(at: url)
  movie.startRecording(to: url, recordingDelegate: recorder)
  for sig in [SIGINT, SIGTERM] {
    signal(sig, SIG_IGN)
    let s = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    s.setEventHandler { movie.stopRecording() }
    s.resume()
    stops.append(s)
  }
}
app.activate(ignoringOtherApps: true)
app.run()
