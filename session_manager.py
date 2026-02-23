import sys
import json
import os

SESSIONS_FILE: str | None = os.environ.get("ATMUX_SESSIONS_FILE")


def load_sessions() -> dict:
    if SESSIONS_FILE is not None:
        if not os.path.exists(SESSIONS_FILE):
            return {}

        with open(SESSIONS_FILE, "r") as file:
            try:
                return json.load(file)
            except json.JSONDecodeError:
                return {}

    return {}


def save_sessions(hashmap: dict):
    if SESSIONS_FILE is not None:
        with open(SESSIONS_FILE, "w") as file:
            json.dump(hashmap, file, indent=4)


def check_session_exists(session_name: str) -> str:
    sessions_map: dict = load_sessions()

    if sessions_map.get(session_name) is not None:
        return "True"
    else:
        return "False"


def set_session(
    session_name: str,
    session_path: str,
    window_count: int,
    window_names: str,
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


def get_session_path(session_name: str) -> str:
    session_map: dict = load_sessions()
    return session_map[session_name]["session_path"]


def get_window_count(session_name: str) -> int:
    session_map: dict = load_sessions()
    return session_map[session_name]["window_count"]


def get_window_names(session_name: str) -> str:
    session_map: dict = load_sessions()
    return session_map[session_name]["window_names"]


def get_running_all() -> str:
    session_map: dict = load_sessions()
    session_names: str = ""

    for session in session_map:
        if session_map[session]["is_session_running"] == "True":
            session_names += session + " "

    return session_names


def set_all_running_false():
    session_map: dict = load_sessions()
    session_names: list = get_running_all().split()

    for session in session_names:
        session_map[session]["is_session_running"] = "False"

    save_sessions(session_map)


def get_session_running(session_name: str) -> str:
    session_map: dict = load_sessions()
    return session_map[session_name]["is_session_running"]


def set_session_running(session_name: str, session_running: str):
    session_map: dict = load_sessions()
    session_map[session_name]["is_session_running"] = session_running
    save_sessions(session_map)


def delete(session_name: str):
    session_map: dict = load_sessions()
    del session_map[session_name]

    save_sessions(session_map)


def main():
    # Args: 0: script_name, 1... etc
    command = sys.argv[1]

    session_name = None
    session_path = None
    window_count = None
    is_session_running = None
    window_names = None

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
                window_names = sys.argv[5]
            elif len(sys.argv) == 4:
                session_path = sys.argv[3]
                window_count = 1
                window_names = "zsh"
            else:
                session_path = "~"
                window_count = 1
                window_names = "zsh"

            set_session(
                session_name,
                session_path,
                window_count,
                window_names,
                "False",  # set running always false, handle it manually through extra call
            )
        case "set-windows":
            session_name = sys.argv[2]
            window_count = int(sys.argv[3])
            window_names = sys.argv[4]

            set_session(
                session_name,
                get_session_path(session_name),
                window_count,
                window_names,
                "False",
            )
        case "get-session-path":
            session_name = sys.argv[2]
            print(get_session_path(session_name))
        case "get-window-count":
            session_name = sys.argv[2]
            print(get_window_count(session_name))
        case "get-window-names":
            session_name = sys.argv[2]
            print(get_window_names(session_name))
        case "get-running-all":
            print(get_running_all())
        case "get-running":
            session_name = sys.argv[2]
            print(get_session_running(session_name))
        case "set-running":
            session_name = sys.argv[2]
            is_session_running = sys.argv[3]
            set_session_running(session_name, is_session_running)
        case "set-all-running-false":
            set_all_running_false()
        case "delete":
            session_name = sys.argv[2]
            delete(session_name)


if __name__ == "__main__":
    main()
