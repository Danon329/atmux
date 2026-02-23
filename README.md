# Add-On for Terminal Multiplexer (ATMUX)

Could also be that that is some kind of tmux wrapper. Don't know how to classify it.
I pretty much just want to add stuff to tmux, which absence kind of annoys me :)

Well absence is the wrong word. It exists also in tmux, but can be done easier for the user, at least for the tracking of running sessions.
Serialization is a story of its own.

### So what have I added?

* Serialization of tmux sessions
* Tracker for actually attached sessions

Thats it, currently.

I still want to add more "settings" options.
Like an ls, delete or get-running-session.

## How to get it to work?

1. Clone the repo to wherever you want  
``git clone https://github.com/Danon329/atmux.git``

2. Make your atmux.sh an executable  
``chmod +x atmux.sh``

3. Go to your .zshrc or .bashrc file and add an alias (at least that is what I have done)  
``alias atmux="$HOME/path/to/your/atmux/file/atmux.sh``

4. It is ***very*** important that you have this specific folder structure for saving:
`$HOME/.config/atmux/sessions.json`
If that doesn't exist, please create it, because I don't have checks yet, that could create it for you.
You will get riddled with errors if that happens

If you want to change the saving location, open the atmux.sh file and on the very top there is an export 
`ATMUX_STATE_FILE`, there you can put your path.
