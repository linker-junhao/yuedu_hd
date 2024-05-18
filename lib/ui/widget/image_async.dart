
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_async_provider.dart';

class FadeInImageWithoutAuth extends StatefulWidget {
  const FadeInImageWithoutAuth({
    Key? key,
    required this.placeholder,
    required this.image,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  }) : super(key: key);

  /// Creates a widget that uses a placeholder image stored in memory while
  /// loading the final image from the network.
  ///
  /// [placeholder] contains the bytes of the in-memory image.
  ///
  /// [image] is the URL of the final image.
  ///
  /// [placeholderScale] and [imageScale] are passed to their respective
  /// [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// The [placeholder], [image], [placeholderScale], [imageScale],
  /// [fadeOutDuration], [fadeOutCurve], [fadeInDuration], [fadeInCurve],
  /// [alignment], [repeat], and [matchTextDirection] arguments must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [new Image.memory], which has more details about loading images from
  ///    memory.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImageWithoutAuth.memoryNetwork({
    Key? key,
    required Uint8List placeholder,
    required String image,
    double placeholderScale = 1.0,
    double imageScale = 1.0,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  }) : placeholder = MemoryImage(placeholder, scale: placeholderScale),
        image = NetworkImage(image, scale: imageScale),
        super(key: key);

  /// Creates a widget that uses a placeholder image stored in an asset bundle
  /// while loading the final image from the network.
  ///
  /// [placeholder] is the key of the image in the asset bundle.
  ///
  /// [image] is the URL of the final image.
  ///
  /// [placeholderScale] and [imageScale] are passed to their respective
  /// [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// If [placeholderScale] is omitted or is null, the pixel-density-aware asset
  /// resolution will be attempted for the [placeholder] image. Otherwise, the
  /// exact asset specified will be used.
  ///
  /// The [placeholder], [image], [imageScale], [fadeOutDuration],
  /// [fadeOutCurve], [fadeInDuration], [fadeInCurve], [alignment], [repeat],
  /// and [matchTextDirection] arguments must not be null.
  ///
  /// See also:
  ///
  ///  * [new Image.asset], which has more details about loading images from
  ///    asset bundles.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImageWithoutAuth.network(String image,{
    Key? key,
    String placeholder = "",
    AssetBundle? bundle,
    double? placeholderScale,
    double imageScale = 1.0,
    this.fadeOutDuration = const Duration(milliseconds: 200),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  }) : placeholder = NetworkImageWithoutAuth(placeholder),
        image = NetworkImageWithoutAuth(image, scale: imageScale),
        super(key: key);

  /// Image displayed while the target [image] is loading.
  final ImageProvider placeholder;

  /// The target image that is displayed.
  final ImageProvider image;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [image].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [image].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  @override
  State<StatefulWidget> createState() => _FadeInImageState();
}


/// The phases a [FadeInImage] goes through.
@visibleForTesting
enum FadeInImagePhase {
  /// The initial state.
  ///
  /// We do not yet know whether the target image is ready and therefore no
  /// animation is necessary, or whether we need to use the placeholder and
  /// wait for the image to load.
  start,

  /// Waiting for the target image to load.
  waiting,

  /// Fading out previous image.
  fadeOut,

  /// Fading in new image.
  fadeIn,

  /// Fade-in complete.
  completed,
}

typedef _ImageProviderResolverListener = void Function();

class _ImageProviderResolver {
  _ImageProviderResolver({
    required this.state,
    required this.listener,
    this.imageStreamListener
  });

  final _FadeInImageState? state;
  final _ImageProviderResolverListener? listener;
  final ImageStreamListener? imageStreamListener;

  FadeInImageWithoutAuth get widget => state!.widget;

  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  void resolve(ImageProvider provider) {
    final ImageStream? oldImageStream = _imageStream;
    final ImageStreamListener listener = ImageStreamListener(_handleImageChanged);
    _imageStream = provider.resolve(createLocalImageConfiguration(
        state!.context,
        size: widget.width != null && widget.height != null ? Size(widget.width!, widget.height!) : null
    ));
    assert(_imageStream != null);

    if (_imageStream!.key != oldImageStream?.key) {
      oldImageStream?.removeListener(listener);
      _imageStream!.addListener(listener);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo = imageInfo;
    listener!();
  }

  void stopListening() {
    if(imageStreamListener!=null){
      _imageStream?.removeListener(imageStreamListener!);
    }
  }
}

class _FadeInImageState extends State<FadeInImageWithoutAuth> with TickerProviderStateMixin {
  late _ImageProviderResolver _imageResolver;
  late _ImageProviderResolver _placeholderResolver;

