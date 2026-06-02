#!/bin/bash
SESSION_NAME="ai-native-fe-prac"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

tmux has-session -t $SESSION_NAME 2>/dev/null
if [ $? -eq 0 ]; then
    echo "기존 세션을 발견했습니다. 연결합니다..."
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

CMD="claude --dangerously-skip-permissions"

# 좌측 상단: User App
tmux new-session -d -s $SESSION_NAME -n 'Workspace'
P_USER=$(tmux display-message -t $SESSION_NAME:1.1 -p '#{pane_id}')
tmux send-keys -t $P_USER "cd $BASE_DIR/prac-fe-app-user && $CMD" C-m

# User 패널을 좌우 분할 → 우측 상단: Driver App
P_DRIVER=$(tmux split-window -h -t $P_USER -P -F '#{pane_id}')
tmux send-keys -t $P_DRIVER "cd $BASE_DIR/prac-fe-app-driver && $CMD" C-m

# User 패널을 상하 분할 → 좌측 하단: Admin Web
P_MGMT=$(tmux split-window -v -t $P_USER -P -F '#{pane_id}')
tmux send-keys -t $P_MGMT "cd $BASE_DIR/prac-fe-web-management && $CMD" C-m

# Driver 패널을 상하 분할 → 우측 하단: Intro Web
P_INTRO=$(tmux split-window -v -t $P_DRIVER -P -F '#{pane_id}')
tmux send-keys -t $P_INTRO "cd $BASE_DIR/prac-fe-web-intro && $CMD" C-m

# 2x2 정렬
tmux select-layout -t $SESSION_NAME:1 tiled

tmux select-pane -t $P_USER
tmux attach-session -t $SESSION_NAME