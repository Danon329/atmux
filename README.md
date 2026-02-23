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

Next I would recommend creating your own sessions.json file. Be careful that it is named like that.  
You don't have to create your own sessions.json file, but don't be surprised if you will get a python error message, everything should still work fine.  
``touch sessions.json`` -> inside the same folder where atmux.sh is located.
