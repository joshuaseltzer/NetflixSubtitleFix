//
//  Tweak.m
//
//  Created by Joshua Seltzer on 4/8/20.
//
//

@interface NFUIStackButton : UIControl
@end

@interface NFUIPlayerControlsFooterViewRefresh : UIView
@property(nonatomic) __weak NFUIStackButton *audioSubtitlesButton;
@end

@interface NFUIPlayerControlsRefreshViewController : UIViewController
@property(retain, nonatomic) NFUIPlayerControlsFooterViewRefresh *footerControlsView;
@end

@interface NFPlayerBase : NSObject
- (void)percentSubtitleFontSize:(double)arg1;
@end

static NSString *const kNSFSubtitleFontSizeKey = @"subtitleFontSize";
static CGFloat const kNSFDefaultSubtitleFontSize = 80.0;
static CGFloat const kNSFMinimumSubtitleFontSize = 20.0;
static NSString *sNSFSettingsPath = nil;

// helper functions that will set and get the font size value from the preferences file
static NSString *getSettingsPath()
{
    if (sNSFSettingsPath == nil) {
        sNSFSettingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.joshuaseltzer.netflixsubtitlefix.plist"];
    }
    return sNSFSettingsPath;
}
static CGFloat getSubtitleFontSize()
{
    CGFloat fontSize = kNSFDefaultSubtitleFontSize;

    // grab the preferences plist
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:getSettingsPath()];
    if (prefs != nil) {
        fontSize = [[prefs objectForKey:kNSFSubtitleFontSizeKey] floatValue];
    }
    
    return fontSize;
}
static void setSubtitleFontSize(CGFloat fontSize)
{
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:getSettingsPath()];
    if (prefs == nil) {
        prefs = [[NSMutableDictionary alloc] initWithCapacity:1];
    }

    [prefs setObject:[NSNumber numberWithFloat:fontSize] forKey:kNSFSubtitleFontSizeKey];
    [prefs writeToFile:getSettingsPath() atomically:YES];
}

%hook NFPlayerBase

- (void)play
{
    %orig;

    [self percentSubtitleFontSize:getSubtitleFontSize()];
}

%end

%hook NFUIPlayerControlsRefreshViewController

- (void)initFooterControlsView
{
    %orig;

    // add a long press gesture recognizer to the play/pause button
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(NSFAudioSubtitlesButtonLongPress:)];
    longPressGestureRecognizer.minimumPressDuration = 1.0;
    [self.footerControlsView.audioSubtitlesButton addGestureRecognizer:longPressGestureRecognizer];
}

%new
- (void)NSFAudioSubtitlesButtonLongPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer
{
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Subtitle Font Size"
                                                                                 message:[NSString stringWithFormat:@"Enter the font size for the subtitles (default: %f, minimum: %f):", kNSFDefaultSubtitleFontSize, kNSFMinimumSubtitleFontSize]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                                          
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = [NSString stringWithFormat:@"%f", getSubtitleFontSize()];
            textField.placeholder = [NSString stringWithFormat:@"%f", kNSFDefaultSubtitleFontSize];
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.keyboardType = UIKeyboardTypeDecimalPad;
        }];

        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *inputTextField = alertController.textFields[0];
            CGFloat fontSize = [inputTextField.text floatValue];
            if (inputTextField.text.length == 0) {
                setSubtitleFontSize(kNSFDefaultSubtitleFontSize);
            } else if (fontSize >= kNSFMinimumSubtitleFontSize) {
                setSubtitleFontSize(fontSize);
            }
        }]];

        [self presentViewController:alertController animated:YES completion:nil];
    }
}

%end