# Head-based Pointing with Firebase ML Kit
This Flutter App is highly inspired by @giandifra's [Flutter Smile To Face Detection](https://github.com/giandifra/Flutter-Smile-Face-Detection) and used his Dart code as a starting point. But, after the initialization of the base code, this App here paints the 10 landmarks, enables tracking and adds a virtual cursor (in red). All these functionalities required rewriting most of the original code. For this reason, I preferred to start a new repository instead of forking @giandifra's one.

## Firebase ML Vision
The App relies on Firebase Vision models to complete the following tasks:

* **Face Detection:** Firebase implicitly calls *tflite* and runs a single shot multi-box face detector model which is sufficiently fast and quite precise.
* **Face Tracking:** The same model also provides a *FaceID* for each face detection on the frame. This allows to track the same face through iterations.
* **Landmark Detection:** It also detects facial landmarks within the bounding box detection. While the standard landmark detectors provide over 68 or 144 landmarks on the face, this reduced model only provides 10 facial landmarks. It is quite reasonable for mobile applications and in head-based pointing, we need even fewer landmarks to build a stable mapping between the face and the cursor.

## Head-based Pointing

As you may see below, the App demonstrates a dummy cursor with a red circle which is being pointed by the user's head movements measured by the facial landmarks as marked with yellow dots.

![Example](https://media.giphy.com/media/dWkvkSoEfdBIIE2maI/giphy.gif)

## License
[Apache-2.0](http://www.apache.org/licenses/LICENSE-2.0)