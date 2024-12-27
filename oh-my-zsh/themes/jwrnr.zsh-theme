local ret_color="%(?:%{$fg[green]%}:%{$fg[red]%})"
local sep="%{$reset_color%}|"
PROMPT='[ ${ret_color}%T ${sep} %c $(git_prompt_info)] '
RPROMPT=''

ZSH_THEME_GIT_PROMPT_PREFIX="${sep} %{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
