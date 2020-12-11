if exists('g:loaded_github_notif') && g:loaded_github_notif
  finish
endif

let g:loaded_github_notif = 1

command! -nargs=0 NotifEnable call github_notif#run()
command! -nargs=0 NotifDisable call github_notif#stop()
command! -nargs=0 NotifOpen call github_notif#open()
