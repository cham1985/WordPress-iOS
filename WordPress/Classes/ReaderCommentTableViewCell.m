#import "ReaderCommentTableViewCell.h"
#import <DTCoreText/DTCoreText.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"
#import "WPContentViewSubclass.h"
#import "WPWebViewController.h"
#import "NSDate+StringFormatting.h"
#import "NSString+Helpers.h"

#define RCTVCVerticalPadding 10.0f
#define RCTVCIndentationWidth 15.0f
#define RCTVCReplyButtonHeight 24.0f
#define RCTVCCommentTextTopMargin 4.0f

@interface ReaderCommentTableViewCell()<DTAttributedTextContentViewDelegate>

@property (nonatomic, strong) ReaderComment *comment;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *bylineLabel;
@property (nonatomic, strong) UIButton *byButton;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) UIButton *replyButton;

- (void)handleLinkTapped:(id)sender;

@end

@implementation ReaderCommentTableViewCell

+ (CGFloat)heightForComment:(ReaderComment *)comment width:(CGFloat)width tableStyle:(UITableViewStyle)tableStyle accessoryType:(UITableViewCellAccessoryType *)accessoryType {
	static DTAttributedTextContentView *textContentView;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)]; // arbitrary starting frame
		textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		textContentView.edgeInsets = UIEdgeInsetsMake(0.0f, RPVHorizontalInnerPadding, 0.0f, RPVHorizontalInnerPadding);
		textContentView.shouldDrawImages = NO;
		textContentView.shouldLayoutCustomSubviews = YES;
	});

	textContentView.attributedString = [self convertHTMLToAttributedString:comment.content withOptions:nil];

    // Everything but the height of the comment content.
    CGFloat desiredHeight = (RCTVCVerticalPadding * 2) + RPVAvatarSize + RCTVCCommentTextTopMargin + RCTVCReplyButtonHeight;

    // Do the math. We can't trust the cell's contentView's frame because
	// its not updated at a useful time during rotation.
	CGFloat contentWidth = width;

	// reduce width for accessories
	switch ((NSInteger)accessoryType) {
		case UITableViewCellAccessoryDisclosureIndicator:
		case UITableViewCellAccessoryCheckmark:
			contentWidth -= 20.0f;
			break;
		case UITableViewCellAccessoryDetailDisclosureButton:
			contentWidth -= 33.0f;
			break;
		case UITableViewCellAccessoryNone:
			break;
	}

	// reduce width for grouped table views
	if (tableStyle == UITableViewStyleGrouped) {
		contentWidth -= 19;
	}

	// Cell indentation
	CGFloat indentationLevel = [comment.depth integerValue];
	contentWidth -= (indentationLevel * RCTVCIndentationWidth);

	desiredHeight += [textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;

	return desiredHeight;
}


+ (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html withOptions:(NSDictionary *)options {
    NSAssert(html != nil, @"Can't convert nil to AttributedString");
	
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[WPStyleGuide defaultDTCoreTextOptions]];
    [dict setObject:[WPStyleGuide whisperGrey] forKey:DTDefaultTextColor];
    html = [html stringByReplacingHTMLEmoticonsWithEmoji];

	if (options) {
		[dict addEntriesFromDictionary:options];
	}
	
    return [[NSAttributedString alloc] initWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding] options:dict documentAttributes:nil];
}


#pragma mark - Lifecycle Methods

