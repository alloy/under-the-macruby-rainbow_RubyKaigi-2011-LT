b = NSButton.new
b.frame = [50, 50, 150, 20]
b.title = 'making tenderlove'
b.action = 'say:'
b.target = self

w = window
w.contentView.addSubview(b)

def say(_)
  NSSpeechSynthesizer.new.startSpeakingString('zomg')
end
