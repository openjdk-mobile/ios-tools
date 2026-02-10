#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UITextView *label = [[UITextView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 50, self.view.bounds.size.width, 50)];
    label.text = @"Hello OpenJDK Mobile!\nMessage from Java:";
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"Arial" size:18];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:@"output.log"];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];

    UITextView *text = [[UITextView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2, self.view.bounds.size.width, 50)];
    text.textAlignment = NSTextAlignmentCenter;
    text.font = [UIFont fontWithName:@"Arial" size:24];
    if (error) {
        NSLog(@"Error reading file: %@", [error localizedDescription]);
        text.textColor = [UIColor redColor];
        text.text = [NSString stringWithFormat:@"Error: %@", [error localizedDescription]];
    } else {
        NSLog(@"File contents: %@", fileContents);
        text.textColor = [UIColor blueColor];
        text.text = [NSString stringWithFormat:@"%@", fileContents];
    }

    [self.view addSubview:text];
}


@end
