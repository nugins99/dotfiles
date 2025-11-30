set -o  vi
export PATH=/opt/vim/bin:$PATH
export PATH=~/.local/bin:~/.local/node/bin:$PATH

alias ls="ls --color"

# Setup some minikube stuff if minikube is running
if  command -v minikube  &> /dev/null ; then
    if minikube status  > /dev/null ; then

        eval $(minikube completion bash)
        eval $(minikube docker-env)

        # Kubectl alias & completion
        alias kubectl="minikube kubectl --"
        source <(kubectl completion bash)

    fi
fi
unset __conda_setup
# <<< conda init <<<



export PATH="$HOME/.cargo/bin:$PATH"
