import sys
import json
import os

SESSIONS_FILE: str = "sessions.json"


def load_sessions() -> dict:
    if not os.path.exists(SESSIONS_FILE):
        return {}

    with open(SESSIONS_FILE, "r") as file:
        try:
            return json.load(file)
        except json.JSONDecodeError:
            return {}


def save_sessions(hashmap: dict):
    with open(SESSIONS_FILE, "w") as file:
        json.dump(hashmap, file, indent=4)


def check_session_exists(session_name: str) -> bool:
    sessions_map: dict = load_sessions()

    if sessions_map.get(session_name) is not None:
        return True
    else:
        return False


def set_session(
    session_name: str,
    session_path: str,
    window_count: int,
    window_names: dict,
    is_session_running: str,
):
    session_map: dict = load_sessions()
    session_details: dict = {
        "session_path": session_path,
        "window_count": window_count,
        "window_names": window_names,
        "is_session_running": is_session_running,
    }

    session_map[session_name] = session_details
    save_sessions(session_map)


def get_session(session_name: str) -> str:
    session_map: dict = load_sessions()
    return session_map[session_name]


def get_session_running(session_name: str) -> str:
    session_map: dict = load_sessions()
    return session_map[session_name]["is_session_running"]


def set_session_running(session_name: str, session_running: str):
    session_map: dict = load_sessions()
    session_map[session_name]["is_session_running"] = session_running
    save_sessions(session_map)


def main():
    # Args: 0: script_name, 1... etc
    command = sys.argv[1]

    session_name = None
    session_path = None
    window_count = None
    is_session_running = None
    window_names = {}

    match command:
        case "check":
            session_name = sys.argv[2]
            print(check_session_exists(session_name))
        case "set":
            session_name = sys.argv[2]

            # always give path, but don't need to always give window_count
            if len(sys.argv) > 4:
                session_path = sys.argv[3]
                window_count = int(sys.argv[4])

                for i in range(window_count):
                    window_names[i + 1] = sys.argv[5 + i]
            elif len(sys.argv) == 4:
                session_path = sys.argv[3]
                window_count = 1
                window_names = {1: "zsh"}
            else:
                session_path = "~"
                window_count = 1
                window_names = {1: "zsh"}

            set_session(
                session_name,
                session_path,
                window_count,
                window_names,
                "False",  # set running always false, handle it manually through extra call
            )
        case "get":
            session_name = sys.argv[2]
            # TODO: need specific gets. Cannot just parse a dict to bash (I am not gifted enough for that)
        case "get-running-all":
            # TODO: get all running sessions with running = True. Give them back in one string --format: "session1 session2 session3"
            pass
        case "get-running":
            session_name = sys.argv[2]
            print(get_session_running(session_name))
        case "set-running":
            session_name = sys.argv[2]
            is_session_running = sys.argv[3]
            set_session_running(session_name, is_session_running)
        case "set_all_running_false":
            # TODO: Write a function that iterates through all sessions and sets them false
            pass
        # TODO: Create a delete session function, if session gets exited


if __name__ == "__main__":
    main()
