# encoding: UTF-8

# requires to be put in the same directory as https://github.com/drtoast/macruby_graphics

framework 'Cocoa'
here = File.expand_path(File.dirname(__FILE__))
require File.join(here, 'graphics')

SLIDES = File.expand_path('../slides.rtf', __FILE__)

MARGIN = 20

TEXT_ATTRS = {
  #NSFontAttributeName            => NSFont.fontWithName("FedraSansDisStd HeavyCond", size:200) ||
                                      #NSFont.fontWithName("Helvetica Neue Condensed Black", size:200),
  NSParagraphStyleAttributeName  => NSMutableParagraphStyle.new.tap { |p| p.alignment = NSCenterTextAlignment },
  NSStrokeWidthAttributeName     => -2, # negative value means stroke and fill, i.e. bordered
  NSStrokeColorAttributeName     => NSColor.whiteColor,
  NSForegroundColorAttributeName => NSColor.blackColor,
  NSShadowAttributeName          => NSShadow.new.tap { |s| s.shadowOffset = NSMakeSize(0, -5); s.shadowBlurRadius = 5 }
}

HEADING_ATTRS = TEXT_ATTRS.merge({
  NSStrokeColorAttributeName => TEXT_ATTRS[NSForegroundColorAttributeName],
  NSForegroundColorAttributeName => TEXT_ATTRS[NSStrokeColorAttributeName]
})

# there are a few problems with constants resolutions
# on the last MacRuby anyway so just do it simple
include MRGraphics

class SlideManager
  def initialize(slides_rtf_file)
    @slides = NSMutableAttributedString.alloc.initWithPath(slides_rtf_file, documentAttributes:nil)
    _find_slide_locations
    @current_slide = 0
    @backgrounds = []
  end

  def next_slide
    @current_slide += 1 if @current_slide < @slide_locations.length - 1
  end

  def previous_slide
    @current_slide -= 1 if @current_slide > 0
  end

  def current_slide
    text = _current_slide
    # is it a heading?
    attrs = text.string.start_with?('# ') ? HEADING_ATTRS : TEXT_ATTRS
    # get actual content
    text = text.attributedSubstringFromRange(NSMakeRange(2, text.length - 2))
    text.addAttributes(attrs, range:NSMakeRange(0, text.length))
    text
  end

  def current_background
    @backgrounds[@current_slide % @backgrounds.size]
  end

  def add_background(&block)
    @backgrounds << block
  end

  private

  def _current_slide
    # TODO make MacRuby convert ranges?
    @slides.attributedSubstringFromRange(@slide_locations[@current_slide])
  end

  def _find_slide_locations
    pointer = 0
    @slide_locations = @slides.string.split("\n").map do |line|
      start, pointer = pointer, (pointer + line.size + 1)
      NSMakeRange(start, line.size)
    end
  end
end

class SlideView < NSView
  attr_accessor :slide_manager

  def viewWillStartLiveResize
    @boundsBeforeResize = bounds
    super
  end

  def viewDidEndLiveResize
    @boundsBeforeResize = nil
    super
  end

  # As a simple way to support smooth resizing we cache the result image and
  # draw it scaled to the current bounds.
  def drawRect(rect)
    unless inLiveResize
      Canvas.for_rendering(:size => bounds.size) do |c|
        CGContextSetTextMatrix(c.ctx, CGAffineTransformIdentity)
        c.instance_eval(&slide_manager.current_background)
        @renderCache = c.ciimage
      end
    end
    cicontext = CIContext.contextWithCGContext(NSGraphicsContext.currentContext.graphicsPort, options:nil)
    cicontext.drawImage(@renderCache, inRect:bounds, fromRect:@boundsBeforeResize || bounds)

    text = slide_manager.current_slide
    text.drawInRect(NSInsetRect(bounds, MARGIN, MARGIN), withAttributes:nil)
  end

  def keyDown(key)
    case key.keyCode
    when KVK_Escape
      exit
    when KVK_LeftArrow
      slide_manager.previous_slide
      self.needsDisplay = true
    when KVK_RightArrow
      slide_manager.next_slide
      self.needsDisplay = true
    else
      case key.characters
      when "f"
        if @fullscreen
          exitFullScreenModeWithOptions nil
          window.makeFirstResponder self
        else
          enterFullScreenMode NSScreen.mainScreen, withOptions: {NSFullScreenModeAllScreens => false}
        end
        @fullscreen = !@fullscreen
      when "r"
        self.needsDisplay = true
      end
    end
  end
end

slide_manager = SlideManager.new(SLIDES)

slide_manager.add_background do
  # based on canvas_example.rb
  background Color.random
  foregroundColor = Color.random
  fill foregroundColor
  stroke 0.2
  stroke_width 1
  font "Zapfino"

  80.times do
    font_size rand(170)
    fill foregroundColor.copy.darken(rand(0.8))
    letters = %W{ m a c r u b y }
    text(letters[rand(letters.size)], rand(width), rand(height))
  end
end

slide_manager.add_background do
  # based on drawing_iterate_example.rb
  background Color.random

  # create a petal shape with base at (0,0), size 40×150, and bulge at 30px
  shape = Path.new
  shape.petal(0,0,40,150,30)
  # add a circle
  shape.oval(-10,20,20,20)
  # color it red
  shape.fill Color.random

  # increment shape parameters by the specified amount each iteration,
  # or by a random value selected from the specified range
  shape.increment(:rotation, 5.0)
  shape.increment(:scale_x, 0.99)
  shape.increment(:scale_y, 0.96)
  shape.increment(:x, 10.0)
  shape.increment(:y, 12.0)
  shape.increment(:hue,-0.02..0.02)
  shape.increment(:saturation, -0.1..0.1)
  shape.increment(:brightness, -0.1..0.1)
  shape.increment(:alpha, -0.1..0.1)

  # draw 200 petals on the canvas
  translate(width/2-150, height/2+20)
  draw(shape,0,0,200)
end

slide_manager.add_background do
  # based on spirograph_example.rb
  background Color.random
  fill Color.random
  font 'Book Antiqua'
  font_size 12
  translate width/2, height/2

  # rotate, draw text, repeat
  180.times do |frame|
    new_state do
      rotate((frame*2) + 120)
      translate(70,0)
      text('going...', 80, 0)
      rotate(frame * 6)
      text('Around and', 20, 0)
    end
  end
end

frame = NSScreen.mainScreen.visibleFrame
app = NSApplication.sharedApplication
app.setActivationPolicy NSApplicationActivationPolicyRegular
app.activateIgnoringOtherApps true
view = SlideView.alloc.initWithFrame(frame)
view.slide_manager = slide_manager

window = NSWindow.alloc.initWithContentRect(frame,
        styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask,
        backing:NSBackingStoreBuffered,
        defer:false)
window.contentView = view
window.makeFirstResponder view
window.center
window.display
window.makeKeyAndOrderFront(nil)
window.orderFrontRegardless

app.run
