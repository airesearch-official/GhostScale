# GhostScale - The Offline Privacy Upscaler

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Privacy First](https://img.shields.io/badge/Privacy-First-green?style=for-the-badge)
![Offline](https://img.shields.io/badge/Offline-Ready-blue?style=for-the-badge)
![Open Source](https://img.shields.io/badge/Open-Source-orange?style=for-the-badge)

A proof-of-concept offline image upscaler built with Flutter and Real-ESRGAN. Upscales images locally on your device without sending data to the cloud.

## Features

*   **🟢 100% Offline**: No servers, no API keys. Everything runs on your device.
*   **🔒 Privacy First**: Your photos never leave your phone. No spying, no tracking.
*   **⚡ Dual Modes**:
    *   **Fast (Standard)**: Instant edge sharpening using a lightweight model.
    *   **Pro (Detail)**: Restores textures and details using the powerful Real-ESRGAN-x4plus model (downloaded on demand).
*   **🚀 Resolution Control**: Choose between **2K (Fast)** for speed or **4K (Ultra)** for maximum quality.

## Technical Stack

*   **Framework**: Flutter
*   **AI Inference**: `tflite_flutter` with `GpuDelegateV2` for hardware acceleration.
*   **Concurrency**: Heavy processing runs in background Isolates using `compute()` to keep the UI silky smooth.
*   **State Management**: `flutter_riverpod`.

## Disclaimer

This project uses the [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) model architecture. The 'Pro' mode requires a capable device with a decent GPU for reasonable inference times. On older devices, processing may take significantly longer.

## Getting Started

1.  Clone the repository.
2.  Run `flutter pub get`.
3.  Connect an Android device.
4.  Run `flutter run`.

---
*Built with ❤️ and privacy in mind.*
