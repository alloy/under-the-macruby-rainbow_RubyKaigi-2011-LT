# requires to be put in the same directory as https://github.com/drtoast/macruby_graphics

framework 'Cocoa'
here = File.expand_path(File.dirname(__FILE__))
require File.join(here, 'graphics')

SLIDE_WIDTH  = 1024
SLIDE_HEIGHT = 768

BLUR = 1.2

# there are a few problems with constants resolutions
# on the last MacRuby anyway so just do it simple
include MRGraphics

class SlideManager
  def initialize
    @current_slide = 0
    @slides = []
  end

  def next_slide
    @current_slide += 1 if @current_slide < @slides.length - 1
  end

  def previous_slide
    @current_slide -= 1 if @current_slide > 0
  end

  def current_slide
    @slides[@current_slide]
  end

  def add_slide(&block)
    @slides << block
  end
end

class SlideView < NSView
  attr_accessor :slide_manager

  def drawRect(rect)
    NSColor.blackColor.set
    NSRectFill(rect)

    bounds = self.bounds
    size = bounds.size
    ratio = [size.width/SLIDE_WIDTH, size.height/SLIDE_HEIGHT].min

    Canvas.for_rendering(:size => [SLIDE_WIDTH, SLIDE_HEIGHT]) do |c|
      c.translate(size.width/2 - ((SLIDE_WIDTH/2) * ratio), size.height/2 - ((SLIDE_HEIGHT/2 * ratio)))
      c.scale(ratio)
      c.instance_eval(&slide_manager.current_slide)
      applyFilterAndDrawToView(c.ciimage)
    end

    Canvas.for_current_context(:size => [SLIDE_WIDTH, SLIDE_HEIGHT]) do |c|
      c.font "FedraSansDisStd HeavyCond", 200
      c.registration :center
      c.text "Eloy Duran"
    end
  end

  def applyFilterAndDrawToView(ciimage)
    blur = CIFilter.filterWithName("CIGaussianBlur")
    blur.setDefaults
    blur.setValue(BLUR, forKey:KCIInputRadiusKey)
    blur.setValue(ciimage, forKey:KCIInputImageKey)
    cicontext = CIContext.contextWithCGContext(NSGraphicsContext.currentContext.graphicsPort, options:nil)
    cicontext.drawImage(blur.valueForKey(KCIOutputImageKey), atPoint:bounds.origin, fromRect:bounds)
  end

  def keyDown(key)
    case key.keyCode
    when KVK_Escape
      exit
    when KVK_LeftArrow
      slide_manager.previous_slide
      setNeedsDisplay true
    when KVK_RightArrow
      slide_manager.next_slide
      setNeedsDisplay true
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
        setNeedsDisplay true
      end
    end
  end
end

slide_manager = SlideManager.new

slide_manager.add_slide do
  # based on canvas_example.rb
  background Color.black
  white = Color.white
  fill white
  stroke 0.2
  stroke_width 1
  font "Zapfino"

  80.times do
    font_size rand(170)
    fill white.copy.darken(rand(0.8))
    letters = %W{ m a c r u b y }
    text(letters[rand(letters.size)],
            rand(SLIDE_WIDTH),
            rand(SLIDE_HEIGHT))
  end
end

slide_manager.add_slide do
  # based on drawing_iterate_example.rb
  background Color.white

  # create a petal shape with base at (0,0), size 40×150, and bulge at 30px
  shape = Path.new
  shape.petal(0,0,40,150,30)
  # add a circle
  shape.oval(-10,20,20,20)
  # color it red
  shape.fill Color.red

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
  translate(SLIDE_WIDTH/2-150, SLIDE_HEIGHT/2+20)
  draw(shape,0,0,200)
end

slide_manager.add_slide do
  # based on spirograph_example.rb
  background Color.beige
  fill Color.black
  font 'Book Antiqua'
  font_size 12
  translate SLIDE_WIDTH/2, SLIDE_HEIGHT/2

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

frame = [0.0, 0.0, SLIDE_WIDTH, SLIDE_HEIGHT]
app = NSApplication.sharedApplication
app.setActivationPolicy NSApplicationActivationPolicyRegular
app.activateIgnoringOtherApps true
view = SlideView.alloc.initWithFrame(frame)
view.slide_manager = slide_manager

window = NSWindow.alloc.initWithContentRect(frame,
        styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask, 
        backing:NSBackingStoreBuffered, 
        defer:false)
window.contentView = view
window.makeFirstResponder view
window.center
window.display
window.makeKeyAndOrderFront(nil)
window.orderFrontRegardless

app.run