  late AnimationController _controller;
  Animation<double>? _animation;

  FadeInImagePhase _phase = FadeInImagePhase.start;
  FadeInImagePhase get phase => _phase;

  @override
  void initState() {
    _imageResolver = _ImageProviderResolver(state: this, listener: _updatePhase);
    _placeholderResolver = _ImageProviderResolver(state: this, listener: () {
      setState(() {
        // Trigger rebuild to display the placeholder image
      });
    });
    _controller = AnimationController(
      value: 1.0,
      vsync: this,
    );
    _controller.addListener(() {
      setState(() {
        // Trigger rebuild to update opacity value.
      });
    });
    _controller.addStatusListener((AnimationStatus status) {
      _updatePhase();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FadeInImageWithoutAuth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image || widget.placeholder != oldWidget.placeholder)
      _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    _imageResolver.resolve(widget.image);

    // No need to resolve the placeholder if we are past the placeholder stage.
    if (_isShowingPlaceholder)
      _placeholderResolver.resolve(widget.placeholder);

    if (_phase == FadeInImagePhase.start)
      _updatePhase();
  }

  void _updatePhase() {
    if(!mounted){
      return;
    }
    setState(() {
      switch (_phase) {
        case FadeInImagePhase.start:
          if (_imageResolver._imageInfo != null)
            _phase = FadeInImagePhase.completed;
          else
            _phase = FadeInImagePhase.waiting;
          break;
        case FadeInImagePhase.waiting:
          if (_imageResolver._imageInfo != null) {
            // Received image data. Begin placeholder fade-out.
            _controller.duration = widget.fadeOutDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.fadeOutCurve,
            );
            _phase = FadeInImagePhase.fadeOut;
            _controller.reverse(from: 1.0);
          }
          break;
        case FadeInImagePhase.fadeOut:
          if (_controller.status == AnimationStatus.dismissed) {
            // Done fading out placeholder. Begin target image fade-in.
            _controller.duration = widget.fadeInDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.fadeInCurve,
            );
            _phase = FadeInImagePhase.fadeIn;
            _placeholderResolver.stopListening();
            _controller.forward(from: 0.0);
          }
          break;
        case FadeInImagePhase.fadeIn:
          if (_controller.status == AnimationStatus.completed) {
            // Done finding in new image.
            _phase = FadeInImagePhase.completed;
          }
          break;
        case FadeInImagePhase.completed:
        // Nothing to do.
          break;
      }
    });
  }

  @override
  void dispose() {
    _imageResolver.stopListening();
    _placeholderResolver.stopListening();
    _controller.dispose();
    super.dispose();
  }

  bool get _isShowingPlaceholder {
    switch (_phase) {
      case FadeInImagePhase.start:
      case FadeInImagePhase.waiting:
      case FadeInImagePhase.fadeOut:
        return true;
      case FadeInImagePhase.fadeIn:
      case FadeInImagePhase.completed:
        return false;
    }

  }

  ImageInfo? get _imageInfo {
    return _isShowingPlaceholder
        ? _placeholderResolver._imageInfo
        : _imageResolver._imageInfo;
  }

  @override
  Widget build(BuildContext context) {
    assert(_phase != FadeInImagePhase.start);
    final ImageInfo? imageInfo = _imageInfo;
    return RawImage(
      image: imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: imageInfo?.scale ?? 1.0,
      color: Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(EnumProperty<FadeInImagePhase>('phase', _phase));
    description.add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
    description.add(DiagnosticsProperty<ImageStream>('image stream', _imageResolver._imageStream));
    description.add(DiagnosticsProperty<ImageStream>('placeholder stream', _placeholderResolver._imageStream));
  }
}