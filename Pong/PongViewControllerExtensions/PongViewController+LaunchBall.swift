//
//  PongViewController+LaunchBall.swift
//  Pong
//
//  Created by Timofey on 17.05.2022.
//

import Foundation
import UIKit

// NOTE: This extension defines the function used to start the ball
extension PongViewController {

    /// Ball launch function. Generates a random vector of ball speed and launches the ball along this vector
    func launchBall() {
        let ballPusher = UIPushBehavior(items: [ballView], mode: .instantaneous)
        self.ballPushBehavior = ballPusher

        ballPusher.pushDirection = makeRandomVelocityVector()
        ballPusher.active = true

        self.dynamicAnimator?.addBehavior(ballPusher)
    }

    /// Function of ball launch velocity vector generation with almost random direction
    private func makeRandomVelocityVector() -> CGVector {
        // NOTE: Generate a random number from 0 to 1
        let randomSeed = Double(arc4random_uniform(1000)) / 1000

        // NOTE: Create a random angle between about Pi/6 (30 degrees) and Pi/3 (60 degrees)
        let angle = Double.pi * (0.16 + 0.16 * randomSeed)

        // NOTE: We take 1.5 pixels of the screen as the amplitude (strength) of the ball launch
        let amplitude = 1.5 / UIScreen.main.scale

        // NOTE: decomposition of the velocity vector on the X and Y axes
        let x = amplitude * cos(angle)
        let y = amplitude * sin(angle)

        // NOTE: using the generated angle, return it in one of 4 variations
        switch arc4random() % 4 {
        case 0:
            // right, down
            return CGVector(dx: x, dy: y)

        case 1:
            // right, up
            return CGVector(dx: x, dy: -y)

        case 2:
            // left, down
            return CGVector(dx: -x, dy: y)

        default:
            // left, up
            return CGVector(dx: -x, dy: -y)
        }
    }
}
