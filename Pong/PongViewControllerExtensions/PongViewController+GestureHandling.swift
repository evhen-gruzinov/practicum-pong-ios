//
//  PongViewController+GestureHandling.swift
//  Pong
//
//  Created by Timofey on 17.05.2022.
//

import UIKit

// NOTE: In this extension we configure the logic of gesture processing
extension PongViewController {

    // MARK: - Pan Gesture Handling

    /// This feature configures the processing of finger gestures on the screen
    func enabledPanGestureHandling() {
        // NOTE: Create a gesture handler object
        let panGestureRecognizer = UIPanGestureRecognizer()

        // NOTE: Add a gesture handler to the screen view
        view.addGestureRecognizer(panGestureRecognizer)

        // NOTE: Specify to the handler what function to call when processing the gesture
        panGestureRecognizer.addTarget(self, action: #selector(self.handlePanGesture(_:)))

        // NOTE: Save the gesture handler object to a class variable
        self.panGestureRecognizer = panGestureRecognizer
    }

    /// This is a gesture processing function.
    /// It is called every time the user moves his finger on the screen or touches it
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        // NOTE: Смотрим на состояние обработчика жеста
        switch recognizer.state {
        case .began:
            // NOTE: The gesture has started to be recognized, remember the current platform position
            // This is the state when the user has just touched the screen
            lastUserPaddleOriginLocation = userPaddleView.frame.origin.x

        case .changed:
            // NOTE: A touch shift has occurred,
            // calculate the finger displacement and update the position of the plafthorpe
            let translation: CGPoint = recognizer.translation(in: view)
            let translatedOriginX: CGFloat = lastUserPaddleOriginLocation + translation.x

            let platformWidthRatio = userPaddleView.frame.width / view.bounds.width
            let minX: CGFloat = 0
            let maxX: CGFloat = view.bounds.width * (1 - platformWidthRatio)
            userPaddleView.frame.origin.x = min(max(translatedOriginX, minX), maxX)
            dynamicAnimator?.updateItem(usingCurrentState: userPaddleView)

        default:
            // NOTE: In any other state we do nothing
            break
        }
    }
}
