# 心 xin - the root of physical and mental life.

local ret_symbol="ø"
#local ret_symbol="心"
local ret_status="%(?:%{$fg_bold[green]%}${ret_symbol}:%{$fg_bold[red]%}${ret_symbol}%s)"
#local ret_status="%(?:%{$fg_bold[green]%}心:%{$fg_bold[red]%}心%s)"

PROMPT='${ret_status}%{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$reset_color%}'

RPROMPT='%{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%}%{$fg[blue]%} %t%{$reset_color%}%'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%} %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%}"
