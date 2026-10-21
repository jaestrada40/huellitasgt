import Flutter
import UIKit
import UserNotifications
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TextRecognizer") {
      let channel = FlutterMethodChannel(name: "huellitas/ocr", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "recognize", let path = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        TextRecognizer.recognize(path: path, completion: result)
      }
    }
  }
}

/// Lee el texto de una foto con Vision (en el teléfono, sin internet).
/// Devuelve {text: líneas de arriba abajo, confidence: 0..1}.
enum TextRecognizer {
  static func recognize(path: String, completion: @escaping FlutterResult) {
    let request = VNRecognizeTextRequest { request, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(FlutterError(code: "ocr", message: error.localizedDescription, details: nil))
          return
        }
        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let top = observations.compactMap { $0.topCandidates(1).first }
        // Confianza promedio: la letra impresa da ~0.9 o más; la escrita a mano, mucho menos.
        let confidence = top.isEmpty ? 0.0 : Double(top.map { $0.confidence }.reduce(0, +)) / Double(top.count)
        completion(["text": top.map { $0.string }.joined(separator: "\n"), "confidence": confidence])
      }
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["es-ES", "en-US"]

    DispatchQueue.global(qos: .userInitiated).async {
      // Con la URL, Vision respeta la orientación EXIF de las fotos de la cámara.
      let handler = VNImageRequestHandler(url: URL(fileURLWithPath: path), options: [:])
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          completion(FlutterError(code: "ocr", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
