//
//  PongViewController+UIKitDynamics.swift
//  Pong
//
//  Created by Timofey on 17.05.2022.
//

import UIKit

extension PongViewController {
    
    // MARK: - UIKitDynamics

    /// This function adjusts the dynamics of element interaction
    func enableDynamics() {
        // NOTE: Give the ball, the player's platform and the opponent's platform a special tag for identification
        ballView.tag = Constants.ballTag
        userPaddleView.tag = Constants.userPaddleTag
        enemyPaddleView.tag = Constants.enemyPaddleTag

        let dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
        self.dynamicAnimator = dynamicAnimator

        let collisionBehavior = UICollisionBehavior(items: [ballView, userPaddleView, enemyPaddleView])
        collisionBehavior.collisionDelegate = self
        collisionBehavior.collisionMode = .everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.collisionBehavior = collisionBehavior
        dynamicAnimator.addBehavior(collisionBehavior)

        let ballDynamicBehavior = UIDynamicItemBehavior(items: [ballView])
        ballDynamicBehavior.allowsRotation = false
        ballDynamicBehavior.elasticity = 1.0
        ballDynamicBehavior.friction = 0.0
        ballDynamicBehavior.resistance = 0.0
        self.ballDynamicBehavior = ballDynamicBehavior
        dynamicAnimator.addBehavior(ballDynamicBehavior)

        let userPaddleDynamicBehavior = UIDynamicItemBehavior(items: [userPaddleView])
        userPaddleDynamicBehavior.allowsRotation = false
        userPaddleDynamicBehavior.density = 100000
        self.userPaddleDynamicBehavior = userPaddleDynamicBehavior
        dynamicAnimator.addBehavior(userPaddleDynamicBehavior)

        let enemyPaddleDynamicBehavior = UIDynamicItemBehavior(items: [enemyPaddleView])
        enemyPaddleDynamicBehavior.allowsRotation = false
        enemyPaddleDynamicBehavior.density = 100000
        self.enemyPaddleDynamicBehavior = enemyPaddleDynamicBehavior
        dynamicAnimator.addBehavior(enemyPaddleDynamicBehavior)

        let attachmentBehavior = UIAttachmentBehavior.slidingAttachment(
            with: enemyPaddleView,
            attachmentAnchor: .zero,
            axisOfTranslation: CGVector(dx: 1.0, dy: 0.0)
        )
        dynamicAnimator.addBehavior(attachmentBehavior)
    }
}

// NOTE: This extension defines collision handling functions in element dynamics
extension PongViewController: UICollisionBehaviorDelegate {

    // MARK: - UICollisionBehaviorDelegate

    /// This function handles object collisions
    func collisionBehavior(
        _ behavior: UICollisionBehavior,
        beganContactFor item1: UIDynamicItem,
        with item2: UIDynamicItem,
        at p: CGPoint
    ) {
        /// We try to determine if the colliding objects are elements of the mapping
        guard
            let view1 = item1 as? UIView,
            let view2 = item2 as? UIView
        else { return }

        /// Get the names of the colliding elements by the tag
        let view1Name: String = getNameFromViewTag(view1)
        let view2Name: String = getNameFromViewTag(view2)

        /// Print the names of the colliding elements
        print("\(view1Name) has hit \(view2Name)")

        if let ballDynamicBehavior = self.ballDynamicBehavior {
            ballDynamicBehavior.addLinearVelocity(
                ballDynamicBehavior.linearVelocity(for: self.ballView).multiplied(by: Constants.ballAccelerationFactor),
                for: self.ballView
            )
        }

        if view1.tag == Constants.ballTag || view2.tag == Constants.ballTag {
            animateBallHit(at: p)
            playHitSound(.mid)
            lightImpactFeedbackGenerator.impactOccurred()
        }
    }