- (void)dealloc {
    self.delegate = nil;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];

        UIView *view = [[UIView alloc] initWithFrame:self.frame];
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		view.backgroundColor = [WPStyleGuide readGrey];
		[self setSelectedBackgroundView:view];

        CGFloat width = CGRectGetWidth(self.contentView.frame);
        UIImageView *separatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.indentationWidth, 0.0f, width - (self.indentationWidth + RPVHorizontalInnerPadding), 1.0f)];
		separatorImageView.backgroundColor = [WPStyleGuide readGrey];
		separatorImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:separatorImageView];

        self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(RPVHorizontalInnerPadding, RCTVCVerticalPadding, RPVAvatarSize, RPVAvatarSize)];
        [self.contentView addSubview:self.avatarImageView];

        self.timeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.timeButton.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        self.timeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        self.timeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        self.timeButton.titleLabel.font = [WPStyleGuide subtitleFont];
        [self.timeButton setTitleEdgeInsets: UIEdgeInsetsMake(0, 2, 0, -2)];
        [self.timeButton setImage:[UIImage imageNamed:@"reader-postaction-time"] forState:UIControlStateDisabled];
        [self.timeButton setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateDisabled];
        [self.timeButton setEnabled:NO];
        [self.contentView addSubview:self.timeButton];

		self.bylineLabel = [[UILabel alloc] init];
		[self.bylineLabel setFont:[WPStyleGuide subtitleFont]];
		self.bylineLabel.textColor = [WPStyleGuide whisperGrey];
        self.bylineLabel.backgroundColor = [WPStyleGuide itsEverywhereGrey];
		self.bylineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:self.bylineLabel];

        self.byButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.byButton.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        self.byButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.byButton.titleLabel.font = [WPStyleGuide subtitleFont];
        [self.byButton addTarget:self action:@selector(handleAuthorBlogTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.byButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
        [self.contentView addSubview:self.byButton];

		self.textContentView = [[DTAttributedTextContentView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 44.0f)];
        self.textContentView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
		self.textContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.textContentView.edgeInsets = UIEdgeInsetsMake(0.0f, RPVHorizontalInnerPadding, 0.0f, RPVHorizontalInnerPadding);
		self.textContentView.delegate = self;
		self.textContentView.shouldDrawImages = NO;
		self.textContentView.shouldLayoutCustomSubviews = YES;
		[self.contentView addSubview:self.textContentView];

        self.replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.replyButton.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        [self.replyButton addTarget:self action:@selector(handleReplyTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.replyButton setTitle:NSLocalizedString(@"Reply", @"") forState:UIControlStateNormal];
        [self.replyButton setTitleColor:[WPStyleGuide whisperGrey] forState:UIControlStateNormal];
        self.replyButton.titleLabel.font = [WPStyleGuide subtitleFont];
        [self.replyButton sizeToFit];
        [self.contentView addSubview:self.replyButton];
    }
	
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// We have to manually update the indentation of the content view? wtf.
	CGRect frame = self.contentView.frame;
    CGFloat indent = self.indentationWidth * self.indentationLevel;
	frame.origin.x += indent;
	frame.size.width -= indent;
	self.contentView.frame = frame;

    CGFloat width = CGRectGetWidth(self.contentView.frame);

    // Avatar
	self.avatarImageView.frame = CGRectMake(RPVHorizontalInnerPadding, RCTVCVerticalPadding, RPVAvatarSize, RPVAvatarSize);

    // Date button
    frame = self.timeButton.frame;
    frame.origin.x = width - (CGRectGetWidth(frame) + RPVHorizontalInnerPadding + 1.0); // +1 pixel correction
    frame.origin.y = RCTVCVerticalPadding;
    self.timeButton.frame = frame;

    // Byline Label
    frame = self.bylineLabel.frame;
    frame.size.width = CGRectGetMinX(self.timeButton.frame) - (CGRectGetMaxX(self.avatarImageView.frame) + RPVAuthorPadding);
    frame.origin.x = CGRectGetMaxX(self.avatarImageView.frame) + RPVAuthorPadding;
    frame.origin.y = RCTVCVerticalPadding;
    frame.size.height = RPVAvatarSize / 2.0;
    self.bylineLabel.frame = frame;

    // Author's blog
    frame = self.bylineLabel.frame;
    frame.origin.y = CGRectGetMaxY(self.bylineLabel.frame);
    self.byButton.frame = frame;

    // Comment text view
    CGFloat height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:width].height;
    frame = self.textContentView.frame;
    frame.size.height = height;
    frame.origin.y = CGRectGetMaxY(self.byButton.frame) + RCTVCCommentTextTopMargin;
    self.textContentView.frame = frame;
	[self.textContentView setNeedsLayout];

    // Reply button
    frame = self.replyButton.frame;
    frame.origin.x = RPVHorizontalInnerPadding;
    frame.origin.y = CGRectGetMaxY(self.textContentView.frame);
    frame.size.height = RCTVCReplyButtonHeight;
    self.replyButton.frame = frame;
}

- (void)prepareForReuse {
	[super prepareForReuse];
	
	self.textContentView.attributedString = nil;
	self.bylineLabel.text = @"";
    [self.byButton setTitle:@"" forState:UIControlStateNormal];
    [self.byButton setTitle:@"" forState:UIControlStateSelected];
    [self.timeButton setTitle:@"" forState:UIControlStateNormal];
    [self.timeButton setTitle:@"" forState:UIControlStateSelected];
}


#pragma mark - Instance Methods

- (void)configureCell:(ReaderComment *)comment {
	self.comment = comment;
	
	self.indentationWidth = RCTVCIndentationWidth;
	self.indentationLevel = [comment.depth integerValue];

    [self.timeButton setTitle:[comment.dateCreated shortString] forState:UIControlStateNormal];
    [self.timeButton sizeToFit];

	self.bylineLabel.text = comment.author;

    NSString *authorUrl = comment.author_url;
    [self.byButton setTitle:authorUrl forState:UIControlStateNormal];
    self.byButton.enabled = ([authorUrl length] > 0);

	if (!comment.attributedContent) {
		comment.attributedContent = [[self class] convertHTMLToAttributedString:comment.content withOptions:nil];
	}

	self.textContentView.attributedString = comment.attributedContent;
}

- (void)handleLinkTapped:(id)sender {
    NSURL *url = ((DTLinkButton *)sender).URL;
    [self.delegate readerCommentTableViewCell:self didTapURL:url];
}

- (void)handleReplyTapped:(id)sender {
    [self.delegate readerCommentTableViewCellDidTapReply:self];
}

- (void)handleAuthorBlogTapped:(id)sender {
    NSURL *url = [NSURL URLWithString:self.comment.author_url];
    if (!url) {
        return;
    }
    [self.delegate readerCommentTableViewCell:self didTapURL:url];
}

- (void)setAvatar:(UIImage *)image {
    self.avatarImageView.image = image;
}

#pragma mark - DTAttributedTextContentView Delegate Methods

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:nil];
	
	NSURL *URL = [attributes objectForKey:DTLinkAttribute];
    
    if (URL == nil) {
        return nil;
    }
    
	NSString *identifier = [attributes objectForKey:DTGUIDAttribute];
	
	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
	button.URL = URL;
	button.minimumHitSize = CGSizeMake(25.0, 25.0); // adjusts it's bounds so that button is always large enough
	button.GUID = identifier;
	
	// get image with normal link text
	UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];
	[button setImage:normalImage forState:UIControlStateNormal];
	
	// get image for highlighted link text
	UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
	[button setImage:highlightImage forState:UIControlStateHighlighted];
	
	// use normal push action for opening URL
	[button addTarget:self action:@selector(handleLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

@end
