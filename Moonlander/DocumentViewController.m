//
//  DocumentViewController.m
//  Moonlander
//
//  Created by Rick Naro on 4/29/12.
//  Copyright (c) 2012 Rick Naro. All rights reserved.
//

#import "DocumentViewController.h"

@interface DocumentViewController ()

@end

@implementation DocumentViewController

@synthesize documentName=_documentName;
@synthesize documentType=_documentType;
@synthesize documentURL=_documentURL;
@synthesize activityIndicator=_activityIndicator;
@synthesize documentContent=_documentContent;
@synthesize segueActive=_segueActive;


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // If the destination view is the name pass the segue name as the content to display
    if ([segue.destinationViewController isKindOfClass:[DocumentViewController class]]) {
        DocumentViewController *dvc = segue.destinationViewController;
        NSURL *url = [NSURL URLWithString:segue.identifier];
        NSLog(@"%@", segue.identifier);
        if (url) {
            NSURL *urlSansExtension = [url URLByDeletingPathExtension];
            if ([url.scheme isEqualToString:@"http"]) {
                dvc.documentName = segue.identifier;
                dvc.documentType = nil;
            }
            else {
                dvc.documentName = [urlSansExtension relativePath];
                dvc.documentType = [url pathExtension];
            }
        }
        else {
            url = [NSURL fileURLWithPath:segue.identifier];
            NSURL *urlSansExtension = [url URLByDeletingPathExtension];
            DocumentViewController *dvc = segue.destinationViewController;
            dvc.documentType = [url pathExtension];
            dvc.documentName = [urlSansExtension relativePath];
        }
        dvc.segueActive = YES;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Start up the activity indicator
    [self.activityIndicator startAnimating];

    // Prevents white screen flash.
    self.documentContent.opaque = NO;
    self.documentContent.backgroundColor = [UIColor clearColor];

    // Load the document/web page
    [self.documentContent setNavigationDelegate:self];
    NSString *path = [[NSBundle mainBundle] pathForResource:self.documentName ofType:self.documentType];
    self.documentURL = (path == nil) ? [NSURL URLWithString:self.documentName] : [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:self.documentURL];
    [self.documentContent loadRequest:request];

#if defined(TESTFLIGHT_SDK_VERSION) && defined(USE_TESTFLIGHT)
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"%@:%@", @"DocumentView", self.documentName]];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show the navagation bar in this view so we can get back
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Sample error message for testing
//    NSError * myInternalError = [NSError errorWithDomain:@"com.mccarron.error" code:42 userInfo:NULL];
//    [self showErrorPageWithError:myInternalError];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];

    // Hide the navagation bar when leaving the view
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    WKNavigationActionPolicy result = WKNavigationActionPolicyAllow;
    if (navigationAction.navigationType == UIWebViewNavigationTypeLinkClicked && self.segueActive == NO) {
        // Push a new web view to handle the request
        result = WKNavigationActionPolicyCancel;
        
        NSURLRequest *request = navigationAction.request;
        
        // Check which name we use for local and web hrefs
        if ([request.URL.scheme isEqualToString:@"file"]) {
            [self performSegueWithIdentifier:request.URL.lastPathComponent sender:self];
        }
        else {
            [self performSegueWithIdentifier:request.URL.absoluteString sender:self];
        }
    }
    
    decisionHandler(result);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [self.activityIndicator startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.activityIndicator stopAnimating];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showErrorPageWithError: error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showErrorPageWithError: error];
}

- (void)showErrorPageWithError:(NSError *)error {
    // Load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Report the error inside the webview
    NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                             error.localizedDescription];
    [self.documentContent loadHTMLString:errorString baseURL:nil];
}

@end