    /// This function handles object and frame collision
    func collisionBehavior(
        _ behavior: UICollisionBehavior,
        beganContactFor item: UIDynamicItem,
        withBoundaryIdentifier identifier: NSCopying?,
        at p: CGPoint
    ) {
        // NOTE: Trying to determine from the tag if the object of the collision is a ball
        guard
            identifier == nil,
            let itemView = item as? UIView,
            itemView.tag == Constants.ballTag
        else { return }

        animateBallHit(at: p)

        var shouldResetBall: Bool = false
        if abs(p.y) <= Constants.contactThreshold {
            // NOTE: If the collision site is close to the upper boundary,
            // it means the ball hit the top edge of the screen
            //
            // Increase the player's score
            userScore += 1
            shouldResetBall = true
            print("Ball has hit enemy side. User score is now: \(userScore)")
        } else if abs(p.y - view.bounds.height) <= Constants.contactThreshold {
            // NOTE: If the place of collision is close to the bottom edge,
            // it means that the ball hit the bottom edge of the screen
            
            enemyScore += 1
            shouldResetBall = true
            print("Ball has hit user side. Enemy score is now: \(enemyScore)")
            
        }

        if shouldResetBall {
            resetBallWithAnimation()
            playHitSound(.high)
            rigidImpactFeedbackGenerator.impactOccurred()
        } else {
            playHitSound(.low)
            softImpactFeedbackGenerator.impactOccurred()
        }
    }

    // MARK: - Utils

    /// This helper function returns the name of the element by defining it by the "tag"
    private func getNameFromViewTag(_ view: UIView) -> String {
        switch view.tag {
        case Constants.ballTag:
            return "Ball"

        case Constants.userPaddleTag:
            return "User Paddle"

        case Constants.enemyPaddleTag:
            return "Enemy Paddle"

        default:
            return "?"
        }
    }
}

// NOTE: This extension defines functions for dropping the ball
extension PongViewController {

    // MARK: - Reset Ball

    /// This function stops the movement of the ball and resets its position to the middle of the screen
    private func resetBallWithAnimation() {
        // NOTE: Stopping the ball from moving
        stopBallMovement()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // NOTE: after 1 second reset the position of the ball and animate its appearance
            self?.resetBallViewPositionAndAnimateBallAppear()
        }
    }

    /// This function stops the movement of the ball
    private func stopBallMovement() {
        if let ballPushBehavior = self.ballPushBehavior {
            self.ballPushBehavior = nil
            ballPushBehavior.active = false
            dynamicAnimator?.removeBehavior(ballPushBehavior)
        }

        if let ballDynamicBehavior = self.ballDynamicBehavior {
            ballDynamicBehavior.addLinearVelocity(
                ballDynamicBehavior.linearVelocity(for: self.ballView).inverted(),
                for: self.ballView
            )
        }

        dynamicAnimator?.updateItem(usingCurrentState: self.ballView)
    }

    /// This function resets the position of the ball and animates its appearance
    private func resetBallViewPositionAndAnimateBallAppear() {
        // NOTE: reset the ball position
        resetBallViewPosition()
        dynamicAnimator?.updateItem(usingCurrentState: self.ballView)

        // NOTE: set the transparency and size of the ball
        ballView.alpha = 0.0
        ballView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                // set the transparency and size of the ball back to normal
                self.ballView.alpha = 1.0
                self.ballView.transform = .identity
            },
            completion: { [weak self] _ in
                /// at the end of the animation we turn on the processing of the next press to start the ball
                self?.hasLaunchedBall = false
            }
        )
    }

    /// This function resets the position of the ball to the center of the screen
    private func resetBallViewPosition() {
        // NOTE: reset any transformations of the ball
        ballView.transform = .identity

        // NOTE: Resetting the ball position
        let ballSize: CGSize = ballView.frame.size
        ballView.frame = CGRect(
            origin: CGPoint(
                x: (view.bounds.width - ballSize.width) / 2,
                y: (view.bounds.height - ballSize.height) / 2
            ),
            size: ballSize
        )
        
        // Return the player's platform to the starting position
        self.userPaddleView.frame.origin.x = (self.view.bounds.width - self.enemyPaddleView.frame.width) / 2
        self.dynamicAnimator?.updateItem(usingCurrentState: self.userPaddleView)
    }
}
