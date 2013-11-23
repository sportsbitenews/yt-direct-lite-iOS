#import "VideoListViewController.h"
#import "Image.h"
#import "VideoData.h"
#import "GTLYouTube.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UploadController.h"
#import "Utils.h"
#import "VideoPlayerViewController.h"
#import "VideoUploadViewController.h"

@implementation VideoListViewController

- (id)init {
  self = [super init];
  if (self) {
      _getUploads = [[YouTubeGetUploads alloc] init];
      _getUploads.delegate = self;
      _images = [[NSArray alloc] init];
      _videos = [[NSArray alloc] init];
  }
  return self;
}


- (void)loadView {
  self.title = @"YouTube Direct Lite";
     self.navigationItem.hidesBackButton = YES;
   
    [self viewDidLoad];

  //  UITabBar *tabBar = [[UITabBar alloc] initWithFrame:(CGRectMake(0,500,300,50))];
   // UITabBarItem *folderItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemBookmarks tag:1];
   // UITabBarItem *recordItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:2];
    
   // tabBar.delegate = self;
    
   // NSArray *itemsArray = [NSArray arrayWithObjects:folderItem, recordItem, nil];
    //[tabBar setItems:itemsArray animated:YES];
    
    UIBarButtonItem* folderItem = [[UIBarButtonItem alloc] initWithTitle:@"Library" style:UIBarButtonItemStylePlain target:self action:@selector(showVideoLibrary)];

    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem            *recordItem = [[ UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector( showCamera ) ];
    
    
    self.toolbarItems = [ NSArray arrayWithObjects: folderItem, flexible, recordItem, nil ];
    
    self.tableView = [[UITableView alloc] initWithFrame:(CGRectZero) style:(UITableViewStylePlain)];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    self.tableView.rowHeight = 80;
self.tableView.separatorColor = [UIColor clearColor];
    self.view=self.tableView;

    [_getUploads getYouTubeUploadsWithService:_youtubeService];
}

-(void)folderButtonPressed:(UIButton *)button
{
    [self showVideoLibrary];
}

-(void)recordButtonPressed:(UIButton *)button
{
    [self showCamera];
}



#pragma mark - getYouTubeUploads

- (void)getYouTubeUploads:(YouTubeGetUploads *)getUploads
         didFinishWithResults:(NSArray *)results {
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  NSMutableArray *searchResultImages = [NSMutableArray array];
    _videos = results;
  for (VideoData *vData in results) {

    Image *image =
        [[Image alloc] initWithFullImage:vData.fullImage
                               thumbnail:vData.thumbnail
                                  author:vData.getYouTubeId
                                   title:vData.video.snippet.title];
    [searchResultImages addObject:image];
  }

  self.images = searchResultImages;
  [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const kReuseIdentifier = @"imageCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:kReuseIdentifier];
    }
Image *image = [_images objectAtIndex:indexPath.row];
cell.imageView.image = image.thumbnail;
cell.textLabel.text = image.title;
cell.detailTextLabel.text=image.author;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
return cell;
}


- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    return [_images count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoData *selectedVideo = [_videos objectAtIndex:indexPath.row];
    
    VideoPlayerViewController *videoController = [[VideoPlayerViewController alloc] init];
    videoController.videoData = selectedVideo;
    videoController.youtubeService = _youtubeService;

    [[self navigationController] pushViewController:videoController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showCamera
{
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else
    {
        // In case we're running the iPhone simulator, fall back on the photo library instead.
        cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            [Utils showAlert:@"Error" message:@"Sorry, iPad Simulator not supported!"];
            return;
        }
    }
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = self;
    [self presentViewController:cameraUI animated:YES completion:nil];
   
}


- (void)showVideoLibrary
{
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    // In case we're running the iPhone simulator, fall back on the photo library instead.
    cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [Utils showAlert:@"Error" message:@"Sorry, iPad Simulator not supported!"];
        return;
    }
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = self;
    [self presentViewController:cameraUI animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
      didFinishPickingImage : (UIImage *)image
                 editingInfo:(NSDictionary *)editingInfo{
    
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        
        NSURL *videoUrl=[info objectForKey:UIImagePickerControllerMediaURL];
        
        VideoUploadViewController *uploadController = [[VideoUploadViewController alloc] init];
        uploadController.videoUrl = videoUrl;
        uploadController.youtubeService = _youtubeService;
        
        [[self navigationController] pushViewController:uploadController animated:YES];
        //NSData *fileData = [NSData dataWithContentsOfURL:videoUrl];
        
        //[_uploadVideo uploadYouTubeVideoWithService:_youtubeService fileData:fileData];
        
       // if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
       ////     UISaveVideoAtPathToSavedPhotosAlbum (moviePath, nil, nil, nil);
       // }
        
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if (item.tag == 1){
        [self showVideoLibrary];}
    else {
        [self showCamera];  
    }
    
}

@end
