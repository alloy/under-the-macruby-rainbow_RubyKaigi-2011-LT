framework 'Cocoa'

class SlideView < NSView
  COLORS = [NSColor.blackColor, NSColor.whiteColor, NSColor.redColor, NSColor.blueColor]
  def initWithFrame(frame)
    super
    @slide = 0
    self
  end

  def drawRect(rect)
    COLORS[@slide].set
    NSRectFill(rect)
  end

  def keyDown(key)
    case key.keyCode
    when KVK_Escape
      exit
    when KVK_LeftArrow
      @slide -= 1 if @slide > 0
      self.needsDisplay = true
    when KVK_RightArrow
      @slide += 1 if @slide < COLORS.length - 1
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

frame = NSScreen.mainScreen.visibleFrame
app = NSApplication.sharedApplication
app.setActivationPolicy NSApplicationActivationPolicyRegular
app.activateIgnoringOtherApps true
view = SlideView.alloc.initWithFrame(frame)

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
