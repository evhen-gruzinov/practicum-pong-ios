/// Import the library of UI components (interface elements)
import UIKit
import AVFoundation

/// This is the single screen class of our application
///
/// The class has elements of the game display:
/// - `ballView` - ball
/// - `userPaddleView` - player platform
/// - `enemyPaddleView` - opponent's platform
///
/// Also in the class of this screen, the interaction physics of the elements is configured
/// in the function `enableDynamics()`
///
/// And also in this class the processing of finger movements on the screen is implemented,
/// by processing this gesture, the player can move his platform and push the ball away
///
class PongViewController: UIViewController {

    // MARK: - Overriden Properties

    /// This overridden variable defines the allowed screen orientations
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    // MARK: - Subviews

    /// This is the ball mapping variable
    @IBOutlet var ballView: UIView!

    /// This is the display variable of the player's platform
    @IBOutlet var userPaddleView: UIView!

    /// This is the display variable for the opponent's platform
    @IBOutlet var enemyPaddleView: UIView!

    /// This is the dividing line mapping variable
    @IBOutlet var lineView: UIView!

    /// This is a variable displaying the label with the player's score
    @IBOutlet var userScoreLabel: UILabel!
    
    /// This is the variable for displaying the label with the opponent's score
    @IBOutlet var enemyScoreLabel: UILabel!
    
    /// This is the variable for displaying the game result label
    @IBOutlet var resultLabel: UILabel!

    // MARK: - Instance Properties

    /// This is a gesture handler variable
    var panGestureRecognizer: UIPanGestureRecognizer?

    /// This is the variable in which we will remember the last position of the user's platform,
    /// before the user started to move his finger on the screen
    var lastUserPaddleOriginLocation: CGFloat = 0

    /// This is the timer variable that will update the position of the opponent's platform
    var enemyPaddleUpdateTimer: Timer?

    /// This is the `Bool` flag and has two possible values:
    /// - `true` - can be interpreted as "yes"
    /// - `false` - can be interpreted as no
    ///
    /// It is responsible for the need to run the ball on the next screen press
    ///
    var shouldLaunchBallOnNextTap: Bool = false

    /// This is the `Bool` flag, which indicates "has the ball been launched"
    var hasLaunchedBall: Bool = false

    var enemyPaddleUpdatesCounter: UInt8 = 0

    // NOTE: All variables below up to line 74 are needed for the physics setup
    // We won't go into the details of what these are and how they work
    var dynamicAnimator: UIDynamicAnimator?
    var ballPushBehavior: UIPushBehavior?
    var ballDynamicBehavior: UIDynamicItemBehavior?
    var userPaddleDynamicBehavior: UIDynamicItemBehavior?
    var enemyPaddleDynamicBehavior: UIDynamicItemBehavior?
    var collisionBehavior: UICollisionBehavior?

    // NOTE: All variables up to line 82 are used to react to
    // on ball collision - play sound of collision and vibration response
    var audioPlayers: [AVAudioPlayer] = []
    var audioPlayersLock = NSRecursiveLock()
    var softImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    var lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var rigidImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)

    /// This player variable is for repeated playback of background music in the game
    var backgroundSoundAudioPlayer: AVAudioPlayer? = {
        guard
            let backgroundSoundURL = Bundle.main.url(forResource: "background", withExtension: "wav"),
            let audioPlayer = try? AVAudioPlayer(contentsOf: backgroundSoundURL)
        else { return nil }

        audioPlayer.volume = 0.5
        audioPlayer.numberOfLoops = -1

        return audioPlayer
    }()

    /// This variable stores the user account
    var userScore: Int = 0 {
        didSet {
            /// Each time the variable value is updated, we update the text in the label
            updateUserScoreLabel()
        }
    }
    
    /// This variable stores the opponent's score
    var enemyScore: Int = 0 {
        didSet {
            /// Each time the variable value is updated, we update the text in the label
            updateEnemyScoreLabel()
        }
    }

    // MARK: - Instance Methods

    /// This function is started once the screen view is loaded
    /// and is about to appear in the display window
    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         NOTE:  👨‍💻 Note on setting up the game screen  👨‍💻

         This code is now grayed out because the slash with an asterisk
         above this text and under this text `/* */` make it a multi-line comment.
         There are also single-line comments, they start with two slashes: `//`.
         Comments in code are the developers' notes on how a piece of code works.
         Comments are not taken into account when the program works, and are simply ignored.

         The code on line 127 sets up everything you need for the game.
         It is now commented out - there are two slashes `//' at the beginning of the line,
         And function `configurePongGame()` will not start.
         */

        configurePongGame()
                
    }
    
    /// This function is called when the PongViewController screen is displayed on the phone screen
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // NOTE: Enabling interaction dynamics
        self.enableDynamics()
    }

    /// This function is called when the screen has drawn its entire interface for the first time
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // NOTE: Set the rounding radius of the ball equal to half the height
        ballView.layer.cornerRadius = ballView.bounds.size.height / 2
    }

    /// This function handles the beginning of all screen touches
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)

        // NOTE: If you want to launch the ball and the ball has not been launched yet, launch the ball
        if shouldLaunchBallOnNextTap, !hasLaunchedBall {
            hasLaunchedBall = true

            launchBall()
        }
    }

    // MARK: - Private Methods

    /// This function performs the entire configuration (setup) of the screen
    ///
    /// - switches on the processing of the finger gesture on the screen
    /// - switches on the dynamics of elements interaction
    /// - indicates that the next press should start the ball
    ///
    private func configurePongGame() {
        
        resultLabel.isHidden = true
        
        // NOTE: Setting up the label with the score of the player and the opponent
        updateUserScoreLabel()
        updateEnemyScoreLabel()

        // NOTE: Turning on finger gesture processing on the screen
        self.enabledPanGestureHandling()

        // NOTE: Enabling the logic of the opponent's "follow the ball" platform
        self.enableEnemyPaddleFollowBehavior()

        // NOTE: Specify that the next time you press the screen to run the ball
        self.shouldLaunchBallOnNextTap = true

        // NOTE: Start playing background music
        self.backgroundSoundAudioPlayer?.prepareToPlay()
        self.backgroundSoundAudioPlayer?.play()
        
        
    }

    private func updateUserScoreLabel() {
        userScoreLabel.text = "\(userScore)"
        if userScore == 5 {userVictory(whoWin: "Player")}
    }
    
    private func updateEnemyScoreLabel() {
        enemyScoreLabel.text = "\(enemyScore)"
        if enemyScore == 5 {userVictory(whoWin: "Enemy")}
    }
    
    private func userVictory(whoWin: String) {
        
        switch whoWin {
        case "Player":
            print("Player is Winner")
            resultLabel.text = "You win"
        case "Enemy":
            print("AI is Winner")
            resultLabel.text = "You lose"
        default:
            print("Bip-bip")
        }
        
        self.shouldLaunchBallOnNextTap = false
        ballView.isHidden = true
        lineView.isHidden = true
        userPaddleView.isHidden = true
        enemyPaddleView.isHidden = true

        resultLabel.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // этот код запустится через 3 секунды
            //
           
            
            self.resultLabel.isHidden = true
            self.shouldLaunchBallOnNextTap = true
            self.ballView.isHidden = false
            self.userScore =  0
            self.enemyScore = 0
            self.userPaddleView.isHidden = false
            self.enemyPaddleView.isHidden = false
            
        }
    }
    
}
